-- GOLD CUSTOMER ANALYTICS

CREATE OR REPLACE TASK  TASK_GOLD_CUSTOMER_ANALYTICS

WAREHOUSE = COMPUTE_WH

AFTER TASK_MERGE_ORDER,
      TASK_MERGE_CUSTOMER

AS

CREATE OR REPLACE TABLE  GOLD_CUSTOMER_ANALYTICS AS

SELECT

    c.customer_id,
    c.name,
    c.location,

    COUNT(o.order_id) AS total_orders,

    ROUND(SUM(o.order_amount),2) AS total_spent,

    MAX(o.order_date) AS last_order_date

FROM SILVER_CUSTOMER c

LEFT JOIN SILVER_ORDER o
ON c.customer_id = o.customer_id

WHERE c.is_active = TRUE

GROUP BY

c.customer_id,
c.name,
c.location;
