#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

source("global.R")

library("rgdal")
library("raster")
library("scico")
library("tidyr")
library("shiny.i18n")
library("leaflet.extras")
source("getStation.R")

    


# Define server logic required to draw a histogram
shinyServer(function(input, output,session) {
    
    
    #All'apertura dell'app, quando l'utente non ha ancora selezionato nessuna stazione, viene scelta una stazione a caso
    sample_n(stazioni,size=1)->randomStation
    
    
    reactive({
        
        ifelse(input$feriali,"feriali","festivi")

    })->nomeFile
    
    
    myrasters<-reactive({
            
        grep(input$settimana,nomiLayers())->qualeLayer
        req(qualeLayer>0)
        
        raster(paste0(nomeFile(),".tif"),band=qualeLayer)->griglia
        raster(paste0(nomeFile(),"_masks.tif"),band=qualeLayer)->maschera

        list(griglia,maschera)

            
    })
    
    
    reactive({
        
        ifelse(input$language,i18n$get_languages()[1],i18n$get_languages()[2])->language
    
        if(grepl("feriali",nomeFile())){
            
            if(language=="en"){
                c(paste0("March - week ",1:4),paste0("April - week ",1:5))
            }else{
                c(paste0("Marzo - settimana ",1:4),paste0("Aprile - settimana ",1:5))
            }
            
        }else{
            
            if(language=="en"){
                c(paste0("March - week ",1:5),paste0("April - week ",1:4))
            }else{
                c(paste0("Marzo - settimana ",1:5),paste0("Aprile - settimana ",1:4))
            }            
            
        }
    
    })->nomiLayers    
    
    
    observe({
        
        
        updateSelectInput(inputId = "settimana",label="",choices = nomiLayers(),selected=nomiLayers()[1])
        
    })
    
    
    observeEvent(input$mappa_marker_click,{
        
        getStation(.click=input$mappa_marker_click,.x=stazioni,.randomStation = randomStation)->subStazione
        
        
        leafletProxy(mapId="mappa") %>%
            clearPopups() %>%
            addPopups(data=subStazione,lng=subStazione$st_x,lat=subStazione$st_y,options = markerOptions(clickable = FALSE),popup=~nome_stazione)
        
        
    })


    output$mappa<-leaflet::renderLeaflet({

        isolate(getStation(.click=input$mappa_marker_click,.x=stazioni,.randomStation = randomStation)->subStazione)
        
            mappaLeaf %>%
            addRasterImage(x=myrasters()[[1]],colors = pal,opacity=0.8,project=FALSE) %>%
            addRasterImage(x=myrasters()[[2]],opacity=0.4,group = i18n$t("Significant variation area"),colors ="#333333",project=TRUE) %>%
            addCircleMarkers(opacity=1,lat=~st_y,lng=~st_x,radius=4,fillColor="#E26969",stroke=FALSE,fillOpacity=0.8,group = i18n$t("Monitoring stations"),layerId=~station_eu_code,label=~nome_stazione) %>%
            addLayersControl(overlayGroups =c(i18n$t("Monitoring stations"),i18n$t("Significant variation area")),options = layersControlOptions(collapsed = FALSE)) %>%
            hideGroup(group=i18n$t("Significant variation area")) %>%
            addLegend(position="topright",pal=pal,values=seq(-100,100,10),title = i18n$t("% variation")) %>%
            addEasyButton(button=easyButton(icon=icon("globe"),title="Home",onClick = JS("function(btn,map){map.setView({lat:42,lng:12},6);}"))) %>%
            activateGPS() %>%
            addControlGPS(options = gpsOptions(maxZoom=15,setView = TRUE,autoCenter = TRUE)) %>%
            addPopups(data=subStazione,lng=subStazione$st_x,lat=subStazione$st_y,popup = ~nome_stazione,options = markerOptions(clickable = FALSE))
        
    })
    
    

    output$mappaStazione<-renderLeaflet({
        
        getStation(.click=input$mappa_marker_click,.x=stazioni,.randomStation=randomStation)->subStazioni
        
        leaflet(data=subStazioni,options = leafletOptions(zoomControl=FALSE)) %>%
            setView(lng=subStazioni$st_x,lat=subStazioni$st_y,zoom=16) %>%
            addTiles() %>%
            addPulseMarkers(lng=~st_x,lat=~st_y,icon = makePulseIcon(heartbeat = 1,color="#FF3E59"))

    })
    

    output$info<-renderText({
        
        getStation(.click=input$mappa_marker_click,.x=stazioni,.randomStation=randomStation)->subStazione
        
        subStazione %>%
            mutate(tipo_zona=case_when(tipo_zona=="U"~"Urban",
                                       tipo_zona=="R"~"Rural",
                                       tipo_zona=="S"~"Suburban",
                                       tipo_zona=="R-nearcity"~"Rural-nearcity",
                                       tipo_zona=="R-regional"~"Rural-regional",
                                       tipo_zona=="R-remote"~"Rural-remote"))->subStazione
        
        
        subStazione %>%
            mutate(tipo_stazione=case_when(tipo_stazione=="F"~"Foreground",
                                           tipo_stazione=="T"~"Traffic",
                                           tipo_stazione=="I"~"Industrial",
                                           tipo_stazione=="F/I"~"Foreground/Industrial"))->subStazione
        
        ALTITUDE<-i18n$t("Altitude")
        REGION<-i18n$t("Region")
        LONGITUDE<-i18n$t("Longitude")
        LATITUDE<-i18n$t("Latitude")
        PROVINCE<-i18n$t("Province")
        MUNICIPALITY<-i18n$t("Municipality")
        ENVIRONMENTT<-i18n$t("Site environment type")
        STATIONT<-i18n$t("Station type")
        
        #queste infor per il momento non inserite:
        MAJORR<-i18n$t("Distance to major roads")
        SECONDARYRR<-i18n$t("Distance to secondary roads")
        ISURFACE<-i18n$t("Impervious surface")
        
        
        glue::glue("<h3>{str_to_title(tolower(subStazione$nome_stazione))} ({subStazione$station_eu_code})</h3>")->titolo
        glue::glue("<div><strong>{REGION}</strong>: {str_to_title(tolower(str_replace_all(subStazione$regione,'_',' ')))}</div>")->regione        
        glue::glue("<div><strong>{PROVINCE}</strong>: {subStazione$provincia}</div>")->provincia    
        glue::glue("<div><strong>{MUNICIPALITY}</strong>: {subStazione$comune}</div>")->comune        
        glue::glue("<div><strong>{ALTITUDE}</strong>: {ifelse(is.na(subStazione$altitudine),'?',subStazione$altitudine)} m</div>")->altitudine
        glue::glue("<div><strong>{LONGITUDE}</strong>: {round(subStazione$st_x,2)}</div>")->lon
        glue::glue("<div><strong>{LATITUDE}</strong>: {round(subStazione$st_y,2)}</div>")->lat
        # glue::glue("<div><strong>{MAJORR}</strong>: {round(subStazione$d_a1/1000,0)} km</div>")->a1        
        # glue::glue("<div><strong>{SECONDARYRR}</strong>: {round(subStazione$d_a2/1000,0)} km</div>")->a2
        # glue::glue("<div><strong>{ISURFACE}</strong>: {round(subStazione$i_surface,1)} %</div>")->i_surface
        # glue::glue("<div><strong>{ISURFACE}</strong>: {round(subStazione$i_surface,1)} %</div>")->i_surface
        glue::glue("<div><strong>{ENVIRONMENTT}</strong>: {subStazione$tipo_zona}</div>")->tipo_zona
        glue::glue("<div><strong>{STATIONT}</strong>: {subStazione$tipo_stazione}</div>")->tipo_stazione
        
        
        #per aggiungere altre info nel box html, aggiungere le variabili output di glue nella lista passata a purrr_map qui sotto
        paste0("<div style='line-height: 2;'>",htmltools::HTML(purrr::map_chr(list(titolo,regione,provincia,comune,altitudine,lon,lat,tipo_zona,tipo_stazione),.f=paste,sep="")),"</div>")
        
    })    

    output$barplot<-renderEcharts4r({
        

        getStation(.click=input$mappa_marker_click,.x=stazioni,.randomStation=randomStation)->subStazioni

        
        if(!input$feriali){
            subStazioni %>%
                dplyr::select(-matches("^.+festivi."))->subStazioni
        }else{
            subStazioni %>%
                dplyr::select(-matches("^.+feriali."))->subStazioni            
        }
        
        subStazioni$nome_stazione->nome_stazione
        subStazioni$station_eu_code->station_eu_code
        
        subStazioni %>%
            gather(key="settimana",value="variazione",-station_eu_code,-st_x,-st_y,-altitudine,-regione,-provincia,-comune,-nome_stazione,-i_surface,-d_a1,-d_a2,-tipo_zona,-tipo_stazione,-zona_tipo) %>%
            mutate(variazione=round(variazione*100,1)) %>%
            mutate(settimana=str_wrap(str_remove(nomiLayers(),"-"),8))->gdati

        gdati %>%
            e_charts(x=settimana) %>%
            e_bar(serie=variazione) %>%
            e_axis(axis="x",axisLabel=list(fontSize=12,rotate=90,color="#333")) %>%
            e_axis(axis="y",axisLabel=list(fontSize=14,color="#333"),show=TRUE,nameGap=45,nameLocation="middle",name="%",nameTextStyle=list(color="#333",fontWeight="bold",fontSize=14)) %>%
            e_visual_map(serie=variazione,type="piecewise",pieces=list(list(gt=0,color="#5C9F61"),list(lt=0,color="#4B76A0"))) %>%
            e_tooltip(trigger="item",formatter=htmlwidgets::JS("function(params){return(params.value[0]+': '+'<strong>'+params.value[1]+'</strong>'+'%');}")) %>%
            e_legend(show=FALSE) %>%
            e_title(text="",subtext=as.character(i18n$t("2019/2020 variation in NO2")))
        
    })
    
    
    
    observeEvent(input$language,{
        
        #print(paste("Language change!", input$language))
        update_lang(session,language=ifelse(input$language,i18n$get_languages()[1],i18n$get_languages()[2]) )
        
        
    })
    
    
    output$readme<-renderText({
        
        HTML(ifelse(input$language,readmeEN,readmeIT))
        

        
    })
    
    


})
