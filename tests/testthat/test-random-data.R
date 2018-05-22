context("Random data set")

test_that("Return a random data frame", {
  set.seed(641)
  df <- random_data_set(n_rows = 10, n_cols = 3)

  expect_equal(nrow(df), 10)
  expect_named(df, paste("COL", 1:3, sep = "_"))

  expect_equivalent(colSums(df),
                    c(44.43856, 51.538880, 54.894352))
})
