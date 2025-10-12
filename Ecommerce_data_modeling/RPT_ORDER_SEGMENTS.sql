{{ config(materialized='table') }}

WITH params AS (
  SELECT 60::int AS engage_recency_days
),
orders_enriched AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.order_date::date AS order_date,
    ROW_NUMBER() OVER (
      PARTITION BY o.customer_id
      ORDER BY o.order_date, o.order_id
    ) AS order_seq,
    LAG(o.order_date) OVER (
      PARTITION BY o.customer_id
      ORDER BY o.order_date, o.order_id
    ) AS prev_order_date
  FROM public.orders o
)
SELECT
  oe.order_date::date AS date,
  oe.order_id,
  CASE
    WHEN oe.order_seq = 1 THEN 'Acquire'
    WHEN (oe.order_date::date - oe.prev_order_date::date)
         <= (SELECT engage_recency_days FROM params) THEN 'Engage'
    ELSE 'Winback'
  END AS segment
FROM orders_enriched oe
ORDER BY date, order_id