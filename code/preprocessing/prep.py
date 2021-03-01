raw_uri = '/Users/Blessings/Desktop/Cedar_Project/data/raw'
processed_uri = '/Users/Blessings/Desktop/Cedar_Project/data/processed/'

import os
from os.path import join
import json
import random
from collections import defaultdict

#from rastervision.utils.files import (
#    download_if_needed, list_paths, file_to_json, json_to_file, 
#    get_local_path, make_dir, sync_to_dir, str_to_file)

random.seed(12345)

label_uri = join(raw_uri, 'trees_raw.geojson')
with open(label_uri, 'r') as myfile:
    data = myfile.read()

# parse file
label_js = json.loads(data)

tree_features = []
for f in label_js['features']:
    f['properties']['class_name'] = 'tree'
    tree_features.append(f)
label_js['features'] = tree_features

image_to_tree_counts = defaultdict(int)
for f in label_js['features']:
    image_id = f['properties']['image_numb']
    image_to_tree_counts[image_id] += 1
    
# Use top 10% of images by tree count.
experiment_image_count = round(len(image_to_tree_counts.keys()) * 0.1)
sorted_images_and_counts = sorted(image_to_tree_counts.items(), key=lambda x: x[1])
selected_images_and_counts = sorted_images_and_counts[-experiment_image_count:]

ratio = 0.8
training_sample_size = round(ratio * experiment_image_count)
train_sample = random.sample(range(experiment_image_count), training_sample_size)

train_images = []
val_images = []

for i in range(training_sample_size):
    img = selected_images_and_counts[i][0]
    img_path = join('train_images', str(img))
    if i in train_sample:
        train_images.append(img_path)
    else:
        val_images.append(img_path)

def subset_labels(images):
    for i in images:
        img_fn = os.path.basename(i)
        img_id = os.path.splitext(img_fn)[0]
        tiff_features = []
        for l in label_js['features']:
            image_id = l['properties']['image_numb']
            if image_id == img_fn:
                tiff_features.append(l)

        tiff_geojson = {}
        for key in label_js:
            if not key == 'features':
                tiff_geojson[key] = label_js[key]
        tiff_geojson['features'] = tiff_features
        
        #json_to_file(tiff_geojson, join(processed_uri, 'labels', '{}.geojson'.format(img_id)))
        
        with open(join(processed_uri, 'labels', '{}.geojson'.format(img_id)), 'w') as outfile:  
            json.dump(tiff_geojson, outfile)

subset_labels(train_images)
subset_labels(val_images)

def create_csv(images, path):
    csv_rows = []
    for img in images:
        img_id = os.path.splitext(os.path.basename(img))[0]
        img_path = join('train_images', '{}.tif'.format(img_id))
        labels_path = join('labels','{}.geojson'.format(img_id))
        csv_rows.append('"{}","{}"'.format(img_path, labels_path))
    str_to_file('\n'.join(csv_rows), path)

create_csv(train_images, join(processed_uri, 'train-scenes.csv'))
create_csv(val_images, join(processed_uri, 'val-scenes.csv'))
        
