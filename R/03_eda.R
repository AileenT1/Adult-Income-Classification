library(here)
i_am("R/03_eda.R")
source(here("R", "00_packages.R"))

dir.create(here("figures", "eda"), recursive = TRUE, showWarnings = FALSE)

adult_clean <- readRDS(here("data", "processed", "adult_clean.rds"))

income_summary <- adult_clean |>
  count(income, name = "n") |>
  mutate(percent = n / sum(n))

income_plot <- income_summary |>
  ggplot(aes(income, n, fill = income)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_text(
    aes(label = paste0(comma(n), " (", percent(percent, accuracy = 0.1), ")")),
    vjust = -0.4,
    fontface = "bold"
  ) +
  scale_fill_manual(values = income_colors) +
  scale_x_discrete(labels = c(high = "> $50K", not_high = "<= $50K")) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.12))) +
  labs(
    title = "Annual income is moderately imbalanced",
    x = "Income category",
    y = "Number of individuals"
  )

age_plot <- adult_clean |>
  ggplot(aes(age, fill = income, color = income)) +
  geom_density(alpha = 0.25, linewidth = 0.8) +
  scale_fill_manual(values = income_colors) +
  scale_color_manual(values = income_colors) +
  labs(
    title = "Age distributions differ across income groups",
    x = "Age (years)",
    y = "Density",
    fill = "Income",
    color = "Income"
  )

hours_plot <- adult_clean |>
  ggplot(aes(income, hours_per_week, fill = income)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.14, outlier.alpha = 0.08, fill = "white") +
  scale_fill_manual(values = income_colors, guide = "none") +
  scale_x_discrete(labels = c(high = "> $50K", not_high = "<= $50K")) +
  labs(
    title = "Weekly working hours by income category",
    x = "Income category",
    y = "Hours worked per week"
  )

education_summary <- adult_clean |>
  group_by(education_num) |>
  summarise(
    n = n(),
    high_income_rate = mean(income == "high"),
    .groups = "drop"
  )

education_plot <- education_summary |>
  ggplot(aes(education_num, high_income_rate)) +
  geom_line(color = "#0072B2", linewidth = 0.9) +
  geom_point(aes(size = n), color = "#D55E00", alpha = 0.85) +
  scale_x_continuous(breaks = 1:16) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_size_continuous(labels = comma) +
  labs(
    title = "Higher education levels are associated with higher income rates",
    x = "Education level (ordered numeric code)",
    y = "Proportion earning more than $50,000",
    size = "Individuals"
  )

occupation_summary <- adult_clean |>
  group_by(occupation) |>
  summarise(
    n = n(),
    high_income_rate = mean(income == "high"),
    .groups = "drop"
  ) |>
  mutate(occupation = fct_reorder(occupation, high_income_rate))

workclass_summary <- adult_clean |>
  group_by(workclass) |>
  summarise(
    n = n(),
    high_income_rate = mean(income == "high"),
    .groups = "drop"
  ) |>
  mutate(workclass = fct_reorder(workclass, high_income_rate))

occupation_plot <- occupation_summary |>
  ggplot(aes(high_income_rate, occupation)) +
  geom_segment(aes(x = 0, xend = high_income_rate, yend = occupation), color = "grey75") +
  geom_point(aes(size = n), color = "#0072B2") +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Occupation",
    x = "Proportion earning more than $50,000",
    y = NULL,
    size = "Individuals"
  )

workclass_plot <- workclass_summary |>
  ggplot(aes(high_income_rate, workclass)) +
  geom_segment(aes(x = 0, xend = high_income_rate, yend = workclass), color = "grey75") +
  geom_point(aes(size = n), color = "#D55E00") +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Workclass",
    x = "Proportion earning more than $50,000",
    y = NULL,
    size = "Individuals"
  )

employment_plot <- occupation_plot + workclass_plot +
  plot_annotation(title = "Income rates vary across employment categories")

capital_summary <- adult_clean |>
  mutate(
    capital_gain_status = if_else(capital_gain > 0, "Positive gain", "No gain"),
    capital_loss_status = if_else(capital_loss > 0, "Positive loss", "No loss")
  ) |>
  count(capital_gain_status, capital_loss_status, income, name = "n") |>
  group_by(capital_gain_status, capital_loss_status) |>
  mutate(rate = n / sum(n)) |>
  filter(income == "high") |>
  ungroup()

capital_plot <- capital_summary |>
  ggplot(aes(capital_gain_status, capital_loss_status, fill = rate)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = percent(rate, accuracy = 0.1)), fontface = "bold") +
  scale_fill_gradient(low = "#E5F5F9", high = "#D55E00", labels = percent) +
  labs(
    title = "High-income rate by capital gain and loss status",
    x = "Capital gain status",
    y = "Capital loss status",
    fill = "> $50K rate"
  )

plot_files <- list(
  income_distribution = income_plot,
  age_by_income = age_plot,
  hours_by_income = hours_plot,
  education_income_rate = education_plot,
  employment_income_rate = employment_plot,
  capital_income_patterns = capital_plot
)

iwalk(
  plot_files,
  ~ ggsave(
    here("figures", "eda", paste0(.y, ".png")),
    .x,
    width = if_else(.y == "employment_income_rate", 13, 9),
    height = if_else(.y == "employment_income_rate", 7, 5.5),
    dpi = 300
  )
)

eda_summaries <- list(
  income = income_summary,
  education = education_summary,
  occupation = occupation_summary,
  workclass = workclass_summary,
  capital = capital_summary
)

saveRDS(eda_summaries, here("data", "processed", "eda_summaries.rds"))

