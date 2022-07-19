 --question 1 How many customers has Foodie-Fi ever had?
 select count(distinct customer_id) as number_of_customers
 from subscriptions s;
--2What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select date_trunc('month', start_date) as month_start, count(start_date) as num_of_subs
from subscriptions s
join "plans" p 
on p.plan_id = s.plan_id 
where p.plan_id = 0
group by month_start
order by month_start;
--3What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select p.plan_name , count(start_date) as num_of_subs
from subscriptions s
join "plans" p 
on p.plan_id = s.plan_id
where s.start_date > '2020-12-31'
group by p.plan_name;
--4What is the customer count and percentage of customers who have churned rounded to 1 decimal place
select sum(
case when plan_id = '4' then 1 else 0 end), cast(sum(
case when plan_id = '4' then 1 else 0 end) as numeric)/count(distinct customer_id)*100 as churn_percentage
from subscriptions s;
--5How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
--create temporary table to know what was the next plan after each plan
DROP TABLE IF EXISTS next_plan_cte;
CREATE TEMP TABLE next_plan_cte AS(
    SELECT *, 
        LEAD(plan_id, 1) 
        OVER(PARTITION BY customer_id ORDER BY start_date) as next_plan
    FROM subscriptions;
   
select sum(case when next_plan = '4' and plan_id = '0' then 1 else 0 end), cast(sum(case when next_plan = '4' and plan_id = '0' then 1 else 0 end) as numeric)/count(distinct customer_id)*100 as percentage_churn
from next_plan_cte;

--6What is the number and percentage of customer plans after their initial free trial?
select next_plan, count(next_plan), 100 * COUNT(*)::NUMERIC / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM subscriptions) AS conversion_percentage
from next_plan_cte t
where t.plan_id = 0
group by t.next_plan;
--7What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- Retrieve next plan's start date located in the next row based on current row
WITH next_plan AS(
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM subscriptions
WHERE start_date <= '2020-12-31'
),
-- Find customer breakdown with existing plans on or after 31 Dec 2020
customer_breakdown AS (
  SELECT 
    plan_id, 
    COUNT(DISTINCT customer_id) AS customers
  FROM next_plan
  WHERE 
    (next_date IS NOT NULL AND (start_date < '2020-12-31' 
      AND next_date > '2020-12-31'))
    OR (next_date IS NULL AND start_date < '2020-12-31')
  GROUP BY plan_id)
SELECT plan_id, customers, 
  ROUND(100 * customers::NUMERIC / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM subscriptions),1) AS percentage
FROM customer_breakdown
GROUP BY plan_id, customers
ORDER BY plan_id;

select count(customer_id)
from subscriptions s 
where s.start_date <= '2020-12-31';
--8How many customers have upgraded to an annual plan in 2020?
select count(plan_id)
from subscriptions s 
where plan_id = 3 and start_date <= '2020-12-31';
--9How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with annual_memberscte as(select *
from subscriptions s 
where plan_id = 3)
select avg(a.start_date-s.start_date) as days_till_annual
from subscriptions s
join annual_memberscte a
on a.customer_id = s.customer_id
where s.plan_id = 0;
--10Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with annual_memberscte as(select *
from subscriptions
where plan_id = 3),
trial_members as(select*
from subscriptions 
where plan_id = 0),
intervals as (select WIDTH_BUCKET(a.start_date-t.start_date, 0, 360, 12) as avg_days_to_upgrade
  FROM trial_members t
  JOIN annual_memberscte a
    ON t.customer_id = a.customer_id)
select((avg_days_to_upgrade - 1) * 30 || ' - ' ||   (avg_days_to_upgrade) * 30) || ' days' AS breakdown, 
  COUNT(*) AS customers
FROM intervals
GROUP BY avg_days_to_upgrade
ORDER BY avg_days_to_upgrade;
--11How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with monthly_memberscte as(select *
from subscriptions s 
where plan_id = 2)
select *
from subscriptions s
join monthly_memberscte m
on m.customer_id = s.customer_id
where s.plan_id = 1 and s.start_date < m.start_date;

select * from next_plan_cte
