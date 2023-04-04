library(tmap)
library(tmaptools)
library(rnaturalearth)
library(OpenStreetMap)

library(grid)

library(sf)
library(dplyr)
here::i_am("map-for-MS.R")
target.dir <- "sandbox"
dir(here::here(target.dir))
target.file <- "assessment-data-Cordillera-de-Merida.rda"
load(here::here(target.dir,target.file))

download.file(url="https://biogeo.ucdavis.edu/data/diva/wat/VEN_wat.zip",
              destfile=here::here(target.dir,"VEN_wat.zip"))
unzip (here::here(target.dir,"VEN_wat.zip"),
       exdir=here::here(target.dir))
# scp terra.ad.unsw.edu.au:~/workdir/sandbox/deforestacion-vzla/WDPA*gpkg ~/proyectos/IUCN-GET-L4/T6.1-tropical-glaciers-docs/sandbox/
# scp $zID@kdm.restech.unsw.edu.au:/srv/scratch/cesdata/gisdata/admin/global/World-Bank/wb_countries_admin0_10m.zip ~/proyectos/IUCN-GET-L4/T6.1-tropical-glaciers-docs/sandbox/
# scp $zID@kdm.restech.unsw.edu.au:/srv/scratch/cesdata/gisdata/admin/global/World-Bank/wb_disputed_areas_admin0_10m.zip ~/proyectos/IUCN-GET-L4/T6.1-tropical-glaciers-docs/sandbox/

unzip (here::here(target.dir,"wb_countries_admin0_10m.zip"),
       exdir=here::here(target.dir))

adm0 <- read_sf(here::here(target.dir,
                           "WB_countries_Admin0_10m", 
                           "WB_countries_Admin0_10m.shp")) %>% 
  st_make_valid 

vzla <- {adm0 %>% filter(ISO_A2=="VE") %>%  st_cast("POLYGON") %>% slice(1) %>% st_buffer(dist=100000)}
ROI <- st_bbox(WDPA.crop %>% st_buffer(dist=4e5)) %>% st_as_sfc
adm0 <- adm0 %>% st_crop(ROI)

slc.parks <- c("Sierra Nevada","Dr. Antonio José Uzcátegui Burguera (Sierra de la Culata)",  "Tapo - Caparo" )
WDPA <- read_sf(here::here(target.dir,"WDPA-Venezuela.gpkg")) %>% 
  filter(IUCN_CAT %in% "II",
         NAME %in% slc.parks) %>%
  mutate(label=sprintf("%s\nNational Park",NAME))

WDPA$label[2] <- "Sierra de la Culata\nNational Park"

SNNP <- WDPA %>% filter(WDPAID %in% 321)



rivers <- read_sf(here::here(target.dir,"VEN_water_lines_dcw.shp")) %>% 
  filter(HYC_DESCRI %in% "Perennial/Permanent") %>% mutate(label=if_else(NAM %in% "UNK",as.character(NA),NAM))
msurl <- "https://services.arcgisonline.com/arcgis/rest/services/Elevation/World_Hillshade/MapServer/tile/{z}/{y}/{x}"
#osm_VEN <- read_osm(venezuela_rgi6, ext=3,)
#osm_VEN <- read_osm(bb(c(-71.5,8,-70,9.5)), type= msurl)
osm_SNNP <- read_osm(SNNP, type= msurl,ext=1.3)

AOO.cell <- st_make_grid(venezuela_rgi6,cellsize=0.09044,n=c(1,1)) 
library(units)
AOO.cell %>% st_area %>% set_units('km2')

WDPA.crop <- st_crop(WDPA, bb(osm_SNNP, projection = 4326))




#msurl <- "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
osm_glacs <- read_osm(AOO.cell, 
                      type= msurl,ext=3)

tm_shape(osm_glacs) +
  tm_rgb() +
  tm_shape(venezuela_rgi6) +
  tm_borders(col="black")

data(World, metro, rivers, land)




tmap_mode("plot")

## As this study we use 1:2 million data from the World Bank, a digital elevation model and hillshade from a map service, in combination with partial transparency  to provide geographical context. The vector layer for the protected areas is from Protected Planet.


main_fig <- 
  tm_shape(osm_SNNP) +
  tm_rgb(alpha=.6) +
  tm_shape(rivers) +
  tm_lines(col='cyan3',alpha=.6) +
  #  tm_text("label", auto.placement=TRUE) +
  tm_shape(WDPA.crop) +
  tm_fill(col='darkgreen',alpha=.2)+
  tm_borders(col="darkgreen") +
  tm_text("label",size=0.8,col="black",
          xmod=c(2,1,2), ymod=c(3,2,-1)) +
  tm_shape(AOO.cell) +
  tm_borders(col="black") +
  #  tm_symbols(size=.3 ,col="black") +
  tm_scale_bar() +
  tm_graticules(n.x=4, n.y=4, labels.margin.y=0, ticks=FALSE,
                labels.inside.frame = TRUE, lines=FALSE,
                labels.size = 0.7)

sfig1 <- 
  tm_shape(adm0) +
  tm_polygons(col="white",border.col="black", lwd = .5) +
  tm_shape(adm0_xy) +
  tm_text("NAME_EN",size="labelsize",just="center",
          xmod=c(0,.5,0,0,1.5), ymod=c(-.7,1,-.6,-.6,-1.1)) +
  tm_shape(st_bbox(WDPA.crop) %>% st_as_sfc) +
  tm_fill(col="black",alpha=.6)+
#  tm_shape(st_as_sf(wbd)) +
#  tm_text("name",size="labelsize",col="slateblue2",print.tiny = TRUE) +
    #  tm_shape( ) +
#  tm_borders(col="black")+
#  tm_shape(metro) +
#  tm_symbols(col = "red", size = "pop2020", scale = .5) +
  tm_legend(show = FALSE) +
  tm_layout(inner.margin=0,bg.color="aliceblue")


main_fig
print(sfig1, vp = viewport(0.8, 0.35, width = 0.4, height = 0.4))

tmap_save(main_fig,
        filename="~/Desktop/Fig1-Study-area.png",
        insets_tm=sfig1,
        insets_vp=viewport(0.82, 0.32, width = 0.4, height = 0.4))
