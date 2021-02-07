SQLite Basics Reference Notebook
================
H. David Shea
2021-02-04

## Introduction

I am using our `SECDB` initial testing database for this notebook since
it is the first one I have worked on. The code in the notebook have
dependencies on the `DBI` and `RSQLite` libraries.

``` r
library(DBI)
library(RSQLite)
```

Basics covered in this notebook are:

-   connecting to a database

-   investigating database structures

-   creating a table

-   loading data into table

-   querying data from tables

-   updating data in a table

-   deleting data from a table

-   dropping a table

-   disconnecting from a database

We will employ a mix of `DBI` inherent data manipulation with built in
functions and `SQL` statement pass through via `DBI` helper functions.

## Connect to a database

The base `DBI` function `dbConnect` establishes a connection to an
existing database. It requires a connection object to tell it about the
type of database being connected and a file path to the physical
database. For our purposes, that is the default `SQLite` connection
supplied in the package: `RSQLite::SQLite()`. Mostly for demonstration
purposes, I first make a call to `dbCanConnect` which returns `TRUE` if
it is possible to make the connection.

``` r
base_dir <- here::here("")
(db_file <- fs::path(base_dir, "SECDB"))
#> /Users/shea2/R/stock_database/SECDB

if(dbCanConnect(RSQLite::SQLite(), db_file)) {
    secdb <- dbConnect(RSQLite::SQLite(), db_file)
}
```

## Investigating database structures

One of the simplest thing to do in the database is list the existing
tables. That is accomplished by using the `DBI` base function
`dbListTables`.

``` r
dbListTables(secdb)
#> [1] "adjusted_price"       "gics"                 "security"            
#> [4] "security_price"       "universe"             "universe_constituent"
```

To get a list of the fields from specific table, use the `DBI` base
function `dbListFields` supplying the table name of interest.

``` r
dbListFields(secdb, "gics")
#> [1] "code"  "level" "name"
```

## Creating a table

I am going to use data for the `gics` table which we saw in the list
above for all examples in this notebook. However, in order to
demonstrate how to create a table, I will create a *temporary* table -
`gics_temp` - which looks exactly like the `gics` table for the actual
work in the notebook. Later on, we will manipulate data in this table -
`INSERT`, `UPDATE` and `DELETE` - and then ultimately `DROP` the table
for illustration as well.

We have gics data (and other data) as pulled from wikipedia. The data in
the gics table are Global Industry Classification Standard (GICS®) data
developed by MSCI and Standard & Poor’s in 1999. They establish a
hierarchy of sector, industry group, industry and sub-industry
classifications for a broad array of global stocks.

The `stock_data_access.R` script within this project collects the
various data mentioned above. For the GICS data, the tibbles `sct_tbl`,
`igp_tbl`, `ind_tbl` and `sub_tbl` contain data for GICS sectors,
industry groups, industries and sub-industries, respectively. They all
have the same column structure. I will use the `sct_tbl` as the defining
structure for the `gics_temp` table creation.

The built in `DBI` function `dbCreateTable` requires a database
connection, a table name and a data frame with columns representing the
structure required for the table. It will use this information to
`CREATE` the underlying table.

``` r
dbCreateTable(secdb, "gics_temp", sct_tbl)

dbExistsTable(secdb, "gics_temp")
#> [1] TRUE

dbListFields(secdb, "gics_temp")
#> [1] "code"  "level" "name"
```

## Load data into tables

Here I will load data into the just created and empty `gics_temp` table
from the GICS data tibbles mentioned previously.

These are straight forward inserts using the built in `DBI` functions to
`INSERT` into a table. In a subsequent notebook, I will look at some
`INSERT`/`UPDATE` strategies for approaching some of the different table
metaphors that we will employ in the `SECDB` schema.

The base `DBI` function `dbWriteTable` requires a database connection,
table name and a data frame with the data to `INSERT` into the table. By
default, the function assumes that the table does not exist and will
`CREATE` it with column names from the data frame. By default, the
overwrite and append parameters are set to `FALSE` and will cause the
function to fail if the table already exists. Here I want to display the
functionality of `dbWriteTable` as well as `dbAppendTable` - which
`INSERT`s data into an existing table - so I will use `dbWriteTable`
with `overwrite = TRUE` on the initial `INSERT` (for sector data) and
will use `dbAppendTable` for the subsequent `INSERT`s for the industry
group, industry and sub-industry data.

``` r
dbWriteTable(secdb, "gics_temp", sct_tbl, overwrite = TRUE)

dbAppendTable(secdb, "gics_temp", igp_tbl)
#> [1] 24

dbAppendTable(secdb, "gics_temp", ind_tbl)
#> [1] 69

dbAppendTable(secdb, "gics_temp", sub_tbl)
#> [1] 158
```

Note that the `dbAppendTable` calls return the number of rows inserted
into the table.

## Select data from tables

Now that we have some data in one of the `SECDB` tables, we can execute
some queries to pull data into our R session. Here I will use direct
`SQL` statements (e.g., `SELECT* FROM gics_temp`) with the `DBI` help
function set `dbSendQuery` - which executes the `SQL` `SELECT` statement
within the database and returns a *results reference object* - and
`dbFetch` which uses the *results reference object* to pull the `SQL`
statement results back into the R session in a data frame. Once finished
with the *results reference object*, the `dbClearResults` function frees
all resources (local and remote) associated with a result set -
essential for good memory management.

``` r
res <- dbSendQuery(secdb, "SELECT * FROM gics_temp WHERE level = 'SCT'")
dbFetch(res)
#>    code level                   name
#> 1    10   SCT                 Energy
#> 2    15   SCT              Materials
#> 3    20   SCT            Industrials
#> 4    25   SCT Consumer Discretionary
#> 5    30   SCT       Consumer Staples
#> 6    35   SCT            Health Care
#> 7    40   SCT             Financials
#> 8    45   SCT Information Technology
#> 9    50   SCT Communication Services
#> 10   55   SCT              Utilities
#> 11   60   SCT            Real Estate
dbClearResult(res)

res <- dbSendQuery(secdb, "SELECT * FROM gics_temp WHERE level = 'IGP'")
head(dbFetch(res), 10)
#>    code level                               name
#> 1  1010   IGP                             Energy
#> 2  1510   IGP                          Materials
#> 3  2010   IGP                      Capital Goods
#> 4  2020   IGP Commercial & Professional Services
#> 5  2030   IGP                     Transportation
#> 6  2510   IGP           Automobiles & Components
#> 7  2520   IGP        Consumer Durables & Apparel
#> 8  2530   IGP                  Consumer Services
#> 9  2550   IGP                          Retailing
#> 10 3010   IGP           Food & Staples Retailing
dbClearResult(res)

res <- dbSendQuery(secdb, "SELECT * FROM gics_temp WHERE level = 'IND'")
head(dbFetch(res), 10)
#>      code level                        name
#> 1  101010   IND Energy Equipment & Services
#> 2  101020   IND Oil, Gas & Consumable Fuels
#> 3  151010   IND                   Chemicals
#> 4  151020   IND      Construction Materials
#> 5  151030   IND      Containers & Packaging
#> 6  151040   IND             Metals & Mining
#> 7  151050   IND     Paper & Forest Products
#> 8  201010   IND         Aerospace & Defense
#> 9  201020   IND           Building Products
#> 10 201030   IND  Construction & Engineering
dbClearResult(res)

res <- dbSendQuery(secdb, "SELECT * FROM gics_temp WHERE level = 'SUB'")
head(dbFetch(res), 10)
#>        code level                                 name
#> 1  10101010   SUB                   Oil & Gas Drilling
#> 2  10101020   SUB       Oil & Gas Equipment & Services
#> 3  10102010   SUB                 Integrated Oil & Gas
#> 4  10102020   SUB   Oil & Gas Exploration & Production
#> 5  10102030   SUB       Oil & Gas Refining & Marketing
#> 6  10102040   SUB   Oil & Gas Storage & Transportation
#> 7  10102050   SUB              Coal & Consumable Fuels
#> 8  15101010   SUB                  Commodity Chemicals
#> 9  15101020   SUB                Diversified Chemicals
#> 10 15101030   SUB Fertilizers & Agricultural Chemicals
dbClearResult(res)
```

## Updating data in a table

Here, I demonstrate updating existing data within a table. The
`dbSendQuery` function is only appropriate for extracting data from the
database via `SELECT` statements. For all other data manipulation within
the database via `SQL` statements (e.g., `UPDATE`, `DELETE`,
`INSERT INTO`, `DROP TABLE`, etc.), `DBI` provides the `dbSendStatement`
function. This should be used in conjunction with the `dbHasCompleted`
function which returns when/if the operation has completed. Then a call
to `dbGetRowsAffected` can be used to determine how many rows were
affected by the `dbSendStatement` function. As with `dbSendQuery`, when
finished with the results reference object, a call to the
`dbClearResults` function frees all resources (local and remote)
associated with a result set - which is essential for good memory
management.

``` r
res <- dbSendStatement(secdb, "UPDATE gics_temp SET code = code + 100 WHERE level = 'SCT'")
if(dbHasCompleted(res)) {
    dbGetRowsAffected(res)
}
#> [1] 11
dbClearResult(res)

res <- dbSendQuery(secdb, "SELECT * FROM gics_temp WHERE level = 'SCT'")
dbFetch(res)
#>    code level                   name
#> 1   110   SCT                 Energy
#> 2   115   SCT              Materials
#> 3   120   SCT            Industrials
#> 4   125   SCT Consumer Discretionary
#> 5   130   SCT       Consumer Staples
#> 6   135   SCT            Health Care
#> 7   140   SCT             Financials
#> 8   145   SCT Information Technology
#> 9   150   SCT Communication Services
#> 10  155   SCT              Utilities
#> 11  160   SCT            Real Estate
dbClearResult(res)

res <- dbSendStatement(secdb, "UPDATE gics_temp SET code = code - 100 WHERE level = 'SCT'")
if(dbHasCompleted(res)) {
    dbGetRowsAffected(res)
}
#> [1] 11
dbClearResult(res)
```

## Deleting data from a table

Here I demonstrate deleting data from a table. The first `DELETE`
statement removes selected rows from the table - specifically those
`WHERE level = 'SCT'`. The second `DELETE` statement removes all of the
remaining data in the table - here, no `WHERE` clause is provided in the
`DELETE` statement. The same sequence of `dbSendStatement`,
`dbHasCompleted`, `dbGetRowsAffected` and `dbClearResult` as used in the
`UPDATE` example are used here.

``` r
res <- dbSendStatement(secdb, "DELETE FROM gics_temp WHERE level = 'SCT'")
if(dbHasCompleted(res)) {
    dbGetRowsAffected(res)
}
#> [1] 11
dbClearResult(res)

res <- dbSendQuery(secdb, "SELECT * FROM gics_temp WHERE level = 'SCT'")
dbFetch(res)
#> [1] code  level name 
#> <0 rows> (or 0-length row.names)
dbClearResult(res)

res <- dbSendStatement(secdb, "DELETE FROM gics_temp")
if(dbHasCompleted(res)) {
    dbGetRowsAffected(res)
}
#> [1] 251
dbClearResult(res)
```

## Dropping a table

Now, we look at the `DROP TABLE` operation. First, I check that there
are no data in the `gics_temp` table - just to verify that the previous
`DELETE` cleared all of the remaining data. Then I use the `DBI` base
`dbRemoveTable` function to `DROP` the table. Note that the above
combination of `SQL` statement execution for the `UPDATE` and `DELETE`
examples could be used for the `DROP TABLE` execution as well.

``` r
res <- dbSendQuery(secdb, "SELECT * FROM gics_temp")
dbFetch(res)
#> [1] code  level name 
#> <0 rows> (or 0-length row.names)
dbClearResult(res)

dbExistsTable(secdb, "gics_temp")
#> [1] TRUE
dbRemoveTable(secdb, "gics_temp")
dbExistsTable(secdb, "gics_temp")
#> [1] FALSE

dbListTables(secdb)
#> [1] "adjusted_price"       "gics"                 "security"            
#> [4] "security_price"       "universe"             "universe_constituent"
```

## Disconnecting from a database

And finally, I will disconnect from the database. The `dbDisconnect`
function closes the connection, discards all pending work, and frees
resources - again essential for good memory management.

``` r
dbDisconnect(secdb)
```
