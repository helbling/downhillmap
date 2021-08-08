<script>

import { onMount } from 'svelte';
import { Map, GeolocateControl } from 'maplibre-gl'

let mapDiv;

onMount(() => {
	const mapTilerKey = "get_your_own_OpIi9ZULNHzrESv6T2vL"
	// at https://cloud.maptiler.com/account/keys/
	const map = new Map({
		container: mapDiv,
		style: 'https://vectortiles.geo.admin.ch/styles/ch.swisstopo.leichte-basiskarte.vt/style.json',
		center: [8.85, 47.49],
		zoom: 15
	})

	map.addControl(
	  new GeolocateControl({
		positionOptions: {
		  enableHighAccuracy: true
		},
	  })
	)
});
</script>

<svelte:head>
	<link rel="stylesheet" href="/maplibre-gl.css" />
</svelte:head>

<style>
	.map {
	  position: absolute;
	  top: 0;
	  bottom: 0;
	  left: 0;
	  right: 0;
	}
</style>

<div class="map" bind:this={mapDiv} />
