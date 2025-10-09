{{ config(materialized='table') }}

WITH oi AS (  -- line items aggregated at the line level
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
ord AS (  -- order header
  SELECT
    o.order_id,
    o.customer_id,
    o.order_date::date AS date,
    o.city,
    o.state,
    o.country
  FROM public.orders o
),
ord_seg AS (  -- per-order segment
  SELECT
    os.order_id,
    os.segment
  FROM {{ ref('RPT_ORDER_SEGMENTS') }} os    
)

SELECT
  ord.date,
  oi.order_id,
  oi.order_line_id,
  oi.product_id,
  p.product_name,
  p.category,
  ord_seg.segment,                  -- segment inherited from the order
  ord.city,
  ord.state,
  ord.country,
  ord.customer_id,
  oi.units,
  oi.line_revenue,
  oi.line_gross_profit
FROM ord
JOIN oi
  ON oi.order_id = ord.order_id
LEFT JOIN ord_seg
  ON ord_seg.order_id = ord.order_id
LEFT JOIN public.products p
  ON p.product_id = oi.product_id
WHERE ord.order_id IS NOT NULL
ORDER BY ord.date, oi.order_id

