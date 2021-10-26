#queso programma prende le maschere create con R-INLA, le trasforma in vettoriali, filtra
#le aree troppo piccole e ricrea dei rasters di maschere. Queste maschere con leaflet servono
#a evidenziare le aree statisticamente significative di variazione dell'NO2.
rm(list=objects())
library("raster")
library("smoothr")
library("tidyverse")
library("furrr")

future::plan(multicore,workers=4)

GIORNI<-c("feriali","festivi")[2]

stack(glue::glue("mediaMasked_{GIORNI}_modelloMETEO1920_mese3_regionelombardia.nc"))->mybrick3
stack(glue::glue("mediaMasked_{GIORNI}_modelloMETEO1920_mese4_regionelombardia.nc"))->mybrick4

stack(mybrick3,mybrick4)->mybrick

nlayers(mybrick)->numeroLayers

furrr::future_map(1:numeroLayers,.f=function(.l){
  
  raster::subset(mybrick,.l)->griglia
  raster::crs(griglia)<-CRS("+init=epsg:32632")

  griglia[griglia> -1000]<-0
  rasterToPolygons(griglia,dissolve=TRUE)->griglia2
  
  smoothr::drop_crumbs(griglia2,threshold = units::set_units(50,km^2))->poligoni
  
  mask(griglia,poligoni)->mascherato
  mascherato[mascherato > -1000]<-0
  
  mascherato
  
})->listaMaschere


stack(listaMaschere)->finale
writeRaster(finale,glue::glue("{GIORNI}_masks.tif"))
