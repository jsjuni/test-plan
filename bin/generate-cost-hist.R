library(jsonlite)
library(tibble)
library(magrittr)
library(ggplot2)

get_changes <- function(t) unlist(union(t[['apply']], t[['retract']]))

get_heat <- function(test, all_categories, costs) {
  test_categories <- get_changes(test)
  tibble(
    category = all_categories,
    test = test[['id']],
    cost = sapply(X = all_categories, FUN = function(c) {
      c_chr = as.character(c)
      if (is.element(c_chr, test_categories)) costs[[c_chr]] else 0
      })
  )
}

args <- commandArgs(trailingOnly <- TRUE)

# args <- c("build/costs.json", "build_pruned/tests-unoptimized.json", "build_pruned/tests-optimized.json", "build_pruned/tests-cfg-plot.png")

cost_map_file <- args[1]
tests_unopt_file <- args[2]
tests_opt_file <- args[3]
png_file <- args[4]

all_costs <- read_json(cost_map_file)
tests_unopt <- read_json(tests_unopt_file)$tests
tests_opt <- read_json(tests_opt_file)$tests

tests <- list(
  unoptimized = tests_unopt,
  optimized = tests_opt
)

costs <- all_costs[['scenarios']]

categories <- Reduce(
  f = function(x, y) union(x, y),
  x = Map(
    f = function(ts) {
      Reduce(
        f = function(set, cats) union(set, cats),
        x = Map(function(t) get_changes(t), ts),
        init = c()
      )
    },
    tests
  )
)

categories_by_cost = categories[order(unlist(costs[categories]), categories)]
categories_factor = factor(x = categories_by_cost, levels = categories_by_cost)

plot_data <- Reduce(
  f = rbind,
  x = Map(
    f = function(tsn) {
      Reduce(
        f = function(df, c) rbind(df, data.frame(dataset = tsn, cost = sum(c["cost"]))[1, ]),
        x = Map(function(t) get_heat(t, categories_factor, costs), tests[[tsn]]),
        init = data.frame(dataset = character(), cost = numeric())
      )
    },
    names(tests)
  )
)

png(filename = png_file, width = 800, height = 600)
ggplot(plot_data, aes(x = cost, fill = dataset)) + geom_histogram(binwidth = 5, position = "dodge")
