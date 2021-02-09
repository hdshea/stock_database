SECDB - Database Initialization Notebook
================
H. David Shea
2021-02-09

## Introduction

This notebook documents ***and*** initializes the `SECDB` basic stock
research database. Only the definition and group constituent tables are
initialized with the chunks processed in this database. However, all
tables are dropped and recreated when running the processing chunks. The
database is currently designed to store stock research data for the
stocks in the Dow Jones Industrial Average (DJIA) and the S&P 500 Index
(SP500). Currently, the DJIA stocks are all completely contained within
the SP500. If that were to change in the future, some additional
processing would be required. This initialization procedure assumes that
the initiation date (`start_date` in time dependent definition and group
constituent tables) for all data in the SECDB database is *today*.

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
#> [1] "adjusted_price"       "gics"                 "security"            
#> [4] "security_price"       "universe"             "universe_constituent"
```

## Initialize base SECDB definition and group constituent tables

As mentioned, the SECDB database is currently designed to store stock
research data for the stocks in the Dow Jones Industrial Average (DJIA)
and the S&P 500 Index (SP500). The DJIA and the SP500 are identified as
*stock universes* in SECDB. The `universe` table contains static
definitions for all of the individual universe.

The following chunks are the raw `sql` code to initialize the instances
of the DJIA and SP500 data within the `universe` table. Note that these
`INSERT` statements use the auto-populate primary key functionality in
`SQLite` to fill in the `uid` fields with the next available sequential
unique values allowed within the table.

``` sql
INSERT
INTO   universe( name, description )
VALUES ( 'DJIA', 'Dow Jones Industrial Average' );
```

``` sql
INSERT
INTO   universe( name, description )
VALUES ( 'SP500', 'S&P 500 Index' );
```

And then, we can quickly check with the following raw `sql` chunk that
the appropriate values have been inserted.

``` sql
SELECT *
FROM   universe;
```

<div class="knitsql-table">

| uid | name  | description                  |
|:----|:------|:-----------------------------|
| 1   | DJIA  | Dow Jones Industrial Average |
| 2   | SP500 | S&P 500 Index                |

</div>

The other base data that we will populate within this notebook are
populated with data sourced from wikipedia. The `stock_data_access.R`
script within this project collects the various data required by
scraping various web pages. These data include descriptive data for the
securities in the DJIA and SP500, industry classification data for the
securities, and the universe groupings for the DJIA and SP500
constituents.

The script is sourced below so that the tibbles produced are available
for loading into the appropriate base tables.

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
specific number ro to no limit by using `max.print = -1` or
`max.print = NA`.

For descriptive security data, the above script pulled data for the S&P
500 index constituents and the Dow Jones Industrial Average
constituents. As mentioned in the introduction, all of the DJIA stocks
are contained within the SP500 stocks. As such, only the SP500
descriptive data will be used to initialize the `security` table.

For the SP500 data are contained in the tibble `SP500_tbl`. For the
initialization, the sourced file above assumed that the `security` table
was empty and created `uid` values explicitly. This is actually required
because the auto-populate primary key functionality in `SQLite` only
works when there is a single integer field primary key. The primary key
for the `security` table references the `uid` and the `start_date`
fields.

The data in the `sp500_tbl` mimic the tables structure for the
`security` table which is required in order to use the `dbAppendTable`
function.

``` r
sp500_tbl
#> # A tibble: 505 x 6
#>      uid start_date end_date   symbol name                      sub_industry_co…
#>    <int> <chr>      <chr>      <chr>  <chr>                                <int>
#>  1     1 2021-02-09 9999-12-31 MMM    3M Company                        20105010
#>  2     2 2021-02-09 9999-12-31 ABT    Abbott Laboratories               35101010
#>  3     3 2021-02-09 9999-12-31 ABBV   AbbVie Inc.                       35202010
#>  4     4 2021-02-09 9999-12-31 ABMD   ABIOMED Inc                       35101010
#>  5     5 2021-02-09 9999-12-31 ACN    Accenture plc                     45102010
#>  6     6 2021-02-09 9999-12-31 ATVI   Activision Blizzard               50202020
#>  7     7 2021-02-09 9999-12-31 ADBE   Adobe Inc.                        45103010
#>  8     8 2021-02-09 9999-12-31 AMD    Advanced Micro Devices I…         45301020
#>  9     9 2021-02-09 9999-12-31 AAP    Advance Auto Parts                25504050
#> 10    10 2021-02-09 9999-12-31 AES    AES Corp                          55105010
#> # … with 495 more rows
```

The following `r` chunk uses the base `DBI` function `dbAppendTable` to
`INSERT` the data from the `sp500_tbl` tibble into the `security` table.

``` r
dbAppendTable(secdb, "security", sp500_tbl)
#> [1] 505
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

| uid | start\_date | end\_date  | symbol | name                       | sector                 |
|:----|:------------|:-----------|:-------|:---------------------------|:-----------------------|
| 1   | 2021-02-09  | 9999-12-31 | MMM    | 3M Company                 | Industrials            |
| 2   | 2021-02-09  | 9999-12-31 | ABT    | Abbott Laboratories        | Health Care            |
| 3   | 2021-02-09  | 9999-12-31 | ABBV   | AbbVie Inc.                | Health Care            |
| 4   | 2021-02-09  | 9999-12-31 | ABMD   | ABIOMED Inc                | Health Care            |
| 5   | 2021-02-09  | 9999-12-31 | ACN    | Accenture plc              | Information Technology |
| 6   | 2021-02-09  | 9999-12-31 | ATVI   | Activision Blizzard        | Communication Services |
| 7   | 2021-02-09  | 9999-12-31 | ADBE   | Adobe Inc.                 | Information Technology |
| 8   | 2021-02-09  | 9999-12-31 | AMD    | Advanced Micro Devices Inc | Information Technology |
| 9   | 2021-02-09  | 9999-12-31 | AAP    | Advance Auto Parts         | Consumer Discretionary |
| 10  | 2021-02-09  | 9999-12-31 | AES    | AES Corp                   | Utilities              |

Displaying records 1 - 10

</div>

The final pieces of data to initialize in the `SECDB` are the group
constituent data for the DJIA and SP500 stocks. These data are
maintained in the `universe_constituent` table in the `SECDB`.

The following raw `sql` chunk displays a *poorly documented* technique
for investigating the makeup of a `SQLite` schema object. Each `SQLite`
database has a *hidden* table named `sqlite_schema` which contains
information about the makeup of the objects in the schema. The `name`
field identifies the object and the `sql` field shows the `SQL`
statement that was executed to create the object. (N.B., There are
easier - maybe better - ways to accomplish what the next two chunks
accomplish, but this is an opportunity to show the interplay
functionality between the different processing chunks - even with
different engines - within R Markdown.)

``` sql
SELECT  sql
FROM    sqlite_schema
WHERE   name = 'universe_constituent';
```

    CREATE TABLE universe_constituent
    (
        universe_uid INTEGER NOT NULL,
        security_uid INTEGER NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        PRIMARY KEY(universe_uid, security_uid, start_date),
        FOREIGN KEY(universe_uid) REFERENCES universe(uid),
        FOREIGN KEY(security_uid) REFERENCES security(uid)
    )

Note that most of the data we need to initialize the
`universe_constituent` table for both the DJIA and the SP500 are
contained in the tibbles that we sourced previously - `djia_tbl` and
`sp500_tbl`, respectively. The missing data items are the `uid` value
for each of the universes.

The following code chunks use raw `sql` to access the `universe` data
(and make that data available via `universe_tbl`) and then `r` to join
the `universe` data with the DJIA and SP500 data and appropraite load
the `universe_constituent` table.

``` sql
SELECT  uid, name
FROM    universe
WHERE   name in ('DJIA', 'SP500');
```

``` r
universe_tbl <- tibble::tibble(universe_tbl)

sp500_uid <- universe_tbl %>% filter(name == 'SP500') %>% select(uid)
djia_uid <- universe_tbl %>% filter(name == 'DJIA') %>% select(uid)

sp500_const <- sp500_tbl %>%
  transmute(
    universe_uid = sp500_uid$uid,
    security_uid = uid,
    start_date = start_date,
    end_date = end_date
  )

djia_const <- djia_tbl %>%
  transmute(
    universe_uid = djia_uid$uid,
    security_uid = uid,
    start_date = start_date,
    end_date = end_date
  )

dbAppendTable(secdb, "universe_constituent", sp500_const)
#> [1] 505

dbAppendTable(secdb, "universe_constituent", djia_const)
#> [1] 30
```

And, we can check with the following raw `sql` chunks to verify that the
universe constituent data are loaded correctly.

``` sql
SELECT  S.uid AS uid,
        S.symbol AS symbol,
        S.name AS name,
        U.name AS universe
FROM    universe U,
        universe_constituent UC,
        security S
WHERE   U.name = 'SP500'
  AND   U.uid  = UC.universe_uid
  AND   UC.start_date <= DATE('now')
  AND   UC.end_date > DATE('now')
  AND   UC.security_uid = S.uid
  AND   S.start_date <= DATE('now')
  AND   S.end_date > DATE('now');
```

<div class="knitsql-table">

| uid | symbol | name                       | universe |
|:----|:-------|:---------------------------|:---------|
| 1   | MMM    | 3M Company                 | SP500    |
| 2   | ABT    | Abbott Laboratories        | SP500    |
| 3   | ABBV   | AbbVie Inc.                | SP500    |
| 4   | ABMD   | ABIOMED Inc                | SP500    |
| 5   | ACN    | Accenture plc              | SP500    |
| 6   | ATVI   | Activision Blizzard        | SP500    |
| 7   | ADBE   | Adobe Inc.                 | SP500    |
| 8   | AMD    | Advanced Micro Devices Inc | SP500    |
| 9   | AAP    | Advance Auto Parts         | SP500    |
| 10  | AES    | AES Corp                   | SP500    |

Displaying records 1 - 10

</div>

``` sql
SELECT  S.uid AS uid,
        S.symbol AS symbol,
        S.name AS name,
        U.name AS universe
FROM    universe U,
        universe_constituent UC,
        security S
WHERE   U.name = 'DJIA'
  AND   U.uid  = UC.universe_uid
  AND   UC.start_date <= DATE('now')
  AND   UC.end_date > DATE('now')
  AND   UC.security_uid = S.uid
  AND   S.start_date <= DATE('now')
  AND   S.end_date > DATE('now');
```

<div class="knitsql-table">

| uid | symbol | name                | universe |
|----:|:-------|:--------------------|:---------|
|   1 | MMM    | 3M Company          | DJIA     |
|  31 | AXP    | American Express Co | DJIA     |
|  38 | AMGN   | Amgen Inc.          | DJIA     |
|  46 | AAPL   | Apple Inc.          | DJIA     |
|  71 | BA     | Boeing Company      | DJIA     |
|  90 | CAT    | Caterpillar Inc.    | DJIA     |
| 101 | CVX    | Chevron Corp.       | DJIA     |
| 108 | CSCO   | Cisco Systems       | DJIA     |
| 115 | KO     | Coca-Cola Company   | DJIA     |
| 153 | DOW    | Dow Inc.            | DJIA     |

Displaying records 1 - 10

</div>
