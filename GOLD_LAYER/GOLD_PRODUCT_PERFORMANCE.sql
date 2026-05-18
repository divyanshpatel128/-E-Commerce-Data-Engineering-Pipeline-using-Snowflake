-- GOLD PRODUCT PERFORMANCE

CREATE OR REPLACE TASK TASK_GOLD_PRODUCT_PERFORMANCE

WAREHOUSE = COMPUTE_WH

AFTER TASK_MERGE_PRODUCT,
      TASK_MERGE_SALES

AS

CREATE OR REPLACE VIEW GOLD_PRODUCT_PERFORMANCE AS

SELECT

    p.product_id,
    p.product_name,
    p.category,

    SUM(s.quantity) AS total_quantity_sold,

    ROUND(SUM(s.total_amount),2) AS total_revenue

FROM SILVER_PRODUCT p

JOIN SILVER_SALES s
ON p.product_id = s.product_id

WHERE p.is_active = TRUE

GROUP BY

p.product_id,
p.product_name,
p.category;
