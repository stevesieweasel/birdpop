server <- function(input, output) {
  
  # filter for elevation ----
  stations_filtered_df <- reactive({
    filtered_stations <- stations %>% 
      filter(elev >= input$elev_input[1] & elev <= input$elev_input[2])
    
    return(filtered_stations)
  })
  
  # filter for species (morphometrics) ----
  morphometrics_filtered_df <- reactive({
    morphometrics_filtered <- morphometrics %>% 
      filter(commonname == input$species_input)
    
    return(morphometrics_filtered)
  })
  
  # station map ----
  output$station_map_output <- renderLeaflet({
    leaflet(data = stations_filtered_df()) %>%
      addProviderTiles("Esri.WorldTopoMap") %>%
      addMarkers(lng = ~long, lat = ~lat, popup = ~paste(name, station, sep = "<br>")) %>% 
      setView(lng = center_lng, lat = center_lat, zoom = 2.5) 
  })
  
  # species richness barchart ----
  output$spp_richness_bar_output <- renderPlot({
    ggplot(data = stations_filtered_df(), aes(x = station, y = species_count)) +
      geom_col() +
      theme_bw() +
      theme(legend.position = 'none',
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
      labs(x = 'Banding Station', y = 'Species Richness',
           title = 'Observed Species Richness at Each MAPS Station')
  })
  
  # morphometric boxplots ----
  output$morphometric_plot <- renderPlot({
    selected_measurement <- input$measurement_input
    
    ggplot(morphometrics_filtered_df(), aes(x = !!sym(selected_measurement), y = weight)) +
      geom_boxplot() +
      theme_bw() +
      labs(x = input$measurement_input, y = 'Body weight (log10 g)') 
  })
  
  # wing length vs body weight scatterplot ----
  output$wing_plot <- renderPlot({
    selected_species <- input$species_input
    
    ggplot(morphometrics_filtered_df(), aes(x = wng, y = weight, color = commonname)) +
      geom_point() +
      theme_bw() +
      labs(x = 'Wing chord (length in mm)', y = 'Body weight (g)', color = 'Species')
  })
  
  # cover photo 1 ----
  output$bird_img <- renderImage({
    list(src = "www/rbnu.jpg",
         width = 1000,
         height = 400)
  }, deleteFile = FALSE)
  
    # cover photo 1 ----
  output$bird_img2 <- renderImage({
    list(src = "www/rbnu2.jpg",
         width = 300,
         height = 400)
  }, deleteFile = FALSE)

  # abundance estimator plot ----
  output$abundance_plot <- renderPlot({
    abundance_filtered_df <- morphometrics %>% 
      filter(commonname == input$abundance_species_input)
    
    # Function to calculate abundance estimates for a given year
    calculate_abundance <- function(data) {
      capture_freq <- data %>%
        group_by(band) %>%
        summarise(nbcap = n()) %>%
        ungroup() %>%
        group_by(nbcap) %>%
        summarise(freq = n()) %>%
        ungroup()
      
      result <- closedpCI.0(capture_freq, dfreq = TRUE, dtype = 'nbcap', m = "M0", t = Inf)
      
      return(result$results)
    }
    
    # Group data by year
    years <- unique(year(abundance_filtered_df$date))
    
    # Calculate abundance estimates for each year
    results_list <- lapply(years, function(y) {
      calculate_abundance(filter(abundance_filtered_df, year == y))
    })
    
    # Combine results into a single data frame
    results_df <- as.data.frame(do.call(rbind, results_list))
    results_df$year <- years
    
    # Define the desired confidence level (e.g., 95%)
    confidence_level <- 0.95
    
    # Calculate the z-value for the desired confidence level (two-tailed)
    z_value <- qnorm((1 + confidence_level) / 2)
    
    # Calculate confidence intervals
    results_df$lower_ci <- results_df$abundance - z_value * results_df$stderr
    results_df$upper_ci <- results_df$abundance + z_value * results_df$stderr
    
    # Plot abundance estimates over time
    ggplot(results_df, aes(x = year, y = abundance)) +
      geom_line() +
      geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci), alpha = 0.3) +
      labs(x = "Year", y = "Abundance Estimate",
           title = paste("Abundance Estimates for", input$abundance_species_input)) +
      theme_bw() +
      scale_x_continuous(breaks = unique(results_df$year), max(results_df$year), 
                         labels = unique(results_df$year)) +
      coord_cartesian(ylim = c(0, max(results_df$upper_ci))) +
      theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  })
}