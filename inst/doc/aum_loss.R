## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = torch::torch_is_installed()
)

## ----setup--------------------------------------------------------------------
library(tabnet)
suppressPackageStartupMessages(library(tidymodels))
library(modeldata)
data("lending_club", package = "modeldata")
set.seed(20250809)

## -----------------------------------------------------------------------------
class_ratio <- lending_club |> 
  summarise(sum( Class == "good") / sum( Class == "bad")) |> 
  pull() 

class_ratio

## -----------------------------------------------------------------------------
lending_club <- lending_club |>
  mutate(
    case_wts = if_else(Class == "bad", class_ratio, 1),
    case_wts = importance_weights(case_wts)
  )

split <- initial_split(lending_club, strata = Class)
train <- training(split)
test  <- testing(split)

tab_rec <- train |>
  recipe() |>
  update_role(Class, new_role = "outcome") |>
  update_role(-has_role(c("outcome", "id", "case_weights")), new_role = "predictor")

xgb_rec <- tab_rec |> 
  step_dummy(term, sub_grade, addr_state, verification_status, emp_length)

tab_mod <- tabnet(epochs = 100) |> 
  set_engine("torch", device = "cpu") |> 
  set_mode("classification")

xgb_mod <- boost_tree(trees = 100) |> 
  set_engine("xgboost") |> 
  set_mode("classification")

tab_wf <- workflow() |> 
  add_model(tab_mod) |> 
  add_recipe(tab_rec) |> 
  add_case_weights(case_wts)

xgb_wf <- workflow() |> 
  add_model(xgb_mod) |> 
  add_recipe(xgb_rec) |> 
  add_case_weights(case_wts)

## -----------------------------------------------------------------------------
tab_fit <- tab_wf |> fit(train)
xgb_fit <- xgb_wf |> fit(train)

tab_test <- tab_fit |> augment(test)
xgb_test <- xgb_fit |> augment(test)

tab_test |> 
  pr_curve(Class, .pred_good) |> 
  autoplot()

xgb_test |>
  pr_curve(Class, .pred_good) |>
  autoplot()


## -----------------------------------------------------------------------------
tab_test |> 
  pr_curve(Class, .pred_good, case_weights = case_wts) |> 
  autoplot() 

xgb_test |>
  pr_curve(Class, .pred_good, case_weights = case_wts) |>
  autoplot() 

## -----------------------------------------------------------------------------
# configure the AUM loss
tab_aum_mod <- tabnet(epochs = 100, loss = tabnet::nn_aum_loss, learn_rate = 0.02) |> 
  set_engine("torch", device = "cpu") |> 
  set_mode("classification")

# derive a workflow
tab_aum_wf <- workflow() |> 
  add_model(tab_aum_mod) |> 
  add_recipe(tab_rec) |> 
  add_case_weights(case_wts)

# fit and augment the test dataset with prediction
tab_aum_fit <- tab_aum_wf |> fit(train)
tab_aum_test <- tab_aum_fit |> augment(test)

## -----------------------------------------------------------------------------
tab_test |> 
  pr_curve(Class, .pred_good) |> 
  autoplot() 

tab_aum_test |> 
  pr_curve(Class, .pred_good) |> 
  autoplot() 

## -----------------------------------------------------------------------------
tab_test |> 
  pr_curve(Class, .pred_good, case_weights = case_wts) |> 
  autoplot() 


tab_aum_test |> 
  pr_curve(Class, .pred_good, case_weights = case_wts) |> 
  autoplot() 

