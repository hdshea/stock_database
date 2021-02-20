.print "Updating security table start_date fields to reflect data from security_price table..."
.print "security.start_date is set to the MIN(security_price.effective_date) for each security..."

UPDATE security
SET    start_date = SP.start_date,
       end_date = SP.end_date
FROM   (SELECT uid, 
        MIN(effective_date) AS start_date,
        DATE(MAX(effective_date),'+1 day') AS end_date
        FROM security_price
        GROUP BY uid) SP
where  security.uid = SP.uid;

UPDATE  security
SET     end_date = '9999-12-31'
WHERE   end_date = (SELECT MAX(end_date) from security WHERE end_date != '9999-12-31');

.exit
