# Shiny-app-EVCS

### Author: Xiyu Zhang

This is a developed shiny app probing the deployment of electric vehicle charging stations (EVCS) in Washington, D.C. 

### Umbrella

In recent years, electric vehicle (EV) sales are continually breaking records. The deployment of electric vehicle charging stations (EVCS) thus turned out to be a crucial topic, since it can at the same time accelerate the consumption of EVs, and accommodate the prolific charging needs of EVs. Adopting EVs is an important step in road decarbonization.

Thus, the deployment of EVCS became a significant policy problem. There are policies implemented to stimulate the deployment of charging infrastructures. In the US context, the most famous one is the National Electric Vehicle Infrastructure (NEVI) Formula Program; while in the DC context, the crucial one is the electric vehicle charging station program.

### Mini Lit Review

What are the factors Affecting the Distribution of EVCSs?

According to California’s advanced clean cars midterm review, the most charging occurs at home, followed by work, then along the travel corridors.
There are three types of electric vehicle supply equipment (EVSE): level 1, level 2, and direct current fast chargers, also known as DCFC. According to another study, home and workplace chargers are level 1 and level 2 EVSE, while these along the highway corridors are DCFCs.

However, this is a conclusion driven by California’s circumstances. What we don’t know is, does the distribution of electric vehicle charging stations in other metropolitan areas, for example, the District of Columbia, follows the same pattern. This is a hole in the current literature.

### QHPT & Methods

How electric charging station distribution varies across a metropolitan area, such as Washington D.C.? My first hypothesis is the demographical and economic attributes, concretized as population density and average income, along with the road density affect the deployment of electric vehicle charging stations with level 1 and level 2 EVSE. My second hypothesis is, the distance to highway corridors affects the number of EVCSs with DCFCs.

My predictions are represented by the plus signs in the same chart. I expect positive correlations between the population density, average income, and road density with the number of level 1 and level 2 EVSE. Also, I expect the deployment of DCFCs to be positively correlated with the distance to the highway corridors.

In general, I will adopt related GIS packages in R language for data processing and hypotheses examination. To test the Airst hypothesis, I will mainly use shapefiles to calculate the population density and road density in each census tract – road density refers to the ratio of the length of the country's total road network to a tract's land area –, and use the calculated result to run a regression model. To test the second hypothesis, I will generate a raster stack, sample raster cells, and draw a scatter plot with trendlines to capture the possible correlation. Also, I am going to test the significance of the correlation.

### Conclusion

DC is ambitious to lay out a proposal for 7,500 electric vehicle charging stations by 2027, which is signed by the D.C. Council in January 2023. In DC, Individual and organizational entities are both encouraged to apply to install EV charging stations, both private and public ones, under the new policies.

That means, although there exist numerous literatures committed to developing an optimal mathematical model of charging station distribution, taking, for example, optimal locations, charge scheduling, grid integration, and even vehicle-to-grid recharge strategy into consideration, the installation of charging stations itself is still a choice of individual will, but not a meticulous calculation.

Thus, people will need assistance while making their decisions: is it profitable to install a public charging station here? To this extent, I regard my research as a first step to developing an intuitive understanding of the current distribution of EVCSs in Washington D.C., and other metropolitan areas and assisting potential investors to make better decisions. Though there are interactive maps showing the location of existing EVCSs, there is a lack of research depicting the pattern of distribution in an area.

### Data source

Restricted by the upload limitation of GitHub, relative data sets are not able to be displayed in this repository. My data source include [DC Census Data](https://opendata.dc.gov/) , [DC Road data](https://opendata.dc.gov/), [Electric Vehicle Charging Station distribution](https://afdc.energy.gov/stations/#/find/nearest), and [DC Interstate Highway](https://opendata.dc.gov/).
