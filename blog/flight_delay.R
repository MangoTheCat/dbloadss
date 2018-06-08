library(argparser)
library(methods)
library(dbloadss)
library(readr)

# Argument parsing --------------------------------------------------------

p <- arg_parser("Run flight delay simulations", name = "flightdelays.R")
p <- add_argument(p, "--verbose", help = "not yet used", flag = TRUE, default = FALSE)
p <- add_argument(p, "--nsim",
                  help = "Number of simulations",
                  type = "integer", short = "-n",
                  default = 50L)
p <- add_argument(p, "--split_date",
                  help = "What day do we simulate from?",
                  type = "character", short = "-d",
                  default = "2013-07-01")
p <- add_argument(p, "--input_path",
                  help = "Full path to input csv",
                  type = "character", short = "-i",
                  default = "flights.csv")
p <- add_argument(p, "--output_path",
                  help = "Full path to output csv",
                  type = "character", short = "-o",
                  default = "simulated_delays.csv")

opt <- parse_args(p)

cat("Running delay simulations:",
    paste0( "  ", names(opt), " = ", opt, collapse = "\n"),
    fill = TRUE)


# Read ------------------------------------------------------------
cat("Reading... ")


input_data <- readr::read_csv(opt$input_path, guess_max = 20000)

cat("Read ", nrow(input_data), " rows", fill = TRUE)

# Run the model -----------------------------------------------------------
cat("Running simulations... ", fill = TRUE)

output_data <- simulate_departure_delays(input_data, nsim = opt$nsim,
                                         split_date = opt$split_date)

# Write -------------------------------------------------------------------
cat("Writing ", nrow(output_data), " rows", fill = TRUE)

readr::write_csv(output_data, opt$output_path)

# All done.
cat("Done.", fill = TRUE)
