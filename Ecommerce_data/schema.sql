SELECT current_database();

CREATE SCHEMA IF NOT EXISTS analytics;

-- Drop existing tables in dependency order (if re-running)
DROP TABLE IF EXISTS analytics.order_items CASCADE;
DROP TABLE IF EXISTS analytics.orders CASCADE;
DROP TABLE IF EXISTS analytics.sessions CASCADE;
DROP TABLE IF EXISTS analytics.marketing_spend_by_campaign CASCADE;
DROP TABLE IF EXISTS analytics.marketing_spend_unassigned CASCADE;
DROP TABLE IF EXISTS analytics.marketing_spend CASCADE;
DROP TABLE IF EXISTS analytics.campaign_new_customers_summary CASCADE;
DROP TABLE IF EXISTS analytics.campaigns CASCADE;
DROP TABLE IF EXISTS analytics.products CASCADE;
DROP TABLE IF EXISTS analytics.customers CASCADE;

-- Core dimensions
CREATE TABLE analytics.customers (
    customer_id                INTEGER PRIMARY KEY,
    region                     TEXT,
    state                      TEXT,
    signup_date                DATE,
    first_order_date           DATE,
    acquisition_campaign_id    INTEGER
);

CREATE TABLE analytics.products (
    product_id           INTEGER PRIMARY KEY,
    product_name         TEXT,
    category             TEXT,
    base_price           NUMERIC(10,2),
    margin_rate          NUMERIC(5,4),
    base_price_original  NUMERIC(10,2),
    price_uplift_pct     NUMERIC(5,4)
);

CREATE TABLE analytics.campaigns (
    campaign_id    INTEGER PRIMARY KEY,
    campaign_name  TEXT,
    channel        TEXT,
    start_date     DATE,
    end_date       DATE
);

-- Web analytics / sessions
CREATE TABLE analytics.sessions (
    session_id    BIGINT PRIMARY KEY,
    customer_id   INTEGER REFERENCES analytics.customers(customer_id),
    session_date  DATE,
    channel       TEXT,
    source        TEXT,
    medium        TEXT,
    campaign_id   INTEGER REFERENCES analytics.campaigns(campaign_id)
);

-- Fact orders
CREATE TABLE analytics.orders (
    order_id          BIGINT PRIMARY KEY,
    customer_id       INTEGER NOT NULL REFERENCES analytics.customers(customer_id),
    session_id        BIGINT REFERENCES analytics.sessions(session_id),
    order_date        DATE NOT NULL,
    campaign_id       INTEGER REFERENCES analytics.campaigns(campaign_id),
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

-- Fact order items (line level)
CREATE TABLE analytics.order_items (
    order_id       BIGINT REFERENCES analytics.orders(order_id),
    product_id     INTEGER REFERENCES analytics.products(product_id),
    qty            INTEGER,
    list_price     NUMERIC(10,2),
    discount_rate  NUMERIC(5,4),
    net_price      NUMERIC(10,2),
    unit_cogs      NUMERIC(10,2),
    gross_profit   NUMERIC(12,2),
    PRIMARY KEY(order_id, product_id)
);

-- Marketing spend
CREATE TABLE analytics.marketing_spend (
    date     DATE,
    channel  TEXT,
    spend    NUMERIC(12,2),
    PRIMARY KEY (date, channel)
);

CREATE TABLE analytics.marketing_spend_by_campaign (
    date             DATE,
    channel          TEXT,
    campaign_id      INTEGER REFERENCES analytics.campaigns(campaign_id),
    campaign_name    TEXT,
    spend            NUMERIC(12,2),
    spend_allocated  NUMERIC(12,2),
    PRIMARY KEY (date, channel, campaign_id)
);

CREATE TABLE analytics.marketing_spend_unassigned (
    date              DATE,
    channel           TEXT,
    spend             NUMERIC(12,2),
    spend_assigned    NUMERIC(12,2),
    spend_unassigned  NUMERIC(12,2),
    PRIMARY KEY (date, channel)
);

CREATE INDEX ON analytics.orders (customer_id, order_date);
CREATE INDEX ON analytics.orders (campaign_id);
CREATE INDEX ON analytics.sessions (campaign_id, session_date);
CREATE INDEX ON analytics.order_items (product_id);
CREATE INDEX ON analytics.marketing_spend_by_campaign (campaign_id);
