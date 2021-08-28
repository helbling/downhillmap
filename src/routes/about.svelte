<style>
	main {
		flex: 1;
		display: flex;
		flex-direction: column;
		padding: 1rem;
		width: 100%;
		max-width: 1024px;
		margin: 0 auto;
		box-sizing: border-box;
	}
	.content {
		width: 100%;
		max-width: var(--column-width);
		margin: var(--column-margin-top) auto 0 auto;
	}
	ul { padding-left:2em; margin:-0.8em }
	li { margin:0.2em }
</style>

<script>
		import '../app.css';
</script>

<main>
	<div class="content">
		<h1>About</h1>

		<p>
			Downhillmap is a map which visualizes the slopes of paths and streets in Switzerland and Liechtenstein with colors. Red is very steep, white is flat.
		</p>

		<p>
			The map is based on data available freely from swisstopo:
		</p>
		<ul>
			<li>
				Paths and streets: <a href="https://www.swisstopo.admin.ch/en/geodata/landscape/tlm3d.html">swissTLM3d</a>
			</li>
			<li>
				Background: <a href="https://www.geo.admin.ch/en/geo-services/geo-services/portrayal-services-web-mapping/vector_tiles_service.html">Vector map (style: Light Base Map)</a>
			</li>
		</ul>

		<p>
			Many thanks to everyone who made the <a href="https://www.swisstopo.admin.ch/en/swisstopo/free-geodata.html">Open Government Data (OGD) strategy </a> possible!
		</p>

		<p>
			The code is available on github:  <a href="https://github.com/helbling/downhillmap">https://github.com/helbling/downhillmap</a>
		</p>

		<p>
			<a href="/">Back to the map</a>
		</p>
	</div>
</main>
