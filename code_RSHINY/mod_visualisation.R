mod_visualisation_ui = function(id) {
  ns = NS(id)
  tabsetPanel(
    tabPanel("Bornes",
             tabsetPanel(
               tabPanel("Carte",
                        sidebarLayout(
                          sidebarPanel(
                            selectInput(ns("condition_acces_sel"), "Condition d'accès :", choices = NULL, multiple = TRUE),
                            selectInput(ns("type_prise_sel"), "Type de prise :", choices = NULL, multiple = TRUE),
                            selectInput(ns("puissance_cat_sel"), "Puissance :", choices = NULL, multiple = TRUE),
                            selectInput(ns("paiement_sel"), "Mode de paiement :", choices = NULL, multiple = TRUE),
                            selectizeInput(ns("communes_bornes"), "Communes (code INSEE) :", choices = NULL, multiple = TRUE)
                          ),
                          mainPanel(
                            leafletOutput(ns("map_bornes"), height = 550)
                          ))),
               
               tabPanel("Visualisation des puissances",
                        fluidRow(
                          column(6,
                                 div(class = "card-style",
                                     div(class = "card-title", HTML("")),
                                     echarts4rOutput(ns("puissance_barplot"), height = "300px")
                                 )),
                          column(6,
                                 div(class = "card-style",
                                     div(class = "card-title", HTML("")),
                                     highchartOutput(ns("puissance_pie"), height = "300px")
                                 ))))
             )),
    
    tabPanel("Véhicules",
             sidebarLayout(
               sidebarPanel(
                 radioButtons(
                   ns("vehicules_tab_choice"), "Méthode de visualisation :",
                   choices = c(
                     "diagramme à barres (Barplot)"                = "bar",
                     "Camembert (Pie Chart)"  = "pie",
                     "Nuage de points(scatter)"        = "scatter",
                     "Boîte à moustaches(Boxplot)"          = "boxplot"
                   ),
                   selected = "bar"
                 ),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'bar'", ns("vehicules_tab_choice")),
                   selectizeInput(ns("vehicules_communes"), "Choisir des communes :", choices = NULL, multiple = TRUE)
                 ),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'pie'", ns("vehicules_tab_choice")),
                   sliderInput(ns("vehicules_top_n"), "Nombre de communes dans le camembert :", min = 3, max = 20, value = 5))
               ),
               mainPanel(
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'bar'", ns("vehicules_tab_choice")),
                   h4("Véhicules électriques par commune", style = "color:#1abc9c;font-weight:bold"),
                   downloadButton(ns("dl_vehicules_barplot"), "Télécharger le barplot", class = "btn-primary btn-sm"),
                   echarts4rOutput(ns("vehicules_barplot"), height = "400px")
                 ),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'pie'", ns("vehicules_tab_choice")),
                   h4("Répartition des VE", style = "color:#e67e22;font-weight:bold"),
                   downloadButton(ns("dl_vehicules_piechart"), "Télécharger le piechart", class = "btn-primary btn-sm"),
                   highchartOutput(ns("vehicules_piechart3D"), height = "500px")
                 ),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'scatter'", ns("vehicules_tab_choice")),
                   h4("Nuage de points VE vs code commune", style = "color:#8e44ad;font-weight:bold"),
                   downloadButton(ns("dl_vehicules_scatter"), "Télécharger le scatter", class = "btn-primary btn-sm"),
                   echarts4rOutput(ns("vehicules_scatter"), height = "400px")
                 ),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'boxplot'", ns("vehicules_tab_choice")),
                   h4("Distribution log(VE) par commune", style = "color:#2c3e50;font-weight:bold"),
                   downloadButton(ns("dl_vehicules_boxplot"), "Télécharger le boxplot", class = "btn-primary btn-sm"),
                   plotlyOutput(ns("vehicules_boxplot"), height = "400px"))
               ))),
    
    tabPanel("Densité",
             sidebarLayout(
               sidebarPanel(
                 radioButtons(ns("densite_tab_choice"), "Méthode de visualisation :", 
                              choices = c(
                                "diagramme à barres (Barplot)"               = "bar",
                                "Camembert (Pie Chart)" = "pie",
                                "Nuage de points (scatter)"       = "scatter",
                                "Boîte à moustaches (Boxplot)"         = "boxplot"
                              ),
                              selected = "bar"),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'bar'", ns("densite_tab_choice")),
                   selectizeInput(ns("densite_communes"), "Choisir des communes :", choices = NULL, multiple = TRUE)
                 ),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'pie'", ns("densite_tab_choice")),
                   sliderInput(ns("densite_top_n"), "Nombre de communes dans le camembert :", min = 3, max = 20, value = 5))
               ),
               mainPanel(
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'bar'", ns("densite_tab_choice")),
                   h4("Densité de population par commune", style = "color:#2980b9; font-weight:bold"),
                   downloadButton(ns("dl_densite_barplot"), "Télécharger le barplot", class = "btn-primary btn-sm"),
                   echarts4rOutput(ns("densite_barplot"), height = "400px")
                 ),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'pie'", ns("densite_tab_choice")),
                   h4("Répartition densité", style = "color:#d35400; font-weight:bold"),
                   downloadButton(ns("dl_densite_piechart"), "Télécharger le piechart", class = "btn-primary btn-sm"),
                   highchartOutput(ns("densite_piechart3D"), height = "500px")
                 ),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'scatter'", ns("densite_tab_choice")),
                   h4("Nuage de points densité vs code commune", style = "color:#8e44ad; font-weight:bold"),
                   downloadButton(ns("dl_densite_scatter"), "Télécharger le scatter", class = "btn-primary btn-sm"),
                   echarts4rOutput(ns("densite_scatter"), height = "400px")
                 ),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'boxplot'", ns("densite_tab_choice")),
                   h4("Boxplot de la densité", style = "color:#27ae60; font-weight:bold"),
                   downloadButton(ns("dl_densite_boxplot"), "Télécharger le boxplot", class = "btn-primary btn-sm"),
                   plotlyOutput(ns("densite_boxplot"), height = "400px"))
               ))))}

#_______________________________Serveur_________________________________________
mod_visualisation_server = function(id, bornes, communes_sf, vehicules, densite) {
  moduleServer(id, function(input, output, session) {
    ns = session$ns
    filtered_bornes = reactive({
      b = bornes
      if (!is.null(input$condition_acces_sel)) b <- b %>% filter(condition_acces %in% input$condition_acces_sel)
      if (!is.null(input$type_prise_sel)) b <- b %>% filter(type_prise %in% input$type_prise_sel)
      if (!is.null(input$puissance_cat_sel)) b <- b %>% filter(puissance_cat %in% input$puissance_cat_sel)
      if (!is.null(input$paiement_sel)) b <- b %>% filter(paiement %in% input$paiement_sel)
      if (!is.null(input$communes_bornes)) b <- b %>% filter(code_insee %in% input$communes_bornes)
      b
    })
    
    
    #_________________________________bornes________________________________________
    output$map_bornes = renderLeaflet({
      
      leaflet(data = filtered_bornes()) %>%
        
        # Fond de carte OpenStreetMap
        addTiles() %>%
        
        # Affichage initial centré sur la France
        setView(
          lng = 2.35,
          lat = 46.60,
          zoom = 6
        ) %>%
        
        # Affichage des bornes de recharge
        addMarkers(
          lng = ~as.numeric(gsub(",", ".", longitude)),
          lat = ~as.numeric(gsub(",", ".", latitude)),
          
          popup = ~paste0(
            "<strong>Station :</strong> ", nom_station, "<br>",
            "<strong>Adresse :</strong> ", adresse_station, "<br>",
            "<strong>Puissance :</strong> ", puissance_nominale, " kW<br>",
            "<strong>Type de prise :</strong> ", type_prise
          ),
          
          # Regroupement automatique des bornes
          clusterOptions = markerClusterOptions()
        )
    })
    
    
  
    # ___________________Données classées pour barplot et camembert_________________
    bornes_classes = reactive({
      bornes %>%
        mutate(puissance_nominale = as.numeric(puissance_nominale)) %>%
        filter(!is.na(puissance_nominale)) %>%
        mutate(classe = cut(
          puissance_nominale,
          breaks = c(0, 22, 50, 100, 150, 350),
          labels = c("≤22 kW", "23–50 kW", "51–100 kW", "101–150 kW", ">150 kW"),
          right = TRUE, include.lowest = TRUE
        )) %>%
        count(classe) %>%
        arrange(classe)
    })
    
    # ______________________________Camembert_______________________________________
    output$puissance_pie = renderHighchart({
      df_puiss = bornes_classes() %>%
        mutate(label = sprintf("%s: %d", classe, n)) %>%
        arrange(desc(n))
      hchart(
        df_puiss,
        "pie",
        hcaes(name = classe, y = n)
      ) %>%
        hc_chart(
          type = "pie",
          options3d = list(
            enabled = TRUE,
            alpha = 45,
            beta = 0,
            depth = 70)
        ) %>%
        hc_plotOptions(
          pie = list(
            depth = 50,
            innerSize = 0,
            dataLabels = list(
              enabled = TRUE,
              format = "{point.name}: {point.percentage:.1f} %",
              distance = 30,
              style = list(fontSize = "13px", fontWeight = "bold", color = "#2c3e50")
            ))
        ) %>%
        hc_colors(RColorBrewer::brewer.pal(8, "Set2")) %>%
        hc_title(
          text = "Répartition des bornes par classe de puissance",
          style = list(color = "#2980b9", fontSize = "18px", fontWeight = "bold")
        ) %>%
        hc_legend(
          align = "center",
          layout = "horizontal",
          verticalAlign = "bottom",
          itemStyle = list(color = "black", fontSize = "14px", fontWeight = "bold")
        ) %>%
        hc_tooltip(
          pointFormat = "<b>{point.y}</b> bornes ({point.percentage:.1f} %)"
        ) %>%
        hc_exporting(
          enabled = TRUE,
          filename = "camembert_puissance",
          buttons = list(
            contextButton = list(
              onclick = JS("function () { this.exportChartLocal({ type: 'image/png' }); }"),
              symbol = "download",
              text = NULL,     
              menuItems = NULL
            )))
    })
    
    #_________________________barplot_______________________________________________
    output$puissance_barplot = renderEcharts4r({
      df = bornes_classes()
      df %>%
        e_charts(classe) %>%
        e_bar(n, name = "") %>%
        e_title("Nombre de bornes par classe de puissance") %>%
        e_tooltip(trigger = "axis") %>%
        e_x_axis(name = "Classe de puissance") %>%
        e_y_axis(name = "Nombre de bornes") %>%
        e_theme("infographic") %>%
        e_toolbox(feature = list(saveAsImage = list(show = TRUE)))  
    })
    
    #__________________________vehicule_____________________________________________
    
    vehicules_clean = reactive({
      vehicules %>%
        mutate(CODGEO = str_pad(as.character(CODGEO), 5, pad = "0"),
               LIBGEO = as.character(LIBGEO))
    })
    
    #_________________________barplot_______________________________________________    
    output$vehicules_barplot = renderEcharts4r({
      data = vehicules_clean()
      if (!is.null(input$vehicules_communes)) {
        data <- data %>% filter(LIBGEO %in% input$vehicules_communes)
      }
      data %>%
        arrange(desc(NB_VP_RECHARGEABLES_EL)) %>%
        e_charts(LIBGEO) %>%
        e_bar(NB_VP_RECHARGEABLES_EL, name = "Nombre de VE", 
              itemStyle = list(
                color = htmlwidgets::JS(
                  "function(params) {
                 const colors = ['#1abc9c', '#3498db', '#9b59b6', '#f39c12', '#e74c3c'];
                 return colors[params.dataIndex % colors.length];
               }"
                )
              )) %>%
        e_flip_coords() %>%
        e_labels(show = TRUE, position = "right", color = "#000") %>%
        e_tooltip(trigger = "axis") %>%
        e_title("Nombre de véhicules électriques par commune") %>%
        e_axis_labels(x = "NB véhicules", y = "Communes") %>%
        e_legend(show = FALSE) %>%
        e_theme("macarons") %>%
        e_animation(duration = 1000)
    })
    
    #________________________piechart_______________________________________________    
    output$vehicules_piechart3D = renderHighchart({
      vehicules_clean() %>%                                   
        arrange(desc(NB_VP_RECHARGEABLES_EL)) %>%             
        slice_head(n = input$vehicules_top_n) %>%             
        mutate(
          label = sprintf("%s: %s", LIBGEO, NB_VP_RECHARGEABLES_EL)
        ) -> df_pie
      hchart(
        df_pie,
        "pie",
        hcaes(
          name = LIBGEO,
          y    = NB_VP_RECHARGEABLES_EL)
      ) %>%
        hc_chart(
          type      = "pie",
          options3d = list(
            enabled = TRUE,
            alpha   = 45,   
            beta    = 0,    
            depth   = 70    
          )
        ) %>%
        hc_plotOptions(
          pie = list(
            depth      = 50,
            innerSize  = 0,
            dataLabels = list(
              enabled  = TRUE,
              format   = "{point.name}: {point.percentage:.1f} %",
              distance = 30,
              style    = list(fontSize = "13px", fontWeight = "bold")
            )
          )
        ) %>%
        hc_colors(RColorBrewer::brewer.pal(8, "Set3")) %>%
        hc_title(
          text = paste0("Répartition des véhicules électriques : Top ", input$vehicules_top_n, " communes"),
          style = list(
            color = "white",             # couleur du texte
            fontSize = "18px",           # taille optionnelle
            fontWeight = "bold"          # poids optionnel
          )) %>%
        
        hc_legend(
          align         = "center",
          layout        = "horizontal",
          verticalAlign = "bottom"
        ) %>%
        hc_tooltip(
          pointFormat = "<b>{point.y}</b> véhicules ({point.percentage:.1f} %)"
        )
    })
    output$dl_vehicules_piechart = downloadHandler(
      filename = function() "vehicules_piechart.png",
      content = function(file) {
        df_pie <- vehicules_clean() %>%
          arrange(desc(NB_VP_RECHARGEABLES_EL)) %>%
          slice_head(n = input$vehicules_top_n) %>%
          mutate(label = sprintf("%s: %s", LIBGEO, NB_VP_RECHARGEABLES_EL))
        
        hc <- highchart() %>%
          hc_chart(type = "pie", options3d = list(enabled = TRUE, alpha = 45, beta = 0, depth = 70)) %>%
          hc_plotOptions(
            pie = list(
              depth = 50,
              innerSize = 0,
              dataLabels = list(
                enabled = TRUE,
                format = "{point.name}: {point.percentage:.1f} %",
                distance = 30,
                style = list(fontSize = "13px", fontWeight = "bold")
              )
            )
          ) %>%
          hc_add_series_list(
            list_parse2(df_pie %>% transmute(name = LIBGEO, y = NB_VP_RECHARGEABLES_EL))
          ) %>%
          hc_colors(RColorBrewer::brewer.pal(8, "Set3")) %>%
          hc_title(
            text = paste0("Répartition des véhicules électriques : Top ", input$vehicules_top_n, " communes"),
            style = list(color = "white", fontSize = "18px", fontWeight = "bold")
          ) %>%
          hc_exporting(enabled = TRUE)
        
        tmp_html <- tempfile(fileext = ".html")
        saveWidget(hc, tmp_html, selfcontained = TRUE)
        webshot2::webshot(tmp_html, file = file, vwidth = 900, vheight = 600)
      })
    
    #_____________________________________scatter___________________________________      
    output$vehicules_scatter = renderEcharts4r({
      vehicules_clean() %>%
        e_charts(CODGEO) %>%              
        e_scatter(
          NB_VP_RECHARGEABLES_EL,
          symbol_size = 8
        ) %>%
        e_title(
          text = "Véhicule vs code commune",
          left = "center",
          textStyle = list(
            color = "#ffffff",
            fontSize = 18,
            fontWeight = "bold"
          )
        ) %>%
        e_tooltip(trigger = "item") %>%
        e_x_axis(
          name = "Code commune (INSEE)",
          nameLocation = "middle",
          nameGap = 30,
          axisLabel = list(rotate = 45),
          nameTextStyle = list(color = "white")  
        ) %>%
        e_y_axis(
          name = "Nombre de véhicules électriques",
          nameLocation = "middle",
          nameGap = 40,
          nameTextStyle = list(color = "white")  
        )
    })
    output$dl_vehicules_scatter = downloadHandler(
      filename = function() "vehicules_scatter.png",
      content  = function(file) {
        png(file, width = 900, height = 600)
        chart = vehicules_clean() %>%
          e_charts(CODGEO) %>%
          e_scatter(NB_VP_RECHARGEABLES_EL, symbol_size = 8)
        print(chart)
        dev.off()
      }
    )
    
    #_____________________________boxplot_________________________________________   
    output$vehicules_boxplot = renderPlotly({
      p = vehicules_clean() %>%
        mutate(NB_VP_RECHARGEABLES_EL = as.numeric(NB_VP_RECHARGEABLES_EL)) %>%
        filter(!is.na(NB_VP_RECHARGEABLES_EL)) %>%
        ggplot(aes(x = "", y = log1p(NB_VP_RECHARGEABLES_EL))) +  
        geom_boxplot(fill = "#34495e", alpha = 0.7, outlier.shape = NA) +
        labs(
          title = "Distribution des véhicules électriques",
          y = "log(1 + nombre de VE)",
          x = NULL
        ) +
        theme_minimal(base_size = 14)
      
      ggplotly(p, tooltip = c("y"))
    })
    
    
    output$dl_vehicules_boxplot = downloadHandler(
      filename = function() "vehicules_boxplot.png",
      content = function(file) {
        png(file, width = 900, height = 600)
        plot = vehicules_clean() %>%
          mutate(NB_VP_RECHARGEABLES_EL = as.numeric(NB_VP_RECHARGEABLES_EL)) %>%
          filter(!is.na(NB_VP_RECHARGEABLES_EL)) %>%
          ggplot(aes(x = "", y = log1p(NB_VP_RECHARGEABLES_EL))) +
          geom_boxplot(fill = "#34495e", alpha = 0.7, outlier.shape = NA) +
          labs(
            title = "Distribution des véhicules électriques",
            y = "log(1 + nombre de VE)",
            x = NULL
          ) +
          theme_minimal(base_size = 14)
        print(plot)
        dev.off()
      }
    )
    
    
    #______________________________densite__________________________________________   
    densite_clean = reactive({
      densite %>%
        mutate(codgeo = str_pad(as.character(codgeo), 3, pad = "0"),
               libgeo = as.character(libgeo),
               dens_pop = as.numeric(dens_pop))
    })
    output$densite_barplot = renderEcharts4r({
      data = densite_clean()
      if (!is.null(input$densite_communes)) {
        data <- data %>% filter(libgeo %in% input$densite_communes)
      }
      data %>%
        arrange(desc(dens_pop)) %>%
        e_charts(libgeo) %>%
        e_bar(dens_pop, name = "Densité de population",
              itemStyle = list(
                color = htmlwidgets::JS(
                  "function(params) {
                 const colors = ['#2ecc71', '#3498db', '#e67e22', '#e74c3c', '#9b59b6'];
                 return colors[params.dataIndex % colors.length];
               }"
                )
              )) %>%
        e_flip_coords() %>%
        e_labels(show = TRUE, position = "right", color = "#000") %>%
        e_tooltip(trigger = "axis") %>%
        e_title("Densité de population par commune") %>%
        e_axis_labels(x = "Densité (hab./km²)", y = "Communes") %>%
        e_legend(show = FALSE) %>%
        e_theme("shine") %>%
        e_animation(duration = 1000)
    })
    
    #____________________________Piechart___________________________________________
    output$densite_piechart3D = renderHighchart({
      densite_clean() %>%
        arrange(desc(dens_pop)) %>%
        slice_head(n = input$densite_top_n) %>%
        mutate(
          label = sprintf("%s: %.0f", libgeo, dens_pop)
        ) -> df_dens
      hchart(
        df_dens,
        "pie",
        hcaes(
          name = libgeo,
          y    = dens_pop
        )
      ) %>%
        hc_chart(
          type = "pie",
          options3d = list(
            enabled = TRUE,
            alpha   = 45,
            beta    = 0,
            depth   = 70
          )
        ) %>%
        hc_plotOptions(
          pie = list(
            depth = 50,
            innerSize = 0,
            dataLabels = list(
              enabled  = TRUE,
              format   = "{point.name}: {point.percentage:.1f} %",
              distance = 30,
              style    = list(
                fontSize   = "13px",
                fontWeight = "bold",
                color      = "#2c3e50"
              )
            )
          )
        ) %>%
        hc_colors(RColorBrewer::brewer.pal(8, "Set2")) %>%
        hc_title(
          text = paste0("Répartition de la densité de population : Top ", input$densite_top_n, " communes"),
          align = "center",
          style = list(
            color      = "#2980b9",   # bleu foncé élégant
            fontSize   = "18px",
            fontWeight = "bold"
          )
        ) %>%
        hc_legend(
          align = "center",
          layout = "horizontal",
          verticalAlign = "bottom",
          itemStyle = list(
            color      = "black",
            fontSize   = "14px",
            fontWeight = "bold"
          )
        ) %>%
        hc_tooltip(
          pointFormat = "<b>{point.y}</b> habitants/km² ({point.percentage:.1f} %)"
        )
    })
    output$densite_scatter = renderEcharts4r({
      densite_clean() %>%
        e_charts(codgeo) %>%
        e_scatter(dens_pop, symbol_size = 8) %>%
        e_title("Densité vs code commune") %>%
        e_tooltip()
    })
    
    output$dl_densite_piechart <- downloadHandler(
      filename = function() "densite_piechart.png",
      content = function(file) {
        df_dens <- densite_clean() %>%
          arrange(desc(dens_pop)) %>%
          slice_head(n = input$densite_top_n) %>%
          mutate(label = sprintf("%s: %.0f", libgeo, dens_pop))
        
        hc <- highchart() %>%
          hc_chart(type = "pie", options3d = list(enabled = TRUE, alpha = 45, beta = 0, depth = 70)) %>%
          hc_plotOptions(
            pie = list(
              depth = 50,
              innerSize = 0,
              dataLabels = list(
                enabled = TRUE,
                format = "{point.name}: {point.percentage:.1f} %",
                distance = 30,
                style = list(
                  fontSize = "13px",
                  fontWeight = "bold",
                  color = "#2c3e50"
                )
              )
            )
          ) %>%
          hc_add_series_list(
            list_parse2(df_dens %>% transmute(name = libgeo, y = dens_pop))
          ) %>%
          hc_colors(RColorBrewer::brewer.pal(8, "Set2")) %>%
          hc_title(
            text = paste0("Répartition de la densité de population : Top ", input$densite_top_n, " communes"),
            align = "center",
            style = list(
              color = "#2980b9",
              fontSize = "18px",
              fontWeight = "bold"
            )
          ) %>%
          hc_legend(
            align = "center",
            layout = "horizontal",
            verticalAlign = "bottom",
            itemStyle = list(
              color = "black",
              fontSize = "14px",
              fontWeight = "bold"
            )
          ) %>%
          hc_tooltip(pointFormat = "<b>{point.y}</b> habitants/km² ({point.percentage:.1f} %)")
        
        tmp_html = tempfile(fileext = ".html")
        saveWidget(hc, tmp_html, selfcontained = TRUE)
        webshot2::webshot(tmp_html, file = file, vwidth = 1000, vheight = 600)
      }
    )
    #______________________________boxplot__________________________________________
    output$densite_boxplot = renderPlotly({
      p = densite_clean() %>%
        mutate(dens_pop = as.numeric(dens_pop)) %>%
        ggplot(aes(y = log1p(dens_pop))) +
        geom_boxplot(fill = "#8e44ad", alpha = 0.7) +
        labs(
          title = "Distribution de la densité de population",
          y = "log(1 + densité)"
        ) +
        theme_minimal(base_size = 14)
      
      ggplotly(p, tooltip = c("y")) 
    })
    
    output$dl_densite_boxplot = downloadHandler(
      filename = function() "densite_boxplot.png",
      content = function(file) {
        png(file, width = 900, height = 600)
        plot = densite_clean() %>%
          mutate(dens_pop = as.numeric(dens_pop)) %>%
          ggplot(aes(y = log1p(dens_pop))) +
          geom_boxplot(fill = "#8e44ad", alpha = 0.7) +
          labs(
            title = "Distribution de la densité de population (log)",
            y = "log(1 + densité)"
          ) +
          theme_minimal(base_size = 14)
        print(plot)
        dev.off()
      }
    )
    
    observe({
      updateSelectInput(session, "condition_acces_sel", choices = sort(unique(bornes$condition_acces)))
      updateSelectInput(session, "type_prise_sel", choices = sort(unique(bornes$type_prise)))
      updateSelectInput(session, "puissance_cat_sel", choices = sort(unique(bornes$puissance_cat)))
      updateSelectInput(session, "paiement_sel", choices = sort(unique(bornes$paiement)))
      updateSelectizeInput(session, "communes_bornes", choices = sort(unique(bornes$code_insee)), server = TRUE)
      updateSelectizeInput(session, "vehicules_communes", choices = sort(unique(vehicules$LIBGEO)), server = TRUE)
      updateSelectizeInput(session, "densite_communes", choices = sort(unique(densite$libgeo)), server = TRUE)
    })
    
    #_____________________________barplot___________________________________________
    output$dl_vehicules_barplot = downloadHandler(
      filename = function() "vehicules_barplot.png",
      content = function(file) {
        data = vehicules_clean()
        if (!is.null(input$vehicules_communes)) {
          data <- data %>% filter(LIBGEO %in% input$vehicules_communes)}
        png(file, width = 900, height = 600)
        barplot = data %>%
          arrange(desc(NB_VP_RECHARGEABLES_EL)) %>%
          e_charts(LIBGEO) %>%
          e_bar(NB_VP_RECHARGEABLES_EL) %>%
          e_flip_coords()
        print(barplot)
        dev.off()
      })
    #_______________________________piechart________________________________________
    output$vehicules_piechart = renderEcharts4r({
      vehicules_clean() %>%
        arrange(desc(NB_VP_RECHARGEABLES_EL)) %>%
        slice_head(n = input$vehicules_top_n) %>%
        e_charts(LIBGEO) %>%
        e_pie(
          NB_VP_RECHARGEABLES_EL,
          name = "Véhicules électriques",
          radius = "55%",
          center = list("50%", "38%"),
          label = list(
            show = TRUE,
            formatter = "{b}: {d}%",
            fontSize = 15,
            color = "#2c3e50",
            fontWeight = "bold",
            backgroundColor = "#ecf0f1",
            borderRadius = 5,
            padding = 8),
          labelLine = list(
            show = TRUE,
            length = 30,
            length2 = 20,
            lineStyle = list(width = 1.5)
          )) %>%
        e_title("",
                left = "center",
                textStyle = list(color = "#2980b9", fontSize = 18, fontWeight = "bold")) %>%
        e_legend(
          orient = "horizontal",
          bottom = "2%",
          left = "center",
          textStyle = list(
            color = "white",
            fontSize = 14,
            fontWeight = "bold")) %>%
        e_color(brewer.pal(8, "Set3")) %>%
        e_tooltip(trigger = "item")
    })
    #______________________________barplot__________________________________________   
    output$dl_densite_barplot = downloadHandler(
      filename = function() "densite_barplot.png",
      content = function(file) {
        png(file, width = 900, height = 600)
        data <- densite_clean()
        if (!is.null(input$densite_communes)) {
          data = data %>% filter(libgeo %in% input$densite_communes)
        }
        chart = data %>%
          arrange(desc(dens_pop)) %>%
          e_charts(libgeo) %>%
          e_bar(dens_pop) %>%
          e_flip_coords()
        print(chart)
        dev.off()
      })
    
    #_____________________________scatter___________________________________________    
    output$densite_scatter = renderEcharts4r({
      densite_clean() %>%
        e_charts(codgeo) %>%
        e_scatter(dens_pop, symbol_size = 8) %>%
        e_title(
          text = "Densité vs code commune",
          left = "center",
          textStyle = list(
            color = "#ffffff",        
            fontSize = 18,
            fontWeight = "bold",
            textBorderColor = "#000000",  
            textBorderWidth = 2
          )
        ) %>%
        e_tooltip(trigger = "item") %>%
        e_x_axis(
          name = "Code commune (INSEE)",
          nameLocation = "middle",
          nameGap = 30,
          nameTextStyle = list(
            color = "#ffffff",
            fontWeight = "bold",
            fontSize = 14,
            textBorderColor = "#000000",
            textBorderWidth = 2
          ),
          axisLabel = list(rotate = 45)
        ) %>%
        e_y_axis(
          name = "Densité de population (hab/km²)",
          nameLocation = "middle",
          nameGap = 40,
          nameTextStyle = list(
            color = "#ffffff",
            fontWeight = "bold",
            fontSize = 14,
            textBorderColor = "#000000",
            textBorderWidth = 2
          )
        )
    })
    output$dl_densite_scatter = downloadHandler(
      filename = function() "densite_scatter.png",
      content = function(file) {
        temp_file = tempfile(fileext = ".html")
        densite_clean() %>%
          e_charts(codgeo) %>%
          e_scatter(dens_pop, symbol_size = 8) %>%
          e_title(
            text = "Densité vs code commune",
            left = "center",
            textStyle = list(
              color = "#ffffff",
              fontSize = 18,
              fontWeight = "bold",
              textBorderColor = "#000000",
              textBorderWidth = 2
            )
          ) %>%
          e_tooltip(trigger = "item") %>%
          e_x_axis(
            name = "Code commune (INSEE)",
            nameLocation = "middle",
            nameGap = 30,
            nameTextStyle = list(
              color = "#ffffff",
              fontWeight = "bold",
              fontSize = 14,
              textBorderColor = "#000000",
              textBorderWidth = 2
            ),
            axisLabel = list(rotate = 45)
          ) %>%
          e_y_axis(
            name = "Densité de population (hab/km²)",
            nameLocation = "middle",
            nameGap = 40,
            nameTextStyle = list(
              color = "#ffffff",
              fontWeight = "bold",
              fontSize = 14,
              textBorderColor = "#000000",
              textBorderWidth = 2
            )
          ) %>%
          saveWidget(temp_file, selfcontained = TRUE)
        webshot2::webshot(temp_file, file = file, vwidth = 1000, vheight = 600)
      }
    )
  })  }
