CREATE OR REPLACE TASK ROOT_TASK

WAREHOUSE = COMPUTE_WH
SCHEDULE = '1 MINUTE'

AS

SELECT CURRENT_TIMESTAMP;


-- step 2
CREATE OR REPLACE TASK TASK_COPY_CUSTOMER

WAREHOUSE = COMPUTE_WH

AFTER ROOT_TASK

AS

COPY INTO  bronze_customer
(customer_id, name, email, location, signup_date)

FROM @raw_data/dim_customers

FILE_FORMAT = (FORMAT_NAME = 'csv_data')

ON_ERROR = CONTINUE;

-- step 3

CREATE OR REPLACE STREAM STR_CUSTOMER
ON TABLE BRONZE_CUSTOMER;

-- step 4

-- SELECT * FROM STG_CUSTOMER;

CREATE OR REPLACE TASK TASK_STG_CUSTOMER

WAREHOUSE = COMPUTE_WH

AFTER TASK_COPY_CUSTOMER

WHEN SYSTEM$STREAM_HAS_DATA('STR_CUSTOMER')

AS

CREATE OR REPLACE TRANSIENT TABLE STG_CUSTOMER AS

SELECT *

FROM (

    SELECT *,

           ROW_NUMBER() OVER (

               PARTITION BY customer_id
               ORDER BY updateat DESC

           ) rn

    FROM STR_CUSTOMER

)

WHERE rn = 1;

-- step 5

CREATE OR REPLACE TABLE SILVER_CUSTOMER (

customer_id INT,
name STRING,
email STRING,
email_domain STRING,
location STRING,
signup_date DATE,

hash_value STRING,

start_date DATE,
end_date DATE,

is_active BOOLEAN

);

-- step 6

CREATE OR REPLACE TASK TASK_MERGE_CUSTOMER

WAREHOUSE = COMPUTE_WH

AFTER TASK_STG_CUSTOMER

AS

MERGE INTO SILVER_CUSTOMER tgt

USING STG_CUSTOMER src

ON tgt.customer_id = src.customer_id
AND tgt.is_active = TRUE

WHEN MATCHED
AND tgt.hash_value <> MD5(src.name || src.email || src.location)
--AND src.METADATA$ACTION = 'DELETE'


THEN UPDATE SET

    end_date = CURRENT_DATE,
    is_active = FALSE

WHEN NOT MATCHED
AND src.METADATA$ACTION = 'INSERT'

THEN INSERT (

    customer_id,
    name,
    email,
    email_domain,
    location,
    signup_date,

    hash_value,

    start_date,
    end_date,

    is_active

)

VALUES (

    src.customer_id,
    src.name,
    src.email,

    SPLIT_PART(src.email,'@',2),

    src.location,
    src.signup_date,

    MD5(src.name || src.email || src.location),

    CURRENT_DATE,
    NULL,

    TRUE

);
