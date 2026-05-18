-- step 1

CREATE OR REPLACE TASK TASK_COPY_PRODUCT

WAREHOUSE = COMPUTE_WH

AFTER ROOT_TASK

AS

COPY INTO   bronze_product
(product_id, product_name, category, price)

FROM @raw_data/dim_products

FILE_FORMAT = (FORMAT_NAME = 'csv_data')

ON_ERROR = CONTINUE;

-- step 2

CREATE OR REPLACE STREAM STR_PRODUCT
ON TABLE BRONZE_PRODUCT;

-- step 3

CREATE OR REPLACE TASK TASK_STG_PRODUCT

WAREHOUSE = COMPUTE_WH

AFTER TASK_COPY_PRODUCT

WHEN SYSTEM$STREAM_HAS_DATA('STR_PRODUCT')

AS

CREATE OR REPLACE TRANSIENT TABLE STG_PRODUCT AS

SELECT *

FROM (

SELECT *,

ROW_NUMBER() OVER (

PARTITION BY product_id
ORDER BY updateat DESC

) rn

FROM STR_PRODUCT

)

WHERE rn = 1;

-- step 4

CREATE OR REPLACE TABLE SILVER_PRODUCT (

product_id INT,
product_name STRING,
category STRING,
price NUMBER,

hash_value STRING,

start_date DATE,
end_date DATE,

is_active BOOLEAN

);

-- step 5

CREATE OR REPLACE TASK TASK_MERGE_PRODUCT

WAREHOUSE = COMPUTE_WH

AFTER TASK_STG_PRODUCT

AS

MERGE INTO SILVER_PRODUCT tgt

USING STG_PRODUCT src

ON tgt.product_id = src.product_id
AND tgt.is_active = TRUE

WHEN MATCHED
AND tgt.hash_value <> MD5(src.product_name || src.category || src.price)
--AND src.METADATA$ACTION = 'DELETE'




THEN UPDATE SET

end_date = CURRENT_DATE,
is_active = FALSE

WHEN NOT MATCHED
AND src.METADATA$ACTION = 'INSERT'

THEN INSERT (

product_id,
product_name,
category,
price,

hash_value,

start_date,
end_date,

is_active

)

VALUES (

src.product_id,
src.product_name,
src.category,
src.price,

MD5(src.product_name || src.category || src.price),

CURRENT_DATE,
NULL,

TRUE

);
