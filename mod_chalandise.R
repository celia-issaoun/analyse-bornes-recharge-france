mod_chalandise_ui = function(id) {
  ns = NS(id)
  tagList(
    sidebarLayout(
      sidebarPanel(
        selectizeInput(
          ns("code_insee"), "Code INSEE :",
          choices = NULL, selected = NULL,
          options = list(maxOptions = 1000), multiple = FALSE
        ),
        sliderInput(                          # Choix de 1 à 20 min
          ns("minutes"), "Temps de trajet (minutes) :",
          min = 1, max = 20, value = 15, step = 1
        ),
        actionButton(
          ns("go"), "Afficher zone",
          style = "color: white; background-color: #3498db; border-color: #2980b9; font-weight: bold;"
        ),
        br(),

        tags$div(
          style = "background-color: #e8f4fd; border-radius: 6px; padding: 10px; margin-top: 15px;
                   border-left: 4px solid #3498db; color: #2c3e50; font-size: 14px;",
          HTML('<span style="font-weight:bold;">&#9432; Info :</span> Une seule borne est utilisée pour éviter de dépasser les quotas.')
        )),
    mainPanel(
      leafletOutput(ns("map"), height = 500),
        verbatimTextOutput(ns("status"))
      )))
}


mod_chalandise_server = function(id, bornes, api_key) {
  moduleServer(id, function(input, output, session) {
    ns = session$ns
    observe({
      req(bornes)
      updateSelectizeInput(session, "code_insee",
                           choices = sort(unique(bornes$code_insee)),
                           server  = TRUE)})
    
    observeEvent(input$go, {
      req(input$code_insee, input$minutes)
      
      borne= bornes %>% filter(code_insee == input$code_insee) %>% slice(1)
      if (nrow(borne) == 0) {
        output$status = renderText("Aucune borne trouvée pour ce code INSEE.")
        output$map    = renderLeaflet({ leaflet() %>% addTiles() })
        return()
      }
      
      if (!inherits(borne, "sf")) {
        borne = st_as_sf(borne, coords = c("longitude", "latitude"), crs = 4326)
      }
      coords = matrix(st_coordinates(borne)[1, ], ncol = 2)
      range_sec = as.integer(input$minutes) * 60

      tryCatch({
        isoline = ors_isochrones(
          locations = coords,
          profile   = "driving-car",
          range     = range_sec,      
          interval  = range_sec,
          output    = "sf",
          api_key   = api_key
        )
        
        output$map = renderLeaflet({
          leaflet() %>%
            addTiles() %>%
            addPolygons(data = isoline, fillColor = "blue", fillOpacity = 0.3,
                        color = "blue",
                        label = paste("Zone", input$minutes, "min")) %>%
            addCircleMarkers(data = borne, radius = 6,
                             color = "red", label = ~nom_station)
        })
        output$status = renderText(
          paste0("Zone de ", input$minutes,
                 " min calculée autour de la borne : ", borne$nom_station)
        )
      }, error = function(e) {
        output$status = renderText(paste("Erreur ORS :", e$message))
        output$map    = renderLeaflet({ leaflet() %>% addTiles() })
      })
    })
  })
}