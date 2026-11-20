mod_heatmap_ui = function(id) {
  ns = NS(id)
  tags$div(
    style = "width: 800px; margin: 0 auto;",  
    leafletOutput(ns("map_heatmap"), height = "500px", width = "100%")
  )
}

mod_heatmap = function(id, bornes) {
  moduleServer(id, function(input, output, session) {
    output$map_heatmap = renderLeaflet({
      leaflet(bornes) %>%
        setView(lng = 0.5, lat = 49.2, zoom = 5) %>%
        addProviderTiles(providers$OpenStreetMap.France) %>%
        addHeatmap(
          lng = ~longitude,
          lat = ~latitude,
          intensity = ~nbre_pdc,
          blur = 8,
          radius = 8,
          max = 2
        )
    })
  })
}



