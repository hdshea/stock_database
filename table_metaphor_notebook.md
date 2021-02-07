Table Metaphor Reference Notebook
================
H. David Shea
2021-02-05

## Introduction

In this notebook, I will document the handling of the various table
metaphors that we will be using broadly, but here specifically in the
SECDB database.

The impetus behind using table metaphors and sticking to them as
strongly as possible is that the maintenance of the data in the metaphor
can be generalized across specific instances of individual tables. As
such, since we can query the database about the specific definition of
an individual table, we can aim at producing generalized functions for
maintaining data in tables within the different metaphors. I’ll walk
through the definition and processing logic for each table metaphor in
the rest of this notebook.

## Table metaphors

### Static definition table

The first table metaphor is a simple static definition table. These
generally are tables of reference data that are constant through time.
The basic make up for these tables is:

``` sql
CREATE TABLE IF NOT EXISTS <sd_table_name>
(
    uid INTEGER,
    ...,
     PRIMARY KEY(uid)
);
```

For static definition tables, we will default to having the single
primary key field be named `uid` and be an `INTEGER`. There can and will
be exceptions to this - some of which are specific to the defining data.
However, as we want to have many of the database handling routines
generalize, strong adoption to the metaphor - including field names and
`KEY` definitions - will be the default.

### Time dependent definition table

The next table metaphor is a time dependent definition table. These are
definition tables which can have the specific defining data ( the `...`
in the definition following) change over time but where we want the
identity of the basic element (the `uid` in the definition following) to
be constant through time. The basic make up for these tables is:

``` sql
CREATE TABLE IF NOT EXISTS <tdd_table_name>
(
    uid INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    ...,
    PRIMARY KEY(uid, start_date)
);
```

The `start_date` of each entry will be `YYYY-MM-DD 00:00:01` for the
date on which the definition was *first* relevant. The `end_date` will
be `YYYY-MM-DD 00:00:01` for the date on which the definition was first
***not*** relevant (i.e., one second after the date on which the
definition was *last* relevant). The `end_date` of all current and still
active definition entries will be set to `9999-12-31 23:59:59`.
Adherence to these standard will allow the use of syntax as shown below
for selecting entries relevant on a specific day, with the later example
selecting all of the current and still active entries.

``` sql
SELECT ...
FROM <tdd_table_name>
WHERE start_date <= DATE('1962-02-14')
  AND end_date > DATE('1962-02-14')

SELECT ...
FROM <tdd_table_name>
WHERE start_date <= DATE('now')
  AND end_date > DATE('now')
```

As `9999-12-31 23:59:59` is the latest date recognized in `SQLite`, the
current and still active `end_date` standard allows the
`start_date <= ... end_date > ...` `WHERE` clause form to avoid the need
to special process the case where `end_date` is, say, `NULL` or to
switch to `WHERE end_date = '9999-12-31'` to access current and still
active entries.

### Time series data table

Time series data tables contain data for entities identified in a
definition tables. These will likely be the most common tables
encountered in generally useful database tables - especially in finance
and definitely in our SECDB example. The basic make up for these tables
is:

``` sql
CREATE TABLE IF NOT EXISTS <tsd_table_name>
(
    uid INTEGER NOT NULL,
    effective_date DATE NOT NULL,
    ...,
    PRIMARY KEY(uid, effective_date),
    FOREIGN KEY(uid) REFERENCES <definition_table_name>(uid)
);
```

In the `FOREIGN KEY`, the `<definition_table_name>` will refer to the
static definition or time dependent definition table identifying the
entity for which this time series is relevant.

### Group constituent tables

Group constituent tables contain the time dependent constituents of a
group. These tables can either *only* define the group constituents - in
which case the `...` in the example below will be nothing - or they can
define the group along with providing additional time dependent
descriptive data - in which case the `...` in the example below will be
additional fields. Examples of the latter case include providing
weightings or orderings for the constituents within the group. The basic
make up for these tables is:

``` sql
CREATE TABLE IF NOT EXISTS <gs_table_name>
(
    <group_definition_table_name>_uid INTEGER NOT NULL,
    <constituent_definition_table_name>_uid INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    ...,
    PRIMARY KEY(<group_definition_table_name>_uid, <constituent_definition_table_name>_uid, start_date),
    FOREIGN KEY(<group_definition_table_name>_uid) REFERENCES <group_definition_table_name>(uid),
    FOREIGN KEY(<constituent_definition_table_name>_uid) REFERENCES <constituent_definition_table_name>(uid)
);
```

In the first `FOREIGN KEY`, the `<group_definition_table_name>` will
refer to the static definition or time dependent definition table
identifying the group entity in this relationship. In the second
`FOREIGN KEY`, the `<constituent_definition_table_name>` will refer to
the static definition or time dependent definition table identifying the
constituent entities in this relationship.

Note that group constituent tables can be viewed as a special case of
time dependent definition tables. As such, the standard for date logic
applied to time dependent definition tables carries over for these
tables as well.

## Metaphor processing logic

### Static definition table

### Time dependent definition table

### Time series data table

### Group constituent tables

## Metaphor generalized R functions

### Static definition table

### Time dependent definition table

### Time series data table

### Group constituent tables
