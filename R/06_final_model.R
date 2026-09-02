library(here)
i_am("R/06_final_model.R")
source(here("R", "00_packages.R"))

dir.create(here("figures", "results"), recursive = TRUE, showWarnings = FALSE)

comparison <- readRDS(here("artifacts", "model_comparison.rds"))
analysis_sets <- readRDS(here("data", "processed", "analysis_sets.rds"))

champion_file <- c(
  "Logistic Regression" = "logistic_regression.rds",
  "Elastic Net" = "elastic_net.rds",
  "Linear Discriminant Analysis" = "lda.rds",
  "Decision Tree" = "decision_tree.rds",
  "K-Nearest Neighbors" = "knn.rds",
  "Random Forest" = "random_forest.rds",
  "XGBoost" = "xgboost.rds"
)[[comparison$champion]]

champion_artifact <- readRDS(here("artifacts", champion_file))

if (champion_artifact$tuned) {
  champion_parameters <- select_best(
    champion_artifact$resamples,
    metric = "roc_auc"
  )
  final_workflow <- finalize_workflow(
    champion_artifact$workflow,
    champion_parameters
  )
} else {
  champion_parameters <- tibble(model = comparison$champion)
  final_workflow <- champion_artifact$workflow
}

set.seed(project_seed)
final_fit <- fit(final_workflow, data = analysis_sets$train)

test_predictions <- bind_cols(
  analysis_sets$test |> select(income),
  predict(final_fit, new_data = analysis_sets$test, type = "class"),
  predict(final_fit, new_data = analysis_sets$test, type = "prob")
)

test_metrics <- bind_rows(
  roc_auc(test_predictions, truth = income, .pred_high),
  accuracy(test_predictions, truth = income, estimate = .pred_class),
  sens(test_predictions, truth = income, estimate = .pred_class),
  spec(test_predictions, truth = income, estimate = .pred_class)
)

test_roc <- roc_curve(test_predictions, truth = income, .pred_high)
test_confusion <- conf_mat(test_predictions, truth = income, estimate = .pred_class)

roc_plot <- test_roc |>
  ggplot(aes(1 - specificity, sensitivity)) +
  geom_abline(linetype = "dashed", color = "grey55") +
  geom_path(color = "#D55E00", linewidth = 1.1) +
  coord_equal() +
  labs(
    title = paste("Held-out ROC curve:", comparison$champion),
    x = "False-positive rate (1 - specificity)",
    y = "True-positive rate (sensitivity)"
  )

confusion_data <- as.data.frame(test_confusion$table)

confusion_plot <- confusion_data |>
  ggplot(aes(Prediction, Truth, fill = Freq)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = comma(Freq)), size = 5, fontface = "bold") +
  scale_fill_gradient(low = "#E5F5F9", high = "#0072B2", labels = comma) +
  labs(
    title = "Held-out test confusion matrix",
    x = "Predicted income",
    y = "Observed income",
    fill = "Individuals"
  )

baseline_auc <- test_metrics |>
  filter(.metric == "roc_auc") |>
  pull(.estimate)

predictors <- setdiff(names(analysis_sets$test), "income")

set.seed(project_seed)
permutation_importance <- map_dfr(seq_along(predictors), function(index) {
  predictor <- predictors[[index]]
  permuted_test <- analysis_sets$test
  permuted_test[[predictor]] <- sample(permuted_test[[predictor]])
  permuted_probabilities <- predict(
    final_fit,
    new_data = permuted_test,
    type = "prob"
  )
  permuted_auc <- roc_auc_vec(
    truth = permuted_test$income,
    estimate = permuted_probabilities$.pred_high,
    event_level = "first"
  )
  tibble(
    predictor = predictor,
    importance = baseline_auc - permuted_auc
  )
}) |>
  arrange(desc(importance))

importance_plot <- permutation_importance |>
  slice_max(importance, n = 12, with_ties = FALSE) |>
  mutate(predictor = fct_reorder(predictor, importance)) |>
  ggplot(aes(importance, predictor)) +
  geom_col(fill = "#0072B2", width = 0.7) +
  scale_x_continuous(labels = number_format(accuracy = 0.001)) +
  labs(
    title = "Permutation importance for the champion model",
    subtitle = "Importance is the decrease in held-out ROC AUC after shuffling a predictor",
    x = "Decrease in ROC AUC",
    y = NULL
  )

ggsave(
  here("figures", "results", "test_roc_curve.png"),
  roc_plot,
  width = 7,
  height = 6,
  dpi = 300
)
ggsave(
  here("figures", "results", "confusion_matrix.png"),
  confusion_plot,
  width = 7,
  height = 5.5,
  dpi = 300
)
ggsave(
  here("figures", "results", "predictor_importance.png"),
  importance_plot,
  width = 8,
  height = 6,
  dpi = 300
)

final_results <- list(
  champion = comparison$champion,
  parameters = champion_parameters,
  final_workflow = final_workflow,
  final_fit = final_fit,
  test_predictions = test_predictions,
  test_metrics = test_metrics,
  confusion_matrix = test_confusion,
  roc_curve = test_roc,
  permutation_importance = permutation_importance
)

saveRDS(final_results, here("artifacts", "final_model_results.rds"))

