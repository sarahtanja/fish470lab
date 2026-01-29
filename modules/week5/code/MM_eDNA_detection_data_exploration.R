### California Current eDNA dataset
### Spring 2026

library(tidyverse)

load("C:/Users/Amy Van Cise/Desktop/eDNA_MM_detections.Rdata")

#0. Data setup (for us only)
# fish_data <- read_csv("C:/Users/Amy Van Cise/Desktop/M3_compiled_taxon_table_wide.csv") %>%
#   pivot_longer(-c(BestTaxon, Class), names_to = "Sample", values_to = "nReads") %>%
#   separate(Sample, into = c(NA,NA,"popID","sampID","dilution","techRep")) %>%
#   unite(popID,sampID, col = "NWFSCsampleID", sep = "-") %>%
#   filter(Class != "Mammalia") %>%
#   separate(BestTaxon, into = c("genus","sp",NA), sep=" ") %>%
#   mutate(sp = case_when(is.na(sp)~"sp.",
#                         TRUE~sp)) %>%
#   unite(genus, sp, col = "Species", sep = " ", remove = FALSE) %>%
#   select(-sp) %>% 
#   group_by(NWFSCsampleID, genus, Species) %>%
#   summarize(nReads = round(mean(nReads), digits =0)) %>%
#   pivot_wider(names_from = Species, values_from = nReads)

# detect_data <- detect_data_clean %>% 
#   select(NWFSCsampleID, BestTaxon, common_name, Class, Family,
#          Prey.family, Detected, station, depth, bathy.bottom.depth,
#          lat, lon, year, month, day) %>% 
#   group_by(NWFSCsampleID, BestTaxon) %>% 
#   mutate(sumDetected = sum(Detected)) %>% 
#   mutate(Detected = case_when(sumDetected > 0~1,
#                               TRUE~0)) %>% 
#   select(-sumDetected) %>% 
#   slice_head() %>% 
#   ungroup() %>% 
#   rename("Species" = BestTaxon, "Prey" = Prey.family) %>% 
#   mutate(Prey = case_when(common_name %in% c("California sea lion", "northern fur seal")~"generalist",
#                           TRUE~Prey)) %>% 
#   mutate(Species = as.character(Species))
# 
# save(detect_data, file = "C:/Users/Amy Van Cise/Desktop/eDNA_MM_detections.Rdata")
# write_csv(detect_data, file = "C:/Users/Amy Van Cise/Desktop/eDNA_MM_detections.csv")

# detect_data_fish <- detect_data %>% 
#   left_join(fish_data, by = "NWFSCsampleID")
# 
# write_csv(detect_data_fish, file = "C:/Users/Amy Van Cise/Desktop/eDNA_MM_fish_detections.csv")

#1. Wrangle: use filter to just look at just positive detections

detect_data_positive <- detect_data %>% 
  filter(Detected == 1)

#2a Visualize: plot MM detections by depth
ggplot(detect_data_positive, aes(y = common_name, x = depth, 
                            fill = Family, color = Family)) +
  geom_count(alpha = 0.7) +
  coord_flip(clip = "off") +
  scale_x_reverse() +
  scale_y_discrete(guide = guide_axis(n.dodge = 2)) +
  theme_minimal()

#2b Visualize: plot MM detection 2D map
library(ggOceanMaps)

#first have them make the map
base_map <- basemap(limits = c(min(detect_data$lon),
                                    max(detect_data$lon),
                                    min(detect_data$lat),
                                    max(detect_data$lat)),
                         bathy.style = "rcb", crs = 4236,
                         rotate = FALSE)
## must download data the first time this is run each day. Select 1 for yes.

#then add points to the map

whale_map <- base_map +
  geom_point(data = detect_data_positive, aes(x=lon, y=lat, color = Family),
             alpha = 0.5, size = 2)

whale_map

#2c Visualize: plot MM detections in 3D
library(plotly)

#using phocids (true seals) as an example here, students can do whatever they want
phocids <- detect_data_positive %>% filter(Family == "Phocidae")

plot_ly(phocids,
  x = ~lon,
  y = ~lat,
  z = ~rev(depth),
  color = ~Species,
  type = "scatter3d",
  mode = "markers") %>% #this first bit up to here is all you need. The rest makes it a bit fancier
  layout(scene = list(aspectmode = "manual",
                      aspectratio = list(x = 1, y = 3, z = 0.5), #this stretches longitude axis so that it's a bit closer to reality
                      zaxis = list(autorange = "reversed"), #this reverses the depth axis so that deeper detections are at the bottom
                      xaxis = list(title = "Longitude"),
                      yaxis = list(title = "Latitude")))


dev.off()

### Now let's try looking at fishes

detect_data_fish <- read_csv("C:/Users/Amy Van Cise/Desktop/eDNA_MM_fish_detections.csv")
#1 Wrangle: filter for 1 MM and pivot the fish to a single column

detect_data_humpy <- detect_data_fish %>% 
  filter(common_name == "humpback whale") %>% 
  pivot_longer(17:length(.), names_to = "prey_species", values_to = "nReads") %>% 
  filter(nReads > 10) %>% 
  group_by(NWFSCsampleID) %>% 
  mutate(prey_prop = nReads/sum(nReads)) %>% 
  group_by(Detected, genus) %>%
  filter(mean(prey_prop, na.rm = TRUE) > 0.10) %>%
  ungroup()

detect_data_lags <- detect_data_fish %>% 
  filter(common_name == "Pacific white-sided dolphin") %>% 
  pivot_longer(17:length(.), names_to = "prey_species", values_to = "nReads") %>% 
  filter(nReads > 10) %>% 
  group_by(NWFSCsampleID) %>% 
  mutate(prey_prop = nReads/sum(nReads)) %>% 
  group_by(genus, Detected) %>%
  filter(mean(prey_prop, na.rm = TRUE) > 0.10) %>%
  ungroup()
  

#2 Visualize: fish vs predator presence

ggplot(detect_data_humpy, aes(x = genus, y = prey_prop)) +
  geom_boxplot(aes(fill = genus)) +
  theme(legend.position = "none") +
  facet_wrap(~Detected) +
  scale_x_discrete(guide = guide_axis(n.dodge = 4)) +
  theme_minimal()

ggplot(detect_data_lags, aes(x = genus, y = prey_prop)) +
  geom_boxplot(aes(fill = genus)) +
  theme(legend.position = "none") +
  facet_wrap(~Detected) +
  scale_x_discrete(guide = guide_axis(n.dodge = 3)) +
  theme_minimal()

#2b Visualize: map of fishes


#option 1: plot prey species on top of each other

#keep only prey species you want to plot!
humpy_prey <- detect_data_humpy %>% 
  filter(genus %in% c("Stenobrachius", "Bathylagidae", "Clupea", "Engraulis", "Thunnus", "Sardinops"))

#now plot!
base_map +
  geom_point(data = humpy_prey, 
             aes(x=lon, y = lat, size = prey_prop, 
                 color = genus),
             alpha = 0.6)

#option 2: pie charts!

#first we have to wrangle again!
humpy_wide <- detect_data_humpy %>% 
  filter(Detected == 1) %>% 
  pivot_wider(names_from=genus, values_from = prey_prop, values_fill = 0)

# ok now plot
library(scatterpie)
library(ggnewscale)

base_map +
  new_scale_fill() +
  geom_scatterpie(data = humpy_wide,
    aes(lon, lat), cols = c("Stenobrachius", "Bathylagidae","Clupea", "Engraulis", "Thunnus", "Sardinops"),
    pie_scale = 4) +
  scale_fill_manual(values = pnw_palette("Cascades"))

  
