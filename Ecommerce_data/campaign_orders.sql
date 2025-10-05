{
  { 
    config(materialized='table') 
  }
  
}

 SELECT
  o.order_id,
  o.order_date::date                   AS dt,
  o.campaign_id,
  o.customer_id,
  o.revenue,
  o.gross_profit,
  (o.order_date = o.first_order_date  AND o.campaign_id IS NOT NULL) AS is_new_customer
FROM public.orders o