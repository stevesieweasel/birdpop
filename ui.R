# navbar page ----
ui <- navbarPage(
  
  #  apply {fresh} theme ----
   theme = "shiny_fresh_theme.css",
  
   # add css file ----
   header = tags$head(
   tags$link(rel = "stylesheet", type = "text/css", href = "sass-styles.css")
   ),
  
  title = "Washington State MAPS Data Explorer",

  # (Page 1) intro tabPanel ----
  tabPanel(title = "About this App",
           # intro image fluidRow ----
           fluidRow(
             # use columns to create white space on sides
             column(1),
             column(10,           div(
               id = "centered_bird_img_container",
               imageOutput("bird_img", width = "100%")
             ),),
             column(1)
             
           ), # END intro image fluidRow

         # intro text fluidRow ----
         fluidRow(
           # use columns to create white space on sides
           column(1),
           column(10, includeMarkdown("text/about.md")),
           column(1)

         ), # END intro text fluidRow

         hr(), # creates light gray horizontal line

         # footer text ----
         includeMarkdown("text/footer.md")
   
  ), # END (Page 1) intro tabPanel
  
  # (Page 2) data viz tabPanel ----
  tabPanel(title = "MAPS Stations",


                      # stations sidebarLayout ----
                      sidebarLayout(

                        # stations sidebarPanel ----
                        sidebarPanel(

                          # stationspickerInput ----
                          sliderInput(inputId = "elev_input", label = "Select a range of elevations (meters)",
                                      min = 3, max = 2100, value = c(3, 2100)), # END elevation pickerInput

                ), # END station sidebarPanel

                        # station mainPanel ----
                        mainPanel(
                          includeMarkdown("text/map_page.md"),
                          
                          # START Map fluidRow
                          fluidRow(
                            # use columns to create white space on sides
                            column(1),
                            column(10,  leafletOutput(outputId = "station_map_output")  %>%  
                            withSpinner(color = "#006792", type = 1),),
                            column(1)
                          ), # END map fluidRow
                          
                          tags$div(style = "margin-top: 20px;"), # add some space

                          # START barchart fluidRow
                          fluidRow(
                            # use columns to create white space on sides
                            column(1),
                            column(10,plotOutput(outputId = "spp_richness_bar_output")  %>%  
                            withSpinner(color = "#006792", type = 1)),
                            column(1)
                          ), # END barchart fluidRow                          


                        ) # END stations mainPanel

                      ) # END stations sidebarLayout





  ), # END (Page 2) data viz tabPanel

  
  # (Page 3) data viz tabPanel ----
  tabPanel(title = "Morphometrics",
           

             
             # morphometrics tabPanel ----
             tabPanel(title = "Morphometrics",

                      tags$img(src = "wing_chord.jpg", width = 200, height = 150),  
                      tags$img(src = "rbnu.jpg", width = 300, height = 150), 
                      tags$img(src = "olfl.jpg", width = 300, height = 150),
                      tags$img(src = "band_sizing.jpg", width = 300, height = 150),
                      
                      tags$div(style = "margin-top: 20px;"), # add some space

                      # morphometrics sidebarLayout ----
                      sidebarLayout(
                        
                        # morphometric sidebarPanel ----
                        sidebarPanel(
                          
                          # measurement type pickerInput ----
                          radioButtons(inputId = "measurement_input", 
                                      label = "Select measurement type:",
                                      choices = c('Age', 'Sex', 'Breeding_Status', 'Fat_Content'),
                                      selected = 'Age'), 
                          # END morphometirc measurement type pickerInput
                          
                          # START species pickerInput ----
                          pickerInput(inputId = 'species_input',
                                      label = "Select species of interest:",
                                      choices = c(unique(morphometrics$spec)),
                                      selected = c("SWTH","AMRO"),
                                      options = pickerOptions(actionsBox = TRUE),
                                      multiple = TRUE),


                          
                          # END species pickerInput ----
                          
                        ), # END morphometric sidebarPanel
                        
                        # morphometric mainPanel ----
                        mainPanel(
                          
                          includeMarkdown("text/morphometrics_page.md"),
                          
                          plotOutput(outputId = "morphometric_plot") %>% 
                            withSpinner(color = "#006792", type = 1),
                          
                          tags$div(style = "margin-top: 20px;"), # add some space
                          
                          plotOutput(outputId = "wing_plot") %>% 
                            withSpinner(color = "#006792", type = 1)
                          
                        ) # END morph mainPanel
                        
                      ) # END morph sidebarLayout
                      
             ), # END morph tabPanel
             

           
  ) # END (Page 3) data viz tabPanel
) # END navbarPage
