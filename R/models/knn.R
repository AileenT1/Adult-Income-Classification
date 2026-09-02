library(here)
i_am("R/models/knn.R")
source(here("R", "00_packages.R"))
source(here("R", "recipes", "linear_distance_recipe.R"))

dir.create(here("artifacts"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("figures", "tuning"), recursive = TRUE, showWarnings = FALSE)

adult_folds <- readRDS(here("data", "processed", "cv_folds.rds"))
analysis_sets <- readRDS(here("data", "processed", "analysis_sets.rds"))

knn_spec <- nearest_neighbor(
  neighbors = tune(),
  dist_power = tune(),
  weight_func = tune()
) |>
  set_engine("kknn") |>
  set_mode("classification")

knn_workflow <- workflow() |>
  add_recipe(linear_distance_recipe) |>
  add_model(knn_spec)

knn_grid <- tibble(
  neighbors = c(5L, 11L, 21L, 31L, 45L, 61L, 75L),
  dist_power = c(1.0, 1.5, 2.0, 1.0, 1.5, 2.0, 1.5),
  weight_func = c(
    "rectangular", "triangular", "epanechnikov", "triangular",
    "epanechnikov", "rectangular", "triangular"
  )
)

set.seed(project_seed)
knn_tuning_data <- analysis_sets$train |>
  group_by(income) |>
  slice_sample(prop = 0.20) |>
  ungroup()

set.seed(project_seed)
knn_tuning_folds <- vfold_cv(knn_tuning_data, v = 10, strata = income)

registerDoParallel(cores = 2)
set.seed(project_seed)
knn_tuning_resamples <- tune_grid(
  knn_workflow,
  resamples = knn_tuning_folds,
  grid = knn_grid,
  metrics = classification_metrics,
  control = control_grid(
    save_pred = TRUE,
    save_workflow = TRUE,
    parallel_over = "resamples"
  )
)

knn_best <- select_best(knn_tuning_resamples, metric = "roc_auc")
knn_final_workflow <- finalize_workflow(knn_workflow, knn_best)

set.seed(project_seed)
knn_resamples <- fit_resamples(
  knn_final_workflow,
  resamples = adult_folds,
  metrics = classification_metrics,
  control = control_resamples(
    save_pred = TRUE,
    save_workflow = TRUE,
    parallel_over = "resamples"
  )
)
stopImplicitCluster()

knn_plot <- autoplot(knn_tuning_resamples) +
  labs(
    title = "K-nearest-neighbors tuning results",
    subtitle = "Hyperparameters tuned with stratified 10-fold CV on a 20% training subset"
  )

ggsave(
  here("figures", "tuning", "knn_tuning.png"),
  knn_plot,
  width = 10,
  height = 7,
  dpi = 300
)

saveRDS(
  list(
    model_name = "K-Nearest Neighbors",
    workflow = knn_final_workflow,
    resamples = knn_resamples,
    tuning_resamples = knn_tuning_resamples,
    best_parameters = knn_best,
    tuned = FALSE,
    tuning_note = "Tuned on a stratified 20% subset; evaluated on the full shared folds."
  ),
  here("artifacts", "knn.rds")
)
