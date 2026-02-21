# =============================================================
# Radar plots of CAP network activation profiles
#
# Reads per-network mean activation summary CSVs (output of the
# Python CAPs pipeline) and saves radar chart PNGs/SVGs for each
# CAP to results/main_figures/02_radar_figs/.
#
# Paths are read from the project .env file (BASE_DIR, RESULTS_DIR).
# =============================================================

# Load required libraries
library(fmsb)
library(tidyverse)
library(gridExtra)
library(RColorBrewer)
library(scales)
library(dplyr)
library(dotenv)
load_dot_env()

######################################################################

# Set working directory and parameters
base_dir <- Sys.getenv("BASE_DIR")
results_dir <- Sys.getenv("RESULTS_DIR")
k <- 7
runs_str <- "run-ON"

# Load the CSV file
csv_file <- file.path(results_dir, 'main_figures', '02_radar_figs',
                      paste0('mean_activation_posneg_summary_k7.csv'))

means_df <- read.csv(csv_file)

str(means_df)

means_df <- means_df %>% 
  filter(Network!="Limbic")

# View the data structure
print(head(means_df))
print(str(means_df))

# Create output directory for R plots
output_dir <- file.path(results_dir, 'main_figures', '02_radar_figs')
#dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Define colors
color_positive <- alpha("#cd0000", 0.3)
color_negative <- alpha("#0000cd", 0.3)
color_positive_line <- "#cd0000"
color_negative_line <- "#0000cd"

# Function to create radar plot for a single CAP
create_cap_radar <- function(cap_num, similarity_df, save_plot = TRUE) {
  
  # Filter data for this CAP
  cap_data <- similarity_df %>%
    filter(CAP == paste0('CAP ', cap_num))
  
  network_order <- c('THA', 'DMN', 'SMN', 'VN', 'FPN', 'DAN', 'VAN', 'CER', 'SUB')
  
  positive_data <- cap_data %>%
    select(Network, Mean_Positive_Activation) %>%
    pivot_wider(names_from = Network, values_from = Mean_Positive_Activation) %>%
    select(all_of(network_order))
  
  negative_data <- cap_data %>%
    select(Network, Mean_Negative_Activation) %>%
    pivot_wider(names_from = Network, values_from = Mean_Negative_Activation) %>%
    select(all_of(network_order))
  
  # Calculate CAP-specific max and min values
  positive_values <- as.numeric(positive_data[1, ])
  negative_values <- as.numeric(negative_data[1, ])
  
  cap_max <- max(c(positive_values, negative_values), na.rm = TRUE)
  cap_min <- min(c(positive_values, negative_values), na.rm = TRUE)
  
  # Add small buffer to max and ensure min is not negative 
  cap_max <- cap_max * 1.1  # 10% buffer above max
  cap_min <- max(0, cap_min * 0.9)  # 10% buffer below min, but not negative
  
  # Prepare radar data (max, min, positive, negative)
  radar_data <- rbind(
    rep(cap_max, length(network_order)),  # CAP-specific Max
    rep(cap_min, length(network_order)),  # CAP-specific Min
    positive_values,
    negative_values
  )
  
  radar_data <- as.data.frame(radar_data)
  colnames(radar_data) <- network_order
  rownames(radar_data) <- c("Max", "Min", "Positive", "Negative")
  
  # Create the plot
  if (save_plot) {
    png(file.path(output_dir, paste0('CAP', cap_num, '_radar_plot_R.png')), 
        units='cm', width = 18, height = 16, res=400)  
  }
  
  par(mar = c(0, 0, 1, 0))
  
  # Calculate 5 axis labels: show values at positions 1, 3, 5; empty at 2, 4
  axis_range <- cap_max - cap_min
  axis_labels <- c(
    sprintf("%.2f", cap_min),                           # Position 1
    '',                                                 # Position 2 (empty)
    sprintf("%.2f", cap_min + axis_range * 0.5),       # Position 3 (middle)
    '',                                                 # Position 4 (empty)
    sprintf("%.2f", cap_max)                            # Position 5
  )
  
  # Plot both positive and negative activations together
  radarchart(radar_data,
             axistype = 1,
             pcol = c(color_positive_line, color_negative_line),
             #pfcol = c(color_positive, color_negative),
             plwd = 8,
             plty = c(1, 1),  # Both solid lines
             cglcol = "lightgrey",
             cglty = 1,
             axislabcol = "black",
             caxislabels = axis_labels,  # Dynamic axis labels with correct 5-element format
             cglwd = 0.8,
             vlcex = 4,
             calcex = 3,  # Size of axis labels
             seg = 4,       # Number of segments (5 segments for 5 labels)
             #title = paste0("CAP ", cap_num)
  )
  
  if (save_plot) {
    dev.off()
  }
  
  # Create legend SVG (only once, not for each CAP)
  if (cap_num == 1) {
    svg(file.path(output_dir, 'radar_plot_legend.svg'), 
        width = 6, height = 0.8)  # Smaller dimensions for legend only
    
    par(mar = c(0, 0, 0, 0))
    plot.new()
    
    legend(x = "center", 
           legend = c("High Amplitude Activation", "Low Amplitude Activation"),
           bty = "n",
           pch = 20,
           lty = c(1, 1),
           lwd = 10,
           col = c(color_positive_line, color_negative_line),
           cex = 1.5,
           pt.cex = 1.5,
           horiz = FALSE)
    
    dev.off()
  }
}

# Create individual radar plots for each CAP
for (i in 1:k) {
  create_cap_radar(i, means_df)
  cat(paste0("Created radar plot for CAP ", i, "\n"))
}