#!/bin/bash

## Install ogr2ogr (https://gdal.org/programs/ogr2ogr.html)
# apt install gdal-bin
# apt install zip

## Create KML and shapefile versions of masterfile
ogr2ogr -f "KML" -a_srs EPSG:4326 -sql "SELECT polygon_name AS Name, * FROM canadian_subregions" canadian_subregions.kml canadian_subregions.geojson
ogr2ogr -f "ESRI Shapefile" -a_srs EPSG:4326 canadian_subregions.shp canadian_subregions.geojson
zip canadian_subregions.shp.zip canadian_subregions.dbf canadian_subregions.prj canadian_subregions.shp canadian_subregions.shx
rm canadian_subregions.dbf canadian_subregions.prj canadian_subregions.shp canadian_subregions.shx

## Create subsets for each agency
agencies="avalanche_canada avalanche_quebec kananaskis parks_canada_byk parks_canada_glacier parks_canada_jasper parks_canada_waterton"
for agency in $agencies; do
	echo "Subsetting $agency"
	mkdir -p subsets/$agency
	cd subsets/$agency
	ogr2ogr -f "GeoJSON" -nln "" -sql "SELECT * FROM canadian_subregions WHERE agency_name = '$agency'"  $agency.geojson ../../canadian_subregions.geojson
	ogr2ogr -f "KML" -a_srs EPSG:4326 -sql "SELECT polygon_name AS Name, * FROM canadian_subregions WHERE agency_name = '$agency'" $agency.kml ../../canadian_subregions.geojson
	ogr2ogr -f "ESRI Shapefile" -a_srs EPSG:4326 -sql "SELECT * FROM canadian_subregions WHERE agency_name = '$agency'" $agency.shp ../../canadian_subregions.geojson
	zip $agency.shp.zip $agency.dbf $agency.prj $agency.shp $agency.shx
	rm $agency.dbf $agency.prj $agency.shp $agency.shx
	cd -
done
