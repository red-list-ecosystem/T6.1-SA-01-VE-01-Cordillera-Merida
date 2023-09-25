## This creates a cloudfree mosic image, code adapted from: 
# https://sites.northwestern.edu/researchcomputing/2021/11/19/downloading-satellite-images-made-easy/
import ee
import rasterio
import requests
import zipfile
from rasterio.plot import show as showRasterio
import matplotlib.pyplot as plt
import os
import numpy as np

# Trigger the authentication flow.
ee.Authenticate()

# Initialize the library.
ee.Initialize()

filename="CordilleraMerida-Sentinel.tif"

# Define area of interest

lon=-71.02317 
lat=8.544352
sze=0.1

# define the area of interest, using the Earth Engines geometry object
coords = [
     [lon - sze/2., lat - sze/2.],
     [lon + sze/2., lat - sze/2.],
     [lon + sze/2., lat + sze/2.],
     [lon - sze/2., lat + sze/2.],
     [lon - sze/2., lat - sze/2.]
]
aoi = ee.Geometry.Polygon(coords)
dateMin = '2019-12-01'
dateMax = '2020-04-01'

# get the image using Google's Earth Engine
db = ee.Image(ee.ImageCollection('COPERNICUS/S2_SR')\
                   .filterBounds(aoi)\
                   .filterDate(ee.Date(dateMin), ee.Date(dateMax))\
                   .sort('CLOUDY_PIXEL_PERCENTAGE')\
                   .first())

# add the latitude and longitude
db = db.addBands(ee.Image.pixelLonLat())

# define the bands that I want to use.  B4 is red, B3 is green, B2 is blue
# https://developers.google.com/earth-engine/datasets/catalog/COPERNICUS_S2_SR#bands
bands = ['B4', 'B3', 'B2']

# export geotiff images, these go to Drive and then are downloaded locally
for selection in bands:
  task = ee.batch.Export.image.toDrive(image=db.select(selection),
                                 description=selection,
                                 scale=30,
                                 region=aoi,
                                 fileNamePrefix=selection,
                                 crs='EPSG:4326',
                                 fileFormat='GeoTIFF')
  task.start()
  
  url = db.select(selection).getDownloadURL({
      'scale': 30,
      'crs': 'EPSG:4326',
      'fileFormat': 'GeoTIFF',
      'region': aoi})
  
  r = requests.get(url, stream=True)
  
  filenameZip = selection+'.zip'
  filenameTif = selection+'.tif'
  
  # unzip and write the tif file, then remove the original zip file
  with open(filenameZip, "wb") as fd:
      for chunk in r.iter_content(chunk_size=1024):
          fd.write(chunk)
  
  zipdata = zipfile.ZipFile(filenameZip)
  zipinfos = zipdata.infolist()
  
  # iterate through each file (there should be only one)
  for zipinfo in zipinfos:
      zipinfo.filename = filenameTif
      zipdata.extract(zipinfo)
  
  zipdata.close()

# open the images
B2 = rasterio.open('B2.tif')
B3 = rasterio.open('B3.tif')
B4 = rasterio.open('B4.tif')

 #get the scaling
image = np.array([B2.read(1), B3.read(1), B4.read(1)]).transpose(1,2,0)
p2, p98 = np.percentile(image, (2,98))

# use the B2 image as a starting point so that I keep the same parameters
B2_geo = B2.profile
B2_geo.update({'count': 3})

with rasterio.open(filename, 'w', **B2_geo) as dest:
    dest.write( (np.clip(B4.read(1), p2, p98) - p2)/(p98 - p2)*255, 1)
    dest.write( (np.clip(B3.read(1), p2, p98) - p2)/(p98 - p2)*255, 2)
    dest.write( (np.clip(B2.read(1), p2, p98) - p2)/(p98 - p2)*255, 3)

B2.close()
B3.close()
B4.close()

# remove the intermediate files
for selection in bands:
    os.remove(selection + '.tif')
    os.remove(selection + '.zip')
