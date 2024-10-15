library(shiny)
library(shinythemes)  # For themes
library(leaflet)
library(leaflet.extras)
library(sf)
library(ggplot2)
library(dbscan)
library(dplyr)
library(bslib)


# Load and prepare the data
data <- read.csv("roadtrafficaccidentlocations.csv", header = TRUE, sep = ",")
data_clean <- data[c(1,6,7,11,12,13,14,19,20,21,24,25,34,35,36)]
accidents <- data_clean[data_clean$AccidentInvolvingBicycle == "true",]
accidents <- accidents[-6]

# Convert to spatial data
accidents_sf_lv95 <- st_as_sf(accidents, coords = c("AccidentLocation_CHLV95_E", "AccidentLocation_CHLV95_N"), crs = 2056)
accidents_sf_wgs84 <- st_transform(accidents_sf_lv95, crs = 4326)


theme1 <- bs_theme(
  bg = "skyblue",
  fg = "black",
  primary = "skyblue",
  base_font = font_google("Space Mono"),
  code_font = font_google("Space Mono")
)

# UI
ui <- fluidPage(
  theme = theme1,  # shinytheme(flatly),
  # Use a professional theme

  # Custom CSS for larger map and better styling
  tags$head(
    tags$style(HTML("
      .leaflet-container { height: 600px !important; }  /* Set a specific height for the map */
      .sidebar { background-color: #f9f9f9; padding: 20px; border-radius: 5px; }
      .title { font-size: 24px; font-weight: bold; color: #2c3e50; }
      .slider-input { margin-bottom: 30px; }
      input[type='range'] { margin: 10px 0; }  /* Style the range slider */
      .footer { text-align: center; font-size: 14px; color: #95a5a6; padding-top: 20px; }
    "))
  ),

  titlePanel("Bicycle Accidents Analysis"),

  sidebarLayout(
    sidebarPanel(
      div(class = "sidebar",
          h4("Customize Your View", class = "title"),

          # Dropdown to select plot type
          selectInput("plot_type", "Select Plot Type",
                      choices = c("Heatmap", "Cluster", "Severity Map")),

          # Slider to select year range
          sliderInput("year_range", "Select Year Range",
                      min = min(accidents$AccidentYear, na.rm = TRUE),
                      max = max(accidents$AccidentYear, na.rm = TRUE),
                      value = c(2021, max(accidents$AccidentYear, na.rm = TRUE)),
                      step = 1, sep = ""),

          # Conditional sliders for DBSCAN clustering parameters
          conditionalPanel(
            condition = "input.plot_type == 'Cluster'",
            sliderInput("epsilon", "Maximum distance for points to be counted together", min = 0.0005, max = 0.005, value = 0.001, step = 0.0001),
            sliderInput("min_pts", "Least number of points needed to define a cluster", min = 5, max = 50, value = 20, step = 1)
          )
      )
    ),

    mainPanel(
      leafletOutput("map", width = "100%", height = "600px")  # Set height explicitly
    )
  ),

  # Footer section
  div(class = "footer",
      "Designed by US | © 2024")
)



# Server
server <- function(input, output) {

  filtered_data <- reactive({
    # Filter the data by the selected year range
    accidents_filtered <- accidents_sf_wgs84 %>%
      filter(AccidentYear >= input$year_range[1] & AccidentYear <= input$year_range[2])
    return(accidents_filtered)
  })

  output$map <- renderLeaflet({
    if (input$plot_type == "Heatmap") {
      leaflet(filtered_data()) %>%
        addTiles() %>%
        addHeatmap(
          lng = ~st_coordinates(filtered_data())[,1],
          lat = ~st_coordinates(filtered_data())[,2],
          radius = 10,
          blur = 20,
          max = 0.01
        ) %>%
        setView(lng = mean(st_coordinates(filtered_data())[,1]),
                lat = mean(st_coordinates(filtered_data())[,2]),
                zoom = 12)

    } else if (input$plot_type == "Cluster") {
      # Ensure the filtered data is not empty before clustering
      if (nrow(filtered_data()) > 0) {
        coords <- st_coordinates(filtered_data())
        # Perform DBSCAN clustering
        dbscan_result <- dbscan(coords, eps = input$epsilon, minPts = input$min_pts)

        # Add cluster column to filtered data
        filtered_with_clusters <- filtered_data() %>%
          mutate(cluster = as.factor(dbscan_result$cluster))

        # Plot the clusters
        leaflet() %>%
          addTiles() %>%
          addCircleMarkers(data = filtered_with_clusters,
                           lng = ~st_coordinates(filtered_with_clusters)[,1],
                           lat = ~st_coordinates(filtered_with_clusters)[,2],
                           color = ~ifelse(cluster == 0, "gray", "red"),
                           fillOpacity = 0.7,
                           radius = 5,
                           popup = ~paste("Accident ID:", AccidentUID, "<br>",
                                          "Cluster:", cluster)) %>%
          addLegend("bottomright",
                    colors = c("red", "gray"),
                    labels = c("Clustered Accidents", "Noise"),
                    title = "Accident Density")
      } else {
        leaflet() %>% addTiles()  # Render a blank map if no data is available
      }

    } else if (input$plot_type == "Severity Map") {
      severity_palette <- colorFactor(palette = c("blue", "gray", "purple", "black"),
                                      levels = unique(accidents$AccidentSeverityCategory_en))

      leaflet(filtered_data()) %>%
        addTiles() %>%
        addCircleMarkers(
          lng = ~st_coordinates(filtered_data())[,1],
          lat = ~st_coordinates(filtered_data())[,2],
          radius = 3,
          color = ~severity_palette(AccidentSeverityCategory_en),
          fill = TRUE,
          fillOpacity = 0.7,
          clusterOptions = markerClusterOptions(),
          popup = ~paste("Accident Time:", AccidentHour, "<br>",  # Updated field name
                         "Accident Severity:", AccidentSeverityCategory_en)
        ) %>%
        addLegend(pal = severity_palette, values = ~AccidentSeverityCategory_en, title = "Accident Severity")
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)

