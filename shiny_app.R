
# This is the shiny skeleton for my final project

# setup -----------------------------------------

# 1. Load packages

library(sf)
library(tmap)
library(tidyverse)
library(shiny)
library(shinydashboard)

# 2. Set the tmap mode to 'view'

tmap_mode('view')

# 3. Load data

# geometry, population and income of census tracts

census <-
  st_read('data/dc_census.geojson') %>% 
  select(-STATEFP)

# initial electric vehicle charging station data

stations <-
  st_read('data/alt_fuel_stations.geojson') %>% 
  filter(state == 'DC') %>%
  
  # EPSG 32618 is UTM zone 18N for Washington DC, same as the crs of 'census'
  
  st_transform(crs = 32618) %>% 
  
  # select variables of interest
  
  select(id, ev_dc_fast_num, ev_level1_evse_num,
         ev_level2_evse_num) %>% 
  
  # subset the station data to DC area
  
  st_crop(census)

# convert 3 types of electric vehicle supply equipment data to numeric

stations$ev_dc_fast_num <-
  stations$ev_dc_fast_num %>% 
  replace_na(0) %>% 
  as.numeric()

stations$ev_level1_evse_num <-
  stations$ev_level1_evse_num %>% 
  replace_na(0) %>% 
  as.numeric()

stations$ev_level2_evse_num <-
  stations$ev_level2_evse_num %>% 
  replace_na(0) %>% 
  as.numeric()

# DC road data

road <-
  st_read('data/Roads.geojson') %>% 
  st_transform(crs = 32618) %>% 
  select(OBJECTID)

# Calculate road density in each census tract

census_road <-
  census %>% 
  mutate(road_density = 
           
           # exclude the area proportion that does not contain road to 
           # calculate the road density of each census tract
           
           1 - 
           
           # drop units for the result
           
           units::drop_units(
             
             # calculate the area that each census tract contains road
             
             (census %>% 
                st_difference(
                  
                  # unionize road as a multipolygon
                  
                  st_union(road)) %>% 
                group_by(GEOID) %>% 
                
                # calculate the area
                
                st_area())
             
             # divided by the total area of each census tract
             
             / (census$ALAND + 
                  census$AWATER)))

# EVSE attributes

EVSE_attribute <-
  census_road %>% 
  st_join(stations %>% 
            mutate(EVSE = ev_level1_evse_num + ev_level2_evse_num) %>% 
            select(EVSE)) %>% 
  mutate_at('EVSE', ~replace_na(., 0)) %>% 
  mutate(population_density = (POPULATION / ALAND)) %>% 
  mutate(income = INCOME) %>% 
  pivot_longer(c(road_density, population_density, income),
               names_to = 'attribute',
               values_to = 'value')

# highway corridor data

interstate_highway <-
  st_read('data/Interstate_Highways.geojson') %>% 
  st_transform(crs = 32618) %>% 
  select(geometry)

# Inspect the stations contain DC fast chargers' distance to highways

stations_w_DCFC <-
  stations %>% 
  
  # generate a Boolean value for future grouping: whether the charging station
  # contains direct current fast charger (DCFC)
  
  mutate(DCFC = if_else(ev_dc_fast_num == 0,
                        FALSE,
                        TRUE)) %>% 
  
  # calculate each station's distance to interstate highway
  
  mutate(distance_to_highway = 
           st_distance(.,
                       interstate_highway %>% 
                         
                         # unionize sf lines into a multi-linestring
                         
                         st_union()))

# drop the unit to conduct a t test

stations_w_DCFC$distance_to_highway <-
  units::drop_units(stations_w_DCFC$distance_to_highway)

# ui --------------------------------------------

ui <-
  dashboardPage(
    
    dashboardHeader(title = 'Washington D.C. Electric Vehicle Charging 
                    Stations'),
    
    dashboardSidebar(
      sidebarMenu(
        menuItem(text = 'EVSE Distribution',
                 icon = icon('map'),
                 tabName = 'distribution'),
        menuItem(text = 'Factors Affecting Distribution',
                 icon = icon('chart-line'),
                 tabName = 'correlation'),
        menuItem(text = 'DCFC Distribution',
                 icon = icon('table'),
                 tabName = 'dcfc'),
        menuItem(text = 'DCFC to Highway',
                 icon = icon('car'),
                 tabName = 'highway'))
    ),
    
    dashboardBody(
      tabItems(
        tabItem(tabName = 'distribution',
                h2('EVSE Distribution'),
                radioButtons(
                  inputId = 'EVSE_type',
                  label = 'EVSE type',
                  choiceNames = c('Level 1 and Level 2', 
                                  'Direct Current Fast Charger'),
                  choiceValues = c('EVSE_1n2', 'EVSE_dc')),
                tmapOutput(outputId = 'EVSE_distribution')),
        
        tabItem(tabName = 'correlation',
                h2('Factors Affecting EVSE Distribution'),
                selectInput(
                  inputId = 'attribute',
                  label = 'Factor',
                  choices = c('population_density', 'road_density',
                              'income')),
                plotOutput(outputId = 'plot_output')),
        
        tabItem(tabName = 'dcfc',
                h2('DCFC Distribution'),
                p(paste('Compare the distance to highway between ', 
                        'EVCS containing only level 1 and level ',
                        '2 chargers, and EVCS containing DCFCs.')),
                dataTableOutput(outputId = 'DCFC_table')),
        
        tabItem(tabName = 'highway',
                h2('DCFC to Highway'),
                p('Further study: Compare to the DCFC density per hectare'),
                tmapOutput(outputId = 'distance_to_highway'))
      )
    )
  )

# server ----------------------------------------

server <-
  function(input, output) { 
    
    # Data sub-setting and summarizing ------------------------------------
    
    # Census containing different types of EVSEs
    
    census_EVSE <-
      reactive({
        census %>% 
          st_join(
            stations %>% 
              mutate(EVSE_1n2 = ev_level1_evse_num + ev_level2_evse_num,
                     EVSE_dc = ev_dc_fast_num) %>% 
              select(EVSE = input$EVSE_type)) %>% 
          mutate_at('EVSE', ~replace_na(., 0)) %>% 
          group_by(GEOID) %>% 
          summarise(n = sum(EVSE))
      })
    
    # Test factors affecting EVSE distributions
    
    EVSE_1n2_correlation <-
      reactive({
        EVSE_attribute %>% 
          filter(attribute == input$attribute)
      })
    
    # Outputs --------------------------------------------------------------
    
    # EVSE distribution
    
    output$EVSE_distribution <-
      renderTmap(
        census_EVSE() %>% 
          left_join(census %>% 
                      select(GEOID, ALAND) %>% 
                      as_tibble()) %>% 
          
          # convert the density unit to EVCS per hectare
          
          mutate(density = n / ALAND * 10000) %>% 
          tm_shape(name = 'EVSE Density') +
          tm_polygons(title = 'EVSE per hectare',
                      col = 'density'))
    
    # factors affecting the EVSE distribution
    
    output$plot_output <-
      renderPlot(
        EVSE_1n2_correlation() %>% 
          ggplot(
            aes(x = value,
                y = EVSE)) +
          geom_point() +
          geom_smooth(
            
            # 'linear model' as 'lm' function, looking for simple relation
            
            method = 'lm') +
          theme_minimal())
    
    # DCFC Distribution Table
    
    output$DCFC_table <-
      renderDataTable(
        stations_w_DCFC %>% 
          group_by(DCFC) %>% 
          summarise(mean = mean(distance_to_highway)) %>% 
          
          # convert to tibble for only selecting DCFC and means in the next step
          
          as_tibble() %>% 
          select(DCFC, mean))
    
    # Distance to highway
    
    output$distance_to_highway <-
      renderTmap(
        census %>% 
          mutate(distance_to_hw = 
                   st_distance(.,
                               interstate_highway) %>% 
                   
                   # convert the unit from 'm' to 'km' for better visualization
                   
                   units::set_units('km')) %>% 
          tm_shape(
            name = 'Distance to Interstate Highways') +
          tm_polygons(
            title = 'Distance to Highways (km)',
            col = 'distance_to_hw',
            palette = 'PuBuGn'))
    
  }

# knit and run app ------------------------------

shinyApp(ui, server)