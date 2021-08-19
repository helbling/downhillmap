#!/bin/sh

mkdir -p var

SHP_PATH=var/swissTLM3D_TLM_STRASSE.shp
DESCRIPTION=$(date '+Imported %F on ')$(cat /proc/sys/kernel/hostname)

if [ ! -f $SHP_PATH ]; then
	wget https://data.geo.admin.ch/ch.swisstopo.swisstlm3d/swisstlm3d_2021-04/swisstlm3d_2021-04_2056_5728.shp.zip -O var/tlm3d.shp.zip
	unzip -j var/tlm3d.shp.zip 2021_SWISSTLM3D_SHP_CHLV95_LN02/TLM_STRASSEN/swissTLM3D_TLM_STRASSE.* -d var/
fi

SHAPE_ENCODING=utf8 ogr2ogr \
	-f "PostgreSQL" PG:"dbname=downhillmap user=gisuser" \
	--config PG_USE_COPY YES \
	-overwrite \
	-lco geometry_name=geom \
	-lco precision=no \
	-lco description="$DESCRIPTION" \
	-t_srs EPSG:4326 \
	-nlt PROMOTE_TO_MULTI \
	-nln tlm_strasse_3d \
	-dim XYZ \
	$SHP_PATH
