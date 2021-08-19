#!/bin/sh

OUT=var/tlm_strasse_slope.mbtiles

rm -f $OUT

ogr2ogr -dsco MINZOOM=12 -dsco MAXZOOM=18 -f MBTILES $OUT PG:"dbname=downhillmap user=gisuser" tlm_strasse_slope # -clipdst 8.689674 47.462188 8.892401 47.53148
