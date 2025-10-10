{{ config(materialized='table') }}

WITH spend AS (
  SELECT
    m.campaign_id,
    m.date::date           AS date,
    SUM(m.spend_allocated) AS spend,
    MIN(m.channel)         AS channel
  FROM public.marketing_spend_by_campaign m
  GROUP BY 1,2
),

sess AS (
  SELECT
    s.campaign_id,
    s.session_date::date AS date,
    COUNT(*)             AS sessions
  FROM public.sessions s
  WHERE s.campaign_id IS NOT NULL
  GROUP BY 1,2
),

-- order-level revenue/gp from items
order_totals AS (
  SELECT
    oi.order_id,
    SUM(oi.qty * oi.net_price)                                             AS order_revenue,
    SUM(COALESCE(oi.gross_profit, oi.qty * (oi.net_price - oi.unit_cogs))) AS order_gross_profit
  FROM public.order_items oi
  GROUP BY 1
),

-- use precomputed order segments
orders_for_seg AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.campaign_id,
    o.order_date::date AS date,
    seg.segment
  FROM public.orders o
  JOIN public.rpt_order_segments seg
    ON seg.order_id = o.order_id
  WHERE o.campaign_id IS NOT NULL
),

-- daily order rollup, using segment for new_customers
orders_d AS (
  SELECT
    ofs.campaign_id,
    ofs.date,
    COUNT(*)                                          AS orders,
    COUNT(DISTINCT ofs.customer_id)                   AS customers,
    COUNT(*) FILTER (WHERE ofs.segment = 'Acquire')   AS new_customers,
    SUM(ot.order_revenue)                             AS revenue,
    SUM(ot.order_gross_profit)                        AS gross_profit
  FROM orders_for_seg ofs
  LEFT JOIN order_totals ot ON ot.order_id = ofs.order_id
  GROUP BY 1,2
),

-- segment mix per (date, campaign) based on order-level segments
seg_pivot AS (
  SELECT
    ofs.campaign_id,
    ofs.date,
    COUNT(DISTINCT ofs.customer_id) FILTER (WHERE ofs.segment = 'Acquire') AS seg_acquire_customers,
    COUNT(DISTINCT ofs.customer_id) FILTER (WHERE ofs.segment = 'Engage')  AS seg_engage_customers,
    COUNT(DISTINCT ofs.customer_id) FILTER (WHERE ofs.segment = 'Winback') AS seg_winback_customers
  FROM orders_for_seg ofs
  GROUP BY 1,2
),

-- spend + sessions + orders
base AS (
  SELECT
    COALESCE(spend.date, sess.date, orders_d.date)                         AS date,
    COALESCE(spend.campaign_id, sess.campaign_id, orders_d.campaign_id)    AS campaign_id,
    COALESCE(spend.spend, 0)                                               AS spend,
    COALESCE(sess.sessions, 0)                                             AS sessions,
    COALESCE(orders_d.orders, 0)                                           AS orders,
    COALESCE(orders_d.customers, 0)                                        AS customers,
    COALESCE(orders_d.new_customers, 0)                                    AS new_customers,
    COALESCE(orders_d.revenue, 0)                                          AS revenue,
    COALESCE(orders_d.gross_profit, 0)                                     AS gross_profit
  FROM spend
  FULL OUTER JOIN sess
    ON sess.campaign_id = spend.campaign_id AND sess.date = spend.date
  FULL OUTER JOIN orders_d
    ON orders_d.campaign_id = COALESCE(spend.campaign_id, sess.campaign_id)
   AND orders_d.date = COALESCE(spend.date, sess.date)
),

final AS (
  SELECT
    b.date,
    b.campaign_id,
    c.campaign_name,

    -- parse channel from name (fallback)
    INITCAP(REPLACE(NULLIF(SUBSTRING(c.campaign_name FROM '\(([^)]+)\)$'), ''), '_', ' ')) AS channel_from_name_norm,

    -- channel from data (daily or campaign-level fallback)
    INITCAP(REPLACE(NULLIF(COALESCE(sp.channel, ch.channel), ''), '_', ' '))               AS channel_from_data_norm,

    b.spend,
    b.sessions,
    b.orders,
    b.customers,
    b.new_customers,
    b.revenue,
    b.gross_profit
  FROM base b
  LEFT JOIN public.campaigns c ON c.campaign_id = b.campaign_id
  LEFT JOIN spend sp ON sp.campaign_id = b.campaign_id AND sp.date = b.date
  LEFT JOIN (
    SELECT campaign_id, MIN(channel) AS channel
    FROM spend
    GROUP BY 1
  ) ch ON ch.campaign_id = b.campaign_id
)

SELECT
  f.date,
  f.campaign_id,
  f.campaign_name,
  COALESCE(f.channel_from_data_norm, f.channel_from_name_norm) AS channel,
  f.spend,
  f.sessions,
  f.orders,
  f.customers,
  f.new_customers,
  f.revenue,
  f.gross_profit,
  COALESCE(p.seg_acquire_customers, 0) AS seg_acquire_customers,
  COALESCE(p.seg_engage_customers, 0)  AS seg_engage_customers,
  COALESCE(p.seg_winback_customers, 0) AS seg_winback_customers
FROM final f
LEFT JOIN seg_pivot p
  ON p.campaign_id = f.campaign_id AND p.date = f.date
ORDER BY f.date, f.campaign_name NULLS LAST

