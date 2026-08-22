# Promotions Performance Analysis — Project Write-Up

## The Business Problem

A retail company ran two promotional campaigns — **Diwali** and **Sankranti** —
across 50 stores, covering multiple product categories and five promotion
types (25% Off, 33% Off, 50% Off, BOGOF, and 500 Cashback).

The Sales Director had one core question: **were these promotions actually
effective, and where did they work best or worst?**

That single question broke down into a set of more specific business
questions — top/bottom performing stores, best/worst promotion types,
category-level lift, product-level outliers, and whether promotions struck
a good balance between driving volume and staying revenue-healthy.

## Approach

**Data stack:** Snowflake (source data + transformation logic) → Power BI
(modeling, DAX measures, visuals).

I started by defining two core metrics used throughout the analysis:

- **IR% (Incremental Revenue %)** — revenue lift during the promo period
  vs. baseline
- **ISU% (Incremental Sold Units %)** — unit/volume lift during the promo
  period vs. baseline

These became the backbone of every page in the report — Campaign,
Store, Promotion Type, and Product/Category performance.

## The Bug That Taught Me the Most

While validating a "Top 5 Products" visual, I noticed something odd: for
several products, **IR% and ISU% were showing up as exactly the same
number**, down to two decimal places. That's not a coincidence you'd
expect from real business data.

Digging into the DAX, I found the root cause: my `Total Revenue after
promo` measure was calculating revenue using the **same `BASE_PRICE`**
for both the before-promo and after-promo periods. Algebraically, that
meant the price term cancelled out entirely:

```
IR% = (Qty_after × Price − Qty_before × Price) / (Qty_before × Price)
    = (Qty_after − Qty_before) / Qty_before
    = ISU%
```

In other words, my "Revenue lift" metric was just my "Unit lift" metric
wearing a disguise — it wasn't capturing any real pricing or discount
impact at all. It only became visible at the **product level** (where a
single price applies); at the category level, mixing products with
different prices masked the issue.

## The Fix — Modeling Real Discount Impact

The dataset didn't have a discounted/promo price column — only
`BASE_PRICE` and a `PROMO_TYPE` label (text like "25% OFF", "BOGOF",
"500 Cashback"). So I built a discount model from that:

- **Percentage-based promos** (25%, 33%, 50% OFF) — used directly as the
  discount rate.
- **BOGOF** — modeled as an effective 50% price reduction (2 units for the
  price of 1).
- **500 Cashback** — this one needed more thought, since it's a flat ₹
  amount, not a percentage. I converted it to an equivalent discount rate:
  `500 / BASE_PRICE`, capped at 100% so it couldn't exceed the full price.

```sql
CASE 
    WHEN PROMO_TYPE = '25% OFF' THEN 0.25
    WHEN PROMO_TYPE = '33% OFF' THEN 0.33
    WHEN PROMO_TYPE = '50% OFF' THEN 0.50
    WHEN PROMO_TYPE = 'BOGOF' THEN 0.50
    WHEN PROMO_TYPE = '500 Cashback' THEN LEAST(500.0 / BASE_PRICE, 1)
    ELSE 0
END AS DISCOUNT_PCT
```

I prototyped this logic first in Power BI (as calculated columns) to
validate it row by row, then ported the finalized logic into Snowflake as
proper SQL columns — keeping transformation logic in the data layer
rather than the BI layer, once it was confirmed correct.

## Building an "Effectiveness" Score

Several business questions (like "which promotions strike the best
balance between volume and healthy margins?") needed a way to combine
IR% and ISU% into a single score — since true margin/cost data wasn't
available in the dataset.

I built an **Overall Effectiveness** measure using Power BI What-if
parameters, letting the report viewer interactively adjust how much
weight to give Revenue vs. Units:

```dax
Overall Effectiveness = 
[IR%] * SELECTEDVALUE('IR_Weight'[IR_Weight], 0.5) 
+ [ISU%] * SELECTEDVALUE('ISU_Weight'[ISU_Weight], 0.5)
```

This turned a static "here's the answer" chart into an interactive one —
a Sales Director who cares more about revenue than volume (or vice versa)
can drag a slider and see the ranking change in real time.

## Key Findings

- **Overall promotion effectiveness: 92.28%**
- **BOGOF** and **500 Cashback** were the top-performing promotion types
- **Home Appliances** saw the strongest category-level lift
- A handful of products in Personal Care and Grocery & Staples responded
  *poorly* to promotions — sales actually dropped below baseline during
  the promo period
- City-level performance varied meaningfully, with a small number of
  cities driving a disproportionate share of top-performing stores

## Assumptions & Limitations

- BOGOF and Cashback discount rates are modeled approximations, not
  exact — real-world redemption behavior (not everyone claims cashback)
  isn't captured, so actual Cashback performance may be even stronger
  than shown.
- No true margin/cost data was available, so Overall Effectiveness is
  used as a proxy for "healthy margin balance," not a literal margin
  calculation.
- Base price is treated as fixed per row; where the same product had
  different prices across stores/campaigns, this is reflected in the
  data rather than smoothed over.

## What I'd Do Differently Next Time

- Push for an actual discounted/promo price column at the source, if
  this were a real production dataset — would remove the need for
  discount-type approximations entirely.
- Add a proper statistical correlation/Chi-Square test for the
  Category × Promotion Type relationship, rather than relying solely on
  the weighted Effectiveness score as a business-friendly proxy.
