library(jsonlite)
library(tibble)
library(magrittr)
library(ggplot2)

get_scenarios <- function(t) unlist(t[['scenarios']])
get_quantities <- function(t) names(t[['quantities']])

get_heat <- function(test, all_categories, costs) {
  test_categories <- get_categories(test)
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

# args <- c("--scenarios", "build/costs.json", "build/tests-optimized.json", "build/tests-optimized-scn.png")

type = args[1]
cost_map_file <- args[2]
tests_file <- args[3]
png_file <- args[4]

all_costs <- read_json(cost_map_file)
tests <- read_json(tests_file)$tests

if (type == "--configuration") {
  get_categories <- get_scenarios
  costs <- all_costs[['scenarios']]
  ylabel <- "scenario"
} else if (type == "--observation") {
  get_categories = get_quantities
  costs <- all_costs[['observations']]
  ylabel <- "quantity"
} else stop("invalid type specification")

categories <- Reduce(
  f = function(set, cats) union(set, cats),
  x = Map(function(t) get_categories(t), tests),
  init = c()
)

categories_by_cost = categories[order(unlist(costs[categories]))]
categories_factor = factor(x = categories_by_cost, levels = categories_by_cost)

map_data <- Reduce(
  f = function(df, c) rbind(df, c),
  x = Map(function(t) get_heat(t, categories_factor, costs), tests)
)

scaled_map_data <- Reduce(
  f = function(x, y) rbind(x, y),
  x = Map(
    f = function(df) {
      rle <- rle(df$cost)
      scaled_values = ifelse(rle$lengths > 0, ceiling(rle$values / rle$lengths), rle$values)
      scaled_rle <- assign(x = "rle", value = list(lengths = rle$lengths, values = scaled_values))
      cbind(df, scaled_cost = inverse.rle(x = scaled_rle))
    },
    split(map_data, map_data$category)
  )
)

png(filename = png_file, width = 800, height = 600)

cost_col <- if (type == "--configuration") scaled_map_data$scaled_cost else scaled_map_data$cost
ggplot(scaled_map_data, aes(x=test, y=category)) +
  labs(y = ylabel) + 
  geom_tile(aes(fill = cost_col)) +
  scale_fill_gradient(low = "white", high = "red")


