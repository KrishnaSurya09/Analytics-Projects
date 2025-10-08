{{ config(materialized='table') }}

{# Goal
-----
Assign each customer to one mutually exclusive segment based on their order history and recency.
Include a recency bucket to support further analysis.

Segments (adjust day thresholds in the `params` CTE as needed):
- Acquire: Customers with exactly one order to date
- Engage: Customers with at least two orders and a most recent order within
`engage_recency_days` (default 180) days of the current date
- Winback: Customers with at least one order and no orders in more than `engage_recency_days`
days, indicating a period of inactivity that may require re-engagement

Extra output
------------
- days_since_last_order: Number of days since the last order (CURRENT_DATE minus last_order_date)
- recency_bucket: '0-60', '61-180', or '180+', based on `hot_days` (60) and
`engage_recency_days` (default 180)

Notes
-----
- Only customers with at least one order are included. This is enforced by filters at the end of the query.
- Adjust the analysis windows by modifying `hot_days` and `engage_recency_days` in the `params` section.
- Convert to a dbt model - To convert this to a dbt model, remove the CREATE TABLE or VIEW statements and retain only the final SELECT. #}

WITH params AS (
  SELECT
    60  ::int AS hot_days,              -- recent activity
    180 ::int AS engage_recency_days    -- last order must be within this to be "engage"
),
cust AS (
  SELECT c.customer_id, c.first_order_date::date AS first_order_date
  FROM public.customers c
),
ord AS (
  SELECT o.order_id, o.customer_id, o.order_date::date AS order_date
  FROM public.orders o
),
per_customer AS (
  SELECT
    c.customer_id,
    c.first_order_date,
    COUNT(o.order_id) AS order_count,
    MIN(o.order_date) AS first_order_date_check,
    MAX(o.order_date) AS last_order_date
  FROM cust c
  LEFT JOIN ord o USING (customer_id)
  GROUP BY 1,2
),
scored AS (
  SELECT
    p.*,
    (CURRENT_DATE - p.last_order_date)::int AS days_since_last_order,
    CASE
      WHEN p.order_count = 1 THEN 'acquire'
      WHEN p.order_count >= 2
           AND (CURRENT_DATE - p.last_order_date) <= (SELECT engage_recency_days FROM params)
        THEN 'engage'
      WHEN p.order_count >= 1
           AND (CURRENT_DATE - p.last_order_date) > (SELECT engage_recency_days FROM params)
        THEN 'winback'
      ELSE 'acquire' 
    END AS segment,
    CASE
      WHEN (CURRENT_DATE - p.last_order_date) <= (SELECT hot_days FROM params) THEN '0-60'
      WHEN (CURRENT_DATE - p.last_order_date) <= (SELECT engage_recency_days FROM params) THEN '61-180'
      ELSE '180+'
    END AS recency_bucket
  FROM per_customer p
)
SELECT
  customer_id,
  first_order_date,
  order_count,
  last_order_date,
  days_since_last_order,
  segment,
  recency_bucket
FROM scored
WHERE order_count >= 1            -- removes customers with no orders
  AND last_order_date IS NOT NULL 