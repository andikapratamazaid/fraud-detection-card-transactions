-- 03_rfm.sql
-- Catatan desain: frekuensi di data asli sangat skewed (mayoritas beli 1x),
-- jadi NTILE(5) untuk Frequency akan memecah customer yang nilainya sama
-- secara acak. Frequency dibuat rule-based.

DROP TABLE IF EXISTS rfm_segments;

CREATE TABLE rfm_segments AS
WITH snapshot AS (
    SELECT MAX(order_date) + 1 AS snap_date FROM v_orders_clean
),
base AS (
    SELECT
        v.customer_unique_id,
        (SELECT snap_date FROM snapshot) - MAX(v.order_date) AS recency_days,
        COUNT(DISTINCT v.order_id)                           AS frequency,
        SUM(v.order_value)                                   AS monetary
    FROM v_orders_clean v
    GROUP BY v.customer_unique_id
),
scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- makin baru makin tinggi
        CASE WHEN frequency = 1 THEN 1
             WHEN frequency = 2 THEN 3
             ELSE 5 END                            AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
    FROM base
)
SELECT *,
    CASE
        WHEN r_score >= 4 AND f_score >= 3 AND m_score >= 4 THEN 'Champions'
        WHEN f_score >= 3 AND r_score >= 3                  THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score = 1 AND m_score >= 4  THEN 'Big Spenders (New)'
        WHEN r_score >= 4 AND f_score = 1                   THEN 'New Customers'
        WHEN r_score = 3  AND f_score = 1                   THEN 'Promising'
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk / Cant Lose'
        WHEN r_score <= 2 AND m_score >= 4                  THEN 'Hibernating High-Value'
        ELSE 'Lost / Low Value'
    END AS segment
FROM scored;

-- Ringkasan segmen untuk dashboard / README
SELECT
    segment,
    COUNT(*)                                             AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS pct_customers,
    ROUND(SUM(monetary), 0)                              AS revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue,
    ROUND(AVG(recency_days), 0)                          AS avg_recency_days,
    ROUND(AVG(monetary), 2)                              AS avg_monetary
FROM rfm_segments
GROUP BY segment
ORDER BY revenue DESC;
