## Set your working directory here
setwd('H:/My Drive/snowmodels/dev/forecast-polygons')

## Imports
if(!require(sf)) {install.packages('sf'); library(sf)}

## Read geojson file
fx <- read_sf('canadian_subregions.geojson')

## validate geometry
which_invalid <- which(!st_is_valid(fx))
if (length(which_invalid) > 0) {
  message(paste('Attempting to repair:', paste(fx$polygon_name[which_invalid], collapse = ', ')))
  fx <- st_make_valid(fx)
  which_invalid <- which(!st_is_valid(fx))
  message(ifelse(length(which_invalid) < 1, 'Repaired all!',
                 paste('Failed to repair:', paste(fx$polygon_name[which_invalid], collapse = ', '))))
}

## centroids
centroids <- st_centroid(fx)
centroids_text <- round(st_coordinates(centroids), 3)
fx$centroid <- paste0('[', centroids_text[,1], ', ', centroids_text[,2], ']')

## id
if (any(is.na(fx$id))) {
  if(!require(uuid)) {install.packages('uuid'); library(uuid)}
  new_ids <- UUIDgenerate(n = sum(is.na(fx$id)))
  new_ids <- toupper(new_ids)
  fx$id[is.na(fx$id)] <- new_ids
  message(paste('Created', length(new_ids), 'new ids'))
}

## polygon_number
## Fill empty polygon numbers with any numbers missing in the sequence before increasing the number
if (any(is.na(fx$polygon_number))) {
  for (i in which(is.na(fx$polygon_number))) {
    missing_numbers <- which(!(1:max(fx$polygon_number, na.rm = T) %in% fx$polygon_number))
    fx$polygon_number[i] <- ifelse(length(missing_numbers) == 0,
                                   max(fx$polygon_number, na.rm = T) + 1,
                                   missing_numbers[1])
  }
  message(paste('Set', i, 'new polygon_numbers'))
}

## mountain_range
if (any(is.na(fx$mountain_range))) {
  mountain_ranges <- read_sf('editting_tools/mountain_ranges.kml')
  fx$mountain_range <- st_join(centroids, mountain_ranges)$Name
}
sort(table(fx$mountain_range))

## reference_region
if (any(is.na(fx$reference_region))) {
  reference_regions <- read_sf('editting_tools/reference_regions.geojson')
  fx$reference_regions <- st_join(centroids, reference_regions)$Name
  ## check for subregions with centroids outside of reference regions then manually set
  message('Need to manually set reference regions for: ', paste(fx$polygon_name[is.na(fx$reference_region)], collapse = ', '))
  fx$reference_region[fx$polygon_name %in% c('LLSA', 'Banff')] <- 'Banff Yoho Kootenay'
  fx$reference_region[fx$polygon_name %in% c('Bow Valley')] <- 'Kananaskis'
  fx$reference_region[fx$polygon_name %in% c('Pyramid', 'Miette Lake')] <- 'Jasper'
}
sort(table(fx$reference_region))

## agency_name
fx$agency_name <- 'avalanche_canada'
fx$agency_name[fx$reference_region == 'Glacier'] <- 'parks_canada_glacier'
fx$agency_name[fx$reference_region == 'Waterton Lakes'] <- 'parks_canada_waterton'
fx$agency_name[fx$reference_region == 'Jasper'] <- 'parks_canada_jasper'
fx$agency_name[fx$reference_region %in% c('Banff Yoho Kootenay', 'Little Yoho')] <- 'parks_canada_byk'
fx$agency_name[fx$reference_region == 'Kananaskis'] <- 'kananaskis'
fx$agency_name[fx$polygon_name %in% c('Bighorn', 'Ghost')] <- 'kananaskis'
fx$agency_name[fx$reference_region %in% c('Chic-Chocs', 'Littoral', 'Murdochville')] <- 'avalanche_quebec'
sort(table(fx$agency_name))

## Order rows and columns
fx <- fx[order(fx$agency_name, fx$reference_region, fx$polygon_name),]
fx <- fx[,c('id', 'polygon_name', 'polygon_number', 'mountain_range', 'reference_region', 'agency_name', 'creation_date', 'last_updated', 'centroid')]

## View results
head(fx)

## Save
st_write(fx, 'canadian_subregions_updated.geojson', driver = 'GeoJSON', layer = 'canadian_subregions', layer_options = 'RFC7946=YES', append = FALSE)
