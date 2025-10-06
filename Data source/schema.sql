SELECT current_database();

-- ---- Drop existing tables in dependency order ------------
DROP TABLE IF EXISTS public.order_items                    CASCADE;
DROP TABLE IF EXISTS public.orders                         CASCADE;
DROP TABLE IF EXISTS public.sessions                       CASCADE;
DROP TABLE IF EXISTS public.marketing_spend_by_campaign    CASCADE;
DROP TABLE IF EXISTS public.marketing_spend_unassigned     CASCADE;
DROP TABLE IF EXISTS public.marketing_spend                CASCADE;
DROP TABLE IF EXISTS public.campaign_new_customers_summary CASCADE;
DROP TABLE IF EXISTS public.campaigns                      CASCADE;
DROP TABLE IF EXISTS public.products                       CASCADE;
DROP TABLE IF EXISTS public.customers                      CASCADE;

-- ---- Core dimensions -------------------------------------
CREATE TABLE public.customers (
    customer_id               INTEGER PRIMARY KEY,
    region                    TEXT,
    state                     TEXT,
    signup_date               DATE,
    first_order_date          DATE,
    acquisition_campaign_id   INTEGER
);

CREATE TABLE public.products (
    product_id           INTEGER PRIMARY KEY,
    product_name         TEXT,
    category             TEXT,
    base_price           NUMERIC(10,2),
    margin_rate          NUMERIC(5,4),
    base_price_original  NUMERIC(10,2),
    price_uplift_pct     NUMERIC(5,4)
);

CREATE TABLE public.campaigns (
    campaign_id    INTEGER PRIMARY KEY,
    campaign_name  TEXT,
    channel        TEXT,
    start_date     DATE,
    end_date       DATE
);

-- ---- Web analytics / sessions ----------------------------
CREATE TABLE public.sessions (
    session_id    BIGINT PRIMARY KEY,
    customer_id   INTEGER REFERENCES public.customers(customer_id),
    session_date  DATE,
    channel       TEXT,
    source        TEXT,
    medium        TEXT,
    campaign_id   INTEGER REFERENCES public.campaigns(campaign_id)
);

-- ---- Fact orders -----------------------------------------
CREATE TABLE public.orders (
    order_id          BIGINT PRIMARY KEY,
    customer_id       INTEGER NOT NULL REFERENCES public.customers(customer_id),
    session_id        BIGINT REFERENCES public.sessions(session_id),
    order_date        DATE NOT NULL,
    campaign_id       INTEGER REFERENCES public.campaigns(campaign_id),
    country           TEXT,
    city              TEXT,
    state             TEXT,
    channel           TEXT,
    source            TEXT,
    medium            TEXT,
    first_order_date  DATE,
    is_new_customer   BOOLEAN,
    items             INTEGER,
    units             INTEGER,
    revenue           NUMERIC(12,2),
    gross_profit      NUMERIC(12,2)
);

-- ---- Fact order items (line level) -----------------------
CREATE TABLE public.order_items (
    order_id       BIGINT  REFERENCES public.orders(order_id),
    product_id     INTEGER REFERENCES public.products(product_id),
    qty            INTEGER,
    list_price     NUMERIC(10,2),
    discount_rate  NUMERIC(5,4),
    net_price      NUMERIC(10,2),
    unit_cogs      NUMERIC(10,2),
    gross_profit   NUMERIC(12,2),
    PRIMARY KEY (order_id, product_id)
);

-- ---- Marketing spend -------------------------------------
CREATE TABLE public.marketing_spend (
    date     DATE,
    channel  TEXT,
    spend    NUMERIC(12,2),
    PRIMARY KEY (date, channel)
);

CREATE TABLE public.marketing_spend_by_campaign (
    date             DATE,
    channel          TEXT,
    campaign_id      INTEGER REFERENCES public.campaigns(campaign_id),
    campaign_name    TEXT,
    spend            NUMERIC(12,2),
    spend_allocated  NUMERIC(12,2),
    PRIMARY KEY (date, channel, campaign_id)
);

CREATE TABLE public.marketing_spend_unassigned (
    date              DATE,
    channel           TEXT,
    spend             NUMERIC(12,2),
    spend_assigned    NUMERIC(12,2),
    spend_unassigned  NUMERIC(12,2),
    PRIMARY KEY (date, channel)
);

-- ---- Indexes ---------------------------------------------
CREATE INDEX ON public.orders (customer_id, order_date);
CREATE INDEX ON public.orders (campaign_id);
CREATE INDEX ON public.sessions (campaign_id, session_date);
CREATE INDEX ON public.order_items (product_id);
CREATE INDEX ON public.marketing_spend_by_campaign (campaign_id);