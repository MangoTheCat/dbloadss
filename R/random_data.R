
#' A simple uniform random data set
#'
#' @param n_rows How many rows
#' @param n_cols How many columns
#'
#' @return A data frame with numeric types and simple column names
#'   (COL_1, COL_2 etc)
#' @export
#'
#' @examples
#' random_data_set(10, 3)
random_data_set <- function(n_rows = 1000, n_cols = 5) {

  col_names <- paste("COL", 1:n_cols, sep = "_")

  names(col_names) <- col_names

  data.frame(
    lapply(col_names, function(x) {
      stats::runif(n_rows, 0, 10)
    })
  )
}
