<!-- README.md is generated from README.Rmd. Please edit that file -->
dbloadssss
==========

This package and accompanying scripts is to test load times to MS SQL Server 17 (SS) from various methods:

1.  Pull from SS with a stored procedure
2.  Push from R with `odbc`
3.  Push from R with `RODBC`

This package is really for number 1. We can do the rest from a script, although it's a useful place to keep some functions.

Test Database
=============

The code for this post runs on my Windows 10 laptop, where I have a local SQL Server 17 instance running, with a database called `ml`.

RODBC
=====

`RODBC` was, for a long time, the standard way to connect to SQL Server.

ODBC
====

`odbc` is a relatively new package from RStudio which provides a DBI compliant ODBC interface.

SQL Server External Script
==========================

An alternative approach is to use the new features in SQL Server 17 (and 16) for calling out to R scripts from SQL. This is done via the `sp_execute_external_script` command, which we will wrap in a stored procedure.

License
=======

MIT © Mango Solutions
