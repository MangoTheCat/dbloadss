Deploying R Models in SQL Server
================
Doug Ashton
23 May 2018

Introduction
------------

As an R user who is building models and analysing data one of the key challenges is how do you make those results available to those who need it? After all, data science is about making better decisions, and your results need to get into the hands of the people who make those decisions.

For reporting there are many options from writing [Excel files](https://www.mango-solutions.com/blog/r-the-excel-connection) to [rmarkdown documents](https://rmarkdown.rstudio.com/) and [shiny apps](https://shiny.rstudio.com/). Many businesses will require results to go into a business intelligence (BI) tool alongside a number of other critcial business metrics. Moreover the results need to be refreshed daily. In this situation you will be working with SQL developers to integrate your work. The question is, what is the best way to deliver R code to the BI team?

In this blog post we will be looking at the specific case of deploying a predictive model, written in R, to a Microsoft SQL Server database for consumption by a BI tool. Since SQL Server 16 it is possible to run R services in-database. We'll compare this to controlling the process from R and pushing with [ODBC](https://en.wikipedia.org/wiki/Open_Database_Connectivity).

### Flight delay planning

To demonstrate we'll use the `flights` dataset from the [nycflights13](https://CRAN.R-project.org/package=nycflights13) package to imagine that we are airport planners and we want to test various scenarios related to flight delays. Our data contains the departure delay of all flights leaving the New York airports: JFK, LGA, and EWR in 2013. We've already loaded the dataset into SQL Server. Below is a selection of columns.

``` sql
SELECT TOP(5) flight, origin, dest, sched_dep_time, carrier, time_hour, dep_delay
FROM flights
```

|  flight| origin | dest |  sched\_dep\_time| carrier | time\_hour          |  dep\_delay|
|-------:|:-------|:-----|-----------------:|:--------|:--------------------|-----------:|
|    1545| EWR    | IAH  |               515| UA      | 2013-01-01 05:00:00 |           2|
|    1714| LGA    | IAH  |               529| UA      | 2013-01-01 05:00:00 |           4|
|    1141| JFK    | MIA  |               540| AA      | 2013-01-01 05:00:00 |           2|
|     725| JFK    | BQN  |               545| B6      | 2013-01-01 05:00:00 |          -1|
|     461| LGA    | ATL  |               600| DL      | 2013-01-01 06:00:00 |          -6|

We'll fit a statistical model for the departure delay, and run simulations for the delay of future flights. We want to capture the natural variation from day to day so a useful approach here is a mixed-effects model where each day is a random effect.

``` r
model <- lme4::lmer(
    dep_delay ~ 1 +
      (1 | date:origin) +
      carrier +
      origin +
      sched_dep_time +
      distance +
      week_day,
    data = data_train
  )
```

This is a simple model for demonstration purpopses. For example, it doesn't capture big delays (extreme values) well, but it will serve our purpose. The full model code and data prep is available at [mangothecat/dbloadss](https://github.com/mangothecat/dbloadss) so we won't go through every line here.

Implementation
--------------

The data scientist has done their exploratory work, made some nice notebooks, and are really happy with their p-values. How do we now deploy their model?

### Use Packages

At Mango we believe that the basic unit of work is a package. A well written package will be self-documenting, have a familiar structure, and unit tests. All behind-the-scenes code can be written into unexported functions, and user facing code lives in a small number (often one) of exported functions. This single entry point should be designed for someone who is not an R user to run the code, and if anything goes wrong, be as informative as possible.

The code for this blog post lives in the [dbloadss](https://github.com/mangothecat/dbloadss) package available on GitHub.

### Output Everything

A data scientist will ask: "how can I predict `dep_delay` as accurately as possible?". An airport manager will want to know "how often will the last flight of the day leave after midnight?", or another question that you haven't thought of.

Of course we can use R to answer each of these questions one at a time. However, this is frustrating for everyone because the data scientist wants to be modelling, and the business user has to wait for each new answer.

Fortunately, this is exactly the kind of thing that SQL and BI tools are built to do. So instead of processing the results in R we will output every simulation run into SQL Server and do the post processing in the database or BI tool.

### Push or Pull?

Once the model has been packaged and the interface decided, it remains to decide how to actually run the code. With SQL Server there are three options:

1.  Run the model from R and *push* the results to SQL Server using an ODBC connection.
2.  Call the model from SQL Server using a stored procedure to run an R script using R Services and *pull* the results back.
3.  Invoke an Rscript from SSIS.

Which you choose will depend on a number of factors. Most importantly the skill set of the people managing the process. We'll take some time to look at each one.

The Push (SQL from R)
---------------------

The Pull (R from SQL)
---------------------

The Shift (R from SSIS)
-----------------------

<!-- Blend the below benchmark in -->
Test Database
=============

The code for this post runs on my Windows 10 laptop, where I have a local SQL Server 17 instance running, with a database called `ml`.

Load Times
==========

We're going to push a big data frame into SQL Server using three methods. The data set is a simple randomly generated data frame.

``` r
library(dbloadss)

random_data_set(n_rows = 5, n_cols = 5)
```

    ##      COL_1    COL_2    COL_3     COL_4    COL_5
    ## 1 4.295615 5.539700 4.334157 0.6487283 7.612783
    ## 2 0.033995 6.376495 0.433236 2.3049353 2.036160
    ## 3 3.725420 7.048729 1.841131 6.8994631 7.716952
    ## 4 3.073810 8.147071 2.654020 2.5835894 8.535301
    ## 5 4.962280 8.692725 6.410752 8.2748814 6.859934

R is pretty quick at this sort of thing so we don't really need to worry about how long it takes to make a big data frame.

``` r
n_rows <- 3000000
system.time({
  random_data <- random_data_set(n_rows = n_rows, n_cols = 5)
})
```

    ##    user  system elapsed 
    ##    0.78    0.02    0.81

but what we're interested in is how fast to push this to SQL Server?.

RODBC
-----

`RODBC` was, for a long time, the standard way to connect to SQL Server from R. It's a great package that makes it easy to send queries, collect results, and handles type conversions pretty well. However, it is a bit slow for pushing data in. The fastest I could manage was using the `sqlSave` function with the safeties off. Very interested to hear if there's a better method. For 3m rows it's a no go. So scaling back to 30k rows we get:

``` r
library(RODBC)

db <- odbcDriverConnect('driver={SQL Server};server=localhost\\SQL17ML;database=ml;trusted_connection=true')

n_rodbc <- 30000

odbcQuery(db, "drop table randData;")
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
