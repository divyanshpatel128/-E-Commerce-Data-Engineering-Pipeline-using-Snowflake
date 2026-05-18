-- GOLD SALES SUMMARY

CREATE OR REPLACE TASK TASK_GOLD_SALES_SUMMARY

WAREHOUSE = COMPUTE_WH

AFTER TASK_MERGE_ORDER,
      TASK_MERGE_CUSTOMER,
      TASK_MERGE_PRODUCT,
      TASK_MERGE_SALES,
      TASK_MERGE_STORE

AS

CREATE OR REPLACE TABLE GOLD_SALES_SUMMARY AS

SELECT

    st.region,

    p.category,

    COUNT(DISTINCT s.sales_id) AS total_orders,

    COUNT(DISTINCT s.customer_id) AS total_customers,

    SUM(s.quantity) AS total_quantity,

    ROUND(SUM(s.total_amount),2) AS total_sales,

    ROUND(AVG(s.total_amount),2) AS avg_sales

FROM SILVER_SALES s

JOIN SILVER_CUSTOMER c
ON s.customer_id = c.customer_id
AND c.is_active = TRUE

JOIN SILVER_PRODUCT p
ON s.product_id = p.product_id
AND p.is_active = TRUE

JOIN SILVER_STORE st
ON s.store_id = st.store_id
AND st.is_active = TRUE

GROUP BY

st.region,
p.category;
