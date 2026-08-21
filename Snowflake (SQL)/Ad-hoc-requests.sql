--1.Create data base and schema
create DATABASE Atliqmart;
create SCHEMA starschema;

--2.checking all the tables data
select count(*) from FACT_EVENTS;
describe table DIM_CAMPAIGNS;
select count(*) from dim_products;
SELECT count(*) from dim_stores;

--3.Comparing total quantity sold before promotions and after promotions
selec sum(quantity_sold_before_promo) as before_promo,
       sum(quantity_sold_after_promo) as after_promo
                              from fact_events;

-- 4. ISU growth % (increment sold unit)
select round((((sum(quantity_sold_after_promo)-sum(quantity_sold_before_promo))
          /sum(quantity_sold_before_promo)*100)),2)
          from fact_events;

-- 5. To add Discount% column (to get promotions price column(effective_promo_price)
 alter  table FACT_EVENTS add column DISCOUNT_PCT float;
 update FACT_EVENTS 
     set DISCOUNT_PCT = CASE
                        when PROMO_TYPE = '25% OFF' then 0.25
                        when PROMO_TYPE = '33% OFF' then 0.33
                        when PROMO_TYPE = '50% OFF' then 0.50
                        when PROMO_TYPE = 'BOGOF'  then 0.50
                        when PROMO_TYPE = '500 Cashback' then least(500.0/BASE_PRICE,1)
                        else 0
                    end;

-- 6. To add promotion price column (effective_promo_price column )
alter table FACT_EVENTS add column EFFECTIVE_PROMO_PRICE float;
update FACT_EVENTS
     set EFFECTIVE_PROMO_PRICE = BASE_PRICE * (1-DISCOUNT_PCT);
     
-- 7.Comparing total revenue before prom and after prom 
select round(sum(quantity_sold_before_promo*BASE_PRICE),2) as revenue_before_promo,
       round(sum(quantity_sold_after_promo*EFFECTIVE_PROMO_PRICE),2) as revenue_after_promo
                              from fact_events;  
                              
-- 8. IR growth % (incremental Revenue)
select (((round(sum(quantity_sold_after_promo*EFFECTIVE_PROMO_PRICE),2)-round(sum(quantity_sold_before_promo*BASE_PRICE),2))
               /round(sum(quantity_sold_before_promo*BASE_PRICE),2))*100) as "IR%"
               from fact_events;                              

-- 9.Identify high-value products that are currently being heavily discounted(BOGOF)
select Distinct p.product_name,f.base_price
                             from DIM_PRODUCTS as p join
                             FACT_EVENTS as f on p.PRODUCT_CODE=f.PRODUCT_CODE
        where f.base_price > 500 and f.PROMO_TYPE ='BOGOF'
        order by f.base_price desc;

-- 10.The cities with the highest store presence(the number of stores in each city)
select city, count(STORE_ID) from DIM_STORES
     group by city order by  count(STORE_ID) desc;

-- 11.Each campaign along with the total revenue generated before and after the campaign.
-- This report should help in evaluating the financial impact of our promotonal campaigns.
select c.CAMPAIGN_NAME,
         round(sum(f.quantity_sold_before_promo*BASE_PRICE)/1000000,2) as total_revenue_before_promo_in_millions,
         round(sum(f.quantity_sold_after_promo*EFFECTIVE_PROMO_PRICE)/1000000, 2) as   total_revenue_after_promo_in_millions
    from FACT_EVENTS as f join DIM_CAMPAIGNS as c on f.CAMPAIGN_ID=c.CAMPAIGN_ID
    group by CAMPAIGN_NAME;

-- 12.calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign.
--  Additionally, provide rankings for the categories based on their ISU%.
-- This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales.
select p.CATEGORY,
       (round((((sum(f.quantity_sold_after_promo)-sum(f.quantity_sold_before_promo))
          /sum(f.quantity_sold_before_promo)*100)),2)) as ISU_percent,
          dense_rank() over ( order by ISU_percent desc) as rank_number
    from  FACT_EVENTS as f join DIM_PRODUCTS as p on f.PRODUCT_CODE=p.PRODUCT_CODE
    join DIM_CAMPAIGNS as c on f.CAMPAIGN_ID=c.CAMPAIGN_ID
    where c.CAMPAIGN_NAME = 'Diwali'
    group by p.category;

--13. Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns.
-- This analysis helps identify the most successful products in terms Of incremental revenue across our campaigns, assisting in product optimization
select p. PRODUCT_NAME,
       p. CATEGORY,
       (round(((sum(f.quantity_sold_after_promo*EFFECTIVE_PROMO_PRICE)- sum(f.quantity_sold_before_promo*BASE_PRICE))
          /sum(f.quantity_sold_before_promo*BASE_PRICE))*100,2)) as "IR%"
    from FACT_EVENTS as f join DIM_PRODUCTS as p on f.PRODUCT_CODE=p.PRODUCT_CODE
    group by p. PRODUCT_NAME ,p. CATEGORY
    order by "IR%" desc limit 5;
    
 --14. To connect to power bi need warehouses name 
 Show warehouses;