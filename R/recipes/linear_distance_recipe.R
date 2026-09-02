library(here)
i_am("R/recipes/linear_distance_recipe.R")
source(here("R", "00_packages.R"))

analysis_sets <- readRDS(here("data", "processed", "analysis_sets.rds"))

linear_distance_recipe <- recipe(income ~ ., data = analysis_sets$train) |>
  step_other(native_country, threshold = 0.01, other = "other_country") |>
  step_novel(all_nominal_predictors()) |>
  step_dummy(all_nominal_predictors(), one_hot = FALSE) |>
  step_zv(all_predictors()) |>
  step_normalize(all_numeric_predictors())

