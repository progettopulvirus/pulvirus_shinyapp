#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

source("global.R")
library("shinydashboard")
library("shinydashboardPlus")
library("shinycssloaders")
library("shinyWidgets")


c(paste0("March - week ",1:4),paste0("April - week ",1:5))->scelteIniziali
c(paste0("March - week ",1:4),paste0("April - week ",1:5))->scelteIniziali_it

i18n<-Translator$new(translation_csvs_path = "translations/",separator_csv = ",",automatic =FALSE)
i18n$set_translation_language("en")
shiny.i18n::usei18n(i18n)

# Define UI for application that draws a histogram
dashboardPage(
    header = dashboardHeader(title=span("A spatio-temporal analysis of NO2 concentrations during the Italian 2020 COVID-19 lockdown",style="font-size: 14px;"),
                             titleWidth=550,
                             tags$li(shiny.i18n::usei18n(i18n),class="dropdown"),
                             tags$li(class="dropdown",tags$a(span(i18n$t("R-INLA code "),icon("github")),target="_blank",title="GITHUB repository link",href="https://github.com/progettopulvirus/A_spatiotemporal_analysis_of_NO2_concentrations"))),
    sidebar = dashboardSidebar(
        width=NULL,
        collapsed = TRUE,
        minified = FALSE,
        tagList(tags$br(),tags$br()),
        switchInput(inputId="language",label=i18n$t("Language"),value = TRUE,onLabel = i18n$get_languages()[1] ,offLabel = i18n$get_languages()[2]),
        tagList(tags$br(),tags$div(i18n$t("Select the raster map"),class="shiny-input-container",style="padding-bottom: 0px !important;")),
        tags$br(),
        switchInput(label=i18n$t("Days"),inputId = "feriali",value = TRUE,onLabel = i18n$t("Weekdays"),offLabel=i18n$t("Sunday")),
        selectInput(inputId="settimana",label="",multiple = FALSE,choices =i18n$t(scelteIniziali),selected =i18n$t(scelteIniziali[1]))
        
    ),#fine sidebar
    body =dashboardBody(
        tags$style(type="text/css","#mappa {height: calc(95vh - 80px) !important;}"),
        tags$style(type="text/css",".info {background: rgba(255,255,255,1);}"), #trasparenza della legenda 
        tags$style(type="text/css","#readme {height: calc(95vh - 80px) !important;}"),
        tags$style(type="text/css",".skin-blue .main-header .logo{background-color: #3c8dbc;}"),
        tags$style(type="text/css",".box{box-shadow: 0px 0px #FFF;};"),
        tags$style(type="text/css",".bootstrap-switch .bootstrap-switch-handle-off.bootstrap-switch-primary, .bootstrap-switch .bootstrap-switch-handle-on.bootstrap-switch-primary {color: #333; font-weight: bold; background-color: #E5E5E5 !important;}"),
 
        
        fluidRow(
            tabBox(
                id="tabMappa",
                width = 12,
                tabPanel(title=i18n$t("Raster maps"),icon = icon("globe"),leaflet::leafletOutput(outputId = "mappa") %>% withSpinner()),
                tabPanel(title=i18n$t("Station info"),icon=icon("calendar"),
                         fluidRow(
                            column(width=3,box(width=NULL,htmlOutput(outputId = "info"))),
                            column(width=6,box(width=NULL,echarts4rOutput(outputId = "barplot"))),
                            column(width=3,box(width=NULL,leafletOutput(outputId = "mappaStazione")))
                         )
                         ),#fine tabPanel
                tabPanel(
                    title=i18n$t("Readme"),icon=icon("book"),includeHTML("readme.html")
                )
            )#fine tabBox
        )
        
        
    )#fine body 
    
    
    
)#fine dhashboardPage
