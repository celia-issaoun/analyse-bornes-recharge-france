mod_principal_ui = function(id) {
  ns = NS(id)
  
  fluidPage(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
    ),
    
    titlePanel("Analyse de l'accès aux bornes de recharge électrique en France"),
    tabsetPanel(
      type = "tabs",
      tabPanel("Présentation de l'application",
               div(
                 class = "presentation-section bg-voiture animated",
                 style = "max-width: 950px; margin: auto; padding-bottom: 30px;",
                 
                 tags$h2("", class = "titre-centre", style = "color: white;"),
                 
                 div(class = "presentation-grid",
                     
                     div(class = "presentation-card",
                         tags$details(open = TRUE,
                                      tags$summary(
                                        span("Bienvenue dans notre application", class = "summary-title", style = "display: block; text-align: center; color: orange; font-weight: bold; font-size: 20px;")),
                                      div(class = "presentation-content active",
                                          tags$p("Dans un contexte de transition écologique et de lutte contre le changement climatique, 
                  la mobilité électrique s’impose comme un levier stratégique pour réduire les émissions de gaz à effet de serre."),
                                          tags$p("Le développement du véhicule électrique (VE) repose sur la mise en place d’un réseau de bornes de recharge dense, équitablement réparti et performant."),
                                          tags$p("Cette application interactive vous permet de visualiser et analyser ces infrastructures à l’échelle communale, 
                  en croisant les données de bornes, de véhicules électriques et de densité de population.")
                                      )
                         )
                     ),
                     
                     div(class = "presentation-card",
                         tags$details(
                           tags$summary(
                             span("Données utilisées", class = "summary-title", style = "display: block; text-align: center; color: orange; font-weight: bold; font-size: 20px;")),
                           div(class = "presentation-content",
                               tags$p("Trois jeux de données principaux :"),
                               tags$ul(
                                 tags$li(tags$b("Bornes de recharge : "), "localisation et caractéristiques des bornes disponibles."),
                                 tags$li(tags$b("Véhicules électriques : "), "nombre de véhicules  électriques par commune."),
                                 tags$li(tags$b("Densité de population : "), " nombre d’habitants au km² par commune, issu de l’INSEE.")
                               ),
                               tags$p("Ces données permettent d’établir un lien entre l’offre (infrastructures de recharge) et la demande (population, véhicules).")
                           )
                         )
                     ),
                     
                     div(class = "presentation-card",
                         tags$details(
                           tags$summary(
                             span("Visualisation", class = "summary-title", style = "display: block; text-align: center; color: orange; font-weight: bold; font-size: 20px;")
                           ),
                           div(class = "presentation-content",
                               tags$p("L'onglet Visualisation présente sous forme de cartes et graphiques interactifs les dimensions principales explorées dans cette application :"),
                               tags$ul(
                                 tags$li(tags$b("Bornes de recharge : "), "carte interactive, histogrammes, camemberts 3D et boxplots selon la puissance."),
                                 tags$li(tags$b("Véhicules électriques : "), "graphiques en barres, camemberts, scatter plots et boîtes à moustaches."),
                                 tags$li(tags$b("Densité de population : "), "comparaison des communes via des visualisations dynamiques selon leur densité.")
                               ),
                               tags$p("Ces visualisations permettent d'explorer de manière intuitive la répartition géospatiale et les inégalités territoriales.")
                           )
                         )
                     ),
                     
                     div(class = "presentation-card",
                         tags$details(
                           tags$summary(
                             span("Méthodes d’analyse", class = "summary-title", style = "display: block; text-align: center; color: orange; font-weight: bold; font-size: 20px;")),
                           div(class = "presentation-content",
                               tags$p("L’onglet Méthodes d’analyse propose deux axes d’exploration complémentaires :"),
                               tags$ul(
                                 tags$li(tags$b("Analyse de la densité : "), "étude de la répartition des bornes à travers une carte de chaleur, une estimation par noyau (KDE), et une analyse croisée de la couverture par commune."),
                                 tags$li(tags$b("Analyse de la proximité : "), "mesure de l’accessibilité via les distances routières aux bornes et les zones de chalandise générées en fonction du temps de trajet.")
                               ),
                               tags$p("Ces méthodes permettent de caractériser la distribution géospatiale des infrastructures de recharge et leur accessibilité pour les usagers.")
                           )
                         )
                     )
                 )
               )
      ),
      
      tabPanel("Données utilisées", uiOutput(ns("donnees_ui"))),
      tabPanel("Visualisation", mod_visualisation_ui(ns("visualisation"))),
      tabPanel("Méthodes d'analyse",
               tabsetPanel(
                 tabPanel("Analyse de la densité",
                          tabsetPanel(
                            tabPanel("Carte de chaleur",  mod_heatmap_ui(ns("heatmap1"))),
                            tabPanel("Densité Kernel",   mod_kernel_ui(ns("kernel1"))),
                            tabPanel("Couverture",       mod_couverture_densite_ui(ns("couverture1")))
                          )
                 ),
                 tabPanel("Analyse de la proximité",
                          tabsetPanel(
                            tabPanel("Distances",          mod_distance_ui(ns("distance1"))),
                            tabPanel("Zone de chalandise", mod_chalandise_ui(ns("zone15")))
                          )
                 )))
    )
  )
}


mod_principal = function(id, bornes_raw, vehicules, densite, communes, api_key) {
  moduleServer(id, function(input, output, session) {
    ns = session$ns
    
    bornes = bornes_raw %>%
      filter(!is.na(latitude), !is.na(longitude)) %>%
      mutate(
        puissance_nominale = as.numeric(puissance_nominale),
        type_prise = ifelse(is.na(type_prise), "Inconnue", type_prise),
        puissance_cat = case_when(
          is.na(puissance_nominale) ~ "Inconnue",
          puissance_nominale <= 22 ~ "≤22 kW",
          puissance_nominale <= 50 ~ "22-50 kW",
          puissance_nominale > 50 ~ ">50 kW"
        )
      )
    
    vehicules_stats = reactive({
      vehicules %>%
        summarise(
          total = sum(NB_VP_RECHARGEABLES_EL, na.rm = TRUE),
          moyenne = round(mean(NB_VP_RECHARGEABLES_EL, na.rm = TRUE), 1),
          mediane = median(NB_VP_RECHARGEABLES_EL, na.rm = TRUE)
        )
    })
    
    output$total_vehicules = renderText({ vehicules_stats()$total })
    output$moyenne_vehicules = renderText({ vehicules_stats()$moyenne })
    output$mediane_vehicules = renderText({ vehicules_stats()$mediane })
    
    output$table_vehicules = DT::renderDT({
      datatable(vehicules, extensions = "Buttons", options = list(
        dom = 'Bfrtip',
        buttons = c( 'csv', 'excel', 'pdf'),
        scrollX = TRUE,
        pageLength = 10
      ), class = 'stripe hover cell-border nowrap') %>%
        formatStyle(
          columns = names(vehicules),
          backgroundColor = '#2c2c3e',
          color = '#f1f1f1'
        ) %>%
        formatStyle('NB_VP_RECHARGEABLES_EL',
                    backgroundColor = styleInterval(c(50, 100, 500), c('#2c3e50', '#2980b9', '#27ae60', '#c0392b')),
                    color = 'white'
        )
    })
    
    densite_stats = reactive({
      densite %>%
        summarise(
          moyenne = round(mean(dens_pop, na.rm = TRUE), 1),
          mediane = median(dens_pop, na.rm = TRUE),
          max = max(dens_pop, na.rm = TRUE)
        )
    })
    
    output$moyenne_densite = renderText({ densite_stats()$moyenne })
    output$mediane_densite = renderText({ densite_stats()$mediane })
    output$max_densite     = renderText({ densite_stats()$max })
    
    output$table_densite = DT::renderDT({
      datatable(densite, extensions = "Buttons", options = list(
        dom = 'Bfrtip',
        buttons = c('csv', 'excel', 'pdf'),
        scrollX = TRUE,
        pageLength = 10
      ), class = 'stripe hover cell-border nowrap') %>%
        formatStyle(
          columns = names(densite),
          backgroundColor = '#2c2c3e',
          color = '#f1f1f1'
        ) %>%
        formatStyle('dens_pop',
                    backgroundColor = styleInterval(c(30, 50, 100, 500), c('#34495e', '#1abc9c', '#f39c12', '#e67e22', '#c0392b')),
                    color = 'white'
        )
    })
    
    bornes_stats <- reactive({
      bornes %>%
        summarise(
          moyenne = round(mean(puissance_nominale, na.rm = TRUE), 1),
          mediane = median(puissance_nominale, na.rm = TRUE),
          max = max(puissance_nominale, na.rm = TRUE)
        )
    })
    
    output$moyenne_bornes = renderText({ bornes_stats()$moyenne })
    output$mediane_bornes = renderText({ bornes_stats()$mediane })
    output$max_bornes     = renderText({ bornes_stats()$max })
    
    output$table_bornes = DT::renderDT({
      datatable(bornes, extensions = "Buttons", options = list(
        dom = 'Bfrtip',
        buttons = c('csv', 'excel', 'pdf'),
        scrollX = TRUE,
        pageLength = 10
      ), class = 'stripe hover cell-border nowrap') %>%
        formatStyle(
          columns = names(bornes),
          backgroundColor = '#2c2c3e',
          color = '#f1f1f1'
        ) %>%
        formatStyle('puissance_nominale',
                    backgroundColor = styleInterval(c(22, 50, 100), c('#7f8c8d', '#2980b9', '#27ae60', '#c0392b')),
                    color = 'white'
        )
    })
    
    output$donnees_ui = renderUI({
      tabsetPanel(
        tabPanel("Bornes de recharge",
                 div(style = "max-width: 900px; margin: auto; padding: 20px;",
                     fluidRow(
                       column(4, div(class = "info-box box-total", icon("bolt", class = "info-icon"), h4("Puissance moyenne", class = "info-title"), textOutput(ns("moyenne_bornes"), container = span))),
                       column(4, div(class = "info-box box-moyenne", icon("compress-arrows-alt", class = "info-icon"), h4("Médiane", class = "info-title"), textOutput(ns("mediane_bornes"), container = span))),
                       column(4, div(class = "info-box box-mediane", icon("battery-full", class = "info-icon"), h4("Max", class = "info-title"), textOutput(ns("max_bornes"), container = span)))
                     ),
                     br(),
                     fluidRow(column(12, DTOutput(ns("table_bornes"))))
                 )),
        
        
        tabPanel("Véhicules électriques",
                 div(style = "max-width: 900px; margin: auto; padding: 20px;",
                     fluidRow(
                       column(4, div(class = "info-box box-total", icon("car", class = "info-icon"), h4("Total VE", class = "info-title"), textOutput(ns("total_vehicules"), container = span))),
                       column(4, div(class = "info-box box-moyenne", icon("calculator", class = "info-icon"), h4("Moyenne", class = "info-title"), textOutput(ns("moyenne_vehicules"), container = span))),
                       column(4, div(class = "info-box box-mediane", icon("chart-bar", class = "info-icon"), h4("Médiane", class = "info-title"), textOutput(ns("mediane_vehicules"), container = span)))
                     ),
                     br(),
                     fluidRow(column(12, DTOutput(ns("table_vehicules"))))
                 )),
        
        tabPanel("Densité de population",
                 div(style = "max-width: 900px; margin: auto; padding: 20px;",
                     fluidRow(
                       column(4, div(class = "info-box box-total", icon("users", class = "info-icon"), h4("Moyenne", class = "info-title"), textOutput(ns("moyenne_densite"), container = span))),
                       column(4, div(class = "info-box box-moyenne", icon("align-center", class = "info-icon"), h4("Médiane", class = "info-title"), textOutput(ns("mediane_densite"), container = span))),
                       column(4, div(class = "info-box box-mediane", icon("chart-line", class = "info-icon"), h4("Max", class = "info-title"), textOutput(ns("max_densite"), container = span)))
                     ),
                     br(),
                     fluidRow(column(12, DTOutput(ns("table_densite"))))
                 ))
        
 
        )})
    
    
    mod_visualisation_server("visualisation", bornes, reactive(communes), vehicules, densite)
    mod_heatmap("heatmap1", bornes)
    mod_kernel("kernel1", bornes)
    mod_couverture_densite("couverture1", bornes, vehicules, densite)
    mod_distance("distance1", bornes)
    mod_chalandise_server("zone15", bornes, api_key)
  })
} 