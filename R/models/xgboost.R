library(here)
i_am("R/models/xgboost.R")
source(here("R", "00_packages.R"))
source(here("R", "recipes", "boost_recipe.R"))

dir.create(here("artifacts"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("figures", "tuning"), recursive = TRUE, showWarnings = FALSE)

adult_folds <- readRDS(here("data", "processed", "cv_folds.rds"))

xgboost_spec <- boost_tree(
  mtry = tune(),
  trees = tune(),
  min_n = tune(),
  tree_depth = tune(),
  learn_rate = tune(),
  loss_reduction = tune(),
  sample_size = tune()
) |>
  set_engine("xgboost", nthread = 1, verbosity = 0) |>
  set_mode("classification")

xgboost_workflow <- workflow() |>
  add_recipe(boost_recipe) |>
  add_model(xgboost_spec)

set.seed(project_seed)
xgboost_grid <- grid_latin_hypercube(
  mtry(range = c(3L, 30L)),
  trees(range = c(300L, 1000L)),
  min_n(range = c(2L, 40L)),
  tree_depth(range = c(2L, 8L)),
  learn_rate(range = c(-3, -0.5)),
  loss_reduction(range = c(-5, 1)),
  sample_prop(range = c(0.6, 1.0)),
  size = 25
)

registerDoParallel(cores = 2)
set.seed(project_seed)
xgboost_resamples <- tune_grid(
  xgboost_workflow,
  resamples = adult_folds,
  grid = xgboost_grid,
  metrics = classification_metrics,
  control = control_grid(
    save_pred = TRUE,
    save_workflow = TRUE,
    parallel_over = "resamples"
  )
)
stopImplicitCluster()

xgboost_plot <- autoplot(xgboost_resamples) +
  labs(title = "XGBoost tuning results")

ggsave(
  here("figures", "tuning", "xgboost_tuning.png"),
  xgboost_plot,
  width = 12,
  height = 8,
  dpi = 300
)

saveRDS(
  list(
    model_name = "XGBoost",
    workflow = xgboost_workflow,
    resamples = xgboost_resamples,
    tuned = TRUE
  ),
  here("artifacts", "xgboost.rds")
)

