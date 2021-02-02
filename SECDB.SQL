-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

CREATE TABLE IF NOT EXISTS universe
(
    uid INTEGER PRIMARY KEY,
    name TEXT,
    description TEXT
);


CREATE UNIQUE INDEX IF NOT EXISTS universe_name
ON universe ( name );

CREATE TABLE IF NOT EXISTS gics
(
    code INTEGER PRIMARY KEY,
    level TEXT,
    name TEXT 
);

CREATE UNIQUE INDEX IF NOT EXISTS gics_name
ON gics ( level, name );

CREATE TABLE IF NOT EXISTS security
(
    uid INTEGER PRIMARY KEY,
    symbol TEXT,
    name TEXT,
    sub_industry_code INTEGER
);

CREATE UNIQUE INDEX IF NOT EXISTS security_symbol
ON security ( symbol );

