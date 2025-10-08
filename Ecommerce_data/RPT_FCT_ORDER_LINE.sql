{{ config(materialized='table') }}

WITH oi AS (
  SELECT
    oi.order_id,
	oi.order_line_id,
    oi.product_id,
    SUM(oi.qty)                                        AS units,
    SUM(oi.qty * oi.net_price)                         AS line_revenue,
    SUM(COALESCE(oi.gross_profit, oi.qty * (oi.net_price - oi.unit_cogs)))
                                                       AS line_gross_profit
  FROM public.order_items oi
  GROUP BY 1,2,3
),
ord AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.order_date::date AS date,
    o.city,
    o.state,
    o.country
  FROM public.orders o
),
enriched AS (
  SELECT
    ord.date,
    ord.order_id,
	oi.order_line_id,
    ord.customer_id,
    ord.city, ord.state, ord.country,     -- location from orders
    cs.segment,
    oi.product_id,
    p.product_name,
    p.category,
    oi.units,
    oi.line_revenue,
    oi.line_gross_profit
  FROM ord
  LEFT JOIN oi                   ON oi.order_id = ord.order_id
  LEFT JOIN public.products  p   ON p.product_id = oi.product_id
  LEFT JOIN {{ ref('RPT_CUSTOMER_SEGMENTS') }} cs ON cs.customer_id = ord.customer_id
)
SELECT
  date,
  order_id,
  order_line_id,
  product_id,
  product_name,
  category,
  segment,
  city, state, country,
  customer_id, 
  units,
  line_revenue,
  line_gross_profit
FROM enriched
WHERE order_id IS NOT NULL
GROUP BY
  date, order_id, order_line_id, product_id, product_name, category, segment, city, state, country, customer_id, units, line_revenue, line_gross_profit
ORDER BY date, order_id ASC
