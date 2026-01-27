### Generate KW diet data

library(tidyverse)
library(ggridges)

set.seed(42)

sample.df <- data.frame(Sample = paste0("Sample", seq(1,300,1)),
                      Ind = paste0("Ind", sample(1:30, 300, TRUE)),
                      Month = as.factor(sample(1:12, 300, TRUE)))

ggplot(sample.df, aes(x = Ind, fill = Month)) +
  geom_bar(stat = "count")

#### simulate diet

alpha_base <- c(8, 4, 3, 0.5, 0,
  0.7, 0.5, 0.3, 0.2)

seasonal_effects <- matrix(1, nrow = 9,
                           ncol = 12,
                           dimnames = list(c("Chinook salmon",
                            "chum salmon",
                            "coho salmon",
                            "steelhead salmon",
                            "pink salmon",
                            "sablefish",
                            "lingcod",
                            "arrowtooth flounder",
                            "Pacific halibut"),
                            1:12))

# Example seasonal structure
seasonal_effects["Chinook salmon", c(6,7)]  <- 2.5  
seasonal_effects["Chinook salmon", c(1,11,12)]  <- 0.1
seasonal_effects["chum salmon", c(11,12)]  <- 1.3
seasonal_effects["chum salmon", c(5,6,7)]  <- 0
seasonal_effects["coho salmon", c(8,9)]   <- 2.0 
seasonal_effects["coho salmon", c(12,1,2)]   <- 0 
seasonal_effects["sablefish", c(10, 11)]  <- 7
seasonal_effects["sablefish", c(1:8)]  <- 0
seasonal_effects["lingcod", c(1,2,3)]    <- 7
seasonal_effects["lingcod", c(4:11)]    <- 0
seasonal_effects["Pacific halibut", c(2,3,4)] <- 8
seasonal_effects["Pacific halibut", c(6,7)] <- 0
seasonal_effects["arrowtooth flounder", c(6,7)] <- 0
seasonal_effects["arrowtooth flounder", c(10,11,12)] <- 10

# background noise
seasonal_effects <- seasonal_effects *
  matrix(runif(9 * 12, 0.9, 1.1), 9, 12)

# Dirichlet distribution function
rdirichlet_base <- function(n, alpha) {
  k <- length(alpha)
  x <- matrix(
    rgamma(n * k, shape = alpha, rate = 1),
    ncol = k,
    byrow = TRUE
  )
  x / rowSums(x)
}

alpha_by_month <- lapply(1:12, function(m) {
  alpha_base * seasonal_effects[, m]
  })

diet_props <- matrix(NA, nrow(sample.df), 9)

for (i in seq_len(nrow(sample.df))) {
  m <- as.integer(sample.df$Month[i])
  diet_props[i, ] <- rdirichlet_base(1, alpha_by_month[[m]])
}

colnames(diet_props) <- c("Chinook salmon",
                          "chum salmon",
                          "coho salmon",
                          "steelhead salmon",
                          "pink salmon",
                          "sablefish",
                          "lingcod",
                          "arrowtooth flounder",
                          "Pacific halibut")

diet.df <- cbind(sample.df, diet_props) %>% 
  pivot_longer("Chinook salmon":"Pacific halibut",
               names_to = "species",
               values_to = "propDiet") %>% 
  mutate(propDiet = ifelse(propDiet < 0.01, 0, propDiet)) %>% 
  mutate(season = case_when(Month %in% c(1:3)~ "Winter",
                            Month %in% c(4:6)~ "Spring",
                            Month %in% c(7:9)~"Summer",
                            Month %in% c(10:12)~ "Autumn")) 

nSpec_samp <- diet.df %>%   
  group_by(Sample, Month, season) %>% 
  summarise(nSpecies = sum(propDiet > 0))

#### Some potential stats and figures ------------------------------------------

# Does diet change throughout the year? AKA does one species change throughout the year?

#1 ggplot with facet wrap
ggplot(diet.df, aes(x = as.numeric(Month), y = propDiet,
                    color = species, fill = species)) +
  geom_point() +
  geom_smooth(span = 0.8, alpha = 0.5, linewidth = 0.5) +
  facet_wrap(~species) +
  theme_ridges() +
  theme(legend.position = "top",
        text = element_text(size = 11)) +
  labs(x = "Diet proportion", y = "Month") +
  guides(color = guide_legend(nrow = 2),
         fill  = guide_legend(nrow = 2))

#2 filter data to include just one species
propChinook <- diet.df %>% 
  filter(species == "Chinook salmon")

#3 test statistic
chintest <- aov(propDiet ~ season, propChinook)
summary(chintest)

chin.lm <- lm(propDiet ~ as.numeric(Month), propChinook)
summary(chin.lm)

# Does chinook make up a majority of the diet?

#1 wrangle data - learn group_by, summarize, and mutate
diet_summary <- diet.df %>% 
  group_by(Ind,species) %>% 
  summarize(meanDiet = mean(propDiet)) %>% 
  mutate(Chinookyesno = ifelse(species == "Chinook salmon", "yes", "no")) 

#2 plot data
ggplot(diet_summary, aes(y = species, x = meanDiet, fill = species)) +
  geom_density_ridges()

ggplot(diet_summary, aes(x = Chinookyesno, y = meanDiet, fill = Chinookyesno)) +
  geom_boxplot()

#3 statistic
test <- aov(totalprop~Chinookyesno, data=diet_Chinook)
summary(test)

diet_summary_all <- diet.df %>% 
  group_by(species) %>% 
  summarize(meanDiet = mean(propDiet))

##NOT RUN##################################

ggplot(diet.df %>% filter(grepl("salmon", species)), aes(x = propDiet, y = Month, color = species, fill = species)) +
  geom_density_ridges(scale = 1.2, alpha = 0.3,
                      from = 0, to = 1) +
  theme_ridges() +
  theme(legend.position = "top",
        text = element_text(size = 11)) +
  labs(x = "Diet proportion", y = "Month") +
  guides(color = guide_legend(nrow = 2),
         fill  = guide_legend(nrow = 2)) +
  xlim(0,1)

ggplot(diet.df, aes(x = Month, y = propDiet, color = species, fill = species)) +
  geom_boxplot()

# All of these are based on number of species per month/season
test <- aov(nSpecies ~ season, nSpec_samp)
summary(test)

month.test <- aov(nSpecies ~ Month, nSpec_samp)
summary(month.test)

library(dunn.test)
posthoc <- dunn.test(nSpec_samp$nSpecies, nSpec_samp$Month, list = TRUE)

posthoc_results <- data.frame(Comparison = posthoc$comparisons,
                              Z_Statistic = posthoc$Z,
                              P_adjusted = posthoc$P.adjusted) %>% 
  filter(P_adjusted < 0.05) %>% 
  separate(Comparison, into = c("Month1", "Month2"), sep = " - ") %>% 
  pivot_longer(Month1:Month2, names_to = "ComparisonLevel", values_to = "Month") %>% 
  group_by(Month) %>% 
  summarize(nSig = n())

ggplot(nSpec_samp, aes(x = Month, y = nSpecies)) +
  geom_boxplot() +
  geom_point(data = posthoc_results %>% filter(nSig > 8), 
             aes(x = Month, y = 7), color = "red", shape = 8, size = 5)

nSpecies.month <- diet.df %>% group_by(Month, season) %>% 
  filter(propDiet > 0) %>% 
  distinct(species) %>% 
  summarize(nSpecies = n()) 

nSpecies.season <- diet.df %>% 
  group_by(season) %>% 
  filter(propDiet > 0) %>% 
  distinct(species) %>% 
  summarize(nSpecies = n())

