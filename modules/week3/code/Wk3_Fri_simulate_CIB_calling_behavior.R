library(tidyverse)
library(ggsci)

data <- expand_grid(encounter = seq(1:10), minute = seq(1:60)) %>% 
  mutate(calf = case_when(encounter %in% c(1,2,4,8,9)~"yes",TRUE~"no")) %>% 
  mutate(behavior = c(rep(c("feeding/social", "travel"), each = 30, times = 5),
                      rep(c("travel", "feeding/social"), each = 30, times = 5))) %>% 
  mutate(timediff_transition = minute - 31) %>% 
  mutate(combined_call = case_when(calf == "yes" ~ rpois(600, lambda = 3), calf == "no" ~ 0)) %>% 
  mutate(whistle = case_when(behavior == "travel" ~ rpois(600, lambda = 10), 
                             behavior == "feeding/social" ~ rpois(600, lambda = 5),
                             TRUE ~ 0)) %>% 
  mutate(pulsed_call = case_when(behavior == "travel" ~ rpois(600, lambda = 5), 
                                 behavior == "feeding/social" ~ rpois(600, lambda = 10),
                                 TRUE ~ 0)) %>% 
  mutate(group_size = case_when(encounter == 1 ~ 20,
                                encounter == 2 ~ 13,
                                encounter == 3 ~ 48,
                                encounter == 4 ~ 33,
                                encounter == 5 ~ 25,
                                encounter == 6 ~ 29,
                                encounter == 7 ~ 31,
                                encounter == 8 ~ 42,
                                encounter == 9 ~ 35,
                                encounter == 10 ~ 29))


# make calls happen around the behavioral transition -------------------
set.seed(123)  # For reproducibility

# Parameters
total_minutes <- 60
num_encounters <- 10

# Preallocate list to hold each encounter
calls <- data.frame()

for (i in 1:num_encounters) {
  # Randomize start, peak, and end within ±2 minutes
  start_min <- 14 + sample(-1:6, 1)
  peak_min  <- 28 + sample(-4:2, 1)
  end_min   <- 34 + sample(-2:2, 1)
  
  # Ensure values are in valid ranges and logical order
   start_min <- max(1, start_min)
   end_min   <- min(total_minutes, end_min)
   peak_min  <- min(max(start_min + 1, peak_min), end_min - 1)
  
  # Determine mean call count for each call type
  mean_pulsedCalls <- if (i <= 5) 300 else 100
  mean_whistles <- if (i <= 5) 100 else 200
  mean_cc <- 30
  
  # Initialize calls vectors
  pulsedCalls <- rep(0, total_minutes)
  whistles <- rep(0, total_minutes)
  cc <- rep(0, total_minutes)
  
  # Generate Gaussian shape for active period
  active_minutes <- start_min:end_min
  
  if (length(active_minutes)/2 == 0) {
    active_minutes <- active_minutes
  } else {
    active_minutes <- active_minutes[2:length(active_minutes)]
  }
  
  pc_amplitudes <- round(dnorm(seq(-(length(active_minutes))/2,length(active_minutes)/2,1), 
                           mean = 0, sd = 3)*mean_pulsedCalls)
  w_amplitudes <- round(dnorm(seq(-(length(active_minutes))/2,length(active_minutes)/2,1), 
                            mean = 0, sd = 3)*mean_whistles)
  cc_amplitudes <- round(dnorm(seq(-(length(active_minutes))/2,length(active_minutes)/2,1), 
                            mean = 0, sd = 1)*mean_cc)
  
  # Add Poisson noise
  poisNoisy_pulsedCalls <- pmin(rpois(length(pc_amplitudes), lambda = pc_amplitudes), mean_pulsedCalls)
  poisNoisy_whistles <- pmin(rpois(length(w_amplitudes), lambda = w_amplitudes), mean_whistles)
  poisNoisy_cc <- pmin(rpois(length(cc_amplitudes), lambda = cc_amplitudes), mean_cc)
  
  # optional: Gaussian noise instead of Poisson noise
  #gausNoisy_pulsedCalls <- round(pc_amplitudes + rnorm(length(pc_amplitudes), mean = 0, sd = 0.5))
  #noisy_calls <- pmax(0, pmin(noisy_calls, max_calls))  # ensure 0 to max_calls
  
  # Insert into call vectors
  pulsedCalls[active_minutes] <- poisNoisy_pulsedCalls
  whistles[active_minutes] <- poisNoisy_whistles
  
  # For combined calls, set the encounters with 0 calls
  nocc_encounters <- c(3, 5, 6, 7, 10)
  
  if (i %in% nocc_encounters) {
    cc
  } else { 
    cc[active_minutes] <- poisNoisy_cc 
  }
  
  # Store encounter
  tempCalls <- cbind(pulsedCalls, whistles, cc)
  calls <- rbind(calls, tempCalls)
  
}

# add new rows to data ---------------------------------------------------------

data_update <- data %>% 
  select(-whistle, -pulsed_call, -combined_call) %>% 
  bind_cols(calls) %>% 
  rename("combined_call" = cc, "whistle" = whistles,
         "pulsed_call" = pulsedCalls)
    
write.csv(data_update, "CIB_calling_behavior.csv")






