library(here)
i_am("R/models/random_forest.R")
source(here("R", "00_packages.R"))
source(here("R", "recipes", "tree_recipe.R"))

dir.create(here("artifacts"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("figures", "tuning"), recursive = TRUE, showWarnings = FALSE)

adult_folds <- readRDS(here("data", "processed", "cv_folds.rds"))

random_forest_spec <- rand_forest(
  mtry = tune(),
  min_n = tune(),
  trees = 800
) |>
  set_engine(
    "ranger",
    probability = TRUE,
    importance = "permutation",
    num.threads = 1
  ) |>
  set_mode("classification")

random_forest_workflow <- workflow() |>
  add_recipe(tree_recipe) |>
  add_model(random_forest_spec)

set.seed(project_seed)
random_forest_grid <- grid_latin_hypercube(
  mtry(range = c(2L, 12L)),
  min_n(range = c(2L, 50L)),
  size = 20
)

registerDoParallel(cores = 2)
set.seed(project_seed)
random_forest_resamples <- tune_grid(
  random_forest_workflow,
  resamples = adult_folds,
  grid = random_forest_grid,
  metrics = classification_metrics,
  control = control_grid(
    save_pred = TRUE,
    save_workflow = TRUE,
    parallel_over = "resamples"
  )
)
stopImplicitCluster()

random_forest_plot <- autoplot(random_forest_resamples) +
  labs(title = "Random-forest tuning results")

ggsave(
  here("figures", "tuning", "random_forest_tuning.png"),
  random_forest_plot,
  width = 10,
  height = 7,
  dpi = 300
)

saveRDS(
  list(
    model_name = "Random Forest",
    workflow = random_forest_workflow,
    resamples = random_forest_resamples,
    tuned = TRUE
  ),
  here("artifacts", "random_forest.rds")
)

