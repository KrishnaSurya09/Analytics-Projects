{{ config(materialized='table', schema='public') }}


WITH sess AS (
  SELECT s.campaign_id, s.session_date::date AS dt, COUNT(*) AS sessions
  FROM public.sessions s
  WHERE s.campaign_id IS NOT NULL
  GROUP BY 1,2
),
ord AS (
  SELECT
    o.campaign_id,
    o.order_date::date AS dt,
    COUNT(*)                              AS orders,
    COUNT(DISTINCT o.customer_id)         AS customers,
    COUNT(DISTINCT o.customer_id) FILTER (
      WHERE o.order_date = o.first_order_date AND o.campaign_id IS NOT NULL
    )                                     AS new_customers,
    SUM(o.revenue)                        AS revenue,
    SUM(o.gross_profit)                   AS gross_profit
  FROM public.orders o
  GROUP BY 1,2
),
spend AS (
  SELECT m.campaign_id, m.date AS dt,
         MIN(m.channel) AS channel,
         SUM(m.spend_allocated) AS spend
  FROM public.marketing_spend_by_campaign m
  GROUP BY 1,2
),
all_rows AS (
  SELECT dt, campaign_id, channel, spend,
         0::bigint AS sessions, 0::bigint AS orders, 0::bigint AS customers,
         0::bigint AS new_customers, 0::numeric AS revenue, 0::numeric AS gross_profit
  FROM spend
  UNION ALL
  SELECT dt, campaign_id, NULL::text, 0::numeric,
         sessions, 0::bigint, 0::bigint, 0::bigint, 0::numeric, 0::numeric
  FROM sess
  UNION ALL
  SELECT dt, campaign_id, NULL::text, 0::numeric,
         0::bigint, orders, customers, new_customers, revenue, gross_profit
  FROM ord
),
agg AS (
  SELECT
    dt AS date,
    campaign_id,
    MIN(channel)              AS channel,
    SUM(spend)                AS spend,
    SUM(sessions)             AS sessions,
    SUM(orders)               AS orders,
    SUM(customers)            AS customers,
    SUM(new_customers)        AS new_customers,
    SUM(revenue)              AS revenue,
    SUM(gross_profit)         AS gross_profit
  FROM all_rows
  GROUP BY dt, campaign_id
)
SELECT
  a.date,
  a.campaign_id,
  c.campaign_name,
  a.channel,
  a.spend,
  a.sessions,
  a.orders,
  a.customers,
  a.new_customers,
  a.revenue,
  a.gross_profit
FROM agg a
LEFT JOIN public.campaigns c
  ON c.campaign_id = a.campaign_id