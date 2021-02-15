-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

.print "Dropping SECDB schema objects..."

DROP TABLE universe;
DROP TABLE gics;
DROP TABLE security;
DROP TABLE security_price;
DROP TABLE factor;
DROP TABLE factor_data;
DROP TABLE universe_constituent;
DROP VIEW  adjusted_price;

.exit
