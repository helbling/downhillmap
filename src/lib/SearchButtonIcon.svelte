<svelte:options namespace=svg />

<script>
	let { searchActive } = $props();
</script>

<svg id="i-search" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="16" height="16" fill="none" stroke="currentcolor" stroke-linecap="round" stroke-linejoin="round" stroke-width="4">

{#if searchActive}
	<path d="M2 30 L30 2 M30 30 L2 2" />
{:else}
    <circle cx="14" cy="14" r="12" />
    <path d="M23 23 L30 30"  />
{/if}
</svg>
