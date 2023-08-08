
# Set up -----------------------------------------------------------

library(sf)
library(tmap)
library(tidyverse)

# Set the tmap mode to 'view'

tmap_mode('view')

# Load data ---------------------------------------------------------------

# geometry, population and income of census tracts

census <-
  st_read('data/raw/shapefiles/dc_census.geojson') 

# initial electric vehicle charging station data

station_initial <-
  st_read('research_proj/data/alt_fuel_stations.geojson') %>% 
  filter(state == 'DC') %>%
  
  # EPSG 32618 is UTM zone 18N for Washington DC, same as the crs of 'census'
  
  st_transform(crs = 32618)

# processed electric vehicle charging station data

stations <-
  station_initial %>% 
  
  # select variables of interest
  
  select(access_code, id, ev_dc_fast_num, ev_level1_evse_num,
         ev_level2_evse_num) %>% 
  
  # subset the station data to DC area
  
  st_crop(census)

# DC road data

road <-
  st_read('research_proj/data/Roads.geojson') %>% 
  st_transform(crs = 32618)

# highway corridor data

interstate_highway <-
  st_read('research_proj/data/Interstate_Highways.geojson') %>% 
  st_transform(crs = 32618)

# other economic data coming from ACS

economic <-
  st_read('research_proj/data/ACS_Economic_Characteristics.geojson')

# Interactive tmap --------------------------------------------------------

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

# data wrangling

# radio button menu

stations %>% 
  mutate(EVSE_1n2 = ev_level1_evse_num + ev_level2_evse_num,
         EVSE_dc = ev_dc_fast_num)

census %>% 
  st_join(stations_EVSE) %>% 
  group_by(GEOID, EVSE) %>% 
  summarise(n = n()) %>% 
  left_join(census %>% 
              select(GEOID, ALAND) %>% 
              as_tibble()) %>% 
  
  # convert the density unit to EVCS per hectare
  
  mutate(density = n / ALAND * 10000) %>% 
  tm_shape(name = 'EVSE Density') +
  tm_polygons(title = 'EVSE per hectare',
              col = 'density')

# Interactive ggplot -----------------------------------------------------------

# Road density

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

# checkbox input

attribute_select <-
  'Population Density'

EVSE_1n2_correlation <-
  if(attribute_select == 'Population Density') {
    census %>% 
      st_join(EVSE_types) %>% 
      
      # generate the population density variable
      
      mutate(attribute = POPULATION / ALAND)
  } else if(attribute_select == 'Road Density'){
    census_road %>% 
      st_join(EVSE_types) %>% 
      mutate(attribute = road_density)
  } else {
    census %>% 
      st_join(EVSE_types) %>% 
      mutate(attribute = INCOME)
  }

EVSE_1n2_correlation %>% 
  ggplot(
    aes(x = attribute,
        y = EVSE)) +
  geom_point() +
  geom_smooth(
    
    # 'linear model' as 'lm' function, looking for simple relation
    
    method = 'lm') +
  theme_minimal()

# How to display the significance of the fit line?
# since the gray shade is the confidence interval around the smooth function, 
# and the gray shade covers both the increasing and decreasing trends. Thus, it
# is impossible for us to tell there exists any one-sided correlation between 
# the variables.

# Kable -------------------------------------------------------------

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

# develop a kable to compare distance to highway between level 1 + level 2 
# chargers and DCFCs

stations_w_DCFC %>% 
  group_by(DCFC) %>% 
  summarise(mean = mean(distance_to_highway)) %>% 
  
  # convert to tibble for only selecting DCFC and means in the next step
  
  as_tibble() %>% 
  select(DCFC, mean) %>% 
  knitr::kable()

# conduct t test to test whether the difference is statistically significant

stations_w_DCFC$distance_to_highway <-
  
  # drop the units to conduct t test
  
  units::drop_units(stations_w_DCFC$distance_to_highway)

t.test(stations_w_DCFC %>% 
         filter(DCFC == F) %>% 
         pull(distance_to_highway),
       stations_w_DCFC %>% 
         filter(DCFC == T) %>% 
         pull(distance_to_highway),
       
       # set the alternative hypothesis to be the previous one less than 
       # the latter one
       
       alternative = 'less')

# the test result shows that it is statistically significant for the former
# one greater than the latter one

# Static map --------------------------------------------------------------

# probe the distance each census tract to the highway, for comparing with the 
# distribution of DCFC by readers

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
    palette = 'PuBuGn')






