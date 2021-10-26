#I tiff di creaTifFromNetCdf.R e rasterToPolygons devono essere elaboratu usando l'espg 32632.
#Soltanto alla fine (con il programma che segue) si deve passare all'epsg 3857 (e' l'espg usato da leaflet).
#L'uso di epsg:3857 evita la riproiezione dei rasters da parte di leaflet e velocizza la visualizzazione su shiny.

#Fare attenzione: per passare a epsg:3857 usare il comando leaflet::projectRasterToLeaflet. Se invece si
#riproietta usando CRS("+init=epsg:3857) i rasters poi non coincidono con le mappe.
rm(list=objects())
library("raster")
library("tidyverse")

purrr::walk(list.files(pattern="^.+tif$"),.f=function(nomeFile){
  
  stack(nomeFile)->griglia
  raster::crs(griglia)<-CRS("+init=epsg:32632")
  leaflet::projectRasterForLeaflet(griglia,method="bilinear")->finale
  
  writeRaster(finale,paste0("s",nomeFile))
  
})