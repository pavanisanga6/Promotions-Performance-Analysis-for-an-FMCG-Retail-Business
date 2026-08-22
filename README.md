# Promotions Performance Analysis — FMCG Retail

A Power BI + Snowflake project analyzing promotional campaign 
performance for a retail business that ran Diwali and Sankranti 
promotions across 50 stores.

## Business Problem
The Sales Director wanted to know: how effective were the promotions, 
and which stores, cities, categories, and promotion types performed 
well or poorly?

## Key Metrics
- **IR% (Incremental Revenue %)** — revenue lift from promotions
- **ISU% (Incremental Sold Units %)** — unit/volume lift from promotions
- **Overall Effectiveness** — a weighted composite of IR% and ISU%, 
  with interactive What-if sliders to re-weight based on business priority

## Key Findings
- Overall promotion effectiveness: 92.28%
- BOGOF and 500 Cashback were the top-performing promotion types
- Home Appliances category saw the strongest lift

## Tools Used
Snowflake (data modeling, CASE-based discount logic) · Power BI 
(DAX measures, What-if parameters, Key Influencers AI visual)

## Assumptions & Caveats
- BOGOF discount modeled as 50% effective price reduction
- Cashback discount modeled as ₹ value ÷ base price (assumes full redemption)
- True margin/cost data unavailable; Effectiveness score used as a proxy

## Dashboard Preview
See `/screenshots` folder or open the `.pbix` file in `/powerbi`
