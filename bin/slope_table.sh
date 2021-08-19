#!/bin/sh

OTHERCOLS="uuid, objektart, belagsart, kunstbaute, name"

psql -d downhillmap gisuser << EOT

	DROP TABLE IF EXISTS tlm_strasse_slope;

	CREATE TABLE tlm_strasse_slope AS
		SELECT
			geom,
			(st_z(st_startpoint(geom)) - st_z(st_endpoint(geom)))/st_length(geom::geography) as slope,
			$OTHERCOLS
		FROM (
			SELECT
				CASE WHEN st_z(st_startpoint(splitted)) < st_z(st_endpoint(splitted)) THEN St_Reverse(splitted) ELSE splitted END as geom,
				$OTHERCOLS
			FROM (
				SELECT
					(st_dump(st_split(geom, st_points(geom)))).geom as splitted,
					$OTHERCOLS
				FROM tlm_strasse_3d
			) a
		) b;

	CREATE INDEX ON tlm_strasse_slope using GIST(geom);
EOT

