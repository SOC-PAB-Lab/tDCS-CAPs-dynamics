################################################################################
# 04_plot_caps_occ_dt.R
#
# Plots CAP occurrence rate and dwell time across tDCS sessions (Sham,
# Unilateral, Bilateral). Produces two figure types:
#   1. Paired line plots for CAP4 (Sham vs. Unilateral; Sham vs. Bilateral)
#   2. Box plots with jittered points for all CAPs (occurrence rate & dwell time)
# Outputs are saved to results/main_figures/05_caps_occ_dt/
################################################################################

library(dotenv)
library(dplyr)
library(knitr)
library(ggpubr)
library(rstatix)
library(ggplot2)
library(tidyr)
library(tidyverse)
library(patchwork)
library(RColorBrewer)

load_dot_env(file = "../.env")

BASE_DIR    <- Sys.getenv("BASE_DIR")
RESULTS_DIR <- Sys.getenv("RESULTS_DIR")

INPUT_DIR        <- file.path(BASE_DIR)
PLOTS_OUTPUT_DIR <- file.path(RESULTS_DIR, "main_figures", "05_caps_occ_dt")

dir.create(PLOTS_OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)


prepare_df_only_on <- function(file_path) {
  # Read data from the provided file path
  data <- read.csv(file_path)

  # Clean up columns: remove original session/run and rename _name columns
  data <- data %>%
    select(-session, -run) %>%
    rename(session = session_name, run = run_name)

  # Filter to include only "On" data
  data_on <- data %>% filter(run == "tDCS On")

  # Convert factors with proper reference levels
  data_on$session <- factor(data_on$session, levels = c("Sham", "Unilateral", "Bilateral"))
  data_on$subject <- factor(data_on$subject)
  return(data_on)
}

# Function to create paired comparison plots (simplified - removed increasers/decreasers)
create_paired_plot <- function(data, condition1, condition2, title, capX, data_type) {
  # Validate capX parameter
  cap_col <- paste0("CAP", capX)
  if (!cap_col %in% colnames(data)) {
    stop(paste("Column", cap_col, "does not exist in the dataset"))
  }

  # Filter data for the two conditions
  filtered_data <- data %>%
    filter(session %in% c(condition1, condition2))

  # Create a dataset for paired connections
  paired_data <- filtered_data %>%
    select(subject, session, all_of(cap_col)) %>%
    pivot_wider(names_from = session, values_from = all_of(cap_col))

  # Calculate means for each condition
  mean_values <- filtered_data %>%
    group_by(session) %>%
    summarize(cap_value = mean(get(cap_col)))

  # Convert the paired data back to long format for plotting
  long_data <- paired_data %>%
    pivot_longer(cols = c(all_of(condition1), all_of(condition2)),
                 names_to = "session",
                 values_to = "cap_value") %>%
    mutate(session = factor(session, levels = c(condition1, condition2)))

  # Create consistent y-axis labels with CAP number
  if (data_type == "occurrence") {
    y_label <- paste0("CAP", capX, " Occurrence Rate")
  } else if (data_type == "dwelltime") {
    y_label <- paste0("CAP", capX, " Dwell Time")
  } else {
    y_label <- "Value"
  }

  # Single color for all lines (removed increasers/decreasers distinction)
  line_color <- "gray60"

  # Create the plot
  p <- ggplot() +
    # Add individual subject lines
    geom_line(data = long_data,
              aes(x = session, y = cap_value, group = subject),
              color = line_color, size = 1.0, alpha = 0.7) +
    # Add points at each data point
    geom_point(data = long_data,
               aes(x = session, y = cap_value, group = subject),
               color = line_color, size = 2.5, fill = "white", shape = 21, stroke = 1.2) +
    # Add the mean line
    geom_line(data = mean_values %>%
                mutate(session = factor(session, levels = c(condition1, condition2))),
              aes(x = session, y = cap_value, group = 1),
              color = "black", size = 1.8) +
    # Add points for mean values
    geom_point(data = mean_values %>%
                 mutate(session = factor(session, levels = c(condition1, condition2))),
               aes(x = session, y = cap_value, group = 1),
               color = "black", size = 4.5, shape = 16) +
    # Labels and theme
    labs(x = "",
         y = y_label,
         title = title) +
    theme_minimal() +
    theme(legend.position = "none",
          plot.title = element_text(size = 14, hjust = 0.5),
          axis.title.x = element_text(size = 12),
          axis.title.y = element_text(size = 16),
          axis.text = element_text(size = 14),
          axis.line = element_line(color = "black", size = 0.5),
          panel.border = element_blank(),
          panel.background = element_rect(fill = "transparent", color = NA))

  return(p)
}

# Function to create and save plots for CAP4 only
create_cap4_plots <- function(k) {
  # Create directory for plots if it doesn't exist
  plot_dir <- file.path(PLOTS_OUTPUT_DIR, "CAP4_paired_data")
  dir.create(plot_dir, recursive = TRUE, showWarnings = FALSE)

  # Define file paths
  occ_file_path <- file.path(INPUT_DIR, "caps_dynamics_run-ON",
                             paste0("caps_nclust-", k),
                             "CAP_occurence_times.csv")
  dt_file_path <- file.path(INPUT_DIR, "caps_dynamics_run-ON",
                            paste0("caps_nclust-", k),
                            "CAP_dwelltime.csv")

  # Load data
  df_occ <- prepare_df_only_on(occ_file_path)
  df_dt <- prepare_df_only_on(dt_file_path)

  # Define conditions to compare
  comparisons <- list(
    c("Sham", "Unilateral", "Sham vs. Unilateral"),
    c("Sham", "Bilateral", "Sham vs. Bilateral"),
    c("Unilateral", "Bilateral", "Unilateral vs. Bilateral")
  )

  # Only process CAP4
  cap_num <- 4
  cap_col <- paste0("CAP", cap_num)

  # Find global min and max values for CAP4 across both data types and all conditions
  occ_values <- df_occ %>%
    filter(session %in% c("Sham", "Unilateral", "Bilateral")) %>%
    pull(cap_col)

  dt_values <- df_dt %>%
    filter(session %in% c("Sham", "Unilateral", "Bilateral")) %>%
    pull(cap_col)

  # Calculate separate y-axis ranges for each data type
  occ_min <- min(occ_values, na.rm = TRUE)
  occ_max <- max(occ_values, na.rm = TRUE)
  occ_range <- occ_max - occ_min
  occ_min <- occ_min - 0.05 * occ_range
  occ_max <- occ_max + 0.05 * occ_range

  dt_min <- min(dt_values, na.rm = TRUE)
  dt_max <- max(dt_values, na.rm = TRUE)
  dt_range <- dt_max - dt_min
  dt_min <- dt_min - 0.05 * dt_range
  dt_max <- dt_max + 0.05 * dt_range

  # Create occurrence rate plots
  occ_plots <- list()
  for (i in 1:length(comparisons)) {
    comp <- comparisons[[i]]
    condition1 <- comp[1]
    condition2 <- comp[2]

    plot <- create_paired_plot(df_occ, condition1, condition2, "", capX = cap_num, data_type = "occurrence")

    # Remove y-axis title from all but the first plot
    if (i >= 2) {
      plot <- plot + labs(y = "") +
        theme(axis.text.y = element_text(margin = margin(l = 10)))
    }

    occ_plots[[i]] <- plot + ylim(occ_min, occ_max)
  }

  # Create dwell time plots
  dt_plots <- list()
  for (i in 1:length(comparisons)) {
    comp <- comparisons[[i]]
    condition1 <- comp[1]
    condition2 <- comp[2]

    plot <- create_paired_plot(df_dt, condition1, condition2, "", capX = cap_num, data_type = "dwelltime")

    # Remove y-axis title from all but the first plot
    if (i >= 2) {
      plot <- plot + labs(y = "") +
        theme(axis.text.y = element_text(margin = margin(l = 10)))
    }

    dt_plots[[i]] <- plot + ylim(dt_min, dt_max)
  }


  combined_plot_uni <- occ_plots[[1]] / dt_plots[[1]]
  print(combined_plot_uni)

  combined_plot_uni_filename <- file.path(plot_dir, paste0("CAP", cap_num, "_combined_uni_sham.png"))
  ggsave(combined_plot_uni_filename, combined_plot_uni, width = 3, height = 8, dpi = 400, bg = "transparent")

  combined_plot_bi <- occ_plots[[2]] / dt_plots[[2]]
  print(combined_plot_bi)
  combined_plot_bi_filename <- file.path(plot_dir, paste0("CAP", cap_num, "_combined_bi_sham.png"))
  ggsave(combined_plot_bi_filename, combined_plot_bi, width = 3, height = 8, dpi = 400, bg = "transparent")

  combined_plot_uni_bi <- occ_plots[[3]] / dt_plots[[3]]
  print(combined_plot_uni_bi)
  combined_plot_uni_bi_filename <- file.path(plot_dir, paste0("CAP", cap_num, "_combined_uni_bi.png"))
  ggsave(combined_plot_uni_bi_filename, combined_plot_uni_bi, width = 3, height = 8, dpi = 400, bg = "transparent")

  return(list(uni = combined_plot_uni, bi = combined_plot_bi, uni_bi = combined_plot_uni_bi))
}

# Function to create and save box plots for CAP4 
create_cap4_boxplots <- function(k) {
  plot_dir <- file.path(PLOTS_OUTPUT_DIR)
  dir.create(plot_dir, recursive = TRUE, showWarnings = FALSE)

  occ_file_path <- file.path(INPUT_DIR, "caps_dynamics_run-ON",
                             paste0("caps_nclust-", k),
                             "CAP_occurence_times.csv")
  dt_file_path <- file.path(INPUT_DIR, "caps_dynamics_run-ON",
                            paste0("caps_nclust-", k),
                            "CAP_dwelltime.csv")

  df_occ <- prepare_df_only_on(occ_file_path)
  df_dt  <- prepare_df_only_on(dt_file_path)

  make_cap4_boxplot <- function(data_on, data_type) {
    data_on$session <- factor(data_on$session, levels = c("Unilateral", "Bilateral", "Sham"))

    cap_cols <- grep("^CAP\\d+$", colnames(data_on), value = TRUE)
    data_long <- data_on %>%
      pivot_longer(cols = all_of(cap_cols), names_to = "CAP", values_to = "value")

    p2 <- ggplot(data_long, aes(x = CAP, y = value, fill = session)) +
      geom_boxplot(position = position_dodge(width = 0.8),
                   width = 0.7,
                   alpha = 0.7) +
      scale_fill_manual(values = c("Unilateral" = "#e3d54a", "Bilateral" = "#da4f33", "Sham" = "#66a6ba")) +
      geom_point(
        aes(fill = session),
        position = position_jitterdodge(dodge.width = 0.8, jitter.width = 0.2),
        shape = 21,
        size = 1.5,
        alpha = 0.6,
        stroke = 0.5,
        color = "black",
        show.legend = FALSE
      ) +
      labs(
        title = "",
        x = "",
        y = paste("\n\n", data_type),
        fill = "Session"
      ) +
      theme_minimal() +
      theme(
        legend.position = "none",
        plot.title = element_text(face = "bold", size = 20),
        plot.subtitle = element_text(size = 20),
        axis.text = element_text(size = 16),
        axis.title = element_text(size = 18),
        legend.title = element_text(face = "bold", size = 18),
        axis.title.y = element_text(margin = margin(r = 15)),
        legend.text = element_text(size = 16),
        strip.text = element_text(face = "bold", size = 18),
        panel.grid.major.x = element_blank(),
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA),
        axis.line = element_line(color = "black", size = 0.5),
        panel.border = element_blank()
      )
    return(p2)
  }

  bp_occ <- make_cap4_boxplot(df_occ, "Occurrence Rate")
  bp_dt  <- make_cap4_boxplot(df_dt,  "Dwell Time")

  ggsave(file.path(plot_dir, "R_box_plot_only_on_occ_rate.png"),
         bp_occ, width = 9, height = 4, dpi = 400)
  ggsave(file.path(plot_dir, "R_box_plot_only_on_dwell_time.png"),
         bp_dt,  width = 9, height = 4, dpi = 400)

  combined_bp <- bp_occ / bp_dt
  print(combined_bp)
  ggsave(file.path(plot_dir, "box_plot_combined_dwell_occurrence.png"),
         combined_bp, width = 9, height = 8, dpi = 400)

  return(list(occ = bp_occ, dt = bp_dt, combined = combined_bp))
}

# Set the k value and run the analysis
k <- 7
combined_plot <- create_cap4_plots(k)
cap4_boxplots <- create_cap4_boxplots(k)
