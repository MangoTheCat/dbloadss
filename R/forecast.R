
#' Simulate flight departure delays
#'
#' @param flights_in Data Frame. Input data set (flights) with an id variable
#' @param nsim Int. How many simulation runs
#' @param split_date A date or ISO 8601 character string to split the data on
#'
#' @return Simulation results. Probably quite big.
#' @export
#' @import dplyr
#'
#' @examples
#' \dontrun{
#'   library(nycflights13)
#'   flights$id <- 1:nrow(flights)
#'   results <- simulate_departure_delays(flights, nsim = 10)
#' }
simulate_departure_delays <- function(flights_in, nsim = 20,
                                      split_date = "2013-06-01") {

  time_hour <- date <- week_day <- NULL # not global

  # Transform and split the data
  flights_eng <- flights_in %>%
    mutate(date = as.Date(time_hour)) %>%
    mutate(week_day = weekdays(date))

  # Only works within a year
  flights_train <- filter(flights_eng, date < split_date)
  flights_test <- filter(flights_eng, date >= split_date)

  model <- train_delays(flights_train)

  simulated_delays <- simulate_delays(model, flights_test, nsim = nsim)

  simulated_delays

}

train_delays <- function(flights_train) {

  data_train <- flights_train %>%
    mutate_if(is.character, factor)

  fit.me <- lme4::lmer(
    dep_delay ~ 1 +
      (1 | date:origin) +
      carrier +
      origin +
      sched_dep_time +
      distance +
      week_day,
    data = data_train
  )

  fit.me

}

simulate_delays <- function(object, flights_test, nsim) {

  id <- sim_id <- NULL # cmd check

  data_test <- flights_test %>%
    mutate_if(is.character, factor)

  sim.me <- stats::simulate(object, nsim = nsim, newdata = data_test,
                            allow.new.levels = TRUE)

  simulated_delays <- select(data_test, id) %>%
    bind_cols(sim.me) %>%
    tidyr::gather(key = "sim_id", value = "dep_delay", -id) %>%
    mutate(sim_id = as.integer(gsub("^sim_", "", sim_id)))

  simulated_delays
}
