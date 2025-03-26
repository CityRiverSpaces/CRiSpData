# Set the parameters
city_name <- "Bucharest"
river_name <- "Dâmbovița"
crs <- 32635
network_buffer <- 2500
buildings_buffer <- 100
dem_buffer <- 2500

# Get bounding box ----
bb <- osmdata::getbb(city_name) |> as.vector()
names(bb) <- c("xmin", "ymin", "xmax", "ymax")
bb <- sf::st_bbox(bb)
sf::st_crs(bb) <- sf::st_crs("EPSG:4326")

# Get city boundary ----
boundary <- bb |>
  osmdata::opq() |>
  osmdata::add_osm_feature("boundary", "administrative") |>
  osmdata::osmdata_sf()

boundary <- boundary$osm_multipolygons |>
  dplyr::filter(.data$`name:en` == stringr::str_extract(city_name, "^[^,]+")) |>
  sf::st_geometry() |>
  sf::st_transform(crs)

# Get the river centreline ----
river_centerline <- bb |>
  osmdata::opq() |>
  osmdata::add_osm_feature("waterway", "river") |>
  osmdata::osmdata_sf()
river_centerline <- river_centerline$osm_multilines |>
  dplyr::filter(dplyr::if_any(dplyr::matches("name"),
                              \(x) x == river_name)) |>
  sf::st_filter(sf::st_as_sfc(bb), .predicate = sf::st_intersects) |>
  sf::st_geometry() |>
  sf::st_union()

# Get the river surface ----
river_surface <- bb |>
  osmdata::opq() |>
  osmdata::add_osm_feature("natural", "water") |>
  osmdata::osmdata_sf()
river_surface <- dplyr::bind_rows(river_surface$osm_polygons,
                                  river_surface$osm_multipolygons) |>
  sf::st_geometry() |>
  sf::st_as_sf() |>
  sf::st_make_valid() |>
  sf::st_filter(river_centerline, .predicate = sf::st_intersects) |>
  sf::st_union()

# Save clipped river centerline for AoI calculation
river_centerline_clipped <- river_centerline |>
  sf::st_intersection(sf::st_as_sfc(bb)) |>
  sf::st_transform(crs)

# Transform river centerline and surface into projected crs
river_centerline <- sf::st_transform(river_centerline, crs)
river_surface <- sf::st_transform(river_surface, crs)

# Initialise osm data object
bucharest_osm <- list(
  bb = bb,
  boundary = boundary,
  river_centerline = river_centerline,
  river_surface = river_surface
)

# Get streets and railways ----
aoi_network <- sf::st_buffer(river_centerline_clipped, network_buffer) |>
  sf::st_union(sf::st_buffer(river_surface, network_buffer))
bucharest_osm <-
  append(bucharest_osm, list(aoi_network = aoi_network |>
                               sf::st_transform(sf::st_crs("EPSG:4326"))))

highway_values <- c("motorway", "trunk", "primary", "secondary", "tertiary")
link_values <- vapply(X = highway_values,
                      FUN = \(x) sprintf("%s_link", x),
                      FUN.VALUE = character(1),
                      USE.NAMES = FALSE)

bb_buffer <- 2000
bb_exp <- bb |>
  sf::st_as_sfc() |>
  sf::st_transform(crs) |>
  sf::st_buffer(bb_buffer) |>
  sf::st_bbox() |>
  sf::st_transform(sf::st_crs("EPSG:4326"))

# Get streets
# aoi <- sf::st_bbox(aoi_network) |> sf::st_transform(sf::st_crs("EPSG:4326"))
# aoi_network_streets <- aoi_network |> sf::st_transform(sf::st_crs("EPSG:4326"))
streets <- bb_exp |>
  osmdata::opq() |>
  osmdata::add_osm_feature("highway", c(highway_values, link_values)) |>
  osmdata::osmdata_sf()

poly_to_lines <- streets$osm_polygons |>
  sf::st_cast("LINESTRING") |>
  suppressWarnings()
streets_lines <- streets$osm_lines |>
  dplyr::bind_rows(poly_to_lines) |>
  dplyr::select("highway") |>
  dplyr::rename("type" = "highway")

# aoi <- sf::st_as_sfc(aoi)
# mask <- sf::st_intersects(streets_lines, aoi_network_streets, sparse = FALSE)
# streets_lines <- streets_lines[mask, ]
streets <- sf::st_transform(streets_lines, crs)
bucharest_osm <- append(bucharest_osm, list(streets = streets))

# Get railways
# aoi <- sf::st_bbox(aoi_network) |> sf::st_transform(sf::st_crs("EPSG:4326"))
# aoi_network_railways <- aoi_network |> sf::st_transform(sf::st_crs("EPSG:4326"))
railways <- bb_exp |>
  osmdata::opq() |>
  osmdata::add_osm_feature("railway", "rail") |>
  osmdata::osmdata_sf()
railways_lines <- railways$osm_lines |>
  dplyr::select("railway") |>
  dplyr::rename("type" = "railway")

# aoi <- sf::st_as_sfc(aoi)
# mask <- sf::st_intersects(railways_lines, aoi_network_railways, sparse = FALSE)
# railways_lines <- railways_lines[mask, ]
# railways_lines <- sf::st_transform(railways_lines, crs)
railways <- sf::st_transform(railways_lines, crs)
bucharest_osm <- append(bucharest_osm, list(railways = railways))

# Get buildings ----
aoi_buildings <- sf::st_buffer(river_centerline, buildings_buffer) |>
  sf::st_union(sf::st_buffer(river_surface, buildings_buffer))

bucharest_osm <-
  append(bucharest_osm, list(aoi_buildings = aoi_buildings |>
                               sf::st_transform(sf::st_crs("EPSG:4326"))))

aoi <- sf::st_bbox(aoi_buildings) |> sf::st_transform(sf::st_crs("EPSG:4326"))
aoi_buildings <- sf::st_transform(aoi_buildings, sf::st_crs("EPSG:4326"))
buildings <- aoi |>
  osmdata::opq() |>
  osmdata::add_osm_feature("building", NULL) |>
  osmdata::osmdata_sf()
buildings <- buildings$osm_polygons |>
  sf::st_make_valid() |>
  sf::st_filter(aoi_buildings, .predicate = sf::st_intersects) |>
  dplyr::filter(building != "NULL") |>
  sf::st_geometry() |>
  sf::st_transform(crs)

bucharest_osm <- append(bucharest_osm, list(buildings = buildings))

# Fix encoding issue in the WKT strings in the OSM data ----
fix_wkt_encoding <- function(x) {
  wkt <- sf::st_crs(x)$wkt
  sf::st_crs(x)$wkt <- gsub("°|º", "\\\u00b0", wkt)  # replace with ASCII code
  x
}
bucharest_osm <- lapply(bucharest_osm, fix_wkt_encoding)

# Get the DEM data ----
aoi_buff <- sf::st_buffer(bucharest_osm$aoi_network, dem_buffer)
endpoint = "https://earth-search.aws.element84.com/v1"
collection = "cop-dem-glo-30"
bb_dem <- sf::st_bbox(aoi_buff) |> sf::st_transform(sf::st_crs("EPSG:4326"))
asset_urls <- rstac::stac(endpoint) |>
  rstac::stac_search(collections = collection, bbox = bb_dem) |>
  rstac::get_request() |>
  rstac::assets_url()
rasters <- lapply(asset_urls, terra::rast)
rasters <- lapply(rasters, terra::crop, terra::ext(bb_dem), snap = "out")
if (length(rasters) > 1) {
  dem <- do.call(terra::merge, args = rasters)
} else {
  dem <- rasters[[1]]
}
bucharest_dem <- dem |> terra::wrap()

# Save as package data
usethis::use_data(bucharest_osm, overwrite = TRUE, compress = "xz")
usethis::use_data(bucharest_dem, overwrite = TRUE, compress = "xz")
