
<!-- README.md is generated from README.Rmd. Please edit that file -->

# CRiSpData

<!-- badges: start -->
<!-- badges: end -->

This package contains geospatial data on urban river spaces used in
CRiSp and related packages. The dataset contains vector data of the city
boundary, bounding box enclosing the city boundary, spatial networks
(street centerlines, railway lines), the river (centerline and surface),
buildings surrounding the river, as well as a digital elevation model.

The current dataset contains the case of River Dâmbovița in Bucharest.
The data were derived from open sources such as
[OpenStreetMap](https://wiki.openstreetmap.org/wiki/Overpass_API) and
[Copernicus DEM
GLO-30](https://dataspace.copernicus.eu/explore-data/data-collections/copernicus-contributing-missions/collections-description/COP-DEM).

## Installation

You can install the development version of CRiSpData from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("CityRiverSpaces/CRiSpData")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(CRiSpData)

plot(bucharest_osm$boundary)
plot(bucharest_osm$streets$geometry, lwd = 0.5, add = TRUE)
plot(bucharest_osm$river_centerline, col = "blue", add = TRUE)
plot(bucharest_osm$river_surface, col = "blue", border = NA, add = TRUE)
```
