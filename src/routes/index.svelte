<script>

import { onMount } from 'svelte';
import { Map, AttributionControl, GeolocateControl, ScaleControl, Popup } from 'maplibre-gl'

class AboutButton {
	onAdd(map) {
		this._map = map;
		/*
		const span = document.createElement('span');
		span.className = 'maplibregl-ctrl-attrib-button';
		 */

		const button = document.createElement('button');
		button.className = 'about-button';
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

let mapDiv;

onMount(() => {
	const map = new Map({
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
		map.addSource('slopes', {
			"type": "vector",
			"scheme": "tms",
			"tiles": [ document.location.origin + "/tile/{z}/{x}/{y}"], // NOTE for develpment: uncomment scheme:tms and use "http://localhost:3000/tile?z={z}&x={x}&y={y}"
			"minzoom": 12,
			"maxzoom": 18
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
			"filter": [ 'all',
				[ '==', [ 'geometry-type' ], 'LineString'],
				//			[ '>=', [ 'get', 'slope' ], 0.05],
			],
			"source": "slopes",
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
		}), "road_path");
		map.addLayer(Object.assign({}, slopeStyle, {
			'filter': [ 'all',
				isLinestring,
				["!", isPath],
			],
			"id": "slopes_street",
		}), "building_2d");


		// distinguish steps from paths
		const roadPath = map.getLayer('road_path');
		if (roadPath) {
			const roadPathFilter = roadPath.filter.slice(); // clone
			map.setFilter('road_path', ['all', roadPathFilter, ['!=', ['get', 'subclass'], 'steps']]);
			
			const steps = {
				id: 'steps',
				filter: ['all', roadPathFilter, ['==', ['get', 'subclass'], 'steps']]	,
				type: "line",
				source: "swissmaptiles",
				"source-layer": "transportation",
				minzoom: 14,
				layout: {
					"line-cap": "butt",
					"line-join": "bevel",
					"visibility": "visible"
				},
				paint: {
					'line-blur': map.getPaintProperty('road_path', 'line-blur'),
					'line-color': map.getPaintProperty('road_path', 'line-color'),
					'line-opacity': map.getPaintProperty('road_path', 'line-opacity'),
					'line-width': map.getPaintProperty('road_path', 'line-width'),
					'line-dasharray': [1, 1],
				},
			};
			map.addLayer(steps, 'road_path');
			map.moveLayer('slopes_path', 'steps');
		}

		map.addLayer({
			"id": "slopes_text",
			"type": "symbol",
			'minzoom': 18,
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
			"source": "slopes",
			"source-layer": "tlm_strasse_slope",
		});

		const popup = new Popup({
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

	map.addControl(
	  new GeolocateControl({
		positionOptions: {
		  enableHighAccuracy: true
		},
	  })
	);

	map.addControl(
		new AttributionControl({
			compact: false,
		})
	);

	map.addControl(new ScaleControl());
	map.addControl(new AboutButton());

});
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
	:global(.about-button a) {
		width:100%;
		height:100%;
		display:inline-block;
	}
	:global(.about-button svg) {
		margin-top:2.5px;
	}
</style>

<div class="map" bind:this={mapDiv} />
