library(here)
i_am("R/models/lda.R")
source(here("R", "00_packages.R"))
source(here("R", "recipes", "linear_distance_recipe.R"))

dir.create(here("artifacts"), recursive = TRUE, showWarnings = FALSE)

adult_folds <- readRDS(here("data", "processed", "cv_folds.rds"))

lda_spec <- discrim_linear() |>
  set_engine("MASS") |>
  set_mode("classification")

lda_workflow <- workflow() |>
  add_recipe(linear_distance_recipe) |>
  add_model(lda_spec)

set.seed(project_seed)
lda_resamples <- fit_resamples(
  lda_workflow,
  resamples = adult_folds,
  metrics = classification_metrics,
  control = control_resamples(save_pred = TRUE, save_workflow = TRUE)
)

saveRDS(
  list(
    model_name = "Linear Discriminant Analysis",
    workflow = lda_workflow,
    resamples = lda_resamples,
    tuned = FALSE
  ),
  here("artifacts", "lda.rds")
)

