## This creates a cloudfree mosic image, code adapted from: 
# https://developers.google.com/earth-engine/tutorials/community/sentinel-2-s2cloudless
import ee
import rasterio
import requests
import zipfile
from rasterio.plot import show as showRasterio
import matplotlib.pyplot as plt
import os
import numpy as np
# Import the folium library.
import folium
from folium.features import DivIcon
import io
from PIL import Image

# Trigger the authentication flow.
ee.Authenticate()

# Initialize the library.
ee.Initialize()

# Define collection filter and cloud mask parameters

lon=-71.02317 
lat=8.544352
sze=0.05

# define the area of interest, using the Earth Engines geometry object
coords = [
     [lon - sze/2., lat - sze/2.],
     [lon + sze/2., lat - sze/2.],
     [lon + sze/2., lat + sze/2.],
     [lon - sze/2., lat + sze/2.],
     [lon - sze/2., lat - sze/2.]
]
coords = [
     [-71.072, 8.5],
     [-70.98156, 8.5],
     [-70.98156, 8.59044],
     [-71.072, 8.59044],
     [-71.072, 8.5]
]
coords2 = [
     [8.5, -71.072],
     [8.5, -70.98156],
     [8.59044,-70.98156],
     [8.59044, -71.072],
     [8.5, -71.072]
]

AOI = ee.Geometry.Polygon(coords)
START_DATE = '2021-12-01'
END_DATE = '2022-04-01'
CLOUD_FILTER = 60
CLD_PRB_THRESH = 50
NIR_DRK_THRESH = 0.15
CLD_PRJ_DIST = 1
BUFFER = 50

# Build a Sentinel-2 collection

def get_s2_sr_cld_col(aoi, start_date, end_date):
    # Import and filter S2 SR.
    s2_sr_col = (ee.ImageCollection('COPERNICUS/S2_SR')
        .filterBounds(aoi)
        .filterDate(start_date, end_date)
        .filter(ee.Filter.lte('CLOUDY_PIXEL_PERCENTAGE', CLOUD_FILTER)))
    # Import and filter s2cloudless.
    s2_cloudless_col = (ee.ImageCollection('COPERNICUS/S2_CLOUD_PROBABILITY')
        .filterBounds(aoi)
        .filterDate(start_date, end_date))
    # Join the filtered s2cloudless collection to the SR collection by the 'system:index' property.
    return ee.ImageCollection(ee.Join.saveFirst('s2cloudless').apply(**{
        'primary': s2_sr_col,
        'secondary': s2_cloudless_col,
        'condition': ee.Filter.equals(**{
            'leftField': 'system:index',
            'rightField': 'system:index'
        })
    }))

# Define cloud mask component functions 

def add_cloud_bands(img):
    # Get s2cloudless image, subset the probability band.
    cld_prb = ee.Image(img.get('s2cloudless')).select('probability')
    # Condition s2cloudless by the probability threshold value.
    is_cloud = cld_prb.gt(CLD_PRB_THRESH).rename('clouds')
    # Add the cloud probability layer and cloud mask as image bands.
    return img.addBands(ee.Image([cld_prb, is_cloud]))

def add_shadow_bands(img):
    # Identify water pixels from the SCL band.
    not_water = img.select('SCL').neq(6)
    # Identify dark NIR pixels that are not water (potential cloud shadow pixels).
    SR_BAND_SCALE = 1e4
    dark_pixels = img.select('B8').lt(NIR_DRK_THRESH*SR_BAND_SCALE).multiply(not_water).rename('dark_pixels')
    # Determine the direction to project cloud shadow from clouds (assumes UTM projection).
    shadow_azimuth = ee.Number(90).subtract(ee.Number(img.get('MEAN_SOLAR_AZIMUTH_ANGLE')));
    # Project shadows from clouds for the distance specified by the CLD_PRJ_DIST input.
    cld_proj = (img.select('clouds').directionalDistanceTransform(shadow_azimuth, CLD_PRJ_DIST*10)
        .reproject(**{'crs': img.select(0).projection(), 'scale': 100})
        .select('distance')
        .mask()
        .rename('cloud_transform'))
    # Identify the intersection of dark pixels with cloud shadow projection.
    shadows = cld_proj.multiply(dark_pixels).rename('shadows')
    # Add dark pixels, cloud projection, and identified shadows as image bands.
    return img.addBands(ee.Image([dark_pixels, cld_proj, shadows]))

#Final cloud-shadow mask

def add_cld_shdw_mask(img):
    # Add cloud component bands.
    img_cloud = add_cloud_bands(img)
    # Add cloud shadow component bands.
    img_cloud_shadow = add_shadow_bands(img_cloud)
    # Combine cloud and shadow mask, set cloud and shadow as value 1, else 0.
    is_cld_shdw = img_cloud_shadow.select('clouds').add(img_cloud_shadow.select('shadows')).gt(0)
    # Remove small cloud-shadow patches and dilate remaining pixels by BUFFER input.
    # 20 m scale is for speed, and assumes clouds don't require 10 m precision.
    is_cld_shdw = (is_cld_shdw.focalMin(2).focalMax(BUFFER*2/20)
        .reproject(**{'crs': img.select([0]).projection(), 'scale': 20})
        .rename('cloudmask'))
    # Add the final cloud-shadow mask to the image.
    return img_cloud_shadow.addBands(is_cld_shdw)

#Define cloud mask application function
def apply_cld_shdw_mask(img):
    # Subset the cloudmask band and invert it so clouds/shadow are 0, else 1.
    not_cld_shdw = img.select('cloudmask').Not()
    # Subset reflectance bands and update their masks, return the result.
    return img.select('B.*').updateMask(not_cld_shdw)



# Define a method for displaying Earth Engine image tiles to a folium map.
def add_ee_layer(self, ee_image_object, vis_params, name, show=True, opacity=1, min_zoom=0):
    map_id_dict = ee.Image(ee_image_object).getMapId(vis_params)
    folium.raster_layers.TileLayer(
        tiles=map_id_dict['tile_fetcher'].url_format,
        attr='Map Data &copy; <a href="https://earthengine.google.com/">Google Earth Engine</a>',
        name=name,
        show=show,
        opacity=opacity,
        min_zoom=min_zoom,
        overlay=True,
        control=True
        ).add_to(self)

# Add the Earth Engine layer method to folium.
folium.Map.add_ee_layer = add_ee_layer

# Process the collection

s2_sr_cld_col = get_s2_sr_cld_col(AOI, START_DATE, END_DATE)

s2_sr_median = (s2_sr_cld_col.map(add_cld_shdw_mask)
                             .map(apply_cld_shdw_mask)
                             .median())

# Create a folium map object.

center = AOI.centroid(10).coordinates().reverse().getInfo()
m = folium.Map(location=center, zoom_start=13)

folium.PolyLine(
    locations=coords2, ## because this has to be lat first ^.^
    color="#f2f211",
    weight=5,
    tooltip="AOO cell",
).add_to(m)



ls = ["Bolivar","La Concha","Humboldt"]
ps = [ [8.53730,-71.04504], [8.54740,-71.024722],[8.54114,-71.0001]]

for j in (0,1,2):
  folium.Marker(ps[j], 
        popup= ls[j],
        icon=DivIcon(
        icon_size=(150,36),
        icon_anchor=(7,20),
        html="""<div style="font-size: 18pt; color : #303002">{:d}</div>""".format(j+1),
        )).add_to(m)
  m.add_child(folium.CircleMarker(ps[j], color="#f2f211", radius=15))


# Add layers to the folium map.
m.add_ee_layer(s2_sr_median,
                {'bands': ['B4', 'B3', 'B2'], 'min': 0, 'max': 2500, 'gamma': 1.1},
                'S2 cloud-free mosaic', True, 1, 9)


# Add a layer control panel to the map.
m.add_child(folium.LayerControl())

# Display the map.
#display(m)
m.save("CordilleraMerida-Cloudless.html")


img_data = m._to_png(5)
img = Image.open(io.BytesIO(img_data))
img.save('CordilleraMerida-Cloudless.png')
#


