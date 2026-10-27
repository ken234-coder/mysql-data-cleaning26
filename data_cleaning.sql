/* =====================================================================
   Project : Customer Survey Data Cleaning (MySQL)
   Source  : raw_data (imported from CSV)
   Output  : raw_data_copy (cleaned working copy)
   Steps   : 1. Create working copy
             2. Remove duplicate customers
             3. Handle blank emails/phones and merge into one contact column
             4. Split address into street, city, state
             5. Standardize rewards_member
             6. Convert survey_date and survey_time to proper types
             7. Standardize service_feedback
             8. Trim freetext_response
   ===================================================================== */

-- MySQL Workbench safe-update mode blocks UPDATEs without a key in the WHERE clause
SET SQL_SAFE_UPDATES = 0;

-- Inspect the raw data
SELECT *
FROM raw_data;


/* ---------------------------------------------------------------------
   STEP 1: Create a working copy (keeps the raw table untouched)
   rn numbers each customer's records, newest survey_time first
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS raw_data_copy;

CREATE TABLE raw_data_copy AS
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY survey_time DESC) AS rn
FROM raw_data;

SELECT * FROM raw_data_copy;


/* ---------------------------------------------------------------------
   STEP 2: Remove duplicates (keep the latest record per customer)
   --------------------------------------------------------------------- */
-- Check: rows to keep vs rows to delete
SELECT * FROM raw_data_copy WHERE rn = 1;
SELECT * FROM raw_data_copy WHERE rn > 1;

DELETE FROM raw_data_copy
WHERE rn > 1;

ALTER TABLE raw_data_copy
DROP COLUMN rn;


/* ---------------------------------------------------------------------
   STEP 3: Handle blank email/phone values and merge into one column
   --------------------------------------------------------------------- */
UPDATE raw_data_copy
SET email = NULL
WHERE email = '';

UPDATE raw_data_copy
SET phone = NULL
WHERE phone = '';

-- Check the merge logic before applying it
SELECT email, phone, COALESCE(email, phone, 'not available') AS contact
FROM raw_data_copy;

ALTER TABLE raw_data_copy
ADD COLUMN contact TEXT AFTER customer_id;

UPDATE raw_data_copy
SET contact = COALESCE(email, phone, 'not available');

ALTER TABLE raw_data_copy
DROP COLUMN email,
DROP COLUMN phone;


/* ---------------------------------------------------------------------
   STEP 4: Split address into street, city and state
   TRIM removes the space left after each comma
   --------------------------------------------------------------------- */
-- Check the split before applying it
SELECT address,
       TRIM(SUBSTRING_INDEX(address, ',', 1))                           AS street,
       TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(address, ',', 2), ',', -1)) AS city,
       TRIM(SUBSTRING_INDEX(address, ',', -1))                          AS state
FROM raw_data_copy;

ALTER TABLE raw_data_copy
ADD COLUMN street TEXT AFTER contact,
ADD COLUMN city   TEXT AFTER street,
ADD COLUMN state  TEXT AFTER city;

UPDATE raw_data_copy
SET street = TRIM(SUBSTRING_INDEX(address, ',', 1)),
    city   = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(address, ',', 2), ',', -1)),
    state  = TRIM(SUBSTRING_INDEX(address, ',', -1));

ALTER TABLE raw_data_copy
DROP COLUMN address;

SELECT * FROM raw_data_copy;


/* ---------------------------------------------------------------------
   STEP 5: Standardize rewards_member (trim spaces, uppercase)
   --------------------------------------------------------------------- */
UPDATE raw_data_copy
SET rewards_member = TRIM(UPPER(rewards_member));


/* ---------------------------------------------------------------------
   STEP 6: Convert survey_date and survey_time to proper data types
   --------------------------------------------------------------------- */
-- Check the conversion before applying it
SELECT survey_date,
       STR_TO_DATE(survey_date, '%d-%m-%Y') AS converted_date
FROM raw_data_copy;

UPDATE raw_data_copy
SET survey_date = STR_TO_DATE(survey_date, '%d-%m-%Y');

ALTER TABLE raw_data_copy
MODIFY COLUMN survey_date DATE;

UPDATE raw_data_copy
SET survey_time = STR_TO_DATE(survey_time, '%H:%i');

ALTER TABLE raw_data_copy
MODIFY COLUMN survey_time TIME;


/* ---------------------------------------------------------------------
   STEP 7: Standardize service_feedback categories
   TRIM handles stray spaces; ELSE keeps any value not matched below
   --------------------------------------------------------------------- */
-- Check the new labels before applying them
SELECT DISTINCT service_feedback,
       CASE
           WHEN TRIM(service_feedback) LIKE '%excellent%'    THEN 'Excellent'
           WHEN TRIM(service_feedback) LIKE 'Average%'       THEN 'Average service'
           WHEN TRIM(service_feedback) LIKE '%Poor service'  THEN 'Poor service'
           WHEN TRIM(service_feedback) LIKE 'Good service'   THEN 'Good service'
           WHEN TRIM(service_feedback) LIKE 'Great service'  THEN 'Great service'
           ELSE service_feedback
       END AS new_category
FROM raw_data_copy;

UPDATE raw_data_copy
SET service_feedback = CASE
        WHEN TRIM(service_feedback) LIKE '%excellent%'    THEN 'Excellent'
        WHEN TRIM(service_feedback) LIKE 'Average%'       THEN 'Average service'
        WHEN TRIM(service_feedback) LIKE '%Poor service'  THEN 'Poor service'
        WHEN TRIM(service_feedback) LIKE 'Good service'   THEN 'Good service'
        WHEN TRIM(service_feedback) LIKE 'Great service'  THEN 'Great service'
        ELSE service_feedback
    END;


/* ---------------------------------------------------------------------
   STEP 8: Trim whitespace from free-text responses
   --------------------------------------------------------------------- */
UPDATE raw_data_copy
SET freetext_response = TRIM(freetext_response);


/* ---------------------------------------------------------------------
   FINAL CHECK
   --------------------------------------------------------------------- */
SELECT *
FROM raw_data_copy;

SET SQL_SAFE_UPDATES = 1;
