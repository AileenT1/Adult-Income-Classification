library(here)
i_am("R/05_model_comparison.R")
source(here("R", "00_packages.R"))

dir.create(here("figures", "results"), recursive = TRUE, showWarnings = FALSE)

artifact_paths <- c(
  logistic_regression = "logistic_regression.rds",
  elastic_net = "elastic_net.rds",
  lda = "lda.rds",
  decision_tree = "decision_tree.rds",
  knn = "knn.rds",
  random_forest = "random_forest.rds",
  xgboost = "xgboost.rds"
)

model_artifacts <- map(
  artifact_paths,
  ~ readRDS(here("artifacts", .x))
)

extract_selected_metrics <- function(model_artifact) {
  all_metrics <- collect_metrics(model_artifact$resamples)

  if (model_artifact$tuned) {
    best_parameters <- select_best(model_artifact$resamples, metric = "roc_auc")
    selected_metrics <- all_metrics |>
      filter(.config == best_parameters$.config)
  } else {
    best_parameters <- tibble(.config = unique(all_metrics$.config)[1])
    selected_metrics <- all_metrics
  }

  roc_row <- selected_metrics |> filter(.metric == "roc_auc") |> slice(1)
  accuracy_row <- selected_metrics |> filter(.metric == "accuracy") |> slice(1)

  list(
    summary = tibble(
      model = model_artifact$model_name,
      roc_auc = roc_row$mean,
      roc_auc_se = roc_row$std_err,
      accuracy = accuracy_row$mean,
      accuracy_se = accuracy_row$std_err
    ),
    best_parameters = best_parameters
  )
}

selected_results <- map(model_artifacts, extract_selected_metrics)

model_summary <- map_dfr(selected_results, "summary")
best_parameters <- map(selected_results, "best_parameters")

complexity_order <- c(
  "Logistic Regression" = 1,
  "Linear Discriminant Analysis" = 2,
  "Elastic Net" = 3,
  "Decision Tree" = 4,
  "K-Nearest Neighbors" = 5,
  "Random Forest" = 6,
  "XGBoost" = 7
)

model_summary <- model_summary |>
  mutate(complexity = unname(complexity_order[model])) |>
  arrange(desc(roc_auc), desc(accuracy), complexity) |>
  mutate(rank = row_number())

analysis_sets <- readRDS(here("data", "processed", "analysis_sets.rds"))
majority_accuracy <- max(prop.table(table(analysis_sets$train$income)))
champion <- model_summary$model[[1]]

comparison_plot_data <- model_summary |>
  select(model, roc_auc, roc_auc_se, accuracy, accuracy_se) |>
  pivot_longer(
    cols = c(roc_auc, accuracy),
    names_to = "metric",
    values_to = "estimate"
  ) |>
  mutate(
    std_err = if_else(metric == "roc_auc", roc_auc_se, accuracy_se),
    metric = recode(metric, roc_auc = "ROC AUC", accuracy = "Accuracy"),
    model = fct_reorder(model, estimate, .fun = max)
  )

model_comparison_plot <- comparison_plot_data |>
  ggplot(aes(estimate, model, color = metric)) +
  geom_vline(
    xintercept = majority_accuracy,
    linetype = "dashed",
    color = "grey45"
  ) +
  geom_errorbarh(
    aes(xmin = estimate - std_err, xmax = estimate + std_err),
    height = 0.16,
    position = position_dodge(width = 0.45)
  ) +
  geom_point(size = 3, position = position_dodge(width = 0.45)) +
  scale_color_manual(values = c("ROC AUC" = "#D55E00", "Accuracy" = "#0072B2")) +
  scale_x_continuous(labels = number_format(accuracy = 0.01), limits = c(0.70, 1.00)) +
  labs(
    title = "Ten-fold cross-validation performance",
    subtitle = "Error bars show one standard error; dashed line is majority-class accuracy",
    x = "Mean cross-validation estimate",
    y = NULL,
    color = NULL
  )

ggsave(
  here("figures", "results", "model_comparison.png"),
  model_comparison_plot,
  width = 10,
  height = 6,
  dpi = 300
)

model_comparison <- list(
  summary = model_summary,
  best_parameters = best_parameters,
  champion = champion,
  majority_accuracy = majority_accuracy
)

saveRDS(model_comparison, here("artifacts", "model_comparison.rds"))

