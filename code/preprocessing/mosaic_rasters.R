if (Sys.getenv("USER") == 'thembelihle') {
  datwd = "/Volumes/Storage/Clipped Rasters/"
  giswd = "gis/" # for geospatial files
  reswd = "/Volumes/Storage/results/"}

library(dplyr, quietly = T)
library(raster, quietly = T) # To handle rasters
library(rasterVis, quietly = T) # For fancy raster visualisations
library(rgdal, quietly = T) # To communicate with GDAL and handle shape files
library(gdalUtils, quietly = T)
library(spatial.tools, quietly = T)
library(doMC, quietly = T) # To run code in parallel

# Point to where the input files are
all_files <-   list.files(path = datwd, pattern = "*.tif") %>%
  paste0(datwd, .)

# Set a standardized projection using the PROJ.4 string convention
stdCRS <- "+proj=tmerc +lat_0=0 +lon_0=19 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"

# Import mask layer
buffered_mask <- readOGR( dsn = paste0(giswd, "buffered_mask.gpkg"), 
                          layer = "Buffered",
                          verbose = FALSE)


# Make a empty raster template file to build onto
e <- extent(buffered_mask)
template <- raster(e) # empty raster having same extent as mask
projection(template) <- stdCRS # set its CRS

# Write template to file
out_file <- paste0(reswd, "merged_rasters.tif") # name of output file
writeRaster(template, filename = out_file, overwrite = TRUE, format ="GTiff")

# merge all raster tiles into one large .tif file
sfQuickInit(cpus = 4) # from package spatial.tools to launch a parallel PSOCK cluster
mosaic_rasters(gdalfile = all_files, 
               dst_dataset = out_file, 
               of = "GTiff",
               force_ot = "Byte",
               #co = list("COMPRESS=JPEG", "PHOTOMETRIC=YCBCR"),
               verbose = T)
sfQuickStop() # from package spatial.tools to stop a parallel PSOCK cluster

gdalinfo(out_file)

# Read in and visualize the merged_raster
merged_raster <- raster(out_file)
plot(merged_raster)
