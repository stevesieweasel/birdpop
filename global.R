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

# DATA WRANGLING ----
## Station info ----
stations <- read_sf(here('data', 'wa_maps_stations.csv')) %>% 
  clean_names() %>% 
  select(station, name, declat, declng, elev, habitat) %>% 
  rename(lat = declat, long = declng) %>% 
  mutate(lat = as.numeric(lat), 
         long = as.numeric(long),
         elev = as.numeric(elev))

## Species Richness calculations
species_richness <- read_csv(here('data','wa_maps_banding.csv')) %>% 
  clean_names() %>% 
  select(spec, date, station) %>% 
  drop_na() %>% 
  group_by(station) %>%
  summarize(species_count = n_distinct(spec))

## Adding species richness column to station sf
stations <- left_join(stations, species_richness, by = 'station')

## Finding optimal location to center station map
center_lng <- median(stations$long)
center_lat <- median(stations$lat)

# Wrangling raw banding data into tidy df of useful morphometrics
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
  mutate(f = as.factor(f)) %>% 
  rename('Fat_Content' = 'f', 
         'Breeding_Status' = 'brstat',
         'Sex' = 'sex',
         'Age' = 'age') %>% 
  drop_na()

alpha <- read_csv(here('data', 'bird_alpha.csv')) %>% 
  clean_names() %>% 
  select(spec, commonname, sciname)

morphometrics <- left_join(morphometrics, alpha, by = 'spec') %>% 
  drop_na(commonname)


## Reorder the levels of the Age and Breeding_Status factors
morphometrics$Age <- factor(morphometrics$Age, levels = c("Nestling", 
                                                          "1st year", 
                                                          ">1st year", 
                                                          "2nd year", 
                                                          ">2nd year"))
morphometrics$Breeding_Status <- factor(morphometrics$Breeding_Status, 
                                        levels = c("Breeder",
                                                   "Usual breeder",
                                                   "Occasional breeder",
                                                   "Altitudinal disperser",
                                                   'Migrant',
                                                   "Transient"))

