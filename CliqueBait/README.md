# CliqueBait
5th case study of the 8 week sql challenge

query written in Postgres


Study case details and questions: https://8weeksqlchallenge.com/case-study-6/

![logocase](https://8weeksqlchallenge.com/images/case-study-designs/6.png)

View the Solution script [here](https://github.com/EwaoluwaO/8-week-sql-challenge/blob/fc97a56282fb062f915f7da75b18fbad6ea7e19d/DataMart/Cliquebaitscript.sql)

## Enterprise Relationship Diagram
![table1](results/Relationship%20diagram.png)

## Campaigns Analysis

Generate a table that has 1 single row for every unique visit_id record and has the following columns:

`user_id`

`visit_id`

`visit_start_time`: the earliest event_time for each visit

`page_views`: count of page views for each visit

`cart_adds`: count of product cart add events for each visit

`purchase`: 1/0 flag if a purchase event exists for each visit

`campaign_name`: map the visit to a campaign if the visit_start_time falls between the start_date and end_date

`impression`: count of ad impressions for each visit

`click`: count of ad clicks for each visit
(Optional column) `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

```sql
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
```
Result:
![ResultTable](results/Result%20table.png)

