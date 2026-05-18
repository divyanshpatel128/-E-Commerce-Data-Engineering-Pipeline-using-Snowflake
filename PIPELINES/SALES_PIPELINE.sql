
CREATE OR REPLACE TASK TASK_COPY_SALES

WAREHOUSE = COMPUTE_WH

AFTER ROOT_TASK

AS

COPY INTO  bronze_sales
(sales_id, customer_id, product_id, store_id, quantity, discount, date, total_amount)

FROM @raw_data/fact_sales

FILE_FORMAT = (FORMAT_NAME = 'csv_data')

ON_ERROR = CONTINUE;

-- step 2

CREATE OR REPLACE STREAM STR_SALES
ON TABLE BRONZE_SALES;

-- step 3

CREATE OR REPLACE TASK TASK_STG_SALES

WAREHOUSE = COMPUTE_WH

AFTER TASK_COPY_SALES

WHEN SYSTEM$STREAM_HAS_DATA('STR_SALES')

AS

CREATE OR REPLACE TRANSIENT TABLE STG_SALES AS

SELECT *

FROM (

SELECT *,

ROW_NUMBER() OVER (

PARTITION BY sales_id
ORDER BY updateat DESC

) rn

FROM STR_SALES

)

WHERE rn = 1;

-- step 4

CREATE OR REPLACE TABLE SILVER_SALES (

sales_id INT,
customer_id INT,
product_id INT,
store_id INT,
quantity INT,
discount NUMBER,
date DATE,
total_amount FLOAT

);


-- step 5

CREATE OR REPLACE TASK TASK_MERGE_SALES

WAREHOUSE = COMPUTE_WH

AFTER TASK_STG_SALES

AS

MERGE INTO SILVER_SALES tgt

USING STG_SALES src

ON tgt.sales_id = src.sales_id

WHEN MATCHED THEN

UPDATE SET

tgt.customer_id = src.customer_id,
tgt.product_id = src.product_id,
tgt.store_id = src.store_id,
tgt.quantity = src.quantity,
tgt.discount = src.discount,
tgt.date = src.date,
tgt.total_amount = src.total_amount

WHEN NOT MATCHED THEN

INSERT (

sales_id,
customer_id,
product_id,
store_id,
quantity,
discount,
date,
total_amount

)

VALUES (

src.sales_id,
src.customer_id,
src.product_id,
src.store_id,
src.quantity,
src.discount,
src.date,
src.total_amount

);
