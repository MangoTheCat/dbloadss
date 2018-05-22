context("Simulate delays")

test_that("Simulate simple model", {

  set.seed(12)

  flights_fake <- data.frame(
    id = 1:40,
    dep_delay = rnorm(40, 10, 5),
    sched_dep_time = floor(runif(40, 0, 2400)),
    date = rep(Sys.Date() + 1:8, each = 5)
  )


  model <- lme4::lmer(dep_delay ~ 1 + sched_dep_time + (1 | date),
                      data = flights_fake[1:20,])

  sims <- simulate_delays(model, flights_test = flights_fake[21:40, ], nsim = 5)

  expect_equal(dim(sims), c(20*5, 3))

  expect_named(sims, c("id", "sim_id", "dep_delay"))

})
