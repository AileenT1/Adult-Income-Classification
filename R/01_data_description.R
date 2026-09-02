library(here)
i_am("R/01_data_description.R")
source(here("R", "00_packages.R"))

dir.create(here("data", "processed"), recursive = TRUE, showWarnings = FALSE)

adult_raw <- read_csv(
  here("data", "adult.csv"),
  na = "?",
  show_col_types = FALSE
) |>
  clean_names()

expected_columns <- c(
  "age", "workclass", "fnlwgt", "education", "education_num",
  "marital_status", "occupation", "relationship", "race", "sex",
  "capital_gain", "capital_loss", "hours_per_week", "native_country",
  "income"
)

if (!identical(names(adult_raw), expected_columns)) {
  stop("The raw Adult data columns do not match the expected schema.", call. = FALSE)
}

variable_table <- tibble(
  variable = expected_columns,
  type = map_chr(adult_raw, ~ class(.x)[1]),
  role = c(
    "Predictor", "Predictor", "Excluded", "Excluded", "Predictor",
    rep("Predictor", 9), "Outcome"
  ),
  description = c(
    "Age in years",
    "Employment sector or work arrangement",
    "Census final sampling weight",
    "Highest educational credential",
    "Ordered numeric encoding of education",
    "Marital status",
    "Occupation category",
    "Relationship to the household reference person",
    "Race category recorded in the Census data",
    "Sex category recorded in the Census data",
    "Annual capital gains in US dollars",
    "Annual capital losses in US dollars",
    "Usual hours worked per week",
    "Country of birth",
    "Whether annual income is at most or above $50,000"
  )
)

numeric_summary <- adult_raw |>
  select(where(is.numeric)) |>
  pivot_longer(everything(), names_to = "variable", values_to = "value") |>
  group_by(variable) |>
  summarise(
    n = sum(!is.na(value)),
    mean = mean(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE),
    minimum = min(value, na.rm = TRUE),
    q1 = quantile(value, 0.25, na.rm = TRUE),
    median = median(value, na.rm = TRUE),
    q3 = quantile(value, 0.75, na.rm = TRUE),
    maximum = max(value, na.rm = TRUE),
    .groups = "drop"
  )

categorical_counts <- adult_raw |>
  select(where(~ is.character(.x) || is.factor(.x))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "level") |>
  count(variable, level, name = "n", .drop = FALSE) |>
  group_by(variable) |>
  mutate(percent = n / sum(n)) |>
  ungroup()

outcome_summary <- adult_raw |>
  count(income, name = "n") |>
  mutate(percent = n / sum(n))

missing_summary <- adult_raw |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") |>
  mutate(percent_missing = n_missing / nrow(adult_raw))

data_description <- list(
  dimensions = dim(adult_raw),
  variable_table = variable_table,
  numeric_summary = numeric_summary,
  categorical_counts = categorical_counts,
  outcome_summary = outcome_summary,
  missing_summary = missing_summary,
  incomplete_rows = sum(!complete.cases(adult_raw)),
  duplicate_rows = sum(duplicated(adult_raw))
)

saveRDS(data_description, here("data", "processed", "data_description.rds"))

