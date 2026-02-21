# Load required libraries
library(fmsb)
library(tidyverse)
library(gridExtra)
library(RColorBrewer)
library(scales)
library(dplyr)

# Set working directory and parameters
base_dir <- getwd()
k <- 7
runs_str <- "run-ON"

# Load the CSV file
csv_file <- file.path(base_dir, 'plots', 'caps_radar_plots', 
                      paste0('cosine_similarity_summary_k', k, '.csv'))

similarity_df <- read.csv(csv_file)

str(similarity_df)

similarity_df <- similarity_df %>% 
  filter(Network!="Limbic")

# View the data structure
print(head(similarity_df))
print(str(similarity_df))

# Create output directory for R plots
output_dir <- file.path(base_dir, 'plots', 'caps_radar_plots', paste0('k', k, '_cosine'))
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

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
  
  # Add small buffer to max and ensure min is not negative (optional)
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
        width = 2000, height = 2000, res = 500)
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
             plwd = 3,
             plty = c(1, 1),  # Both solid lines
             cglcol = "lightgrey",
             cglty = 1,
             axislabcol = "black",
             caxislabels = axis_labels,  # Dynamic axis labels with correct 5-element format
             cglwd = 0.8,
             vlcex = 2,
             calcex = 1.2,  # Size of axis labels
             seg = 4,       # Number of segments (5 segments for 5 labels)
             #title = paste0("CAP ", cap_num)
  )
  
  if (save_plot) {
    dev.off()
  }
  
  # Create legend PNG at 500 DPI (only once, not for each CAP)
  if (cap_num == 1) {
    png(file.path(output_dir, 'radar_plot_legend_500dpi.png'), 
        width = 3000, height = 400, res = 500)
    
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

































######################################################################

# Load required libraries
library(fmsb)
library(tidyverse)
library(gridExtra)
library(RColorBrewer)
library(scales)
library(dplyr)

# Set working directory and parameters
base_dir <- getwd()
k <- 7
runs_str <- "run-ON"

# Load the CSV file
csv_file <- file.path(base_dir, 'plots', 'caps_radar_plots', 
                      paste0('mean_activation_posneg_summary_k7.csv'))

means_df <- read.csv(csv_file)

str(means_df)

means_df <- means_df %>% 
  filter(Network!="Limbic")

# View the data structure
print(head(means_df))
print(str(means_df))

# Create output directory for R plots
output_dir <- file.path(base_dir, 'plots', 'caps_radar_plots', paste0('k7_mean_activation_pos_neg'))
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

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
  
  # Add small buffer to max and ensure min is not negative (optional)
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




























################################################################################

# Load required libraries
library(fmsb)
library(tidyverse)
library(gridExtra)
library(RColorBrewer)
library(scales)
library(dplyr)

# Set working directory and parameters
base_dir <- getwd()
k <- 7
runs_str <- "run-ON"

# Load the CSV file (updated for mean activation data)
csv_file <- file.path(base_dir, 'plots', 'caps_radar_plots', 
                      paste0('mean_activation_summary_k', k, '.csv'))

activation_df <- read.csv(csv_file)

str(activation_df)

activation_df <- activation_df %>% 
  filter(Network!="Limbic")

# View the data structure
print(head(activation_df))
print(str(activation_df))

# Create output directory for R plots
output_dir <- file.path(base_dir, 'plots', 'caps_radar_plots', paste0('k', k, '_mean_activation'))
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Define colors for mean activation
color_mean <- alpha("#2E8B57", 0.3)  # Sea green with transparency
color_mean_line <- "#2E8B57"         # Sea green solid

# Calculate data range for consistent scaling across all CAPs
data_range <- range(activation_df$Mean_Activation, na.rm = TRUE)
max_val <- max(abs(data_range))
axis_max <- ceiling(max_val * 10) / 10  # Round up to nearest 0.1
axis_min <- -axis_max

# Function to create radar plot for a single CAP
create_cap_radar <- function(cap_num, activation_df, save_plot = TRUE) {
  
  # Filter data for this CAP
  cap_data <- activation_df %>%
    filter(CAP == paste0('CAP ', cap_num))
  
  network_order <- c('THA', 'DMN', 'SMN', 'VN', 'FPN', 'DAN', 'VAN', 'CER', 'SUB')
  
  mean_data <- cap_data %>%
    select(Network, Mean_Activation) %>%
    pivot_wider(names_from = Network, values_from = Mean_Activation) %>%
    select(all_of(network_order))
  
  # Prepare radar data (max, min, mean activation)
  # Note: For radar charts, we need positive values, so we'll shift the data
  # by adding the absolute minimum to make all values positive
  shift_amount <- abs(axis_min)
  shifted_max <- axis_max + shift_amount
  shifted_min <- 0
  
  radar_data <- rbind(
    rep(shifted_max, length(network_order)),  # Max (shifted)
    rep(shifted_min, length(network_order)),  # Min (shifted)
    as.numeric(mean_data[1, ]) + shift_amount # Mean activations (shifted)
  )
  
  radar_data <- as.data.frame(radar_data)
  colnames(radar_data) <- network_order
  rownames(radar_data) <- c("Max", "Min", "Mean")
  
  if (save_plot) {
    svg(file.path(output_dir, paste0('CAP', cap_num, '_radar_plot_R.svg')), 
        width = 4, height = 4)  # Width and height in inches for SVG
  }
  
  par(mar = c(0, 0, 1, 0))
  
  # Create axis labels that reflect the original scale
  n_segments <- 4
  tick_values <- seq(axis_min, axis_max, length.out = n_segments + 1)
  axis_labels <- c('', format(tick_values[2], digits = 2), 
                   format(tick_values[3], digits = 2), 
                   format(tick_values[4], digits = 2), 
                   format(tick_values[5], digits = 2))
  
  # Plot mean activations
  radarchart(radar_data,
             axistype = 1,
             pcol = color_mean_line,
             pfcol = color_mean,
             plwd = 3,
             plty = 1,
             cglcol = "lightgrey",
             cglty = 1,
             axislabcol = "black",
             caxislabels = axis_labels,
             cglwd = 0.8,
             vlcex = 1.5,
             calcex = 1.2,
             seg = n_segments
  )
  
  if (save_plot) {
    dev.off()
  }
  
  # Print summary statistics for this CAP
  cat(paste0("CAP ", cap_num, " - Mean activation range: ", 
             round(min(mean_data), 4), " to ", round(max(mean_data), 4), "\n"))
}

# Create individual radar plots for each CAP
for (i in 1:k) {
  create_cap_radar(i, activation_df)
  cat(paste0("Created radar plot for CAP ", i, "\n"))
}

# Create legend PNG at 500 DPI
png(file.path(output_dir, 'radar_plot_legend_500dpi.png'), 
    width = 2000, height = 400, res = 500)

# Create an empty plot for the legend
par(mar = c(0, 0, 0, 0))
plot.new()

# Add legend in the center
legend(x = "center", 
       legend = "Mean Activation",
       bty = "n",
       pch = 20,
       lty = 1,
       lwd = 10,
       col = color_mean_line,
       cex = 1.5,
       pt.cex = 1.5,
       horiz = FALSE)

dev.off()

# Print overall summary statistics
cat("\nOverall Summary Statistics:\n")
cat(paste0("Global mean activation: ", round(mean(activation_df$Mean_Activation), 4), "\n"))
cat(paste0("Global std deviation: ", round(sd(activation_df$Mean_Activation), 4), "\n"))
cat(paste0("Global range: ", round(min(activation_df$Mean_Activation), 4), 
           " to ", round(max(activation_df$Mean_Activation), 4), "\n"))

# Create a summary table showing mean activation by network across all CAPs
network_summary <- activation_df %>%
  group_by(Network) %>%
  summarise(
    Mean_Activation = mean(Mean_Activation),
    SD_Activation = sd(Mean_Activation),
    Min_Activation = min(Mean_Activation),
    Max_Activation = max(Mean_Activation),
    .groups = 'drop'
  ) %>%
  arrange(desc(Mean_Activation))

print("Mean activation by network (averaged across all CAPs):")
print(network_summary)






# # Create a summary heatmap
# library(ggplot2)
# library(viridis)
# 
# # Reshape data for heatmap
# heatmap_data <- similarity_df %>%
#   pivot_longer(cols = c(Positive_Cosine_Similarity, Negative_Cosine_Similarity),
#                names_to = "Type",
#                values_to = "Cosine_Similarity") %>%
#   mutate(Type = ifelse(Type == "Positive_Cosine_Similarity", "Positive", "Negative"))
# 
# # Create heatmap
# p_heatmap <- ggplot(heatmap_data, aes(x = Network, y = CAP, fill = Cosine_Similarity)) +
#   geom_tile() +
#   facet_wrap(~ Type, ncol = 2) +
#   scale_fill_viridis_c(name = "Cosine\nSimilarity") +
#   theme_minimal() +
#   theme(axis.text.x = element_text(angle = 45, hjust = 1),
#         axis.text = element_text(size = 12),
#         axis.title = element_text(size = 14),
#         strip.text = element_text(size = 14),
#         legend.title = element_text(size = 12),
#         legend.text = element_text(size = 10)) +
#   labs(title = paste0("Network Cosine Similarity Heatmap (k=", k, ")"),
#        x = "Network",
#        y = "CAP")
# 
# # Save heatmap
# ggsave(file.path(output_dir, paste0('CAP_network_similarity_heatmap_k', k, '.png')),
#        p_heatmap, width = 12, height = 8, dpi = 300)
# 
# # Print summary statistics
# cat("\n=== Summary Statistics ===\n")
# summary_stats <- similarity_df %>%
#   group_by(CAP) %>%
#   summarise(
#     Max_Positive_Network = Network[which.max(Positive_Cosine_Similarity)],
#     Max_Positive_Value = max(Positive_Cosine_Similarity),
#     Max_Negative_Network = Network[which.max(Negative_Cosine_Similarity)],
#     Max_Negative_Value = max(Negative_Cosine_Similarity)
#   )
# 
# print(summary_stats)
# 
# cat(paste0("\nAll plots saved in: ", output_dir, "\n"))