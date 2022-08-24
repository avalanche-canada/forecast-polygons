## Imports
library(sp)
library(rgdal)
library(rgeos)
library(uuid)
library(geojsonio)

## Read geojson file
subregion_dir <- 'H:/My Drive/snowmodels/subregions'
fx <- geojson_read(file.path(subregion_dir, 'canadian_subregions.geojson'), parse = T, what = 'sp')

## id
new_ids <- UUIDgenerate(n = sum(is.na(fx$id)))
fx$id[is.na(fx$id)] <- new_ids
fx$id <- toupper(fx$id)

## polygon_number
fx$polygon_number <- 1:nrow(fx)

## mountain_range
mountain_ranges <- readOGR(file.path(subregion_dir, 'edits/mountain_ranges.kml'))
fx$mountain_range <- over(gCentroid(fx, byid = T), mountain_ranges)$Name
sort(table(fx$mountain_range))

## reference_region
reference_regions <- readOGR(file.path(subregion_dir, 'edits/reference_regions.kml'))
fx$reference_region <- over(gCentroid(fx, byid = T), reference_regions)$Name
## check for subregions with centroids outside of reference regions then manually set
message('Need to manually set reference regions for:')
print(as.character(fx$polygon_name[is.na(fx$reference_region)]))
fx$reference_region[fx$polygon_name %in% c('LLSA', 'Banff')] <- 'Banff Yoho Kootenay'
fx$reference_region[fx$polygon_name %in% c('Bow Valley')] <- 'Kananaskis'
fx$reference_region[fx$polygon_name %in% c('Pyramid', 'Miette Lake')] <- 'Jasper'
sort(table(fx$reference_region))

## agency_name
fx$agency_name <- 'avalanche_canada'
fx$agency_name[fx$reference_region == 'Glacier'] <- 'parks_canada_glacier'
fx$agency_name[fx$reference_region == 'Waterton Lakes'] <- 'parks_canada_waterton'
fx$agency_name[fx$reference_region == 'Jasper'] <- 'parks_canada_jasper'
fx$agency_name[fx$reference_region %in% c('Banff Yoho Kootenay', 'Little Yoho')] <- 'parks_canada_byk'
fx$agency_name[fx$reference_region == 'Kananaskis'] <- 'kananaskis'
fx$agency_name[fx$polygon_name %in% c('Bighorn', 'Ghost')] <- 'kananaskis'
fx$agency_name[fx$reference_region == 'Chic-Chocs'] <- 'avalanche_quebec'
sort(table(fx$agency_name))

## Order rows and columns
fx <- fx[order(fx$agency_name, fx$reference_region, fx$polygon_name),]
fx$polygon_number <- 1:nrow(fx)
fx <- fx[,c('id', 'polygon_name', 'polygon_number', 'mountain_range', 'reference_region', 'agency_name', 'creation_date', 'last_updated')]

## View results
head(fx)
View(fx@data)

## Save
geojson_write(fx, file = file.path(subregion_dir, 'canadian_subregions_unwound.geojson'), layer = '')

## Remember to perform command line corrections to the output of geojson_write
# cd /mnt/h/My\ Drive/snowmodels/subregions
# geojson-rewind canadian_subregions_unwound.geojson > canadian_subregions_fixed.geojson
# sed -i 's/{"type":"Feature"/\'$'\n{"type":"Feature"/g' canadian_subregions_fixed.geojson
