if (Sys.getenv("USER") == 'thembelihle')  {
  datwd = "data/raw/vector/"
  giswd = "gis/"
  reswd = "data/processed/labels/"}

library(rgdal, quietly = T) # To communicate with GDAL and handle shape files
library(spdplyr, quietly = T)
library(geojsonio, quietly = T)

# Set a standardized projection using the PROJ.4 string convention
stdCRS <- "+proj=tmerc +lat_0=0 +lon_0=19 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"


# Read in the 'trees' shapefile containing ALL annotations
all_trees <- readOGR(dsn = paste0(datwd, "trees_final/trees_final.shp"),
               layer = "trees_final", 
               verbose = FALSE)

all_trees <- all_trees %>% 
    mutate(image_ID = as.numeric(levels(image_numb))[image_numb])

# Labels of the scenes containing at least one tree
positive_scenes <- all_trees$image_ID %>% unique()

# Write label files for all positive scenes to file
for (scene in positive_scenes) {
  tree_subset <- all_trees %>% 
    filter(image_ID == scene)
  json_text <- geojson_json(tree_subset, convert_wgs84 = TRUE, crs = CRS(stdCRS)) %>%
    pretty()
  file_uri <- paste0(reswd, "all/cederberg_", scene, ".json")
  json_text %>% write(file = file_uri)
}


########################
# Train/Val/Test split #
########################

# Create bins based on number of trees
tree_counts <- all_trees@data %>% group_by(image_ID) %>% 
                summarize(n_trees =n()) %>% 
                mutate(bin = case_when(
                  n_trees <= 30 ~ as.character(n_trees),
                  n_trees > 30 & n_trees <= 40 ~ '(30, 40]',
                  n_trees > 40 & n_trees <= 50 ~ '(40, 50]',
                  n_trees > 50 & n_trees <= 60 ~ '(50, 60]',
                  n_trees > 60 ~ '>60'
                ))

# Group by bins and sample
# train : val : test split is 60 : 20 : 20
train_scenes <- tree_counts %>% group_by(bin) %>% sample_frac(0.6)
other_scenes <- anti_join(tree_counts, train_scenes, by = 'image_ID')

val_scenes <- other_scenes %>% group_by(bin) %>% sample_frac(0.5)
test_scenes <- anti_join(other_scenes, val_scenes, by = 'image_ID')


# Plot distribution of number of trees across scenes in the three sets
train_scenes$n_trees %>% density() %>% 
  plot(xlab = "Number of trees",
       typ = "l", col = "#F39C12", 
       lwd = 2, las = 1,
       cex.axis = 1.2,
       cex.main = 1.2,
       cex.lab = 1.2,
       ylim = c(0, .08),
       main = "")
val_scenes$n_trees %>% density() %>% lines(col = "#69b3a2", lwd = 2)
test_scenes$n_trees %>% density() %>% lines(col = "#5DADE2", lwd = 2)
legend(60, 0.075, legend=c("Train", "Validation", "Test"),
       col=c("#F39C12", "#69b3a2", "#5DADE2"),
       lty=1, lwd = 2, cex=1.2, bty = "n")


# Write train labels to file
for (img in train_scenes$image_ID){
  tree_subset <- all_trees %>%
    filter(image_ID == img)
  file_uri <- paste0(reswd, "train/cederberg_", img, ".json")
  geojson_json(tree_subset, convert_wgs84 = TRUE, crs = CRS(stdCRS)) %>%
    pretty() %>%
    write(file = file_uri)
}

# Write val labels to file
for (img in val_scenes$image_ID){
  tree_subset <- all_trees %>%
    filter(image_ID == img)
  file_uri <- paste0(reswd, "valid/cederberg_", img, ".json")
  geojson_json(tree_subset, convert_wgs84 = TRUE, crs = CRS(stdCRS)) %>%
    pretty() %>%
    write(file = file_uri)
}

# Write test labels to file 
for (img in test_scenes$image_ID){
  tree_subset <- all_trees %>%
    filter(image_ID == img)
  file_uri <- paste0(reswd, "test/cederberg_", img, ".json")
  geojson_json(tree_subset, convert_wgs84 = TRUE, crs = CRS(stdCRS)) %>%
    pretty() %>%
    write(file = file_uri)
}

