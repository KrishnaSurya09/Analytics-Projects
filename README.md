# Project Background
This project analyzes a realistic, synthetic e-commerce dataset to understand revenue drivers, product performance, geographic patterns, and customer lifecycle dynamics. It combines SQL-based modeling, a clean reporting layer, and an interactive dashboard for exploration.

Insights and recommendations are provided on the following key areas:

- **Overall Sales Trends**
- **Top Products by Category**
- **Geographic Performance**
- **Customer Segments & Lifecycle**

The SQL used to model the data for this analysis can be found here → [link](https://github.com/KrishnaSurya09/Analytics--Ecommerce-Data-Project/tree/main/Ecommerce_data_modeling).

Explore the interactive dashboard here → [link](https://public.tableau.com/views/EcommerceDashboard_17602401761000/Overview?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link).

# Data Structure & Initial Checks
The core warehouse model **(Postgres / Dbt data-modeling)** is organized into base transactional/marketing tables and a small set of reporting marts.
**Tables (selected)**:
- **orders** — order header (order_id, customer_id, session_id, campaign_id, order_date, location, revenue, units, margin)
- **order_items** — order lines (order_id, product_id, qty, net_price, line_revenue, line_cogs, line_gross_profit)
- **products** — product catalog (product_id, name, category, base_price, margin_pct, price_uplift_pct)
- **sessions** — web analytics sessions (session_id, customer_id, session_date, channel/source/medium, campaign_id)
- **campaigns** — campaign metadata (campaign_id, name, channel, start_date, end_date)
- **marketing_spend** — daily spend by channel (date, channel, spend)
- **marketing_spend_by_campaign** — daily spend by campaign (date, channel, campaign_id, spend, spend_allocated)
- **rpt_campaign_performance_daily** — reporting mart (date, campaign_id, channel, sessions, orders, customers, revenue, gross_profit, new/engage/winback counts)
- **rpt_order_segments** — order-level segment tags (order_id, date, segment)
- **rpt_fct_order_line** — denormalized order line fact for BI (date, order_id, order_line_id, product_id, product_name, category, segment, city/state/country, units, line_revenue, line_gross_profit)

**Row quality checks performed**:
- Validated referential integrity (orders ↔ order_items; sessions ↔ campaigns).
- Ensured monetary fields are non-negative and consistent (line_revenue = qty × net_price).
- Deduped sessions and order lines on composite keys.
- Normalized location fields (city, state, country) for mapping.

**Entity Relationship Diagram (ERD)**:

> <img width="1000" height="800" alt="Image" src="https://github.com/user-attachments/assets/45132ef2-b476-48f1-818f-21c296c90e41" />



# Executive Summary

### Overview of Findings

1. **Topline & customers:** YTD revenue is essentially flat (**$10.20M**, **+0.67%**; orders **+2.37%**). The Engage and Winback segments drive growth, whereas **Acquire** has experienced a sharp decline.
2. **What’s selling (and profitable):** **Laptops (+4.0%)** and **Tablets (+17.1%)** offset weakness in **Smartphones (−11.2%)**. On a gross-profit lens, **Smartphones are also down (~−11%)**, while **Laptops (~+1.7%)** and **Cameras (~+1.2%)** tick up.
3. **Where & when to focus:** Strong states include **MI, NH, WY, CT, WA, OH, IA**; activity skews to **Tue–Thu** and **spring/early summer**. Repeat behavior clusters at **~72 days** (75% by **~141 days**), guiding lifecycle touches at **~60–150 days**.

> <img width="1000" height="800" alt="Image" src="https://github.com/user-attachments/assets/4e0aacbf-708f-40fe-bd30-1f58e60f35a6" />


## Insights Deep Dive

### 1) Overall Sales Trends
- **Steady topline, slight AOV/mix pressure.** YTD 2025 revenue is **$10,204,719 (+0.67%)** with **5,192 orders (+2.37%)**. Orders are growing slightly faster than revenue, indicating modest AOV or mix headwinds throughout the year.
- **Clear seasonality.** Traffic/orders concentrate on **Tue–Thu** with a pronounced **Apr–Jun** lift; weekends remain consistently lighter—useful for staffing and promo timing.
- **Channel composition is broad.** Campaign revenue share skews to **Paid Search ~24%**, **Email ~16%**, **Affiliate ~16%**, **Referral ~15%**, **Paid Social ~12%**, **Organic ~8%**, **Direct ~8%**—a healthy mix that limits channel risk but invites ROI tuning.
- **Category momentum diverges.** Rolling 12‑month sparklines show **Laptops** steady‑up and **Tablets** volatile‑up, while **Smartphones** trend down and **Cameras** stay flat—guiding where to place new launches vs. clearance.

---

### 2) Top Products by Category (Revenue)
- **Laptops are the anchor.** YTD **$2.59M (+4.0%)** with leaders like **Vivid Laptop J0R** and **Novax Laptop EG1** (~**$188k** each). Several SKUs cluster just below, suggesting breadth—not just single‑SKU dependency.
- **Smartphones need help.** YTD **$2.24M (−11.2%)**; even with strong items (e.g., **Orbit Smartphone AHF**, **Pulse Smartphone TGS**), the category underperforms—pricing, positioning, or competitive pressure likely.
- **Cameras are stable.** YTD **$1.83M (+0.17%)** with dependable earners (e.g., **Pulse Camera T97**). Maintain depth and attach accessories to lift per‑order economics.
- **Tablets are rising.** YTD **$1.08M (+17.1%)**; **Novax Tablet W37** and **Lumio Tablet TRA** are outsized contributors—ideal for bundles and cross‑sells from Laptops.

> <img width="664" height="413" alt="Image" src="https://github.com/user-attachments/assets/a51be93e-6a45-427b-8d51-1472134e8ab3" />
---

### 3) Geographic Performance
- **Revenue concentration.** Top states include **Michigan ($301k)**, **New Hampshire ($279k)**, **Wyoming ($277k)**, **Connecticut ($267k)**, **Washington ($259k)**, **Ohio ($253k)**, and **Iowa ($249k)**. Consider tilting marketing and inventory towards these states.
- **Regional pockets & whitespace.** Midwest/Northeast pockets are over‑indexing, while several western states are under‑penetrated—prime for test‑and‑learn prospecting.
- **Profit lens confirms NH as a standout.** **New Hampshire** leads GP at **$60,025 (+43.8% YoY)**, driven by **Cameras ($18,387)**, then **Smartphones ($9,832)**, **Tablets ($8,298)**, **Laptops ($7,970)**—target camera‑led promotions in similar markets.

> <img width="738" height="862" alt="Image" src="https://github.com/user-attachments/assets/352c89a9-0f27-4e24-b14f-9d20377b5cdc" />

---

### 4) Customer Segments & Lifecycle
- **Engage + Winback power growth.** YTD revenue by segment: **Engage $5.10M (+17.5%)**, **Winback $4.83M (+215%)**, **Acquire $276.8k (−93.5%)**—lifecycle programs are working; acquisition efficiency is the gap.
- **Recent month echoes the pattern.** Orders: **Acquire 3 (−96.3%)**, **Engage 235 (−8.9%)**, **Winback 249 (+25.1%)** vs. last September.
- **Repeat timing is predictable.** **50%** of returners repurchase in **~72 days**; **75%** by **~141 days**; **mean ~99 days** due to a long tail—set journeys at **~60–70d**, with follow‑ups at **~90/120/150d**.
  
> <img width="729" height="280" alt="Image" src="https://github.com/user-attachments/assets/cf17ded4-ed20-4f2e-bec4-ca823aa7872c" />
  Total Orders:
> <img width="231" height="241" alt="Image" src="https://github.com/user-attachments/assets/9063d744-40f7-4552-a02f-7a81d1e6ea86" />

---

### 5) Gross Profit Highlights *(Complementary to Revenue)*
- **Category GP mirrors the revenue story.** **Smartphones ($404k, −11.0% YoY)** are the profitability drag; **Laptops ($403k, +1.7%)** and **Cameras ($386k, +1.2%)** are slightly positive—protect smartphone margins (discount guardrails, trade‑in/financing, accessory attach).
- **Hero SKUs drive outsized GP.** Standouts include **Vivid Laptop J0R ($29.9k GP, +60%)**, **Pulse Camera T97 ($42.9k GP)**, **Novax Tablet W37 ($24.8k GP)**—ideal for hero placement, inventory depth, and bundles.
- **State-level profit mix informs targeting.** NH’s GP mix (Camera‑led, then Smartphones/Tablets/Laptops) suggests category‑targeted local campaigns can outperform broad offers.

---

## Recommendations
- **Double down on Tablet momentum.** Expand inventory depth for top SKUs, bundle accessories, and cross‑sell from Laptops to Tablets for mobile productivity personas.
- **Geographic focus plays.** Prioritize **MI, NH, WY, CT, WA, OH, IA** with localized promos and shipping SLAs; pilot market development in underperforming western states.
- **Lifecycle timing.** Schedule winback series at **~60–70 days**, with reinforcement touches at **~90, 120, and 150 days** to capture the tail without over‑messaging.
- **Merchandising for Smartphones.** Address the **−11%** drag by refreshing hero SKUs, price‑testing with limited‑time markdowns, and highlighting trade‑in/financing options to reduce sticker shock.

---

## Future Work (Marketing Performance)
Integrate **marketing spend** at both channel and campaign levels to compute **ROAS, POAS (profit on ad spend), CAC, cost/order, and margin‑after‑media**. Add a simple **last‑touch attribution** (configurable **7–30 day** window) to attribute revenue and gross profit to campaigns, with drilldowns by **segment (Acquire/Engage/Winback)** and **geo**.

---

## Assumptions and Caveats
- The dataset is synthetic/obfuscated; product names and geos are plausible but not real.
- Some small states show outsized variance due to lower base volumes (interpret deltas with caution).
- A small share of sessions lack campaign tags and are bucketed under Direct/Organic.
- Monetary values rounded; **gross profit = line_revenue − line_cogs**; taxes/shipping excluded.
- Returning‑customer timing derived from order gaps; refunds/exchanges excluded from repeat logic.
