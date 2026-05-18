
-- step 1

CREATE OR REPLACE TASK TASK_COPY_ORDER

WAREHOUSE = COMPUTE_WH

AFTER ROOT_TASK

AS

COPY INTO  bronze_order
(order_id, customer_id, order_date, order_amount, order_status)

FROM @raw_data/orders_batch

FILE_FORMAT = (FORMAT_NAME = 'csv_data')

ON_ERROR = CONTINUE;

-- step 2

CREATE OR REPLACE STREAM STR_ORDER
ON TABLE BRONZE_ORDER;

-- step 3

CREATE OR REPLACE TASK TASK_STG_ORDER

WAREHOUSE = COMPUTE_WH

AFTER TASK_COPY_ORDER

WHEN SYSTEM$STREAM_HAS_DATA('STR_ORDER')

AS

CREATE OR REPLACE TRANSIENT TABLE STG_ORDER AS

SELECT *

FROM (

SELECT *,

ROW_NUMBER() OVER (

PARTITION BY order_id
ORDER BY updateat DESC

) rn

FROM STR_ORDER

)

WHERE rn = 1;

-- step 4

CREATE OR REPLACE TABLE SILVER_ORDER (

order_id INT,
customer_id INT,
order_date DATE,
order_amount FLOAT,
order_status STRING

);

-- step 5

CREATE OR REPLACE TASK TASK_MERGE_ORDER

WAREHOUSE = COMPUTE_WH

AFTER TASK_STG_ORDER

AS

MERGE INTO SILVER_ORDER tgt

USING STG_ORDER src

ON tgt.order_id = src.order_id

WHEN MATCHED THEN

UPDATE SET

    tgt.customer_id = src.customer_id,
    tgt.order_date = src.order_date,
    tgt.order_amount = src.order_amount,
    tgt.order_status = src.order_status

WHEN NOT MATCHED THEN

INSERT (

    order_id,
    customer_id,
    order_date,
    order_amount,
    order_status

)

VALUES (

    src.order_id,
    src.customer_id,
    src.order_date,
    src.order_amount,
    src.order_status

);
