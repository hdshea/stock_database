SECDB - Database Initialization Notebook
================
H. David Shea
2021-02-09

## Introduction

This notebook documents **and** initializes the `SECDB` basic stock
research database. Only the definition and group constituent tables are
initialized with the chunks processed in this notebook. However, all
tables are dropped and recreated when running the processing chunks. The
database is currently designed to store stock research data for a large
section of US listed and traded stocks - roughly representing the stocks
in the S&P 1500 Index (SP1500). This initialization procedure assumes
that the initiation date (`start_date` in time dependent definition and
group constituent tables) for all data in the SECDB database is *today*.

NOTE: This will be adjusted when we - later - load the pricing data for
securities and get a better feel for the actual time frame for
securities.

Sidebar: This notebook will also serve to document/experiment with
mixing multiple execution engines within a single R Markdown document.
Specifically, I will use the `bash`, `sql`, and `r` engines in various
processing chunks within this notebook. One of the drawbacks that I have
seen so far with chunks using the `sql` engine, is that only single
`SQL` statements can be executed within the chunk. So, when many `SQL`
statements are *logically* required together - for instance when
dropping or recreating the entire schema - I have included the `SQL`
statements in a script file and process them via the `SQLite` command
within a `bash` engine chunk.

## Recreate SECDB

The next two code chunks process `SQL` scripts through the
`sqlite3 SECDB` command via the `bash` engine.

This chunk references `DROP_SECDB_SCHEMA.SQL` as input to drop all of
the schema objects for `SECDB`. Note that if the schema objects do not
exist, you will see warning messages.

``` bash
sqlite3 SECDB < DROP_SECDB_SCHEMA.SQL
#> Dropping SECDB schema objects...
```

This chunk references `CREATE_SECDB_SCHEMA.SQL` as input to create all
of the schema objects for `SECDB`.

``` bash
sqlite3 SECDB < CREATE_SECDB_SCHEMA.SQL
#> Creating SECDB schema objects...
```

The next chunk - which is an `r` chunk - uses the `RSQLite` function
`dbListTables` to verify that the tables have been created.

``` r
dbListTables(secdb)
#> [1] "adjusted_price" "factor"         "factor_data"    "gics"          
#> [5] "security"       "security_price"
```

## Initialize base SECDB definition and group constituent tables

As mentioned, the SECDB database is currently designed to store stock
research data for - roughly - the stocks in the S&P 1500 Index (SP1500).

The base data that we will populate within this notebook are populated
with data sourced from wikipedia. The `stock_data_access.R` script
within this project collects the various data required by scraping
various web pages. These data include descriptive data for the
securities in the SP500, SP400 and SP600 - collectively the SP1500 and
industry classification data for the securities.

The script is sourced below so that the tibbles produced are available
for loading into the appropriate base tables.

NOTE: There is a portion of this code which accesses Yahoo Finance which
takes a long time to process and - currently - has limited utility for
sourcing sub-industry classifications for some older securities with
missing classifications. Looking for a better solution currently.

``` r
source(fs::path(base_dir, "stock_data_access.R"))
```

The data in the gics table are Global Industry Classification Standard
(GICS®) data developed by MSCI and Standard & Poor’s in 1999. They
establish a hierarchy of sector, industry group, industry and
sub-industry classifications for a broad array of global stocks.

For the GICS data, the tibbles `sct_tbl`, `igp_tbl`, `ind_tbl` and
`sub_tbl` contain data for GICS sectors, industry groups, industries and
sub-industries, respectively. They all have the same column structure.
The following `r` chunk uses the base `DBI` function `dbAppendTable` to
`INSERT` the data from the four tibbles.

``` r
dbAppendTable(secdb, "gics", sct_tbl)
#> [1] 11

dbAppendTable(secdb, "gics", igp_tbl)
#> [1] 24

dbAppendTable(secdb, "gics", ind_tbl)
#> [1] 69

dbAppendTable(secdb, "gics", sub_tbl)
#> [1] 158
```

Note that the `dbAppendTable` calls return the number of rows inserted
into the table for each call. And, we can check with the following raw
`sql` chunks to verify that the data are loaded correctly.

``` sql
SELECT *
FROM   gics
WHERE  level = 'SCT';
```

<div class="knitsql-table">

| code | level | name                   |
|-----:|:------|:-----------------------|
|   50 | SCT   | Communication Services |
|   25 | SCT   | Consumer Discretionary |
|   30 | SCT   | Consumer Staples       |
|   10 | SCT   | Energy                 |
|   40 | SCT   | Financials             |
|   35 | SCT   | Health Care            |
|   20 | SCT   | Industrials            |
|   45 | SCT   | Information Technology |
|   15 | SCT   | Materials              |
|   60 | SCT   | Real Estate            |

Displaying records 1 - 10

</div>

``` sql
SELECT * 
FROM   gics
WHERE  level = 'IGP';
```

<div class="knitsql-table">

| code | level | name                               |
|-----:|:------|:-----------------------------------|
| 2510 | IGP   | Automobiles & Components           |
| 4010 | IGP   | Banks                              |
| 2010 | IGP   | Capital Goods                      |
| 2020 | IGP   | Commercial & Professional Services |
| 5010 | IGP   | Communication Services             |
| 2520 | IGP   | Consumer Durables & Apparel        |
| 2530 | IGP   | Consumer Services                  |
| 4020 | IGP   | Diversified Financials             |
| 1010 | IGP   | Energy                             |
| 3010 | IGP   | Food & Staples Retailing           |

Displaying records 1 - 10

</div>

``` sql
SELECT * 
FROM   gics
WHERE  level = 'IND';
```

<div class="knitsql-table">

|   code | level | name                    |
|-------:|:------|:------------------------|
| 201010 | IND   | Aerospace & Defense     |
| 203010 | IND   | Air Freight & Logistics |
| 203020 | IND   | Airlines                |
| 251010 | IND   | Auto Components         |
| 251020 | IND   | Automobiles             |
| 401010 | IND   | Banks                   |
| 302010 | IND   | Beverages               |
| 352010 | IND   | Biotechnology           |
| 201020 | IND   | Building Products       |
| 402030 | IND   | Capital Markets         |

Displaying records 1 - 10

</div>

``` sql
SELECT *
FROM   gics
WHERE  level = 'SUB';
```

<div class="knitsql-table">

|     code | level | name                          |
|---------:|:------|:------------------------------|
| 50201010 | SUB   | Advertising                   |
| 20101010 | SUB   | Aerospace & Defense           |
| 20106015 | SUB   | Agricultural & Farm Machinery |
| 30202010 | SUB   | Agricultural Products         |
| 20301010 | SUB   | Air Freight & Logistics       |
| 20302010 | SUB   | Airlines                      |
| 20305010 | SUB   | Airport Services              |
| 50101010 | SUB   | Alternative Carriers          |
| 15104010 | SUB   | Aluminum                      |
| 25504010 | SUB   | Apparel Retail                |

Displaying records 1 - 10

</div>

Note that for `sql` chunks, the default in R Markdown is to display the
first 10 records returned by `SELECT` statements in a document. This can
be changed with the chunk option `max.print` which can be set equal to a
specific number or to no limit by using `max.print = -1` or
`max.print = NA`.

For descriptive security data, the above script pulled data for the S&P
1500 index constituents.

Data for the SP1500 are contained in the tibble `sp1500_tbl`. For the
initialization, the sourced file above assumed that the `security` table
was empty and created `uid` values explicitly. This is actually required
because the auto-populate primary key functionality in `SQLite` only
works when there is a single integer field primary key. The primary key
for the `security` table references the `uid` and the `start_date`
fields.

*\[TODO: discuss strategy for future insertions\]*

The data in the `sp500_tbl` mimic the tables structure for the
`security` table which is required in order to use the `dbAppendTable`
function.

``` r
sp1500_tbl
#> # A tibble: 1,888 x 6
#>      uid start_date end_date   symbol name                   sub_industry_code
#>    <int> <chr>      <chr>      <chr>  <chr>                              <int>
#>  1     1 2021-02-19 9999-12-31 MMM    3M Company                      20105010
#>  2     2 2021-02-19 9999-12-31 ABT    Abbott Laboratories             35101010
#>  3     3 2021-02-19 9999-12-31 ABBV   AbbVie Inc.                     35202010
#>  4     4 2021-02-19 9999-12-31 ABMD   Abiomed                         35101010
#>  5     5 2021-02-19 9999-12-31 ACN    Accenture                       45102010
#>  6     6 2021-02-19 9999-12-31 ATVI   Activision Blizzard             50202020
#>  7     7 2021-02-19 9999-12-31 ADBE   Adobe Inc.                      45103010
#>  8     8 2021-02-19 9999-12-31 AMD    Advanced Micro Devices          45301020
#>  9     9 2021-02-19 9999-12-31 AAP    Advance Auto Parts              25504050
#> 10    10 2021-02-19 9999-12-31 AES    AES Corp                        55105010
#> # … with 1,878 more rows
```

The following `r` chunk uses the base `DBI` function `dbAppendTable` to
`INSERT` the data from the `sp1500_tbl` tibble into the `security`
table.

``` r
dbAppendTable(secdb, "security", sp1500_tbl)
#> [1] 1888
```

And, we can check with the following raw `sql` chunks to verify that the
security data are loaded correctly. I also take the opportunity here to
display a `SQL` join between the `security` table and the `gics` table
to display the sector name for the security which is accessed by using
the first two digits of the `sub_industry_code` for the security. Note
that `SQL` does all of the appropriate number and character and back to
number conversion that is required to make the `WHERE` clause join logic
work correctly.

``` sql
SELECT uid,
       DATE(start_date) AS start_date,
       DATE(end_date) AS end_date,
       symbol,
       security.name AS name,
       gics.name AS sector
FROM   security,
       gics
WHERE  gics.level = 'SCT'
  AND  gics.code = SUBSTR(security.sub_industry_code,1,2);
```

<div class="knitsql-table">

| uid | start\_date | end\_date  | symbol | name                   | sector                 |
|:----|:------------|:-----------|:-------|:-----------------------|:-----------------------|
| 1   | 2021-02-19  | 9999-12-31 | MMM    | 3M Company             | Industrials            |
| 2   | 2021-02-19  | 9999-12-31 | ABT    | Abbott Laboratories    | Health Care            |
| 3   | 2021-02-19  | 9999-12-31 | ABBV   | AbbVie Inc.            | Health Care            |
| 4   | 2021-02-19  | 9999-12-31 | ABMD   | Abiomed                | Health Care            |
| 5   | 2021-02-19  | 9999-12-31 | ACN    | Accenture              | Information Technology |
| 6   | 2021-02-19  | 9999-12-31 | ATVI   | Activision Blizzard    | Communication Services |
| 7   | 2021-02-19  | 9999-12-31 | ADBE   | Adobe Inc.             | Information Technology |
| 8   | 2021-02-19  | 9999-12-31 | AMD    | Advanced Micro Devices | Information Technology |
| 9   | 2021-02-19  | 9999-12-31 | AAP    | Advance Auto Parts     | Consumer Discretionary |
| 10  | 2021-02-19  | 9999-12-31 | AES    | AES Corp               | Utilities              |

Displaying records 1 - 10

</div>
