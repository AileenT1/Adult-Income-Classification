library(here)

required_packages <- c(
  "tidyverse", "tidymodels", "janitor", "naniar", "discrim",
  "glmnet", "kknn", "rpart", "ranger", "xgboost", "gt",
  "patchwork", "scales", "doParallel", "rmarkdown"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the following required packages before continuing: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(tidymodels)
  library(janitor)
  library(naniar)
  library(discrim)
  library(glmnet)
  library(kknn)
  library(rpart)
  library(ranger)
  library(xgboost)
  library(gt)
  library(patchwork)
  library(scales)
  library(doParallel)
  library(rmarkdown)
})

theme_set(
  theme_minimal(base_size = 12) +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
)

income_colors <- c("high" = "#D55E00", "not_high" = "#0072B2")
project_seed <- 1312026
classification_metrics <- metric_set(roc_auc, accuracy)

