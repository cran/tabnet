## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = torch::torch_is_installed(),
  out.width = "100%", 
  out.height = "300px", 
  fig.width = 14
)

## ----setup--------------------------------------------------------------------
library(tabnet)
library(tidyverse, warn.conflicts = FALSE)
set.seed(1)
torch::torch_manual_seed(1)

## -----------------------------------------------------------------------------
logit_to_y <- function(logits) {
  p <- exp(logits)/(1 + exp(logits))
  y <- factor(ifelse(p > 0.5, "yes", "no"), levels = c("yes", "no"))
  y
}

make_random_x <- function(n) {
  x <- as.data.frame(lapply(1:10, function(x) rnorm(n)))
  names(x) <- sprintf("V%02d", 1:10)
  x
}

make_syn2 <- function(n = 10000) {
  x <- make_random_x(n)
  logits <- rowSums(x[,3:6])
  x$y <- logit_to_y(logits)
  x
}

make_syn4 <- function(n = 10000) {
  x <- make_random_x(n)
  logits <- ifelse(
    x[,10] > 0,
    rowSums(x[,1:2]),
    rowSums(x[,5:6])
  )
  
  x$y <- logit_to_y(logits)
  x
}

## -----------------------------------------------------------------------------
syn2 <- make_syn2()
syn4 <- make_syn4()

## -----------------------------------------------------------------------------
fit_syn2 <- tabnet_fit(y ~ ., syn2, epochs = 10, verbose = TRUE)

## -----------------------------------------------------------------------------
vip::vip(fit_syn2)

## -----------------------------------------------------------------------------
library(tidyverse)
ex_syn2 <- tabnet_explain(fit_syn2, syn2)

ex_syn2$M_explain %>% 
  mutate(rowname = row_number()) %>% 
  pivot_longer(-rowname, names_to = "variable", values_to = "m_agg") %>% 
  ggplot(aes(x = rowname, y = variable, fill = m_agg)) +
  geom_tile() +
  scale_fill_viridis_c()

## -----------------------------------------------------------------------------
ex_syn2$masks %>% 
  imap_dfr(~mutate(
    .x, 
    step = sprintf("Step %d", .y),
    rowname = row_number()
  )) %>% 
  pivot_longer(-c(rowname, step), names_to = "variable", values_to = "m_agg") %>% 
  ggplot(aes(x = rowname, y = variable, fill = m_agg)) +
  geom_tile() +
  scale_fill_viridis_c() +
  facet_wrap(~step)

## -----------------------------------------------------------------------------
fit_syn4 <- tabnet_fit(y ~ ., syn4, epochs = 10, verbose = TRUE)

## -----------------------------------------------------------------------------
vip::vip(fit_syn4)

## -----------------------------------------------------------------------------
ex_syn4 <- tabnet_explain(fit_syn4, arrange(syn4, V10))
q99 <- function(x) quantile(x, probs = 0.995)

ex_syn4$M_explain %>% 
  mutate(rowname = row_number()) %>% 
  pivot_longer(-rowname, names_to = "variable", values_to = "m_agg") %>% 
  mutate(m_agg = ifelse(m_agg > q99(m_agg), q99(m_agg), m_agg)) %>% 
  ggplot(aes(x = rowname, y = variable, fill = m_agg)) +
  geom_tile() +
  scale_fill_viridis_c()

## -----------------------------------------------------------------------------
ex_syn4$masks %>% 
  imap_dfr(~mutate(
    .x, 
    step = sprintf("Step %d", .y),
    rowname = row_number()
  )) %>% 
  pivot_longer(-c(rowname, step), names_to = "variable", values_to = "m_agg") %>% 
  group_by(step) %>% 
  mutate(m_agg = ifelse(m_agg > q99(m_agg), q99(m_agg), m_agg)) %>% 
  ungroup() %>% 
  ggplot(aes(x = rowname, y = variable, fill = m_agg)) +
  geom_tile() +
  scale_fill_viridis_c() +
  facet_wrap(~step)

