library(recipes)
library(xgboost)
library(nycflights13)

flights_eng <- flights %>%
  filter(!is.na(arr_delay)) %>%
  group_by(month, day) %>%
  mutate(nday = n()) %>%
  ungroup %>%
  mutate(week_day = weekdays(as.Date(paste(2013, month, day, sep="-"))))

flights_train <- filter(flights_eng, month <= 6)
flights_test <- filter(flights_eng, month > 6)

flights_recipe <- recipe(arr_delay ~ month + day +
                           sched_dep_time + sched_arr_time +
                           origin +
                           #dest + # need to fix new levels
                           distance +
                           carrier +
                           week_day,
                         data = flights_eng) %>%
  step_center(all_numeric(), -arr_delay) %>%
  step_scale(all_numeric(), -arr_delay) %>%
#  step_modeimpute(all_nominal()) %>%
  step_meanimpute(all_numeric()) %>%
  step_dummy(all_nominal(), role = "predictor") %>%
  prep(flights_train)


train.x <- bake(flights_recipe, flights_train, all_predictors(), composition = "matrix")
train.y <- bake(flights_recipe, flights_train, all_outcomes(), composition = "matrix")
train.dm <- xgb.DMatrix(data = train.x, label = train.y)

test.x <- bake(flights_recipe, flights_test, composition = "matrix")
test.y <- bake(flights_recipe, flights_test, all_outcomes(), composition = "matrix")
test.dm <- xgb.DMatrix(data = test.x, label = test.y)


xgb_params <- list("booster" = "gbtree",
                 #  "objective" = "multi:softmax",
                   "eval_metric" = "rmse")
nround    <- 50 # number of XGBoost rounds
xgfit <- xgboost(train.dm, params = xgb_params,
                 nrounds = nround,
                 eta = 0.1)

predict(xgfit, test.x) %>% hist(breaks = 200)


