rm(list=objects())
library("raster")
library("config")
library("tidyverse")

Sys.setenv(R_CONFIG_ACTIVE="maschere")
GIORNI<-c("feriali","festivi")[1]


purrr::map_chr(c(3,4),.f=function(MESE){glue::glue(config::get("nome_file"))})->nomiFiles
purrr::map(nomiFiles,.f=~brick(.))->listaBricks

stack(listaBricks)->mystack
mystack*100->mystack
mystack[mystack>100]<-100
mystack[mystack< -100]<- -100

crs(mystack)<-CRS("+init=epsg:32632")
#raster::projectRaster(mystack,crs=CRS("+init=epsg:3857"))->finale
#leaflet::projectRasterForLeaflet(mystack,method="bilinear")->finale
as.integer(mystack)->finale2
writeRaster(finale2,datatype="INT2S",glue::glue(config::get("output_file")),options="COMPRESS=LZW")
