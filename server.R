server <- function(input, output) {
  
  # filter for elevation ----
  stations_filtered_df <- reactive({
    filtered_stations <- stations %>% 
      filter(elev >= input$elev_input[1] & elev <= input$elev_input[2])
    
 
    return(filtered_stations)
  })


  
  # station map ----
  output$station_map_output <- renderLeaflet({
    leaflet(data = stations_filtered_df()) %>%
      addProviderTiles("Esri.WorldTopoMap") %>%
      addMarkers(lng = ~long, lat = ~lat, popup = ~paste(name, station, sep = "<br>")) %>% 
      setView(lng = center_lng, lat = center_lat, zoom = 6.5) })
  
  # species richness barchart ----
  output$spp_richness_bar_output <- renderPlot({
    ggplot(data = stations_filtered_df(), aes(x = station, y = species_count))+
      geom_col() +
      theme_bw() +
      theme(legend.position = 'none',
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
      labs(x = 'Banding Station', y = 'Species Richness')})
  
  
  # morphometric boxplots ----
  output$morphometric_plot <- renderPlot({
    
    selected_measurement <- input$measurement_input
    
    ggplot(morphometrics, aes(x = !!sym(selected_measurement), y = weight)) +
    geom_boxplot() +
    theme_bw() +
    labs(x = input$measurement_input, y = 'Body weight (log10 g)') })
  
  
  # cover photo ----
  output$bird_img <- renderImage({
    
    list(src = "www/rbnu.jpg",
         width = "100%",
         height = 400)
    
  }, deleteFile = F)
  
  # filter for island ----
  island_df <- reactive({

    validate(
      need(length(input$penguin_island_input) > 0, "Please select at least one island to visualize data for.")
    )

    penguins %>%
      filter(island %in% input$penguin_island_input)

  })

  # render the flipper length histogram ----
  output$flipperLength_histogram_output <- renderPlot({

    ggplot(na.omit(island_df()), aes(x = flipper_length_mm, fill = species)) +
      geom_histogram(alpha = 0.6, position = "identity", bins = input$bin_num_input) +
      scale_fill_manual(values = c("Adelie" = "darkorange", "Chinstrap" = "purple", "Gentoo" = "cyan4")) +
      labs(x = "Flipper length (mm)", y = "Frequency",
           fill = "Penguin species") +
      myCustomTheme()
    
  },
  # alt text under the hood for screen readers to pick up.
  alt = "A histogram of penguin flipper lengths (mm). Flipper lengths tend to be smallest on Adélie penguins and largest on Gentoo penguins."
  
  )
  
} # END server