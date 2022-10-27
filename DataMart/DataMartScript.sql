--Data cleansing
create table clean_weekly_sales as select to_date(week_date, 'DD/MM/YY') as week_date,
		extract (week from (to_date(week_date, 'DD/MM/YY'))) as week_number,
		extract (month from (to_date(week_date, 'DD/MM/YY'))) as month_number,
		extract (year from (to_date(week_date, 'DD/MM/YY'))) as calendar_year,
		(case when segment like '%1' then 'Young Adults'
			when segment like '%2' then 'Middle Aged'
			when segment = 'null' then 'unknown'
			else 'Retires'
			end) as age_band,
		region,platform,customer_type,
		(case when segment like 'C%' then 'Couples'
			when segment like 'F%' then 'Family'
			when segment = 'null' then 'unknown'
			else 'error'
			end) as demographic,
		transactions,sales,
		round(sales/transactions::numeric,2) as avg_transactions
from weekly_sales ws;
--What day of the week is used for each week_date value?
select week_date, to_char(week_date,'Day') 
from clean_weekly_sales cws;
--What range of week numbers are missing from the dataset?
WITH cte_all_weeks AS ( 
    SELECT GENERATE_SERIES (1,52) week_number
)
SELECT week_number 
FROM cte_all_weeks
WHERE week_number NOT IN (
    SELECT 
        DISTINCT week_number
    FROM clean_weekly_sales
    )
ORDER BY week_number;
--How many total transactions were there for each year in the dataset?
SELECT
    calendar_year,
    SUM(transactions) total_transaction
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
--What is the total sales for each region for each month?
SELECT 
    region,
    calendar_year,
    month_number,
    SUM(sales) 
FROM clean_weekly_sales
GROUP BY region,month_number ,calendar_year 
ORDER BY calendar_year,month_number; 
--What is the total count of transactions for each platform
SELECT
    platform, 
    COUNT(*) number_transactions
FROM clean_weekly_sales
GROUP BY platform;
--What is the percentage of sales for Retail vs Shopify for each month?
WITH platform_cte AS( 
SELECT 
    month_number,
    calendar_year,
    SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) retail_sales,
    SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) shopify_sales,
    SUM(sales) total_sales
FROM clean_weekly_sales
GROUP BY month_number ,calendar_year 
)
SELECT 
   month_number,
   calendar_year, 
   ROUND((100*retail_sales/total_sales::numeric),2) pct_retail,
   ROUND((100*shopify_sales/total_sales::numeric),2) pct_shopify
FROM platform_cte ; 
--What is the percentage of sales by demographic for each year in the dataset?
SELECT 
    calendar_year,
    demographic,
    SUM(sales) annual_sales,
    ROUND((100*SUM(sales)/SUM(SUM(sales)) OVER (PARTITION BY demographic)),2) as pct
FROM clean_weekly_sales
GROUP BY calendar_year ,demographic 
ORDER BY calendar_year ,demographic ;
--Which age_band and demographic values contribute the most to Retail sales?
SELECT 
    age_band,
    demographic,
    SUM(sales) total_sales,
    ROUND(100*SUM(sales)/((select sum(sales) from clean_weekly_sales cws where platform='Retail')::numeric),2) as pct
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY total_sales desc;
--Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT
    platform, 
    calendar_year,
    ROUND(AVG(avg_transactions),2) average_fr_average, 
    SUM(sales) /SUM(transactions) average_real
FROM clean_weekly_sales cws
GROUP BY platform,calendar_year
ORDER BY platform,calendar_year

--Before & After Analysis
--What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
-- we first need to find out what week 2020-06-15 lies in.
SELECT 
    DATE_PART('week','2020-06-15'::DATE) week_number;
-- its week 25, so 4 weeks before are weeks 21,22,23,24 . 4 weeks after the date are weeks 25,26,27,28.(week 25 is included)
WITH cte_summary AS(
SELECT
    week_number,
    SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN sales ELSE 0 END) sales_before,
    SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN sales ELSE 0 END) sales_after
FROM clean_weekly_sales
WHERE calendar_year = '2020' 
GROUP BY week_number
)
SELECT 
    SUM(sales_before) total_before,
    SUM(sales_after) total_after,
    SUM(sales_after)-SUM(sales_before) difference,
    ROUND(100*(SUM(sales_after)-SUM(sales_before))/SUM(sales_before),2) pct_change
FROM cte_summary;
--What about the entire 12 weeks before and after?
WITH cte_summary AS(
SELECT
    week_number,
    SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN sales ELSE 0 END) sales_before,
    SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN sales ELSE 0 END) sales_after
FROM clean_weekly_sales
WHERE calendar_year = '2020' 
GROUP BY week_number
)
SELECT 
    SUM(sales_before) total_before,
    SUM(sales_after) total_after,
    SUM(sales_after)-SUM(sales_before) difference,
    ROUND(100*(SUM(sales_after)-SUM(sales_before))/SUM(sales_before),2) pct_change
FROM cte_summary;
--How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
--for 4 weeks
with cte_summary as(
select
	calendar_year,
	SUM(case when week_number between 21 and 24 then sales else 0 end) sales_before,
	SUM(case when week_number between 25 and 28 then sales else 0 end) sales_after
from
	clean_weekly_sales
group by
	calendar_year 
)
select
	calendar_year,
	SUM(sales_before) total_before,
	SUM(sales_after) total_after,
	SUM(sales_after)-SUM(sales_before) difference,
	ROUND(100 *(SUM(sales_after)-SUM(sales_before))/ SUM(sales_before), 2) pct_change
from
	cte_summary
group by
	calendar_year
order by
	calendar_year;
--for 12 weeks
with cte_summary as(
select
	calendar_year,
	SUM(case when week_number between 13 and 24 then sales else 0 end) sales_before,
	SUM(case when week_number between 25 and 36 then sales else 0 end) sales_after
from
	clean_weekly_sales
group by
	calendar_year
)
select
	calendar_year,
	SUM(sales_before) total_before,
	SUM(sales_after) total_after,
	SUM(sales_after)-SUM(sales_before) difference,
	ROUND(100 *(SUM(sales_after)-SUM(sales_before))/ SUM(sales_before), 2) pct_change
from
	cte_summary
group by
	calendar_year
order by
	calendar_year;
