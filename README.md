# Adult Income Classification

This project uses demographic, educational, and employment-related variables from the Adult Census Income dataset to classify whether annual income exceeds $50,000.

## Reproduce the analysis

1. Clone or download this repository.
2. Open R in the project root.
3. Restore package versions if an `renv.lock` file is present:

```r
install.packages("renv")
library(renv)
restore()
```

4. Run the complete analysis and render the report:

```r
source("run_pipeline.R")
library(rmarkdown)
render("adult_income_project.Rmd")
```

All paths are created with `here`, so no working-directory changes or machine-specific absolute paths are required. Raw data are stored in `data/`, processed data in `data/processed/`, figures in `figures/`, and fitted model objects in `artifacts/`.

## Analysis design

- Stratified 80% training and 20% testing split.
- Stratified 10-fold cross-validation on the training set.
- Seven classifiers: logistic regression, elastic net, LDA, decision tree, KNN, random forest, and XGBoost.
- ROC AUC is the primary selection metric; accuracy is secondary.
- Only the cross-validation champion is evaluated on the held-out test set.

The analysis is predictive and descriptive. It should not be interpreted causally or used for employment, lending, compensation, or other consequential decisions.

