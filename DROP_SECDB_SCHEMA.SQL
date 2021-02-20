.print "Dropping SECDB schema objects..."

DROP TABLE gics;
DROP TABLE security;
DROP TABLE security_price;
DROP TABLE factor;
DROP TABLE factor_data;
DROP VIEW  adjusted_price;

.exit
