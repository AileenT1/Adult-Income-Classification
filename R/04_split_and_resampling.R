library(here)
i_am("R/04_split_and_resampling.R")
source(here("R", "00_packages.R"))

adult_clean <- readRDS(here("data", "processed", "adult_clean.rds"))

set.seed(project_seed)
adult_split <- initial_split(adult_clean, prop = 0.80, strata = income)
adult_train <- training(adult_split)
adult_test <- testing(adult_split)

set.seed(project_seed)
adult_folds <- vfold_cv(adult_train, v = 10, strata = income)

split_proportions <- bind_rows(
  adult_train |> count(income) |> mutate(dataset = "Training"),
  adult_test |> count(income) |> mutate(dataset = "Testing")
) |>
  group_by(dataset) |>
  mutate(percent = n / sum(n)) |>
  ungroup()

analysis_sets <- list(
  split = adult_split,
  train = adult_train,
  test = adult_test,
  proportions = split_proportions,
  seed = project_seed
)

saveRDS(analysis_sets, here("data", "processed", "analysis_sets.rds"))
saveRDS(adult_folds, here("data", "processed", "cv_folds.rds"))

