-- step 1
CREATE OR REPLACE TASK TASK_COPY_STORE

WAREHOUSE = COMPUTE_WH

AFTER ROOT_TASK

AS

COPY INTO  bronze_store
(store_id, store_name, region)

FROM @raw_data/dim_stores

FILE_FORMAT = (FORMAT_NAME = 'csv_data')

ON_ERROR = CONTINUE;

-- step 2
CREATE OR REPLACE STREAM STR_STORE
ON TABLE BRONZE_STORE;

-- step 3
CREATE OR REPLACE TASK TASK_STG_STORE

WAREHOUSE = COMPUTE_WH

AFTER TASK_COPY_STORE

WHEN SYSTEM$STREAM_HAS_DATA('STR_STORE')

AS

CREATE OR REPLACE TRANSIENT TABLE STG_STORE AS

SELECT *

FROM (

SELECT *,

ROW_NUMBER() OVER (

PARTITION BY store_id
ORDER BY updateat DESC

) rn

FROM STR_STORE

)

WHERE rn = 1;

-- step 4

CREATE OR REPLACE TABLE SILVER_STORE (

store_id INT,
store_name STRING,
region STRING,

hash_value STRING,

start_date DATE,
end_date DATE,

is_active BOOLEAN

);

-- step 5

CREATE OR REPLACE TASK TASK_MERGE_STORE

WAREHOUSE = COMPUTE_WH

AFTER TASK_STG_STORE

AS

MERGE INTO SILVER_STORE tgt

USING STG_STORE src

ON tgt.store_id = src.store_id
AND tgt.is_active = TRUE


WHEN MATCHED
AND tgt.hash_value <> MD5(src.store_name || src.region)
--AND src.METADATA$ACTION = 'DELETE'

THEN UPDATE SET

    end_date = CURRENT_DATE,
    is_active = FALSE
    

WHEN NOT MATCHED
AND src.METADATA$ACTION = 'INSERT'

THEN INSERT (

    store_id,
    store_name,
    region,

    hash_value,

    start_date,
    end_date,

    is_active

)

VALUES (

    src.store_id,
    src.store_name,
    src.region,

    MD5(src.store_name || src.region),

    CURRENT_DATE,
    NULL,

    TRUE

);
