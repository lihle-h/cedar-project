if (Sys.getenv("USER") == 'thembelihle')  {
  datwd = "data/raw/vector/"
  giswd = "gis/"
  reswd = "data/processed/vector/"}

library(raster, quietly = T)
library(rgdal, quietly = T) # To communicate with GDAL and handle shape files

# point to where the input file is
all_cedars <- paste0(datwd, "All_Cedars_2_WGS84.kml") 
# these are the cedar tree localities mapped by Slingsby and Slingby (2019)


# Set a standardized projection using the PROJ.4 string convention
stdCRS <- "+proj=tmerc +lat_0=0 +lon_0=19 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"

# Read in tree localities (point data) from Google Earth KML file
rawpts <- readOGR(dsn = all_cedars, layer = "All_Cedars_2_WGS84")

pts <- spTransform(rawpts, CRS(stdCRS)) # Do spatial transform to project to our chosen CRS
rm(rawpts) # remove raw points

# Save point layer to shapefile
writeOGR(pts, dsn = paste0(reswd, "All_Cedars"), 
         layer = "All_Cedars", 
         driver = "ESRI Shapefile")

