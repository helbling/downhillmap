<script>
	import { run } from 'svelte/legacy';


import { onMount, mount } from 'svelte';
import maplibregl from 'maplibre-gl'
import SearchButtonIcon from '$lib/SearchButtonIcon.svelte';
import AutoComplete from "simple-svelte-autocomplete";

let mapDiv = $state();
let map = $state();
let searchActive = $state(false);
let selectedLocation = $state();

run(() => {
	if (map && selectedLocation) {
		map.fitBounds(selectedLocation.bbox, { maxZoom: 15 });
		searchActive = false;
	}
});


class AboutButton {
	onAdd(map) {
		this._map = map;

		const button = document.createElement('button');
		button.className = 'custom-button';
		button.insertAdjacentHTML(
			'beforeend',
			`<a href='/about'><svg width='24' height='24' viewBox='0 0 20 20' xmlns='http://www.w3.org/2000/svg' fill-rule='evenodd'><path d='M4 10a6 6 0 1012 0 6 6 0 10-12 0m5-3a1 1 0 102 0 1 1 0 10-2 0m0 3a1 1 0 112 0v3a1 1 0 11-2 0'/></svg></span></a>`
		);
		this._container = document.createElement('div');
		this._container.className = 'maplibregl-ctrl maplibregl-ctrl-group';
		this._container.appendChild(button);

		return this._container;
	}

	onRemove() {
		this._container.parentNode.removeChild(this._container);
		this._map = undefined;
	}
}

class SearchButton {
	onAdd(map) {
		this._map = map;

		const button = document.createElement('button');
		button.className = 'custom-button';
		this.icon = mount(SearchButtonIcon, {
			target: button,
			props: { searchActive }
		});
		button.onclick = () => { searchActive = !searchActive };

		this._container = document.createElement('div');
		this._container.className = 'maplibregl-ctrl maplibregl-ctrl-group';
		this._container.appendChild(button);

		return this._container;
	}

	onRemove() {
		this._container.parentNode.removeChild(this._container);
		this._map = undefined;
	}
}

const searchButton = new SearchButton();
run(() => {
		if (searchButton.icon) {
		searchButton.icon.$set({searchActive});
	}
});
run(() => {
		if (searchActive && window) {
		window.setTimeout(
			() => document.querySelector(".location-search input").focus(),
			100
		);
	}
	});
onMount(() => {
	window.map = map = new maplibregl.Map({
		container: mapDiv,
		style: 'https://vectortiles.geo.admin.ch/styles/ch.swisstopo.leichte-basiskarte.vt/style.json',
		center: [8.94122, 47.3709],
		zoom: 15,
		maxBounds: [
			5.9559,
			45.818,
			10.4921,
			47.8084
		],
		hash: true,
		attributionControl: false, // added manually further down
	})

	const lineColor = [
		'interpolate',
		['linear'],
		['get', 'slope'],
	];
	// chroma.js lightyellow, orange, deeppink, darkred
	// https://jsfiddle.net/vis4/cYLZH/
	const chromaJsColors = ['#ffffe0', '#ffe0a9', '#ffbe84', '#ff986d', '#f47361', '#e35056', '#cb2f44', '#ae112a', '#8b0000'];
	chromaJsColors.forEach((color, index) => {

		lineColor.push(0.6 * index / ( chromaJsColors.length - 1 ));
		lineColor.push(color);
	});

	map.on('load', () => {
		var origin = (new URL(window.location.href)).origin;
		map.addSource('slope_exact', {
			"type": "vector",
			"tiles": [origin + "/tile?z={z}&x={x}&y={y}&layer=slope_exact" ],
			"minzoom": 12,
			"maxzoom": 18
		});
		map.addSource('slope_avg', {
			"type": "vector",
			"tiles": [origin + "/tile?z={z}&x={x}&y={y}&layer=slope_avg" ],
			"minzoom": 11,
			"maxzoom": 14
		});

		const slopeStyle = {
			"type": "line",
			'minzoom': 13,
			"paint": {
				"line-width": [
					'interpolate',
					['linear'],
					['zoom'],
					12, 2,
					15, 4,
					18, 10,
				],
				"line-color": lineColor,
			},
			"layout": {
				"line-cap": "round",
			},
			"source": "slope_exact",
			"source-layer": "tlm_strasse_slope",
		};

		const isLinestring = [ '==', [ 'geometry-type' ], 'LineString'];
		const isPath = ['any',
			[ 'in', [ 'get', 'objektart'], ['literal', ['1m Weg', '1m Wegfragment', 'Klettersteig', 'Markierte Spur']]],
			[ 'all',
				[ 'in', [ 'get', 'objektart'], ['literal', ['2m Weg', '2m Wegfragment']]],
				[ 'in', [ 'get', 'belagsart'], ['literal', ['Natur', 'k_W']]],
			],
		];

		map.addLayer(Object.assign({}, slopeStyle, {
			'filter': [ 'all',
				isLinestring,
				isPath,
			],
			"id": "slopes_path",
		}), "road_path_footway");
		map.addLayer(Object.assign({}, slopeStyle, {
			"id": "slopes_avg_path",
			"source": "slope_avg",
			"source-layer": "tlm_strasse_slope_avg",
			'minzoom': 8,
			'maxzoom': 13,

		}), "road_path_footway");
		map.addLayer(Object.assign({}, slopeStyle, {
			'filter': [ 'all',
				isLinestring,
				["!", isPath],
			],
			"id": "slopes_street",
		}), "building_2d");


		let mainSource = Object.keys(map.getStyle().sources).filter((x) => x.startsWith('leichtebasiskarte'))[0] ?? 'leichtebasiskarte_v3.0.1';

		// distinguish steps from paths
		const roadPath = map.getLayer('road_path_footway');
		if (roadPath) {
			const roadPathFilter = roadPath.filter.slice(); // clone
			map.setFilter('road_path_footway', ['all', roadPathFilter, ['!=', ['get', 'subclass'], 'steps']]);

			const steps = {
				id: 'steps',
				filter: ['all', roadPathFilter, ['==', ['get', 'subclass'], 'steps']]	,
				type: "line",
				source: mainSource,
				"source-layer": "transportation",
				minzoom: 14,
				layout: {
					"line-cap": "butt",
					"line-join": "bevel",
					"visibility": "visible"
				},
				paint: {
					'line-blur': map.getPaintProperty('road_path_footway', 'line-blur'),
					'line-color': map.getPaintProperty('road_path_footway', 'line-color'),
					'line-opacity': map.getPaintProperty('road_path_footway', 'line-opacity'),
					'line-width': map.getPaintProperty('road_path_footway', 'line-width'),
					'line-dasharray': [1, 1],
				},
			};
			map.addLayer(steps, 'road_path_footway');
			map.moveLayer('slopes_path', 'steps');
		}

		const slopesTextExact = {
			"id": "slopes_text_exact",
			"type": "symbol",
			'minzoom': 17,
			"layout": {
				"text-field": ['concat', ['to-string', ['round', ['*', 100, ['get', 'slope']]]], '%'],
				"symbol-placement": "line-center",
				"text-font": ["Frutiger Neue Regular"],
				"text-size": 16,
			},
			"paint": {
				'text-halo-blur':0,
				'text-halo-color':'#fff',
				'text-halo-width':2,
			},
			"source": "slope_exact",
			"source-layer": "tlm_strasse_slope",
		};
		map.addLayer(slopesTextExact);
		map.addLayer(Object.assign({}, slopesTextExact, {
			"id": "slopes_text_avg",
			"minzoom": 16,
			"maxzoom": 17,
			"source": "slope_avg",
			"source-layer": "tlm_strasse_slope_avg",
		}));

		const popup = new maplibregl.Popup({
			closeButton: false,
			closeOnClick: false
		});

		for (const layerId of ['slopes_path', 'slopes_street']) {
			map.on('mouseenter', layerId, function (e) {
				map.getCanvas().style.cursor = 'pointer';
				var description = 'Slope: ' + Math.round(e.features[0].properties.slope * 100) + '%';
				popup.setLngLat(e.lngLat).setHTML(description).addTo(map);
			});

			map.on('mouseleave', layerId, function () {
				map.getCanvas().style.cursor = '';
				popup.remove();
			});
		}
	});

	map.addControl(searchButton, 'top-right');
	map.addControl(
		new maplibregl.GeolocateControl({
			positionOptions: {
			  enableHighAccuracy: true
			},
		}),
		'top-right',
	);

	map.addControl(
		new maplibregl.AttributionControl({
			compact: false,
		}),
		'bottom-right',
	);

	map.addControl(new maplibregl.ScaleControl(), 'bottom-left');
	map.addControl(new AboutButton(), 'top-left');

});

async function locationAutocomplete(keyword) {
	const url = 'https://api3.geo.admin.ch/rest/services/api/SearchServer?type=locations&sr=4326&geometryFormat=geojson&limit=10&searchText=' + encodeURIComponent(keyword);

	const response = await fetch(url);
	const json = await response.json();

	return json.features;
}
</script>

<svelte:head>
	<link rel="stylesheet" href="./maplibre-gl.css" />
</svelte:head>

<style>
	.map {
		position: absolute;
		top: 0;
		bottom: 0;
		left: 0;
		right: 0;
	}
	:global(.custom-button a) {
		width:100%;
		height:100%;
		display:inline-block;
	}
	:global(.custom-button svg) {
		margin-top:2.5px;
	}
	:global(.autocomplete) {
		min-width:100% !important;
	}
	.location-search {
		position:absolute;
		top: 9px;
		left: 50px;
		right: 50px;
		display:none;
	}
	.location-search.active {
		display:block;
	}
</style>

<div class="map" bind:this={mapDiv}></div>

<div
	class=location-search
	class:active={searchActive}
>
	<AutoComplete
		searchFunction={locationAutocomplete}
		delay=200
		localFiltering={false}
		bind:selectedItem={selectedLocation}
		labelFunction={item => item ? item.properties.label.replace(/<[^>]*>?/gm, '') : ''}
		showClear={true}
		hideArrow={true}
		/>
</div>
