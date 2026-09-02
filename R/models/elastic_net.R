library(here)
i_am("R/models/elastic_net.R")
source(here("R", "00_packages.R"))
source(here("R", "recipes", "linear_distance_recipe.R"))

dir.create(here("artifacts"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("figures", "tuning"), recursive = TRUE, showWarnings = FALSE)

adult_folds <- readRDS(here("data", "processed", "cv_folds.rds"))

elastic_net_spec <- logistic_reg(
  penalty = tune(),
  mixture = tune()
) |>
  set_engine("glmnet") |>
  set_mode("classification")

elastic_net_workflow <- workflow() |>
  add_recipe(linear_distance_recipe) |>
  add_model(elastic_net_spec)

set.seed(project_seed)
elastic_net_grid <- grid_latin_hypercube(
  penalty(range = c(-5, 0)),
  mixture(range = c(0, 1)),
  size = 20
)

registerDoParallel(cores = 2)
set.seed(project_seed)
elastic_net_resamples <- tune_grid(
  elastic_net_workflow,
  resamples = adult_folds,
  grid = elastic_net_grid,
  metrics = classification_metrics,
  control = control_grid(
    save_pred = TRUE,
    save_workflow = TRUE,
    parallel_over = "resamples"
  )
)
stopImplicitCluster()

elastic_net_plot <- autoplot(elastic_net_resamples) +
  labs(title = "Elastic-net tuning results")

ggsave(
  here("figures", "tuning", "elastic_net_tuning.png"),
  elastic_net_plot,
  width = 10,
  height = 6,
  dpi = 300
)

saveRDS(
  list(
    model_name = "Elastic Net",
    workflow = elastic_net_workflow,
    resamples = elastic_net_resamples,
    tuned = TRUE
  ),
  here("artifacts", "elastic_net.rds")
)

