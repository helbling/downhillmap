import MBTiles from '@mapbox/mbtiles';
import { promisify } from 'util';
import { error } from '@sveltejs/kit';

var MBTilesPromise = promisify(MBTiles);

const dataLayers = ['slope_avg', 'slope_exact'];
let mbtiles;

export async function GET({ url }) {
	const query = url.searchParams;
	const z = parseInt(query.get('z'));
	const x = parseInt(query.get('x'));
	const y = parseInt(query.get('y'));
	const layer = query.get('layer');

	try {
		if (!mbtiles) {
			mbtiles = {};
			for (const dataLayer of dataLayers)
				mbtiles[dataLayer] = await new MBTilesPromise('var/' + dataLayer + '.mbtiles?mode=ro');
		}

		const mbtilesLayer = mbtiles[layer];
		if (!mbtilesLayer)
			throw error(404, 'Layer not found');

		const tile = await promisify(mbtilesLayer.getTile.bind(mbtilesLayer))(z, x, y);

		return new Response(
			tile,
			{
				headers: {
					'content-encoding': 'gzip',
					'content-type': 'application/vnd.mapbox-vector-tile',
				}
			}
		);
	} catch (e) {
		throw error(404, 'Tile not found');
	}
}

