<!-- README.md is generated from README.Rmd. Please edit that file -->
dbloadss
========

This package and accompanying scripts is to test load times to MS SQL Server 17 (SS) from various methods:

1.  Push from R with `RODBC`
2.  Push from R with `odbc`
3.  Pull from SS with a stored procedure

This package is really for number 3. We can do the rest from a script, although it's a useful place to keep some functions.

Test Database
=============

The code for this post runs on my Windows 10 laptop, where I have a local SQL Server 17 instance running, with a database called `ml`.

Load Times
==========

We're going to push a big data frame into SQL Server using three methods. The data set is a simple randomly generated data frame.

``` r
library(dbloadss)

random_data_set(n_rows = 5, n_cols = 5)
#>       COL_1    COL_2     COL_3    COL_4    COL_5
#> 1 7.9700882 2.534203 3.8468740 4.846999 3.554365
#> 2 4.0936430 7.565552 3.1657256 2.141528 3.208285
#> 3 0.9447392 4.957917 5.3309777 1.798137 6.678179
#> 4 2.0889679 8.918446 0.8271645 9.950788 4.035818
#> 5 6.7827475 4.993807 0.6388639 5.940411 8.803349
```

R is pretty quick at this sort of thing so we don't really need to worry about how long it takes to make a big data frame.

``` r
n_rows <- 3000000
system.time({
  random_data <- random_data_set(n_rows = n_rows, n_cols = 5)
})
#>    user  system elapsed 
#>    0.78    0.02    0.81
```

but what we're interested in is how fast to push this to SQL Server?.

RODBC
-----

`RODBC` was, for a long time, the standard way to connect to SQL Server from R. It's a great package that makes it easy to send queries, collect results, and handles type conversions pretty well. However, it is a bit slow for pushing data in. The fastest I could manage was using the `sqlSave` function with the safeties off. Very interested to hear if there's a better method. For 3m rows it's a no go. So scaling back to 30k rows we get:

``` r
library(RODBC)

db <- odbcDriverConnect('driver={SQL Server};server=localhost\\SQL17ML;database=ml;trusted_connection=true')

n_rodbc <- 30000

odbcQuery(db, "drop table randData;")
#> [1] 1
time30k <- system.time({
  RODBC::sqlSave(
    db,
    dat = random_data[1:n_rodbc,],
    tablename = "randData",
    rownames = FALSE,
    fast = TRUE,
    safer = FALSE
  )
})
odbcClose(db)

time30k
#>    user  system elapsed 
#>    2.25    0.88  146.19
```

Over 2 minutes! It's been roughly linear for me so that total write time for 3m rows is a few hours.

ODBC
----

`odbc` is a relatively new package from RStudio which provides a DBI compliant ODBC interface. It is considerably faster for writes. Here we'll push the full 3m rows.

``` r
library(DBI)

dbi <- dbConnect(odbc::odbc(),
                 driver = "SQL Server",
                 server="localhost\\SQL17ML",
                 database = "ml")

time3modbc <- system.time({
  dbWriteTable(dbi,
               name = "randData",
               value = random_data,
               overwrite = TRUE)
})
dbDisconnect(dbi)

time3modbc
#>    user  system elapsed 
#>   10.40    0.56   64.09
```

SQL Server External Script
--------------------------

An alternative approach is to use the new features in SQL Server 17 (and 16) for calling out to R scripts from SQL. This is done via the `sp_execute_external_script` command, which we will wrap in a stored procedure.

License
=======

MIT © Mango Solutions
