library(shiny);library(stats);library(readr);library(leaflet);library(dplyr)
library(leaflet.extras);library(viridis);library(openrouteservice)
library(maps);library(sf);library(stringr);library(shinycssloaders);library(ggplot2)
library(plotly);library(bslib);library(DT);library(echarts4r);library(RColorBrewer)
library(tidyr);library(units);library(osmdata);library(highcharter);library(htmlwidgets)
library(webshot2)
# Définir la clé API
api_key <- readLines("data/api_key.txt")

bornes = read.csv2("data/bornes_complet.csv", fileEncoding = "UTF-8")
communes = readRDS("data/communes.rds")
vehicules = read_delim("data/vehicules_electriques_par_commune.csv",delim=',')
densite = read_csv("data/densite_filtree.csv") %>%mutate(dens_pop = as.numeric(dens_pop))
vehicules = vehicules %>% mutate(NB_VP_RECHARGEABLES_EL = as.numeric(NB_VP_RECHARGEABLES_EL))

source("code_RSHINY/mod_principal.R")
source("code_RSHINY/mod_visualisation.R")
source("code_RSHINY/mod_heatmap.R")
source("code_RSHINY/mod_kernel.R")
source("code_RSHINY/mod_couverture_densite.R")
source("code_RSHINY/mod_distance.R")
source("code_RSHINY/mod_chalandise.R")

ui <- fluidPage(
  mod_principal_ui("module_principal"))

server <- function(input, output, session) {
  mod_principal("module_principal", bornes, vehicules, densite, communes, api_key)}


shinyApp(ui, server)

