library(here)
i_am("R/models/logistic_regression.R")
source(here("R", "00_packages.R"))
source(here("R", "recipes", "linear_distance_recipe.R"))

dir.create(here("artifacts"), recursive = TRUE, showWarnings = FALSE)

adult_folds <- readRDS(here("data", "processed", "cv_folds.rds"))

logistic_spec <- logistic_reg() |>
  set_engine("glm") |>
  set_mode("classification")

logistic_workflow <- workflow() |>
  add_recipe(linear_distance_recipe) |>
  add_model(logistic_spec)

set.seed(project_seed)
logistic_resamples <- fit_resamples(
  logistic_workflow,
  resamples = adult_folds,
  metrics = classification_metrics,
  control = control_resamples(save_pred = TRUE, save_workflow = TRUE)
)

saveRDS(
  list(
    model_name = "Logistic Regression",
    workflow = logistic_workflow,
    resamples = logistic_resamples,
    tuned = FALSE
  ),
  here("artifacts", "logistic_regression.rds")
)

