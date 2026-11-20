# ---- mod_couverture_densite.R ----

mod_couverture_densite_ui <- function(id) {
  ns <- NS(id)
  
  navlistPanel(
    widths = c(3, 9),
    
    tabPanel("Matrice de chaleur",
             h4("Croisement des niveaux de couverture par habitant et par véhicule"),
             plotOutput(ns("heatmap_croisement"), height = "450px")
    ),
    
    tabPanel("Tableau des communes à faible couverture",
             h4("Top 10 % des communes les moins bien couvertes"),
             DT::dataTableOutput(ns("table_moins_couvertes"))
    ),
    
    tabPanel("Données complètes",
             h4("Tableau de couverture des bornes électriques"),
             DT::dataTableOutput(ns("table_couverture"))
    )
  )
}

mod_couverture_densite <- function(id, bornes, vehicules, densite) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    vehicules <- vehicules %>%
      dplyr::rename(code_insee = CODGEO, nb_vehicules = NB_VP_RECHARGEABLES_EL) %>%
      dplyr::mutate(code_insee = stringr::str_trim(code_insee),
                    nb_vehicules = as.numeric(nb_vehicules))
    
    densite <- densite %>%
      dplyr::rename(code_insee = codgeo, densite_pop = dens_pop) %>%
      dplyr::mutate(code_insee = stringr::str_trim(code_insee),
                    densite_pop = as.numeric(densite_pop)) %>%
      dplyr::distinct(code_insee, .keep_all = TRUE)
    
    bornes <- bornes %>%
      dplyr::mutate(code_insee = stringr::str_trim(code_insee))
    
    bornes_commune <- bornes %>%
      dplyr::group_by(code_insee) %>%
      dplyr::summarise(nb_bornes = dplyr::n(), .groups = "drop")
    
    couverture <- bornes_commune %>%
      dplyr::inner_join(vehicules, by = "code_insee") %>%
      dplyr::inner_join(densite, by = "code_insee") %>%
      dplyr::transmute(
        code_insee,
        vehicules_par_borne = nb_vehicules / nb_bornes,
        bornes_par_habitant = nb_bornes / (densite_pop * 15),
        couverture_cat = dplyr::case_when(
          vehicules_par_borne <= 2  ~ "Très bien",
          vehicules_par_borne <= 5  ~ "Correct",
          vehicules_par_borne <= 10 ~ "Faible",
          TRUE                      ~ "Très faible"
        ),
        cat_habitant = dplyr::case_when(
          bornes_par_habitant >= 0.01  ~ "Très bien",
          bornes_par_habitant >= 0.005 ~ "Correct",
          bornes_par_habitant >= 0.001 ~ "Faible",
          TRUE                         ~ "Très faible"
        )
      ) %>%
      dplyr::filter(is.finite(vehicules_par_borne), is.finite(bornes_par_habitant)) %>%
      dplyr::mutate(
        couverture_cat = factor(couverture_cat, levels = c("Très faible", "Faible", "Correct", "Très bien")),
        cat_habitant   = factor(cat_habitant, levels = c("Très faible", "Faible", "Correct", "Très bien"))
      )
    
    # Matrice de chaleur (Heatmap)
    output$heatmap_croisement <- renderPlot({
      couverture %>%
        dplyr::count(couverture_cat, cat_habitant) %>%
        ggplot2::ggplot(ggplot2::aes(x = couverture_cat, y = cat_habitant, fill = n)) +
        ggplot2::geom_tile(color = "white") +
        ggplot2::geom_text(ggplot2::aes(label = n), color = "black", size = 5) +
        ggplot2::scale_fill_gradient(low = "white", high = "darkblue") +
        ggplot2::labs(x = "Couverture par véhicule", y = "Couverture par habitant", fill = "Communes") +
        ggplot2::theme_minimal()
    })
    
    # Communes les moins bien couvertes (Top 10%)
    output$table_moins_couvertes <- DT::renderDataTable({
      nb_communes <- nrow(couverture)
      top10 <- couverture %>%
        dplyr::arrange(desc(vehicules_par_borne)) %>%
        dplyr::slice_head(n = round(0.10 * nb_communes)) %>%
        dplyr::select(code_insee, vehicules_par_borne, bornes_par_habitant, couverture_cat, cat_habitant)
      
      DT::datatable(top10,
                    options = list(pageLength = 10, scrollX = TRUE),
                    rownames = FALSE,
                    filter = "top",
                    class = "compact")
    })
    
    # Tableau complet
    output$table_couverture <- DT::renderDataTable({
      DT::datatable(
        couverture %>% dplyr::select(code_insee, vehicules_par_borne, bornes_par_habitant, couverture_cat, cat_habitant),
        extensions = "Buttons",
        options = list(
          dom = "Bfrtip",
          buttons = c("csv", "excel", "pdf"),
          pageLength = 10,
          scrollX = TRUE
        ),
        class = "stripe hover row-border nowrap",
        filter = "top",
        rownames = FALSE
      )
    })
  })
}

