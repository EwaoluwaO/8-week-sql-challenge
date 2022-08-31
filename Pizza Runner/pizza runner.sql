DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
 --PART 1: FIXING THE TABLES
-- First: customer_orders
--- Creating a view ---
DROP TABLE IF EXISTS customer_orders_cleaned;
CREATE TABLE customer_orders_cleaned AS WITH first_layer AS (
    SELECT order_id,
        customer_id,
        pizza_id,
        CASE
            WHEN exclusions = '' THEN NULL
            WHEN exclusions = 'null' THEN NULL
            ELSE exclusions
        END as exclusions,
        CASE
            WHEN extras = '' THEN NULL
            WHEN extras = 'null' THEN NULL
            ELSE extras
        END as extras,
        order_time
    FROM customer_orders
)
SELECT ROW_NUMBER() OVER (
        -- We are adding a row_number rank to deal with orders having multiple times the same pizza in it
        ORDER BY order_id,
            pizza_id
    ) AS row_number_order,
    order_id,
    customer_id,
    pizza_id,
    exclusions,
    extras,
    order_time
FROM first_layer;

-----------------------------------------------
-- Second: runner_orders:
DROP TABLE IF EXISTS runner_orders_cleaned;
CREATE TABLE runner_orders_cleaned AS WITH first_layer AS (
    SELECT order_id,
        runner_id,
        CAST(
            CASE
                WHEN pickup_time = 'null' THEN NULL
                ELSE pickup_time
            END AS timestamp
        ) AS pickup_time,
        CASE
            WHEN distance = '' THEN NULL
            WHEN distance = 'null' THEN NULL
            ELSE distance
        END as distance,
        CASE
            WHEN duration = '' THEN NULL
            WHEN duration = 'null' THEN NULL
            ELSE duration
        END as duration,
        CASE
            WHEN cancellation = '' THEN NULL
            WHEN cancellation = 'null' THEN NULL
            ELSE cancellation
        END as cancellation
    FROM runner_orders
)
SELECT order_id,
    runner_id, pickup_time,
    CAST(
        regexp_replace(distance, '[a-z]+', '') AS DECIMAL(5, 2)
    ) AS distance,
    CAST(regexp_replace(duration, '[a-z]+', '') AS INT) AS duration,
    cancellation
FROM first_layer;

select *
from runner_orders_cleaned;
--1.change from characters to date and numbers for calculati
select
	COUNT(pizza_id) as number_of_pizzas
from
	customer_orders_cleaned;
--2. how many unique customer orders were made
select
	COUNT(distinct order_id) as number_of_orders
from
	customer_orders_cleaned;
--3.how many sucessful orders were made
select
	runner_id,
	COUNT (order_id)
from
	runner_orders_cleaned
where
	cancellation is null
group by
	runner_id;
--4.how many of each type of pizza was delivered
select
	pn.pizza_name,
	COUNT (customer_orders_cleaned.pizza_id)
from
	customer_orders_cleaned
left join runner_orders_cleaned
	on
	runner_orders_cleaned.order_id = customer_orders_cleaned.order_id
left join pizza_names pn 
	on
	customer_orders_cleaned.pizza_id = pn.pizza_id
where
	cancellation is null
group by
	pn.pizza_name ;
-- how many meat lovers and vegeriterians were ordered
select
	co.customer_id,
	pn.pizza_name,
	COUNT(co.pizza_id)
from
	customer_orders_cleaned co
left join pizza_names pn
	on
	pn.pizza_id = co.pizza_id
group by
	customer_id ,
	pizza_name;
-- maximium number of pizzas delivered in a single order
with pizza_count_cte as (
select
	co.order_id,
	count(co.pizza_id) as number_of_orders
from
	customer_orders_cleaned co
left join runner_orders_cleaned ro
	on
	co.order_id = ro.order_id
where
	cancellation is null
group by
	co.order_id
)
select
	MAX(number_of_orders)
from
	pizza_count_cte pc;
-- 7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select
	co.customer_id,
	SUM(case 
  when co.exclusions is not null or co.extras is not null then 1
  else 0
  end) as at_least_1_change,
	SUM(case 
  when co.exclusions is null and co.extras is null then 1 
  else 0
  end) as no_change
from
	customer_orders_cleaned co
join runner_orders_cleaned ro
 on
	co.order_id = ro.order_id
where
	ro.cancellation is null
group by
	co.customer_id
order by
	co.customer_id;
--8.How many pizzas were delivered that had both exclusions and extras?
select
	SUM(case
		when co.exclusions is not null and co.extras is not null then 1
		else 0
		end) as pizzas_delivered_with_changes
from
	customer_orders_cleaned co
join runner_orders_cleaned ro
	on
	co.order_id = ro.order_id
where
	ro.cancellation is null;
--9.What was the total volume of pizzas ordered for each hour of the day?
select
	extract(
        hour
from
	order_time
    ) as order_hour,
	COUNT(
        extract(
            hour
            from order_time
        )
    ) as count_pizza_ordered
from
	customer_orders_cleaned
group by
	order_hour
order by
	order_hour;
--10What was the volume of orders for each day of the week?
select
	to_char(order_time, 'Day') as day_ordered,
	COUNT(to_char(order_time, 'Day')) as count_pizza_ordered
from
	customer_orders_cleaned
group by
	day_ordered
order by
	day_ordered; 
-- customer experience
--1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select
	registration_week,
	COUNT(registration_week) as runners_signed_up
from
	(
	select
		runner_id,
		cast(to_char(registration_date, 'WW') as numeric) as registration_week
	from
		runners
    ) as runner_sign_date
group by
	registration_week
order by
	registration_week;
--2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select
	ro.runner_id,
	ROUND(
        cast(
            AVG(
                (
                    DATE_PART('hour', ro.pickup_time - co.order_time) * 60 + DATE_PART('second', ro.pickup_time - co.order_time) / 60
                ) + DATE_PART('minute', ro.pickup_time - co.order_time)
            ) as numeric
        ),
        2
    ) as avg_delivery_time
from
	customer_orders_cleaned co
left join runner_orders_cleaned ro
	on
	ro.order_id = co.order_id
group by
	ro.runner_id
order by
	ro.runner_id;
--3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
with preparation_duration_cte as(
select
	COUNT(pizza_id) as numberofpizza ,
	ROUND(
        cast(
            AVG(
                (
                    DATE_PART('hour', ro.pickup_time - co.order_time) * 60 + DATE_PART('second', ro.pickup_time - co.order_time) / 60
                ) + DATE_PART('minute', ro.pickup_time - co.order_time)
            ) as numeric
        ),
        2
    ) as averagepickupduration
from
	runner_orders_cleaned ro
left join customer_orders_cleaned co
	on
	co.order_id = ro.order_id
where
	ro.cancellation is null
group by
	ro.order_id
)
select
	numberofpizza,
	avg(averagepickupduration)
from
	preparation_duration_cte
group by
	numberofpizza;
--4.What was the average distance travelled for each customer?
select
	AVG(ro.distance) as averagedistance,
	co.customer_id
from
	runner_orders_cleaned ro
join customer_orders_cleaned co
	on
	ro.order_id = co.order_id
where
	ro.cancellation is null
group by
	co.customer_id;
--5.What was the difference between the longest and shortest delivery times for all orders?
select
	MAX(duration) - MIN(duration) as difference
from
	runner_orders_cleaned ro
where
	cancellation is null;
--6.What was the average speed for each runner for each delivery and do you notice any trend for these values?
select
	runner_id,
	order_id,
	distance / duration * 60 as speedkmh
from
	runner_orders_cleaned
where
	cancellation is null;
--7.--What is the successful delivery percentage for each runner?
select
	runner_id, 
	100 * SUM(
	case when cancellation is null then 1
	else 0
	end)/ count(order_id) as sucess_percentage
from
	runner_orders_cleaned
group by
	runner_id;
--ingredients
-- 1) What are the standard ingredients for each pizza?
-- Normalize Pizza Recipe table
with pizza_recipes_unstacked as (
select
	pizza_id,
	cast(
            unnest(
                string_to_array(toppings, ', ')
            ) as INT
        ) as topping_id
from
	pizza_recipes)
select
	pn.pizza_name,
	string_agg(topping_name, ',') as ingredients
from
	pizza_recipes_unstacked pr
left join pizza_toppings pt
	on
	pt.topping_id = pr.topping_id
left join pizza_names pn 
	on
	pn.pizza_id = pr.pizza_id
group by
	pn.pizza_name;
--2What was the most commonly added extra?
with extras_unstacked as (
select
	cast(
            unnest(
                string_to_array(extras, ', ')
            ) as INT
        ) as topping_id
from
	customer_orders_cleaned)
select
	pt.topping_name,
	count (eu.topping_id)
from
	extras_unstacked eu
left join pizza_toppings pt 
	on
	pt.topping_id = eu.topping_id
group by
	pt.topping_name;
--3) What was the most common exclusion?
with exclusions_unstacked as (
select
	cast(
            unnest(
                string_to_array(exclusions, ', ')
            ) as INT
        ) as topping_id
from
	customer_orders_cleaned)
select
	pt.topping_name,
	count (eu.topping_id)
from
	exclusions_unstacked eu
left join pizza_toppings pt 
	on
	pt.topping_id = eu.topping_id
group by
	pt.topping_name;
-- 4) Generate an order item for each record in the customers_orders table in the format of one of the following:
--     Meat Lovers
--     Meat Lovers - Exclude Beef
--     Meat Lovers - Extra Bacon
--     Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
--- PRICING
--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes — how much money has Pizza Runner made so far if there are no delivery fees?
select sum(case 
	when pizza_id = 1 then 12
	else 10
end) as total_revenue
from customer_orders_cleaned co
left join runner_orders_cleaned ro
on co.order_id = ro.order_id
where ro.cancellation is null;
--2 What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra ie. all toppings are 1$ but cheese is $2
WITH extras_unstacked AS (
    select CAST(
            UNNEST(
                string_to_array(extras, ', ')
            ) AS INT
        ) AS topping_id
    FROM customer_orders_cleaned)
select sum(case 
	when pizza_id = 1 then 12
	else 10
end)+(select sum(case when topping_id = '4' then 2 else 1 end) from extras_unstacked) as total_revenue
from customer_orders_cleaned co
left join runner_orders_cleaned ro
on co.order_id = ro.order_id
where ro.cancellation is null