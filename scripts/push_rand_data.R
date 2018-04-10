
library(DBI)
devtools::load_all()

dbi <- DBI::dbConnect(odbc::odbc(),
                      driver = "SQL Server",
                      server="localhost\\SQL17ML",
                      database = "ml")


time3modbc <- system.time({
  DBI::dbWriteTable(dbi,
                    name = "randData",
                    value = random_data_set(3000000),
                    overwrite = TRUE)
})

time3modbc
