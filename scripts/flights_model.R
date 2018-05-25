library(recipes)
library(nycflights13)

flights_eng <- flights %>%
  group_by(month, day) %>%
  mutate(nday = n()) %>%
  ungroup %>%
  mutate(week_day = weekdays(as.Date(paste(2013, month, day, sep="-"))))

flights_train <- filter(flights_eng, month <= 6)
flights_test <- filter(flights_eng, month > 6)

flights_recipe <- recipe(arr_delay ~ month + day +
                           sched_dep_time + sched_arr_time +
                           carrier + origin + dest + distance +
                           week_day,
                         data = flights_eng) %>%
  step_center(all_numeric(), -arr_delay) %>%
  step_scale(all_numeric(), -arr_delay) %>%
  #step_dummy(all_nominal(), role = "predictor") %>%
  prep(flights_train)

flights_train_baked <- bake(flights_recipe, flights_train)
flights_test_baked <- bake(flights_recipe, flights_test)

fit <- lm(arr_delay ~ . , data = flights_train_baked)

x <- predict(fit, flights_test_baked)

qplot(fit$residuals, bins = 500)

library(xgboost)

train.x <- as.matrix(select(flights_train_baked, -arr_delay))

flights_eng %>%
  ggplot() +
  geom_boxplot(aes(x = factor(month), arr_delay))

flights_eng %>%
  sample_n(10000) %>%
  group_by(month, day) %>%
  mutate(n=n()) %>%
  ggplot() +
  geom_point(aes(n, arr_delay))


flights_eng %>%
  group_by(origin, month, day) %>%
  summarise(n=n(), av_delay = mean(dep_delay, na.rm = TRUE)) %>%
  ggplot(aes(x = n, y = av_delay)) +
  geom_point() +
  facet_wrap(facets = ~ origin)

flights_eng %>%
  filter(month == 2) %>%
  ggplot(aes(x = dep_delay)) +
  geom_histogram() +
  facet_wrap(facets = ~ week_day)

flights_eng %>%
  #filter(month == 2) %>%
  group_by(week_day) %>%
  summarise(mean = mean(dep_delay, na.rm=TRUE),
            sd = sd(arr_delay, na.rm=TRUE))

daily_flights <- flights_eng %>%
  group_by(origin, month, day) %>%
  mutate(mean_delay = mean(dep_delay, na.rm = TRUE),
         sd_delay = sd(dep_delay, na.rm = TRUE),
         frac_15 = sum(dep_delay>15, na.rm = TRUE)/n()) %>%
  slice(1) %>%
  select(month, day, week_day, origin, nday, mean_delay, sd_delay, frac_15)

ggplot(daily_flights) +
  geom_histogram(aes(x=frac_15)) +
  facet_wrap(~ week_day )

daily_flights %>%
  filter(frac_15 > 0.3) %>%
  ggplot(aes(x = mean_delay)) +
  geom_histogram() +
  facet_wrap(~ week_day )

flights_eng2 <- flights_eng %>%
  group_by(origin, month, day) %>%
  mutate(mean_delay = mean(dep_delay, na.rm = TRUE),
         sd_delay = sd(dep_delay, na.rm = TRUE),
         frac_15 = sum(dep_delay>15, na.rm = TRUE)/n(),
         frac_30 = sum(dep_delay>30, na.rm = TRUE)/n(),
         frac_100 = sum(dep_delay>100, na.rm = TRUE)/n(),
         frac_200 = sum(dep_delay>200, na.rm = TRUE)/n()) %>%
  ungroup()

flights_eng2 %>%
  filter(frac_15 > 0.3) %>%
  ggplot(aes(x = dep_delay)) +
  geom_histogram(bins = 100) +
  facet_wrap(~ week_day )

flights_eng2 %>%
  filter(dep_delay > 60) %>%
  ggplot() +
  geom_polygon(aes(y = dep_delay, x = frac_100, fill = ..level..), stat = "density_2d")

flights_eng %>%
  group_by(origin, month, day) %>%
  mutate(n=n(), av_delay = mean(arr_delay, na.rm = TRUE)) %>%
  mutate(late_day = av_delay > 10) %>%
  ggplot(aes(x = arr_delay)) +
  geom_histogram(bins = 100) +
  facet_wrap(facets = ~ late_day)
