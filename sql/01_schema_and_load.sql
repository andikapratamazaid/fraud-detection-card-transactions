-- 01_schema_and_load.sql  (PostgreSQL)
-- Dataset: Olist Brazilian E-Commerce Public Dataset (Kaggle)
-- Letakkan file CSV di folder yang bisa diakses server, atau pakai \copy dari psql.

DROP TABLE IF EXISTS order_payments, order_items, orders, customers CASCADE;

CREATE TABLE customers (
    customer_id              TEXT PRIMARY KEY,   -- ID per ORDER (bukan per orang!)
    customer_unique_id       TEXT NOT NULL,      -- ID orang sebenarnya
    customer_zip_code_prefix TEXT,
    customer_city            TEXT,
    customer_state           TEXT
);

CREATE TABLE orders (
    order_id                       TEXT PRIMARY KEY,
    customer_id                    TEXT REFERENCES customers(customer_id),
    order_status                   TEXT,
    order_purchase_timestamp       TIMESTAMP,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP
);

CREATE TABLE order_items (
    order_id            TEXT REFERENCES orders(order_id),
    order_item_id       INT,
    product_id          TEXT,
    seller_id           TEXT,
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2),
    freight_value       NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id             TEXT REFERENCES orders(order_id),
    payment_sequential   INT,
    payment_type         TEXT,
    payment_installments INT,
    payment_value        NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- Load (jalankan dari psql, sesuaikan path)
-- \copy customers      FROM 'olist_customers_dataset.csv'      CSV HEADER
-- \copy orders         FROM 'olist_orders_dataset.csv'         CSV HEADER
-- \copy order_items    FROM 'olist_order_items_dataset.csv'    CSV HEADER
-- \copy order_payments FROM 'olist_order_payments_dataset.csv' CSV HEADER
