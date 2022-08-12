--Using the available datasets - answer the following questions using a single query for each one:
--How many users are there?
 select count(distinct user_id)
 from clique_bait.users;
--How many cookies does each user have on average?
with count_cte as(select user_id, count(cookie_id) no_of_cookies
from clique_bait.users
group by user_id)
select avg(no_of_cookies)
from count_cte;
--What is the unique number of visits by all users per month?
select to_char(e.event_time,'Month') as Visit_month,count(distinct visit_id)
from clique_bait.users u 
	join clique_bait.events e
	on e.cookie_id = u.cookie_id
group by visit_month;
--What is the number of events for each event type?
select event_type, count(event_type)
from clique_bait.events e
group by event_type;
--What is the percentage of visits which have a purchase event?
select round((select count(distinct visit_id) from clique_bait.events e where event_type='3')::numeric/count(distinct visit_id)*100,2) percentage_of_purchases
from clique_bait.events e 
; 
--What is the percentage of visits which view the checkout page but do not have a purchase event?
select round(
		((select count(distinct visit_id) from clique_bait.events e where event_type='2')-(select count(distinct visit_id) from clique_bait.events e where event_type='3'))::numeric
		/count(distinct visit_id)*100
			,2) percentage_at_cart
from clique_bait.events e ;
--What are the top 3 pages by number of views?
with pageviews_cte as(select* from clique_bait.events e where event_type='1')
select p.page_name, count(e.page_id) page_views
from pageviews_cte e
	join clique_bait.page_hierarchy p
	on e.page_id=p.page_id
group by p.page_name
order by page_views desc 
limit 3;
--What is the number of views and cart adds for each product category?
select ph.product_category, sum(case when event_type='1' then 1 else 0 end) page_views, sum(case when event_type='2' then 1 else 0 end) cart_adds
from clique_bait.events e 
	join clique_bait.page_hierarchy ph 
	on ph.page_id=e.page_id
group by ph.product_category;
--What are the top 3 products by purchases?
select ph.page_name, count(*) purchases
from clique_bait.events e
	join clique_bait.page_hierarchy ph 
	on e.page_id=ph.page_id
where e.event_type='2'
group by ph.page_name
order by purchases desc 
limit 3;
--2
--Using a single SQL query - create a new output table which has the following details:
--How many times was each product viewed?
--How many times was each product added to cart?
--How many times was each product added to a cart but not purchased (abandoned)?
--How many times was each product purchased?
with product_events_table as(
	select
		e.visit_id, ph.product_id,ph.page_name as product_name,ph.product_category,
		sum(case when event_type='1' then 1 else 0 end) views,
		sum(case when event_type='2' then 1 else 0 end) cart_adds
	from clique_bait.events e 
	join clique_bait.page_hierarchy ph
		on e.page_id=ph.page_id
	where ph.product_id is not null
	group by e.visit_id, ph.product_id, ph.page_name,ph.product_category
),
purchases_cte as(
	select 
		distinct visit_id
	from clique_bait.events e 
	where event_type=3
),
combined_cte as(
	select
		pet.visit_id, 
    	pet.product_id, 
    	pet.product_name, 
    	pet.product_category, 
    	pet.views, 
    	pet.cart_adds,
    CASE WHEN p.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
	from product_events_table pet
	left join purchases_cte p
	on p.visit_id=pet.visit_id
)
  SELECT 
    product_name, 
    product_category, 
    SUM(views) AS views,
    SUM(cart_adds) AS cart_adds, 
    SUM(CASE WHEN cart_adds = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN cart_adds = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
  FROM combined_cte
  GROUP BY product_id, product_name, product_category
;
--Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
--we can use the exact smae method but instead aggregate by product category
with product_events_table as(
	select
		e.visit_id, ph.product_id,ph.page_name as product_name,ph.product_category,
		sum(case when event_type='1' then 1 else 0 end) views,
		sum(case when event_type='2' then 1 else 0 end) cart_adds
	from clique_bait.events e 
	join clique_bait.page_hierarchy ph
		on e.page_id=ph.page_id
	where ph.product_id is not null
	group by e.visit_id, ph.product_id, ph.page_name,ph.product_category
),
purchases_cte as(
	select 
		distinct visit_id
	from clique_bait.events e 
	where event_type=3
),
combined_cte as(
	select
		pet.visit_id, 
    	pet.product_id, 
    	pet.product_name, 
    	pet.product_category, 
    	pet.views, 
    	pet.cart_adds,
    CASE WHEN p.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
	from product_events_table pet
	left join purchases_cte p
	on p.visit_id=pet.visit_id
)
  SELECT 
    product_category, 
    SUM(views) AS views,
    SUM(cart_adds) AS cart_adds, 
    SUM(CASE WHEN cart_adds = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN cart_adds = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
  FROM combined_cte
  GROUP BY product_category;
 
--3 Campaign analysis
select 
  u.user_id, e.visit_id, 
  min(e.event_time) AS visit_start_time,
  sum(case when e.event_type = 1 then 1 else 0 end) AS page_views,
  sum(case when e.event_type = 2 then 1 else 0 end) AS cart_adds,
  sum(case when e.event_type = 3 then 1 else 0 end) AS purchase,
  c.campaign_name,
  sum(case when e.event_type = 4 then 1 else 0 end) AS impression, 
  SUM(case when e.event_type = 5 then 1 else 0 end) AS click, 
  STRING_AGG(CASE WHEN p.product_id IS NOT NULL AND e.event_type = 2 THEN p.page_name ELSE NULL END, 
    ', ' ORDER BY e.sequence_number) AS cart_products
from clique_bait.users AS u
inner join clique_bait.events AS e
  on u.cookie_id = e.cookie_id
left join clique_bait.campaign_identifier AS c
  on e.event_time BETWEEN c.start_date AND c.end_date
left join clique_bait.page_hierarchy AS p
  on e.page_id = p.page_id
group by u.user_id, e.visit_id, c.campaign_name;