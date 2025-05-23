% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parsnip.R
\name{min_grid.tabnet}
\alias{min_grid.tabnet}
\title{Determine the minimum set of model fits}
\usage{
\method{min_grid}{tabnet}(x, grid, ...)
}
\arguments{
\item{x}{A model specification.}

\item{grid}{A tibble with tuning parameter combinations.}

\item{...}{Not currently used.}
}
\value{
A tibble with the minimum tuning parameters to fit and an additional
list column with the parameter combinations used for prediction.
}
\description{
\code{min_grid()} determines exactly what models should be fit in order to
evaluate the entire set of tuning parameter combinations. This is for
internal use only and the API may change in the near future.
}
\details{
\code{fit_max_value()} can be used in other packages to implement a \code{min_grid()}
method.
}
\examples{
library(dials)
library(tune)
library(parsnip)

tabnet_spec <- tabnet(decision_width = tune(), attention_width = tune()) \%>\%
  set_mode("regression") \%>\%
  set_engine("torch")

tabnet_grid <-
  tabnet_spec \%>\%
  extract_parameter_set_dials() \%>\%
  grid_regular(levels = 3)

min_grid(tabnet_spec, tabnet_grid)

}
\keyword{internal}
