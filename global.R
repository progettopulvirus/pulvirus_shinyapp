library("shiny")
library("shiny.i18n")
library("dplyr")
library("leaflet")
library("echarts4r")
library("stringr")
library("htmltools")
library("htmlwidgets")
library("vroom")


#I file rasters hanno proiezione 3857 (Google Mercator) che e' la proiezione di leaflet di default in modo di velocizzare la visualizzazione delle mappe

#color palette for leaflet
leaflet::colorNumeric(palette=scico::scico(n=10,palette="cork"),domain = seq(-100,100,10),na.color = "transparent")->pal

#internazionalization
i18n<-Translator$new(translation_csvs_path = "translations/",separator_csv = ",",automatic =FALSE)
i18n$set_translation_language("en")
shiny.i18n::usei18n(i18n)

#read monitoring sites
vroom("valori_variazioni_no2_2019_2020.csv",delim=";",col_names=TRUE,show_col_types = FALSE)->stazioni


#questa parte va caricata fuori della funzione renderLeaflet, altrimenti si crea un problema di refresh con punti e rasters, quando i punti sono fissi e non variano
leaflet(data=stazioni) %>%
  setView(lng=12,lat=42,zoom=6) %>%
  addTiles() %>%
  addProviderTiles(provider="Stamen.Toner")->mappaLeaf


