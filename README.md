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
#>      COL_1    COL_2     COL_3    COL_4    COL_5
#> 1 7.337917 3.873387 0.4994443 2.026814 9.443235
#> 2 2.281623 4.896035 6.9717638 8.305794 7.919791
#> 3 3.512538 1.542272 5.2494306 3.978269 3.453247
#> 4 5.815818 2.686854 7.6096585 2.029168 8.976130
#> 5 3.637890 6.507928 2.3285816 8.489208 5.399292
```

R is pretty quick at this sort of thing so we don't really need to worry about how long it takes to make a big data frame.

``` r
n_rows <- 3000000
system.time({
  random_data <- random_data_set(n_rows = n_rows, n_cols = 5)
})
#>    user  system elapsed 
#>    0.75    0.01    0.81
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
#>    1.95    0.62  142.98
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
#>   10.28    0.62   63.80
```

SQL Server External Script
--------------------------

An alternative approach is to use the new features in SQL Server 17 (and 16) for calling out to R scripts from SQL. This is done via the `sp_execute_external_script` command, which we will wrap in a stored procedure. This is what that looks like for me:

``` sql
use [ml];

DROP PROC IF EXISTS generate_random_data;
GO
CREATE PROC generate_random_data(@nrow int)
AS
BEGIN
 EXEC sp_execute_external_script
       @language = N'R'  
     , @script = N'  
          library(dbloadss)
          random_data <- random_data_set(n_rows = nrow_r, n_cols = 5)
' 
   , @output_data_1_name = N'random_data'
     , @params = N'@nrow_r int'
     , @nrow_r = @nrow
    WITH RESULT SETS ((
          "COL_1" float not null,   
        "COL_2" float not null,  
        "COL_3" float not null,   
        "COL_4" float not null,
            "COL_5" float not null)); 
END;
GO
```

We then call the stored procedure with another query (skipping out a step that clears it inbetween tests).

``` sql
INSERT INTO randData
EXEC [dbo].[generate_random_data] @nrow = 3000000
```

![SQL Server Timer](SStime.jpg)

and this runs in 34 seconds. My best guess for the performance increase is that the data is serialised more efficiently. More to investigate.

License
=======

MIT © Mango Solutions
