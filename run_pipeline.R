library(here)
i_am("run_pipeline.R")
source(here("R", "00_packages.R"))

pipeline_files <- c(
  here("R", "01_data_description.R"),
  here("R", "02_data_preparation.R"),
  here("R", "03_eda.R"),
  here("R", "04_split_and_resampling.R"),
  here("R", "models", "logistic_regression.R"),
  here("R", "models", "elastic_net.R"),
  here("R", "models", "lda.R"),
  here("R", "models", "decision_tree.R"),
  here("R", "models", "knn.R"),
  here("R", "models", "random_forest.R"),
  here("R", "models", "xgboost.R"),
  here("R", "05_model_comparison.R"),
  here("R", "06_final_model.R")
)

for (pipeline_file in pipeline_files) {
  message("Running ", basename(pipeline_file), " ...")
  source(pipeline_file, local = new.env(parent = globalenv()))
}

message("Pipeline complete. Render adult_income_project.Rmd for the final report.")

