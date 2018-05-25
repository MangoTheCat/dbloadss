library(odbc)
library(DBI)
library(tidyverse)
library(lme4)

con <- DBI::dbConnect(
  odbc::odbc(),
  driver = "SQL Server",
  server = "localhost\\SQL17ML",
  database = "ml"
)

flights_eng <- DBI::dbReadTable(con, "flights") %>%
  mutate(date = as.Date(time_hour)) %>%
  mutate(week_day = weekdays(date))

flights_train <- flights_eng %>%
  filter(month <= 6) %>%
  mutate_if(is.character, factor)

flights_test <- flights_eng %>%
  filter(month > 6) %>%
  mutate_if(is.character, factor)

fit.me <- lmer(dep_delay ~ 1 +
                 (1 | date:origin) +
                 carrier +
                 origin +
                 sched_dep_time +
                 distance +
                 week_day,
               data = flights_train)

summary(fit.me)

sim.me <- simulate(fit.me, nsim = 20, newdata = flights_test,
                   allow.new.levels = TRUE)


simulated_delays <- select(flights_test, id) %>%
  bind_cols(sim.me) %>%
  gather(key = "sim_id", value = "dep_delay", -id) %>%
  mutate(sim = as.integer(gsub("^sim_", "", sim)))

DBI::dbWriteTable(con, "flightdelays", simulated_delays, overwrite = TRUE)
