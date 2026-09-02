library(here)
i_am("R/models/decision_tree.R")
source(here("R", "00_packages.R"))
source(here("R", "recipes", "tree_recipe.R"))

dir.create(here("artifacts"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("figures", "tuning"), recursive = TRUE, showWarnings = FALSE)

adult_folds <- readRDS(here("data", "processed", "cv_folds.rds"))

decision_tree_spec <- decision_tree(
  cost_complexity = tune(),
  tree_depth = tune(),
  min_n = tune()
) |>
  set_engine("rpart") |>
  set_mode("classification")

decision_tree_workflow <- workflow() |>
  add_recipe(tree_recipe) |>
  add_model(decision_tree_spec)

set.seed(project_seed)
decision_tree_grid <- grid_latin_hypercube(
  cost_complexity(range = c(-6, -1)),
  tree_depth(range = c(2L, 20L)),
  min_n(range = c(5L, 100L)),
  size = 25
)

registerDoParallel(cores = 2)
set.seed(project_seed)
decision_tree_resamples <- tune_grid(
  decision_tree_workflow,
  resamples = adult_folds,
  grid = decision_tree_grid,
  metrics = classification_metrics,
  control = control_grid(
    save_pred = TRUE,
    save_workflow = TRUE,
    parallel_over = "resamples"
  )
)
stopImplicitCluster()

decision_tree_plot <- autoplot(decision_tree_resamples) +
  labs(title = "Decision-tree tuning results")

ggsave(
  here("figures", "tuning", "decision_tree_tuning.png"),
  decision_tree_plot,
  width = 10,
  height = 7,
  dpi = 300
)

saveRDS(
  list(
    model_name = "Decision Tree",
    workflow = decision_tree_workflow,
    resamples = decision_tree_resamples,
    tuned = TRUE
  ),
  here("artifacts", "decision_tree.rds")
)

