
# ============================================================
# MODULE KERNEL - DENSITE DES BORNES DE RECHARGE
# ============================================================

# ================= INTERFACE =================

mod_kernel_ui = function(id) {
  
  ns = NS(id)
  
  tagList(
    sidebarLayout(
      
      sidebarPanel(
        width = 3,
        
        selectInput(
          ns("region"),
          "Région :",
          choices = c("Toutes")
        ),
        
        selectInput(
          ns("dep"),
          "Département :",
          choices = c("Tous")
        ),
        
        sliderInput(
          ns("puissance"),
          "Puissance minimale (kW) :",
          min = 0,
          max = 350,
          value = 0
        ),
        
        selectInput(
          ns("prise"),
          "Type de prise :",
          choices = c("Tous")
        ),
        
        actionButton(
          ns("go"),
          "Lancer",
          style = paste0(
            "color:white;",
            "background:#2c3e50;",
            "font-weight:bold;",
            "margin-top:10px;"
          )
        ),
        
        actionButton(
          ns("reset"),
          "Réinitialiser",
          style = paste0(
            "color:white;",
            "background:#2c3e50;",
            "font-weight:bold;",
            "margin-top:10px;"
          )
        )
      ),
      
      mainPanel(
        width = 9,
        
        leafletOutput(
          ns("kdeMap"),
          height = "600px"
        )
      )
    )
  )
}


# ================= SERVEUR =================

mod_kernel = function(id, bornes) {
  
  moduleServer(id, function(input, output, session) {
    
    # ================= REGIONS / DEPARTEMENTS =================
    
    departement_region = tibble::tribble(
      ~dep, ~region,
      
      "01", "Auvergne-Rhône-Alpes",
      "02", "Hauts-de-France",
      "03", "Auvergne-Rhône-Alpes",
      "04", "Provence-Alpes-Côte d’Azur",
      "05", "Provence-Alpes-Côte d’Azur",
      "06", "Provence-Alpes-Côte d’Azur",
      "07", "Auvergne-Rhône-Alpes",
      "08", "Grand Est",
      "09", "Occitanie",
      "10", "Grand Est",
      "11", "Occitanie",
      "12", "Occitanie",
      "13", "Provence-Alpes-Côte d’Azur",
      "14", "Normandie",
      "15", "Auvergne-Rhône-Alpes",
      "16", "Nouvelle-Aquitaine",
      "17", "Nouvelle-Aquitaine",
      "18", "Centre-Val de Loire",
      "19", "Nouvelle-Aquitaine",
      "2A", "Corse",
      "2B", "Corse",
      "21", "Bourgogne-Franche-Comté",
      "22", "Bretagne",
      "23", "Nouvelle-Aquitaine",
      "24", "Nouvelle-Aquitaine",
      "25", "Bourgogne-Franche-Comté",
      "26", "Auvergne-Rhône-Alpes",
      "27", "Normandie",
      "28", "Centre-Val de Loire",
      "29", "Bretagne",
      "30", "Occitanie",
      "31", "Occitanie",
      "32", "Occitanie",
      "33", "Nouvelle-Aquitaine",
      "34", "Occitanie",
      "35", "Bretagne",
      "36", "Centre-Val de Loire",
      "37", "Centre-Val de Loire",
      "38", "Auvergne-Rhône-Alpes",
      "39", "Bourgogne-Franche-Comté",
      "40", "Nouvelle-Aquitaine",
      "41", "Centre-Val de Loire",
      "42", "Auvergne-Rhône-Alpes",
      "43", "Auvergne-Rhône-Alpes",
      "44", "Pays de la Loire",
      "45", "Centre-Val de Loire",
      "46", "Occitanie",
      "47", "Nouvelle-Aquitaine",
      "48", "Occitanie",
      "49", "Pays de la Loire",
      "50", "Normandie",
      "51", "Grand Est",
      "52", "Grand Est",
      "53", "Pays de la Loire",
      "54", "Grand Est",
      "55", "Grand Est",
      "56", "Bretagne",
      "57", "Grand Est",
      "58", "Bourgogne-Franche-Comté",
      "59", "Hauts-de-France",
      "60", "Hauts-de-France",
      "61", "Normandie",
      "62", "Hauts-de-France",
      "63", "Auvergne-Rhône-Alpes",
      "64", "Nouvelle-Aquitaine",
      "65", "Occitanie",
      "66", "Occitanie",
      "67", "Grand Est",
      "68", "Grand Est",
      "69", "Auvergne-Rhône-Alpes",
      "70", "Bourgogne-Franche-Comté",
      "71", "Bourgogne-Franche-Comté",
      "72", "Pays de la Loire",
      "73", "Auvergne-Rhône-Alpes",
      "74", "Auvergne-Rhône-Alpes",
      "75", "Île-de-France",
      "76", "Normandie",
      "77", "Île-de-France",
      "78", "Île-de-France",
      "79", "Nouvelle-Aquitaine",
      "80", "Hauts-de-France",
      "81", "Occitanie",
      "82", "Occitanie",
      "83", "Provence-Alpes-Côte d’Azur",
      "84", "Provence-Alpes-Côte d’Azur",
      "85", "Pays de la Loire",
      "86", "Nouvelle-Aquitaine",
      "87", "Nouvelle-Aquitaine",
      "88", "Grand Est",
      "89", "Bourgogne-Franche-Comté",
      "90", "Bourgogne-Franche-Comté",
      "91", "Île-de-France",
      "92", "Île-de-France",
      "93", "Île-de-France",
      "94", "Île-de-France",
      "95", "Île-de-France"
    )
    
    
    # ================= PREPARATION DES DONNEES =================
    
    bornes = bornes %>%
      dplyr::mutate(
        code_insee = as.character(code_insee),
        
        dep = dplyr::case_when(
          substr(code_insee, 1, 2) %in% c("2A", "2B") ~
            substr(code_insee, 1, 2),
          
          substr(code_insee, 1, 2) %in% c("97", "98") ~
            substr(code_insee, 1, 3),
          
          TRUE ~ substr(code_insee, 1, 2)
        ),
        
        longitude = suppressWarnings(
          as.numeric(gsub(",", ".", as.character(longitude)))
        ),
        
        latitude = suppressWarnings(
          as.numeric(gsub(",", ".", as.character(latitude)))
        ),
        
        puissance_nominale = suppressWarnings(
          as.numeric(gsub(",", ".", as.character(puissance_nominale)))
        ),
        
        type_prise = as.character(type_prise)
      ) %>%
      dplyr::left_join(
        departement_region,
        by = "dep"
      ) %>%
      dplyr::mutate(
        region = ifelse(
          is.na(region),
          "Inconnue",
          region
        )
      )
    
    
    # ================= INITIALISATION DES FILTRES =================
    
    observe({
      
      updateSelectInput(
        session,
        "region",
        choices = c(
          "Toutes",
          sort(unique(bornes$region))
        )
      )
      
      updateSelectInput(
        session,
        "dep",
        choices = c(
          "Tous",
          sort(unique(bornes$dep[!is.na(bornes$dep)]))
        )
      )
      
      updateSelectInput(
        session,
        "prise",
        choices = c(
          "Tous",
          sort(unique(
            bornes$type_prise[!is.na(bornes$type_prise)]
          ))
        )
      )
    })
    
    
    # ================= CARTE INITIALE =================
    
    output$kdeMap = renderLeaflet({
      
      leaflet() %>%
        
        # Fond OpenStreetMap
        addTiles() %>%
        
        # Vue initiale de la France
        setView(
          lng = 2.5,
          lat = 46.5,
          zoom = 6
        )
    })
    
    
    # ================= REINITIALISER =================
    
    observeEvent(input$reset, {
      
      # Réinitialisation des filtres
      updateSelectInput(
        session,
        "region",
        selected = "Toutes"
      )
      
      updateSelectInput(
        session,
        "dep",
        selected = "Tous"
      )
      
      updateSelectInput(
        session,
        "prise",
        selected = "Tous"
      )
      
      updateSliderInput(
        session,
        "puissance",
        value = 0
      )
      
      # Nettoyage de la carte
      leafletProxy(
        "kdeMap",
        session = session
      ) %>%
        
        clearMarkers() %>%
        clearControls() %>%
        clearHeatmap() %>%
        
        setView(
          lng = 2.5,
          lat = 46.5,
          zoom = 6
        )
    })
    
    
    # ================= LANCER L'ANALYSE =================
    
    observeEvent(input$go, {
      
      # Filtrage des données
      data = bornes %>%
        dplyr::filter(
          if (input$region != "Toutes")
            region == input$region
          else TRUE,
          
          if (input$dep != "Tous")
            dep == input$dep
          else TRUE,
          
          puissance_nominale >= input$puissance,
          
          if (input$prise != "Tous")
            type_prise == input$prise
          else TRUE
        ) %>%
        
        # Conserver les coordonnées valides
        dplyr::filter(
          is.finite(longitude),
          is.finite(latitude),
          is.finite(puissance_nominale),
          
          longitude >= -180,
          longitude <= 180,
          
          latitude >= -90,
          latitude <= 90
        ) %>%
        
        # Limitation du nombre de points
        dplyr::slice_head(n = 140000)
      
      
      # ================= NETTOYAGE DE LA CARTE =================
      
      proxy = leafletProxy(
        "kdeMap",
        session = session
      ) %>%
        clearMarkers() %>%
        clearControls() %>%
        clearHeatmap()
      
      
      # ================= AUCUNE DONNEE =================
      
      if (nrow(data) == 0) {
        
        showNotification(
          "Aucune borne ne correspond aux filtres sélectionnés.",
          type = "warning",
          duration = 5
        )
        
        return()
      }
      
      
      # ================= CARTE DE CHALEUR =================
      
      proxy %>%
        
        addHeatmap(
          data = data,
          
          lng = ~longitude,
          lat = ~latitude,
          
          intensity = ~puissance_nominale,
          
          radius = 20,
          blur = 30,
          max = 1
        ) %>%
        
        # ================= MARQUEURS =================
      
      addCircleMarkers(
        data = data,
        
        lng = ~longitude,
        lat = ~latitude,
        
        radius = 2,
        stroke = FALSE,
        fillOpacity = 0.6,
        
        label = ~paste0(
          "Puissance : ",
          puissance_nominale,
          " kW"
        )
      )
      
    })
    
  })
}
