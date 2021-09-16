#!/bin/sh

rm -f var/slope_exact.mbtiles
ogr2ogr -dsco MINZOOM=12 -dsco MAXZOOM=18 -f MBTILES var/slope_exact.mbtiles PG:"dbname=downhillmap user=gisuser" tlm_strasse_slope_exact

ogr2ogr -update -append -dsco MINZOOM=10 -dsco MAXZOOM=12 -f MBTILES var/tlm_strasse_slope.mbtiles PG:"dbname=downhillmap user=gisuser" tlm_strasse_slope_avg -clipdst 8.689674 47.462188 8.892401 47.53148

rm -f var/slope_avg.mbtiles
ogr2ogr -dsco MINZOOM=8 -dsco MAXZOOM=14 -f MBTILES var/slope_avg.mbtiles PG:"dbname=downhillmap user=gisuser" tlm_strasse_slope_avg
