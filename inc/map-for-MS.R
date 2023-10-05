library(tmap)
library(tmaptools)
#library(rnaturalearth)
#library(OpenStreetMap)

library(grid)

library(sf)
library(dplyr)


here::i_am("inc/map-for-MS.R")
target.dir <- "sandbox"
load(here::here(target.dir,"assessment-data-Cordillera-de-Merida.rda"))

adm0 <- read_sf(here::here(target.dir,"WB-VEN.gpkg")) %>% 
  st_make_valid 

slc.parks <- c("Sierra Nevada","Dr. Antonio José Uzcátegui Burguera (Sierra de la Culata)",  "Tapo - Caparo" )

WDPA <- read_sf(here::here(target.dir,"PNs-Merida-WDPA.gpkg")) %>% 
  filter(NAME %in% slc.parks) %>%
  mutate(label=if_else(WDPAID %in% 30033,
                       "Sierra de la Culata\nNational Park",
                       sprintf("%s\nNational Park",NAME)))
SNNP <- WDPA %>% filter(WDPAID %in% 321)

rivers <- read_sf(here::here(target.dir,"DIVA-VEN-rivers.gpkg")) %>% 
  filter(HYC_DESCRI %in% "Perennial/Permanent") %>% mutate(label=if_else(NAM %in% "UNK",as.character(NA),NAM))

hsraster <- here::here(target.dir,"hillshade-rast.tif")
if (!file.exists(hsraster)) {
  msurl <- "https://services.arcgisonline.com/arcgis/rest/services/Elevation/World_Hillshade/MapServer/tile/{z}/{y}/{x}"
  osm_SNNP <- read_osm(SNNP, type= msurl,ext=1.3)
  stars::write_stars(osm_SNNP,
                     dsn=hsraster)
} else {
  osm_SNNP <- stars::read_stars(hsraster)
}

vzla.adm1 <- read_sf(here::here(target.dir,"Venezuela-IGVSB.gpkg"))

vzla <- {adm0 %>% filter(ISO_A2=="VE") %>%  st_cast("POLYGON") %>% slice(1) %>% st_buffer(dist=100000)}

WDPA.crop <- st_crop(WDPA, bb(osm_SNNP, projection = 4326))
vzla.crop <- st_crop(vzla.adm1, bb(osm_SNNP, projection = 4326))

ROI <- st_bbox(WDPA.crop %>% st_buffer(dist=4e5)) %>% st_as_sfc
adm0 <- adm0 %>% st_crop(ROI)

AOO.cell <- st_make_grid(venezuela_rgi6,
                         cellsize=0.09044,
                         n=c(1,1),
                         offset=c(-71.072, 8.5)) 

# AOO.cell %>% st_area %>% set_units('km2')


# annotations in the map:
adm0_xy <- {adm0 %>% st_centroid() %>% slice(1:4)}
adm0_xy$labelsize=c(2,2,.1,.1)

wbd <- data.frame(name=c("Maracaibo\nLake","Caribbean\nSea","Caribbean\nSea"),labelsize=c(0.15,0.35,0.9))
wbd$geom <- st_sfc(st_point(c(-71.6,9.75)),st_point(c(-68,11.25)),st_point(c(-75,11.25)))

ann <- data.frame(code=c("1","3","4","2"),
                  name=c("Bolívar","Humboldt","Mucuñuque"," La Concha "),
                  labelsize=c(0.25,0.25,0.2,0.2))
ann$geom <- st_sfc(st_point(c(-71.0504,8.54114)),
                   st_point(c(-71.0001,8.54740)),
                   st_point(c(-70.800833,8.755278)),
                   st_point(c(-71.024722,8.541944)))
ann <- st_as_sf(ann,crs=4326)

tcks <- data.frame(code=c("71,2","71,0","70,8","70,6",
                          "8,2","8,4","8,6","8,8"))
mxy <- 8.0775
mxx <- -71.395
tcks$geom <- st_sfc(st_linestring(rbind(c(-71.2,8.0),c(-71.2,mxy))),
                   st_linestring(rbind(c(-71.0,8.0),c(-71.0,mxy))),
                   st_linestring(rbind(c(-70.8,8.0),c(-70.8,mxy))),
                   st_linestring(rbind(c(-70.6,8.0),c(-70.6,mxy))),
                   st_linestring(rbind(c(-71.44,8.2),c(mxx,8.2))),
                   st_linestring(rbind(c(-71.44,8.4),c(mxx,8.4))),
                   st_linestring(rbind(c(-71.44,8.6),c(mxx,8.6))),
                   st_linestring(rbind(c(-71.44,8.8),c(mxx,8.8))))
tcks <- st_as_sf(tcks,crs=4326)



edos <- data.frame(name=c("M E R I D A","B A R I N A S"),
                   labelsize=c(0.95,0.95))
edos$geom <- st_sfc(st_point(c(-71,8.4)),
                   st_point(c(-70.6,8.6)))
edos <- st_as_sf(edos,crs=4326)



#msurl <- "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
#osm_glacs <- read_osm(AOO.cell, 
#                      type= msurl,ext=3)

#tm_shape(osm_glacs) +
#  tm_rgb() +
#  tm_shape(venezuela_rgi6) +
#  tm_borders(col="black")


tmap_mode("plot")

## As this study we use 1:2 million data from the World Bank, a digital elevation model and hillshade from a map service, in combination with partial transparency  to provide geographical context. The vector layer for the protected areas is from Protected Planet.

set.seed(832181)
main_fig <- 
  tm_shape(osm_SNNP) +
  tm_rgb(alpha=.6) +
  tm_shape(rivers) +
  tm_lines(col='cyan3',alpha=.6) +
    tm_shape(vzla.crop) +
    tm_borders(col=grey(.5)) +
  tm_shape(edos) +
    tm_text("name",col=grey(.5)) +
  tm_shape(WDPA.crop) +
  tm_fill(col='darkgreen',alpha=.2)+
  tm_borders(col="darkgreen") +
  tm_text("label",size=0.8,col="black",
          xmod=c(2,1,2), ymod=c(3,2,1)) +
  tm_shape(AOO.cell) +
  tm_borders(col="#0F0F0FF0", lty = "dotted") +
  tm_shape(tcks) +
  tm_lines(col="#0F0F0FF0") +
  tm_shape(ann[1:4,]) +
  tm_dots(size=0.05, col="black", shapes = 24) +
  tm_text("name",size=0.6, auto.placement = TRUE) +
  tm_scale_bar() +
  tm_graticules(n.x=4, n.y=4, labels.margin.y=0, ticks=TRUE,
                labels.inside.frame = TRUE, lines=FALSE,
                labels.size = 0.5)

sfig1 <- 
  tm_shape(adm0) +
  tm_polygons(col="white",border.col="black", lwd = .5) +
  tm_shape(adm0_xy) +
  tm_text("NAME_EN",size="labelsize",just="center",
          xmod=c(0,.5,0,0,1.5), ymod=c(-.7,1,-.6,-.6,-1.1)) +
  tm_shape(st_bbox(WDPA.crop) %>% st_as_sfc) +
  tm_fill(col="black",alpha=.6)+
  tm_legend(show = FALSE) +
  tm_layout(inner.margin=0, outer.margin=0, bg.color="aliceblue")



#  tm_shape(st_as_sf(wbd)) +
#  tm_text("name",size="labelsize",col="slateblue2",print.tiny = TRUE) +
    #  tm_shape( ) +
#  tm_borders(col="black")+
#  tm_shape(metro) +
#  tm_symbols(col = "red", size = "pop2020", scale = .5) +


main_fig
print(sfig1, vp = viewport(0.8, 0.35, width = 0.35, height = 0.35))

tmap_save(main_fig,
        filename=here::here(target.dir,"Fig1-Study-area.png"),
        width=120, height=120, units = "mm",
        dpi=600,
        insets_tm=sfig1,
        insets_vp=viewport(0.8, 0.35, width = 0.30, height = 0.30))

