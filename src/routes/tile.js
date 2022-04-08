import MBTiles from '@mapbox/mbtiles';
import { promisify } from 'util';

var MBTilesPromise = promisify(MBTiles);

const dataLayers = ['slope_avg', 'slope_exact'];
let mbtiles;
export async function get({ url }) {
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
			return {
				status: 404,
				body: 'Layer not found',
			};
		const tile = await promisify(mbtilesLayer.getTile.bind(mbtilesLayer))(z, x, y);
		return {
			headers: {
				'content-encoding': 'gzip',
				'content-type': 'application/vnd.mapbox-vector-tile',
			},
			body: tile
		};
	} catch (e) {
		return {
			status: 404,
			body: 'Tile not found',
		}
	}
}

