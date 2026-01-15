#### Analyze calling behavior in Cook Inlet beluga whales
#### FISH 497B Evolutionary Ecology of Marine Mammals
#### Spring 2025

library(tidyverse)
library(PNWColors)
#install.packages("ggsci")
library(ggsci)

data <- read.csv("CIB_calling_behavior.csv")
  
# Let's do some initial data exploration--------------------------------------

# distribution of group sizes
ggplot(data = data, aes(x=group_size)) +
  geom_histogram(binwidth=10) +
  xlab("group size")

# distribution of number of combined calls
data %>% ggplot(aes(x=combined_call)) +
  geom_histogram(binwidth = 1) +
  xlab("# combined calls / minute")

# distribution of number of whistles
ggplot(data = data, aes(x=whistle)) +
  geom_histogram(binwidth = 1) +
  xlab("# whistles / minute")

# distribution of number of pulsed calls
ggplot(data = data, aes(x=pulsed_call)) +
  geom_histogram(binwidth = 1) +
  xlab("# pulsed calls / minute")


#Now let's compare with our behavior parameters----------------------------------

# pivot the dataframe so that we can compare all call types at once
data.long <- data %>% 
  pivot_longer(cols = c(combined_call,whistle,pulsed_call),names_to = "call", values_to = "num.call")

# Does the number of calls in each call type change with group size?
ggplot(data = data.long, aes(x = group_size, y = num.call, color = call, fill = call)) +
  geom_point() +
  theme_minimal()

# is that difference statistically significant?
lm.w <- lm(whistle ~ group_size, data = data)
summary(lm.w)

# Does the number of calls in each call type change with group behavior?

data.long %>% 
  filter(num.call > 0) %>% 
ggplot(aes(x = call, y = num.call, color = behavior, fill = behavior)) +
  geom_boxplot() +
  theme_minimal()

# is that difference statistically significant?
lm.w.behavior <- aov(whistle ~ behavior, data = data)
summary(lm.w.behavior)

lm.pc.behavior <- lm(pulsed_call ~ behavior, data = data)
summary(lm.pc.behavior)

#Does the number of calls in each call type change with calf presence?
ggplot(data = data.long, aes(x = call, y = num.call, color = calf, fill = calf)) +
  geom_violin() +
  theme_minimal()

# is that difference statistically significant?
lm.cc.calf <- lm(combined_call ~ calf, data = data)
summary(lm.cc.calf)

# Put it all together in one pretty visualization ------------------------------

data.long %>% 
  filter(num.call > 0) %>% 
ggplot(aes(x = call, y = num.call, color = behavior, fill = behavior)) +
  geom_boxplot() +
  theme_minimal() +
  facet_wrap(~calf) +
  scale_fill_aaas() +
  scale_color_aaas() +
  xlab("Call type") +
  ylab("Number of calls")

# Look at calling behavior approaching behavioral transition -------------------

data_update_long <- data %>% 
  pivot_longer(pulsed_call:combined_call, names_to = "call_type", values_to = "nCalls")

ggplot(data_update_long, aes(x = timediff_transition, y = nCalls, fill = call_type)) +
  geom_bar(stat = "identity") +
  facet_wrap(~encounter) +
  theme_minimal()

  lm_callsOverTime <- lm(nCalls ~ abs(timediff_transition), data = data_update_long)  
summary(lm_callsOverTime)

ggplot(data_update_long, aes(x = abs(timediff_transition), y = nCalls, 
                             color = call_type, fill = call_type)) +
  geom_jitter(size = 0.5) +
  theme_minimal() +
  geom_smooth() +   
  scale_x_reverse() +
  scale_fill_manual(values = pnw_palette("Shuksan")) +
  scale_color_manual(values = pnw_palette("Shuksan")) +
  xlab("Minutes to/from transition") +
  ylab("Number of calls")
  
