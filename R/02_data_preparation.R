library(here)
i_am("R/02_data_preparation.R")
source(here("R", "00_packages.R"))

dir.create(here("data", "processed"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("figures", "data_preparation"), recursive = TRUE, showWarnings = FALSE)

adult_raw <- read_csv(
  here("data", "adult.csv"),
  na = "?",
  show_col_types = FALSE
) |>
  clean_names()

missing_plot <- gg_miss_var(adult_raw, show_pct = TRUE) +
  labs(
    title = "Missing values in the raw Adult dataset",
    subtitle = "Question marks in the CSV were interpreted as missing values",
    x = NULL,
    y = "Number of missing observations"
  )

ggsave(
  here("figures", "data_preparation", "missingness.png"),
  missing_plot,
  width = 9,
  height = 5,
  dpi = 300
)

adult_clean <- adult_raw |>
  distinct() |>
  drop_na() |>
  mutate(
    income = factor(
      if_else(income == ">50K", "high", "not_high"),
      levels = c("high", "not_high")
    ),
    across(
      c(
        workclass, marital_status, occupation, relationship,
        race, sex, native_country
      ),
      factor
    )
  ) |>
  select(
    income, age, workclass, education_num, marital_status, occupation,
    relationship, race, sex, capital_gain, capital_loss, hours_per_week,
    native_country
  )

if (nrow(adult_clean) != 30139) {
  stop("Expected 30,139 complete unique records after cleaning.", call. = FALSE)
}

if (anyNA(adult_clean)) {
  stop("The cleaned modeling data still contain missing values.", call. = FALSE)
}

if (!identical(levels(adult_clean$income), c("high", "not_high"))) {
  stop("Income factor levels are not in the required event order.", call. = FALSE)
}

write_csv(adult_clean, here("data", "processed", "adult_clean.csv"))
saveRDS(adult_clean, here("data", "processed", "adult_clean.rds"))

cleaning_summary <- tibble(
  stage = c(
    "Raw observations",
    "Rows with at least one missing value",
    "Exact duplicate raw rows",
    "Complete unique modeling observations"
  ),
  n = c(
    nrow(adult_raw),
    sum(!complete.cases(adult_raw)),
    sum(duplicated(adult_raw)),
    nrow(adult_clean)
  )
)

saveRDS(cleaning_summary, here("data", "processed", "cleaning_summary.rds"))

