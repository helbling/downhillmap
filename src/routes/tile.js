import MBTiles from '@mapbox/mbtiles';
import { promisify } from 'util';

var MBTilesPromise = promisify(MBTiles);

export async function get({ query }) {
	const z = parseInt(query.get('z'));
	const x = parseInt(query.get('x'));
	const y = parseInt(query.get('y'));
	const mbtiles = await new MBTilesPromise('var/tlm_strasse_slope.mbtiles?mode=ro');

	try {
		const tile = await promisify(mbtiles.getTile.bind(mbtiles))(z, x, y);
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

