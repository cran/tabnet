
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tabnet

<!-- badges: start -->

[![R build
status](https://github.com/mlverse/tabnet/workflows/R-CMD-check/badge.svg)](https://github.com/mlverse/tabnet/actions)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![CRAN
status](https://www.r-pkg.org/badges/version/tabnet)](https://CRAN.R-project.org/package=tabnet)
[![](https://cranlogs.r-pkg.org/badges/tabnet)](https://cran.r-project.org/package=tabnet)
[![Discord](https://img.shields.io/discord/837019024499277855?logo=discord)](https://discord.com/invite/s3D5cKhBkx)

<!-- badges: end -->

An R implementation of: [TabNet: Attentive Interpretable Tabular
Learning](https://arxiv.org/abs/1908.07442) [(Sercan O. Arik, Tomas
Pfister)](https://doi.org/10.48550/arXiv.1908.07442).  
The code in this repository is an R port using the
[torch](https://github.com/mlverse/torch) package of
[dreamquark-ai/tabnet](https://github.com/dreamquark-ai/tabnet)
PyTorch’s implementation.  
TabNet is augmented with [Coherent Hierarchical Multi-label
Classification
Networks](https://proceedings.neurips.cc//paper/2020/file/6dd4e10e3296fa63738371ec0d5df818-Paper.pdf)
[(Eleonora Giunchiglia et
Al.)](https://doi.org/10.48550/arXiv.2010.10151) for hierarchical
outcomes.

## Installation

Tabnet is temporarily archived on CRAN. We are working hard to get it
back. In the meantime, you can install the released version from
r-universe with:

``` r
install.packages('tabnet', repos = c('https://mlverse.r-universe.dev', 'https://cloud.r-project.org'))
```

The development version can be installed from
[GitHub](https://github.com/mlverse/tabnet) with:

``` r
# install.packages("remotes")
remotes::install_github("mlverse/tabnet")
```

## Basic Binary Classification Example

Here we show a **binary classification** example of the `attrition`
dataset, using a **recipe** for dataset input specification.

``` r
library(tabnet)
suppressPackageStartupMessages(library(recipes))
library(yardstick)
library(ggplot2)
set.seed(1)

data("attrition", package = "modeldata")
test_idx <- sample.int(nrow(attrition), size = 0.2 * nrow(attrition))

train <- attrition[-test_idx,]
test <- attrition[test_idx,]

rec <- recipe(Attrition ~ ., data = train) %>% 
  step_normalize(all_numeric(), -all_outcomes())

fit <- tabnet_fit(rec, train, epochs = 30, valid_split=0.1, learn_rate = 5e-3)
autoplot(fit)
```

<img src="man/figures/README-model-fit-1.png" width="100%" />

The plots gives you an immediate insight about model over-fitting, and
if any, the available model checkpoints available before the
over-fitting

Keep in mind that **regression** as well as **multi-class
classification** are also available, and that you can specify dataset
through **data.frame** and **formula** as well. You will find them in
the package vignettes.

## Model performance results

As the standard method `predict()` is used, you can rely on your usual
metric functions for model performance results. Here we use {yardstick}
:

``` r
metrics <- metric_set(accuracy, precision, recall)
cbind(test, predict(fit, test)) %>% 
  metrics(Attrition, estimate = .pred_class)
#> # A tibble: 3 × 3
#>   .metric   .estimator .estimate
#>   <chr>     <chr>          <dbl>
#> 1 accuracy  binary         0.840
#> 2 precision binary         0.840
#> 3 recall    binary         1
  
cbind(test, predict(fit, test, type = "prob")) %>% 
  roc_auc(Attrition, .pred_No)
#> # A tibble: 1 × 3
#>   .metric .estimator .estimate
#>   <chr>   <chr>          <dbl>
#> 1 roc_auc binary         0.544
```

## Explain model on test-set with attention map

TabNet has intrinsic explainability feature through the visualization of
attention map, either **aggregated**:

``` r
explain <- tabnet_explain(fit, test)
autoplot(explain)
```

<img src="man/figures/README-model-explain-1.png" width="100%" />

or at **each layer** through the `type = "steps"` option:

``` r
autoplot(explain, type = "steps")
```

<img src="man/figures/README-step-explain-1.png" width="100%" />

## Self-supervised pretraining

For cases when a consistent part of your dataset has no outcome, TabNet
offers a self-supervised training step allowing to model to capture
predictors intrinsic features and predictors interactions, upfront the
supervised task.

``` r
pretrain <- tabnet_pretrain(rec, train, epochs = 50, valid_split=0.1, learn_rate = 1e-2)
autoplot(pretrain)
```

<img src="man/figures/README-step-pretrain-1.png" width="100%" />

The example here is a toy example as the `train` dataset does actually
contain outcomes. The vignette on [Self-supervised training and
fine-tuning](https://mlverse.github.io/tabnet/articles/selfsupervised_training.html)
will gives you the complete correct workflow step-by-step.

## Missing data in predictors

{tabnet} leverage the masking mechanism to deal with missing data, so
you don’t have to remove the entries in your dataset with some missing
values in the predictors variables.

# Comparison with other implementations

| Group | Feature | {tabnet} | dreamquark-ai | fast-tabnet |
|----|----|:--:|:--:|:--:|
| Input format | data-frame | ✅ | ✅ | ✅ |
|  | formula | ✅ |  |  |
|  | recipe | ✅ |  |  |
|  | Node | ✅ |  |  |
|  | missings in predictor | ✅ |  |  |
| Output format | data-frame | ✅ | ✅ | ✅ |
|  | workflow | ✅ |  |  |
| ML Tasks | self-supervised learning | ✅ | ✅ |  |
|  | classification (binary, multi-class) | ✅ | ✅ | ✅ |
|  | regression | ✅ | ✅ | ✅ |
|  | multi-outcome | ✅ | ✅ |  |
|  | hierarchical multi-label classif. | ✅ |  |  |
| Model management | from / to file | ✅ | ✅ | v |
|  | resume from snapshot | ✅ |  |  |
|  | training diagnostic | ✅ |  |  |
| Interpretability |  | ✅ | ✅ | ✅ |
| Performance |  | 1 x | 2 - 4 x |  |
| Code quality | test coverage | 85% |  |  |
|  | continuous integration | 4 OS including GPU |  |  |

Alternative TabNet implementation features
