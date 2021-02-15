.print "Updating security table start_date fields to reflect data from security_price table..."
.print "security.start_date is set to the MIN(security_price.effective_date) for each security..."

UPDATE security
SET    start_date = SP.start_date
FROM   (SELECT uid, MIN(effective_date) AS start_date FROM security_price GROUP BY uid) SP
where  security.uid = SP.uid;

.exit
