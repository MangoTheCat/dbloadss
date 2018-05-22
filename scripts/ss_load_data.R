library(odbc)
library(nycflights13)

con <- DBI::dbConnect(
  odbc::odbc(),
  driver = "SQL Server",
  server = "localhost\\SQL17ML",
  database = "ml"
)

flights$id <- 1:nrow(flights)

DBI::dbWriteTable(con, "flights", flights, overwrite = TRUE)

