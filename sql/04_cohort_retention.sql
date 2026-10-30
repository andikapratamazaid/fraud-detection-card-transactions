-- 04_cohort_retention.sql
-- Cohort = bulan pembelian pertama per customer_unique_id.
-- Retention = % customer cohort tsb yang order lagi di bulan ke-N.

DROP TABLE IF EXISTS cohort_retention;

CREATE TABLE cohort_retention AS
WITH first_order AS (
    SELECT customer_unique_id,
           DATE_TRUNC('month', MIN(order_date))::date AS cohort_month
    FROM v_orders_clean
    GROUP BY 1
),
activity AS (
    SELECT DISTINCT
        f.customer_unique_id,
        f.cohort_month,
        (EXTRACT(YEAR  FROM AGE(DATE_TRUNC('month', v.order_date), f.cohort_month)) * 12
       + EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', v.order_date), f.cohort_month)))::int AS month_index
    FROM v_orders_clean v
    JOIN first_order f USING (customer_unique_id)
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS cohort_customers
    FROM first_order GROUP BY 1
)
SELECT
    a.cohort_month,
    a.month_index,
    cs.cohort_customers,
    COUNT(DISTINCT a.customer_unique_id) AS active_customers,
    ROUND(100.0 * COUNT(DISTINCT a.customer_unique_id) / cs.cohort_customers, 2) AS retention_pct
FROM activity a
JOIN cohort_size cs USING (cohort_month)
GROUP BY a.cohort_month, a.month_index, cs.cohort_customers
ORDER BY 1, 2;

-- Pivot (heatmap-ready): bulan 0..6
SELECT
    cohort_month,
    MAX(cohort_customers) AS cohort_size,
    MAX(retention_pct) FILTER (WHERE month_index = 0) AS m0,
    MAX(retention_pct) FILTER (WHERE month_index = 1) AS m1,
    MAX(retention_pct) FILTER (WHERE month_index = 2) AS m2,
    MAX(retention_pct) FILTER (WHERE month_index = 3) AS m3,
    MAX(retention_pct) FILTER (WHERE month_index = 4) AS m4,
    MAX(retention_pct) FILTER (WHERE month_index = 5) AS m5,
    MAX(retention_pct) FILTER (WHERE month_index = 6) AS m6
FROM cohort_retention
GROUP BY cohort_month
ORDER BY cohort_month;

-- Catatan: cohort awal (2016) sangat kecil dan bulan terakhir (2018-09/10)
-- datanya tidak lengkap -> exclude dari kesimpulan.
