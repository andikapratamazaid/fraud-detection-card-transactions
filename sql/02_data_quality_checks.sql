-- 02_data_quality_checks.sql
-- Data asli itu kotor. Cek dulu sebelum analisis, dan dokumentasikan keputusan.

-- 1. Rentang waktu data
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- 2. Distribusi status order (kita hanya pakai yang bukan canceled/unavailable)
SELECT order_status, COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders GROUP BY 1 ORDER BY n DESC;

-- 3. customer_id vs customer_unique_id -> kunci untuk RFM/cohort
SELECT COUNT(DISTINCT customer_id)        AS distinct_customer_id,
       COUNT(DISTINCT customer_unique_id) AS distinct_real_customers
FROM customers;

-- 4. Order tanpa payment / tanpa item
SELECT
  (SELECT COUNT(*) FROM orders o WHERE NOT EXISTS
     (SELECT 1 FROM order_payments p WHERE p.order_id = o.order_id)) AS orders_no_payment,
  (SELECT COUNT(*) FROM orders o WHERE NOT EXISTS
     (SELECT 1 FROM order_items i WHERE i.order_id = o.order_id))    AS orders_no_items;

-- 5. Nilai payment nol / negatif
SELECT COUNT(*) FROM order_payments WHERE payment_value <= 0;

-- 6. Berapa persen customer yang repeat? (ekspektasi: sangat kecil)
WITH c AS (
  SELECT cu.customer_unique_id, COUNT(DISTINCT o.order_id) AS n_orders
  FROM orders o JOIN customers cu USING (customer_id)
  WHERE o.order_status NOT IN ('canceled','unavailable')
  GROUP BY 1
)
SELECT n_orders, COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM c GROUP BY 1 ORDER BY 1;

-- Base view bersih untuk analisis selanjutnya
CREATE OR REPLACE VIEW v_orders_clean AS
SELECT
    cu.customer_unique_id,
    o.order_id,
    o.order_purchase_timestamp::date AS order_date,
    p.order_value
FROM orders o
JOIN customers cu USING (customer_id)
JOIN (   -- pre-aggregate agar tidak double count (1 order bisa punya banyak payment)
    SELECT order_id, SUM(payment_value) AS order_value
    FROM order_payments GROUP BY order_id
) p USING (order_id)
WHERE o.order_status NOT IN ('canceled','unavailable')
  AND p.order_value > 0;
