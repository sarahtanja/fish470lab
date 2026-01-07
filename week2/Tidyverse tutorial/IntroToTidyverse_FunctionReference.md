# Week 2: Tidyverse Function Reference

This document lists all the functions introduced in the Intro To Tidyverse tutorial with a brief explanation for each one.

## Data Import Functions

### `read_csv()`
**Package:** readr 
**Purpose:** Reads a comma-separated values (CSV) file into R as a dataframe.  
**Example:** `search_data <- read_csv("GoogleTrends_timeline.csv", col_names = TRUE)`

## Pipe Operator

### `%>%`
**Package:** magrittr (loaded with tidyverse) 
**Purpose:** Pipe operator that takes the output from one function and sends it as input to the next function, allowing for cleaner, more readable code. 
**Example:** `data %>% function1() %>% function2()`

## Data Wrangling Functions (tidyr)

### `separate()`
**Package:** tidyr 
**Purpose:** Separates one column into multiple columns based on a delimiter (separator). 
**Example:** `separate(Month, into = c("year", "month"), sep = "-", remove = FALSE)`

### `pivot_longer()`
**Package:** tidyr 
**Purpose:** Converts data from "wide" format to "long" format by gathering multiple columns into key-value pairs. 
**Example:** `pivot_longer(gardens:ice_skating, names_to = "search_type", values_to = "nSearches")`

## Data Manipulation Functions (dplyr)

### `rename()`
**Package:** dplyr 
**Purpose:** Changes the names of columns in a dataframe to new names. 
**Example:** `rename("gardens" = `gardens: (United States)`, "date" = Month)`

### `mutate()`
**Package:** dplyr 
**Purpose:** Creates new columns or modifies existing columns in a dataframe. 
**Example:** `mutate(date = ym(date))` or `mutate(nSearches = nSearches - mean(nSearches))`

### `group_by()`
**Package:** dplyr 
**Purpose:** Groups rows in a dataframe by one or more variables so that subsequent operations are performed on each group separately. 
**Example:** `group_by(search_type)` or `group_by(search_type, month)`

### `ungroup()`
**Package:** dplyr 
**Purpose:** Removes grouping from a dataframe. Always use this after you're done with grouped operations. 
**Example:** `ungroup()`

### `summarise()` / `summarize()`
**Package:** dplyr 
**Purpose:** Creates summary statistics for groups of data, reducing multiple rows into a single summary row per group. 
**Example:** `summarise(mean_searches = mean(nSearches))`

### `slice_max()`
**Package:** dplyr 
**Purpose:** Selects the rows with the highest values of a specified variable. 
**Example:** `slice_max(mean_searches)`

### `filter()`
**Package:** dplyr 
**Purpose:** Selects rows from a dataframe that meet specified conditions. 
**Example:** `filter(month %in% c("05","01"))` or `filter(search_type == "gardens")` or `filter(search_type == "ice_skating")`

## Date/Time Functions (lubridate)

### `ym()`
**Package:** lubridate 
**Purpose:** Parses dates that are in year-month format and converts them to Date objects that R can understand chronologically. 
**Example:** `mutate(date = ym(date))`

## Data Visualization Functions (ggplot2)

### `ggplot()`
**Package:** ggplot2 
**Purpose:** Initializes a ggplot object and creates a plotting environment for building layered visualizations. 
**Example:** `ggplot()`

### `geom_line()`
**Package:** ggplot2 
**Purpose:** Adds a line layer to a ggplot, connecting data points with lines. 
**Example:** `geom_line(aes(x = date, y = gardens), color = "purple")`

### `geom_point()`
**Package:** ggplot2 
**Purpose:** Adds a scatter plot layer to a ggplot, displaying individual data points. 
**Example:** `geom_point(aes(x = as.numeric(month), y = nSearches, color = search_type))`

### `theme_minimal()`
**Package:** ggplot2 
**Purpose:** Applies a minimal theme to the plot, creating a cleaner look and feel with less visual clutter. 
**Example:** `theme_minimal()`

### `xlab()`
**Package:** ggplot2 
**Purpose:** Sets or modifies the label for the x-axis. 
**Example:** `xlab("month")`

### `ylab()`
**Package:** ggplot2 
**Purpose:** Sets or modifies the label for the y-axis. 
**Example:** `ylab("Number of searches")`

### `scale_color_manual()`
**Package:** ggplot2 
**Purpose:** Manually sets the color palette for color-mapped variables in the plot. 
**Example:** `scale_color_manual(values = c("purple", "cornflowerblue"))`

## Statistical Analysis Functions

### `aov()`
**Package:** base R (stats) 
**Purpose:** Fits an Analysis of Variance (ANOVA) model to test whether differences between groups are statistically significant. 
**Example:** `aov(formula = nSearches ~ month, data = maxmin_gardens)`

## Additional Notes

- The `aes()` function is used within ggplot2 geometry functions to map variables to visual properties (aesthetics) like x, y, color, etc.
- The `summary()` function is used to view results from statistical models like ANOVA.
- Functions like `as.numeric()` are used for type conversion when needed.
