-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

.print "Dropping SECDB schema objects..."

DROP TABLE universe;
DROP TABLE gics;
DROP TABLE security;
DROP TABLE security_price;
DROP VIEW  adjusted_price;
DROP TABLE universe_constituent;

.exit
