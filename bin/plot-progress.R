library(xml2)

args = commandArgs(trailingOnly = TRUE)
# print(args)

unopt <-args[1]
opt <- args[2]

outfile <- args[3]

# unopt <- "tests-unoptimized-schedule.gan"
# opt <- "tests-optimized-schedule.gan"
# outfile <- "test-campaign-progress.png"

get_dates <- function(path) {
  read_xml(path) |>
    xml_find_all("tasks/task/task[contains(@name, 'Test ')]") |>
    sapply(FUN = function(e) as.numeric(xml_attr(e, "duration")))
}

unopt_durations <- get_dates(unopt)
opt_durations <- get_dates(opt)

df <- data.frame(
  unopt_days = cumsum(unopt_durations),
  opt_days = cumsum(opt_durations),
  tests = 1:length(unopt_durations)
)

png(filename = outfile, width = 12, height = 6, units = "in", res = 72)

plot(df$unopt_days, df$tests,
     type = "l", lty = 2,
     xlab = "days", ylab = "tests completed",
     main = "Test Campaign Progress")
lines(df$opt_days, df$tests, lty = 3)
legend(20, 150, c("unoptimized", "optimized"), lty = c(2, 3))

