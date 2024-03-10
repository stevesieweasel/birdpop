# LOAD LIBRARIES ----
library(shiny)
library(lterdatasampler)
library(palmerpenguins)
library(tidyverse)
library(shinyWidgets)
library(markdown)
library(bslib)
library(here)
library(tsibble)
library(janitor)
library(sf)
library(tmap)
library(leaflet)
library(fresh)
library(shinycssloaders)
library(sass)

# GGPLOT THEME ----
myCustomTheme <- function() {
  theme_light() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14, face = "bold"),
          legend.title = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 13),
          legend.position = "bottom",
          panel.border = element_rect(linewidth = 0.7))
}

# DATA WRANGLING ----
stations <- read_sf(here('data', 'wa_maps_stations.csv')) %>% 
  clean_names() %>% 
  select(station, name, declat, declng, elev, habitat) %>% 
  rename(lat = declat, long = declng) %>% 
  mutate(lat = as.numeric(lat), 
         long = as.numeric(long),
         elev = as.numeric(elev))

species_richness <- read_csv(here('data','wa_maps_banding.csv')) %>% 
  clean_names() %>% 
  select(spec, date, station) %>% 
  drop_na() %>% 
  group_by(station) %>%
  summarize(species_count = n_distinct(spec))

stations <- left_join(stations, species_richness, by = 'station')


center_lng <- median(stations$long)
center_lat <- median(stations$lat)


morphometrics <- read_csv(here('data','wa_maps_banding.csv')) %>% 
  clean_names() %>% 
  select(spec, age, sex, f, fw, wng, weight, brstat) %>% 
  filter(weight != 0, wng != 0, age != 0, brstat != '?') %>%
  mutate(age = ifelse(age == 4, "Nestling",
                      ifelse(age == 2, "1st year",
                             ifelse(age == 1, ">1st year",
                                    ifelse(age == 5, "2nd year",
                                           ifelse(age == 6, ">2nd year", NA)))))) %>% 
  mutate(age = as.factor(age)) %>%   
  mutate(brstat = ifelse(brstat == 'B', "Breeder",
                         ifelse(brstat == 'U', "Usual breeder",
                                ifelse(brstat == 'O', "Occasional breeder",
                                       ifelse(brstat == 'T', "Transient",
                                              ifelse(brstat == 'A', "Altitudinal disperser", 
                                                     ifelse(brstat == 'M', 'Migrant', NA))))))) %>% 
  mutate(brstat = as.factor(brstat)) %>% 
  mutate(spec = as.factor(spec)) %>%
  mutate(f = as.factor(f)) %>% 
  rename('Fat_Content' = 'f', 
         'Breeding_Status' = 'brstat',
         'Sex' = 'sex',
         'Age' = 'age') %>% 
  drop_na()

# Reorder the levels of the Age factor
morphometrics$Age <- factor(morphometrics$Age, levels = c("Nestling", "1st year", ">1st year", "2nd year", ">2nd year"))
morphometrics$Breeding_Status <- factor(morphometrics$Breeding_Status, 
                                        levels = c("Breeder","Usual breeder","Occasional breeder","Altitudinal disperser",'Migrant',"Transient"))
print(levels(morphometrics$Age))

######## trout stuff to clear later
clean_trout <- and_vertebrates |>
  filter(species == "Cutthroat trout") |>
  select(sampledate, section, species, length_mm = length_1_mm, weight_g, channel_type = unittype) |> 
  mutate(channel_type = case_when(
    channel_type == "C" ~ "cascade",
    channel_type == "I" ~ "riffle",
    channel_type =="IP" ~ "isolated pool",
    channel_type =="P" ~ "pool",
    channel_type =="R" ~ "rapid",
    channel_type =="S" ~ "step (small falls)",
    channel_type =="SC" ~ "side channel"
  )) |> 
  mutate(section = case_when(
    section == "CC" ~ "clear cut forest",
    section == "OG" ~ "old growth forest"
  )) |> 
  drop_na()

