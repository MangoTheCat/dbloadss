library(RODBC)

db <- RODBC::odbcDriverConnect('driver={SQL Server};server=localhost\\SQL17ML;database=ml;trusted_connection=true')

nRows <- 10000000
simData <- data.frame(
  X1 = rnorm(nRows),
  X2 = rnorm(nRows),
  X3 = rnorm(nRows),
  X4 = rnorm(nRows),
  X5 = sample(letters, size = nRows, replace = TRUE),
  X6 = sample(letters, size = nRows, replace = TRUE)
)


RODBC::odbcQuery(db, "drop table simData;")
time10k <- system.time({
  RODBC::sqlSave(
    db,
    dat = simData[1:10000,],
    tablename = "simData",
    rownames = FALSE,
    fast = TRUE,
    safer = FALSE
  )
})


library(DBI)

dbi <- DBI::dbConnect(odbc::odbc(), 
                      driver = "SQL Server",
                      server="localhost\\SQL17ML",
                      database = "ml")


time10kodbc <- system.time({
  DBI::dbWriteTable(dbi, 
                    name = "simData2", 
                    value = simData[1:10000, ])
})
