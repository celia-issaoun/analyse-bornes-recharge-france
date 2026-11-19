
# Charger le package
library(rsconnect)

# Chemin de ton application
chemin_app <- "C:/Users/Dell/Desktop/mon_app_shinyl"

# Déployer l'application sur ton compte
rsconnect::deployApp(
  appDir = chemin_app,
  appName = "bornes_de_recharge",
  account = "celiaissaoun",
  server = "shinyapps.io",
  launch.browser = TRUE,
  logLevel = "verbose"
)

