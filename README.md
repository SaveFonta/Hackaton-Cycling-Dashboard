# Hackaton Cycling Dashboard
This dashboard was developed to compete in the Hackaton, organized by the ETH-based association "Sports Analytics Club". Some of the partners were Swiss Cycling, Eviden AG, Veloforum, City of Zurich, Traffic Division and Kanton Zürich, Fachstelle Veloverkehr. 

The main question was "How might we use technology to address the increase in (e)Bike accidents and encourage safe adoption of cycling in Zürich?" 

# Bicycle Accident Analysis Dashboard
This Shiny application provides an interactive tool for analyzing bicycle accident data. Using this dashboard, you can explore the accident locations, visualize accident density with heatmaps, identify clusters of accidents, and observe the severity of incidents based on various filters and visualization methods.

The goal was to identify and then classify, high-accident-inclined area in the city of Zurich. This way, it is possible to tackle those areas
## Features

- **Heatmap Visualization:** Display accident locations as a heatmap to identify areas with a high density of accidents.
- **Cluster Analysis:** Use DBSCAN clustering to group accident locations, helping to reveal areas with recurrent accidents.
- **Severity Mapping:** Visualize accident severity using color-coded markers to represent the severity of each incident.
- **User-friendly Filters:** Use filters to customize views by plot type, year range, and clustering parameters.
  
## Installation

To run this application, you'll need R and the following packages installed:

```r
install.packages(c("shiny", "shinythemes", "leaflet", "leaflet.extras", "sf", "ggplot2", "dbscan", "dplyr", "bslib"))

 
