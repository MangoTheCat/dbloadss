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
#>      COL_1        COL_2     COL_3     COL_4    COL_5
#> 1 3.514714 0.4245965858 7.7877304 1.0901371 2.900792
#> 2 6.691659 8.3968263515 9.1917160 0.5320272 5.376543
#> 3 2.308083 6.5290802228 7.4452816 1.8804203 7.918519
#> 4 9.217424 0.9727795655 0.9013302 8.4349369 9.294825
#> 5 5.765103 0.0002394384 5.9098808 3.4944267 9.910877
```

RODBC
-----

`RODBC` was, for a long time, the standard way to connect to SQL Server.

ODBC
----

`odbc` is a relatively new package from RStudio which provides a DBI compliant ODBC interface.

SQL Server External Script
--------------------------

An alternative approach is to use the new features in SQL Server 17 (and 16) for calling out to R scripts from SQL. This is done via the `sp_execute_external_script` command, which we will wrap in a stored procedure.

License
=======

MIT © Mango Solutions
