if (Sys.getenv("USER") == 'thembelihle') {
  datwd = "/Volumes/Storage/GIS/"
  giswd = "gis/"
  reswd = "data/raw/"}

library(raster, quietly = T) # To handle rasters
library(rgdal, quietly = T) # To communicate with GDAL and handle shape files
library(dplyr, quietly = T)

# Set a standardized projection using the PROJ.4 string convention
stdCRS <- "+proj=tmerc +lat_0=0 +lon_0=19 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"

# Import attribute table of selected grid cells
grid_cells <- paste0(giswd, "extracted_grid_cells.csv") %>% 
  read.csv() %>% 
  as.matrix()



# Import merged RGB raster 
merged_raster_RGB <-paste0(datwd, "merged_rasters_RGB.tif") %>% stack() 

# Write selected tiles to individual TIFF files
for (i in 1:nrow(grid_cells)) {
  e <- grid_cells[i, c("left", "right", "bottom", "top")] %>% 
          extent()
  crop(merged_raster_RGB, e, dataType = "INT1U") %>% 
  writeRaster(filename = paste0(reswd, "Ortho_RGB/","cederberg_", i), 
              format = "GTiff",
              overwrite = T,
              datatype = "INT1U",
              options = c("COMPRESS=NONE")) 
}



# Import merged NRG raster 
merged_raster_NRG <-paste0(datwd, "merged_rasters_NRG.tif") %>% stack() 

# Write selected tiles to individual TIFF files
for (i in 1:nrow(grid_cells)) {
  e <- grid_cells[i, c("left", "right", "bottom", "top")] %>% 
    extent()
  crop(merged_raster_NRG, e, dataType = "INT1U") %>% 
    writeRaster(filename = paste0(reswd, "Ortho_NRG/","cederberg_", i), 
                format = "GTiff",
                overwrite = T,
                datatype = "INT1U",
                options = c("COMPRESS=NONE")) 
}
