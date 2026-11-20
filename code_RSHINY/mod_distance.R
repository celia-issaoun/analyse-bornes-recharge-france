
# ============================================================
# MODULE DISTANCE
# Analyse des distances entre les bornes de recharge
# et les points d'intérêt OpenStreetMap
# ============================================================


# ============================================================
# 1. INTERFACE UTILISATEUR
# ============================================================

mod_distance_ui = function(id) {
  
  ns = NS(id)
  
  tagList(
    
    sidebarLayout(
      
      sidebarPanel(
        
        selectizeInput(
          ns("commune"),
          "Commune (code INSEE) :",
          choices = NULL,
          multiple = FALSE
        ),
        
        selectInput(
          ns("poi_type"),
          "Type de Point d'intérêt :",
          choices = c(
            "Parcs" = "leisure=park",
            "Restaurants" = "amenity=restaurant",
            "Hôpitaux" = "amenity=hospital",
            "Centres commerciaux" = "shop=mall",
            "Autoroutes" = "highway=motorway"
          )
        ),
        
        tags$div(
          
          style = "margin-bottom: 20px;",
          
          actionButton(
            ns("charger"),
            "Charger les données",
            class = "btn btn-primary",
            style = "margin-right: 10px;"
          ),
          
          actionButton(
            ns("calculer"),
            "Calculer les distances",
            class = "btn btn-success",
            style = "margin-right: 10px;"
          ),
          
          actionButton(
            ns("tout_afficher"),
            "Carte et distance",
            class = "btn btn-warning"
          )
        )
      ),
      
      mainPanel(
        
        uiOutput(
          ns("contenu_dynamique")
        )
      )
    )
  )
}


# ============================================================
# 2. SERVEUR
# ============================================================

mod_distance = function(id, bornes) {
  
  moduleServer(id, function(input, output, session) {
    
    # ========================================================
    # 2.1 VARIABLES REACTIVES
    # ========================================================
    
    mode_affichage = reactiveVal("carte")
    
    pois = reactiveVal(NULL)
    
    # Clé permettant de vérifier que les POI correspondent
    # à la commune et au type sélectionnés.
    cle_pois = reactiveVal(NULL)
    
    
    # ========================================================
    # 2.2 INITIALISATION DES COMMUNES
    # ========================================================
    
    observe({
      
      communes = sort(unique(
        as.character(bornes$code_insee)
      ))
      
      communes = communes[
        !is.na(communes) & nzchar(communes)
      ]
      
      updateSelectizeInput(
        session = session,
        inputId = "commune",
        choices = communes,
        selected = if (length(communes) > 0) {
          communes[1]
        } else {
          character(0)
        },
        server = TRUE
      )
      
    })
    
    
    # ========================================================
    # 2.3 PREPARATION DES BORNES SELECTIONNEES
    # ========================================================
    
    bornes_selection = reactive({
      
      req(input$commune)
      
      df = bornes %>%
        
        dplyr::filter(
          as.character(code_insee) == input$commune
        ) %>%
        
        dplyr::mutate(
          
          longitude = suppressWarnings(
            as.numeric(
              gsub(",", ".", as.character(longitude))
            )
          ),
          
          latitude = suppressWarnings(
            as.numeric(
              gsub(",", ".", as.character(latitude))
            )
          )
        ) %>%
        
        dplyr::filter(
          is.finite(longitude),
          is.finite(latitude),
          
          longitude >= -180,
          longitude <= 180,
          
          latitude >= -90,
          latitude <= 90
        )
      
      validate(
        need(
          nrow(df) > 0,
          "Aucune borne avec des coordonnées valides pour cette commune."
        )
      )
      
      sf::st_as_sf(
        df,
        coords = c("longitude", "latitude"),
        crs = 4326
      )
      
    })
    
    
    # ========================================================
    # 2.4 REINITIALISATION SI LES FILTRES CHANGENT
    # ========================================================
    
    observeEvent(
      list(input$commune, input$poi_type),
      {
        
        pois(NULL)
        cle_pois(NULL)
        
        mode_affichage("carte")
        
      },
      ignoreInit = TRUE
    )
    
    
    # ========================================================
    # 2.5 CHARGEMENT DES POINTS D'INTERET
    # ========================================================
    
    observeEvent(input$charger, {
      
      req(input$commune, input$poi_type)
      
      bornes_sf = bornes_selection()
      
      pois(NULL)
      cle_pois(NULL)
      
      # Séparer la clé et la valeur OSM
      key_value = strsplit(
        input$poi_type,
        "=",
        fixed = TRUE
      )[[1]]
      
      if (length(key_value) != 2) {
        
        showNotification(
          "Type de point d'intérêt invalide.",
          type = "error"
        )
        
        return()
      }
      
      
      # ======================================================
      # DEFINITION DE LA ZONE DE RECHERCHE
      # ======================================================
      
      # Zone de 10 km autour des bornes sélectionnées
      zone = bornes_sf %>%
        
        sf::st_transform(2154) %>%
        
        sf::st_union() %>%
        
        sf::st_buffer(10000) %>%
        
        sf::st_transform(4326)
      
      bbox = sf::st_bbox(zone)
      
      
      # ======================================================
      # REQUETE OPENSTREETMAP
      # ======================================================
      
      showNotification(
        "Chargement des points d'intérêt OpenStreetMap...",
        type = "message",
        duration = 5
      )
      
      donnees = tryCatch({
        
        requete = osmdata::opq(
          bbox = bbox,
          timeout = 120
        ) %>%
          
          osmdata::add_osm_feature(
            key = key_value[1],
            value = key_value[2]
          )
        
        osmdata::osmdata_sf(requete)
        
      }, error = function(e) {
        
        showNotification(
          paste(
            "Erreur de connexion à OpenStreetMap :",
            conditionMessage(e)
          ),
          type = "error",
          duration = 10
        )
        
        NULL
        
      })
      
      
      # Arrêter uniquement ce traitement si Overpass échoue
      if (is.null(donnees)) {
        
        pois(NULL)
        
        return()
      }
      
      
      # ======================================================
      # PREPARATION DES GEOMETRIES
      # ======================================================
      
      geometries = NULL
      
      
      # Cas des autoroutes
      if (key_value[1] == "highway") {
        
        lignes = donnees$osm_lines
        
        if (!is.null(lignes) && nrow(lignes) > 0) {
          
          # Représentation ponctuelle des lignes
          coords = lapply(
            sf::st_geometry(lignes),
            function(g) {
              
              coord = sf::st_coordinates(g)
              
              sf::st_point(
                as.numeric(coord[1, c("X", "Y")])
              )
            }
          )
          
          geometries = sf::st_sf(
            geometry = sf::st_sfc(
              coords,
              crs = 4326
            )
          )
        }
        
      } else {
        
        # Récupération des points OSM
        points = donnees$osm_points
        
        # Récupération des polygones OSM
        polygones = donnees$osm_polygons
        
        multipolygones = donnees$osm_multipolygons
        
        liste_pois = list()
        
        
        if (!is.null(points) && nrow(points) > 0) {
          
          liste_pois[[length(liste_pois) + 1]] =
            points %>%
            dplyr::select(
              dplyr::any_of("name"),
              geometry
            )
          
        }
        
        
        if (!is.null(polygones) && nrow(polygones) > 0) {
          
          poly_points = suppressWarnings(
            sf::st_point_on_surface(polygones)
          )
          
          liste_pois[[length(liste_pois) + 1]] =
            poly_points %>%
            dplyr::select(
              dplyr::any_of("name"),
              geometry
            )
        }
        
        
        if (!is.null(multipolygones) &&
            nrow(multipolygones) > 0) {
          
          multi_points = suppressWarnings(
            sf::st_point_on_surface(multipolygones)
          )
          
          liste_pois[[length(liste_pois) + 1]] =
            multi_points %>%
            dplyr::select(
              dplyr::any_of("name"),
              geometry
            )
        }
        
        
        # Fusion des points d'intérêt
        if (length(liste_pois) > 0) {
          
          liste_pois = lapply(
            liste_pois,
            function(x) {
              
              if (!"name" %in% names(x)) {
                x$name = NA_character_
              }
              
              x %>%
                dplyr::select(name, geometry)
            }
          )
          
          geometries = dplyr::bind_rows(liste_pois)
          
          # Supprimer uniquement les géométries identiques
          geometries$coord_x =
            sf::st_coordinates(geometries)[, 1]
          
          geometries$coord_y =
            sf::st_coordinates(geometries)[, 2]
          
          geometries = geometries %>%
            dplyr::distinct(
              coord_x,
              coord_y,
              .keep_all = TRUE
            ) %>%
            dplyr::select(
              -coord_x,
              -coord_y
            )
        }
      }
      
      
      # ======================================================
      # VERIFICATION DES POINTS D'INTERET
      # ======================================================
      
      if (is.null(geometries) ||
          nrow(geometries) == 0) {
        
        pois(NULL)
        
        showNotification(
          "Aucun point d'intérêt trouvé pour cette sélection.",
          type = "warning",
          duration = 6
        )
        
        return()
      }
      
      
      # Harmoniser le système de coordonnées
      geometries = sf::st_transform(
        geometries,
        4326
      )
      
      # Conserver uniquement les POI dans la zone étudiée
      dans_zone = lengths(
        sf::st_intersects(geometries, zone)
      ) > 0
      
      geometries = geometries[dans_zone, ]
      
      
      if (nrow(geometries) == 0) {
        
        showNotification(
          "Aucun point d'intérêt dans la zone de recherche.",
          type = "warning"
        )
        
        return()
      }
      
      
      # Enregistrement des résultats
      pois(geometries)
      
      cle_pois(
        paste(input$commune, input$poi_type, sep = "|")
      )
      
      mode_affichage("carte")
      
      showNotification(
        paste(
          nrow(geometries),
          "points d'intérêt chargés avec succès."
        ),
        type = "message",
        duration = 5
      )
      
    })
    
    
    # ========================================================
    # 2.6 VALIDATION DES DONNEES CHARGEES
    # ========================================================
    
    pois_valides = reactive({
      
      req(input$commune, input$poi_type)
      
      cle_attendue = paste(
        input$commune,
        input$poi_type,
        sep = "|"
      )
      
      req(
        !is.null(cle_pois()),
        identical(cle_pois(), cle_attendue),
        pois()
      )
      
      pois()
    })
    
    
    # ========================================================
    # 2.7 CALCUL DES DISTANCES
    # ========================================================
    
    distances = reactive({
      
      bornes_sf = bornes_selection()
      
      points_sf = pois_valides()
      
      req(nrow(points_sf) > 0)
      
      # Projection métrique Lambert-93
      bornes_proj = sf::st_transform(
        bornes_sf,
        2154
      )
      
      pois_proj = sf::st_transform(
        points_sf,
        2154
      )
      
      
      # Matrice des distances en mètres
      dist_mat = sf::st_distance(
        bornes_proj,
        pois_proj
      )
      
      
      # Distance minimale pour chaque borne
      min_dist_m = apply(
        dist_mat,
        1,
        min
      )
      
      min_dist_km_num =
        as.numeric(
          units::set_units(
            min_dist_m,
            "km"
          )
        )
      
      
      # Estimation théorique à 50 km/h
      temps_min = round(
        (min_dist_km_num / 50) * 60,
        1
      )
      
      
      # Coordonnées des bornes
      coord = sf::st_coordinates(
        bornes_sf
      )
      
      
      # Tableau de résultats
      df = bornes_sf %>%
        
        sf::st_drop_geometry() %>%
        
        dplyr::mutate(
          
          Distance_km = round(
            min_dist_km_num,
            2
          ),
          
          Temps_min = temps_min,
          
          lon = round(
            coord[, 1],
            4
          ),
          
          lat = round(
            coord[, 2],
            4
          )
        ) %>%
        
        dplyr::distinct(
          lon,
          lat,
          .keep_all = TRUE
        ) %>%
        
        dplyr::filter(
          Distance_km <= 10
        ) %>%
        
        dplyr::mutate(
          Adresse = adresse_station,
          `Nb bornes` = nbre_pdc
        ) %>%
        
        dplyr::select(
          Nom = nom_station,
          Adresse,
          `Nb bornes`,
          Distance_km,
          `Temps théorique (min)` = Temps_min
        )
      
      df
    })
    
    
    # ========================================================
    # 2.8 BOUTON CALCULER LES DISTANCES
    # ========================================================
    
    observeEvent(input$calculer, {
      
      req(pois_valides())
      
      mode_affichage("table")
      
    })
    
    
    # ========================================================
    # 2.9 BOUTON CARTE ET DISTANCE
    # ========================================================
    
    observeEvent(input$tout_afficher, {
      
      req(
        bornes_selection(),
        pois_valides()
      )
      
      mode_affichage("tous")
      
    })
    
    
    # ========================================================
    # 2.10 TABLEAU DES RESULTATS
    # ========================================================
    
    output$resultats = renderTable({
      
      req(pois_valides())
      
      distances()
      
    })
    
    
    # ========================================================
    # 2.11 CARTE OPENSTREETMAP
    # ========================================================
    
    output$carte = renderLeaflet({
      
      bornes_sf = bornes_selection()
      
      points_sf = pois_valides()
      
      leaflet() %>%
        
        addTiles() %>%
        
        addCircleMarkers(
          data = bornes_sf,
          color = "blue",
          radius = 5,
          fillOpacity = 0.8,
          label = ~nom_station
        ) %>%
        
        addCircleMarkers(
          data = points_sf,
          color = "red",
          radius = 4,
          fillOpacity = 0.8
        ) %>%
        
        fitBounds(
          lng1 = sf::st_bbox(bornes_sf)[["xmin"]],
          lat1 = sf::st_bbox(bornes_sf)[["ymin"]],
          lng2 = sf::st_bbox(bornes_sf)[["xmax"]],
          lat2 = sf::st_bbox(bornes_sf)[["ymax"]]
        )
      
    })
    
    
    # ========================================================
    # 2.12 AFFICHAGE DYNAMIQUE
    # ========================================================
    
    output$contenu_dynamique = renderUI({
      
      if (mode_affichage() == "carte") {
        
        leafletOutput(
          session$ns("carte"),
          height = 500
        )
        
      } else if (mode_affichage() == "table") {
        
        div(
          style = "margin-top:20px;",
          tableOutput(
            session$ns("resultats")
          )
        )
        
      } else if (mode_affichage() == "tous") {
        
        tagList(
          
          leafletOutput(
            session$ns("carte"),
            height = 350
          ),
          
          div(
            style = "margin-top:20px;",
            tableOutput(
              session$ns("resultats")
            )
          )
        )
      }
      
    })
    
  })
}
