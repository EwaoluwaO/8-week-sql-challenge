CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);
INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
 CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
 CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
 --- question 1
 SELECT sales.customer_id, SUM(menu.price)
  FROM sales
  LEFT JOIN menu
  ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id;
  --question 2
 SELECT COUNT (DISTINCT order_date) AS "number of days visited", customer_id
FROM sales
GROUP BY customer_id;
--question 3 first product ordered by customers
SELECT customer_id, product_name
FROM(	
	SELECT customer_id, order_date, product_name,
	DENSE_RANK() OVER(PARTITION BY customer_id
	ORDER BY sales.order_date) AS ranking
	FROM sales
	LEFT JOIN menu
	ON sales.product_id = menu.product_id)
WHERE ranking = 1
GROUP BY customer_id , product_name;
--question 4 most purchased for everyone
SELECT sales.product_id, menu.product_name, COUNT(sales.product_id) AS "most_purchased"
FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.product_id, menu.product_name
ORDER BY most_purchased DESC
LIMIT 1;
--question 5
SELECT customer_id, product_name, times_bought
FROM(
	SELECT customer_id, product_name,count(sales.product_id) AS times_bought, DENSE_RANK () OVER(PARTITION BY customer_id ORDER BY count(sales.product_id)) AS ranking
	FROM sales
	LEFT JOIN menu
	ON sales.product_id = menu.product_id
	GROUP BY customer_id, product_name)
WHERE ranking=1
GROUP BY customer_id, product_name;
--Question 6 first thing ordered after joining
SELECT customer_id, product_name
FROM(
	SELECT sales.customer_id, sales.order_date, members.join_date, sales.product_id, DENSE_RANK () OVER(PARTITION BY sales.customer_id ORDER BY order_date) AS ranking
	FROM sales
	INNER JOIN members
	ON sales.customer_id = members.customer_id
	WHERE order_date >= join_date) AS f
LEFT JOIN menu
	ON f.product_id = menu.product_id
WHERE ranking = 1;
--question 7 what was ordered before the customer became a member
SELECT customer_id, product_name
FROM (
	SELECT sales.customer_id, sales.order_date, members.join_date, sales.product_id, DENSE_RANK () OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC) AS ranking
	FROM sales
	INNER JOIN members
	ON sales.customer_id = members.customer_id
	WHERE order_date < join_date) AS f
LEFT JOIN menu
	ON f.product_id = menu.product_id
WHERE ranking = 1;
--question 8 amount spent before becoming member
SELECT customer_id, COUNT (DISTINCT f.product_id), SUM(menu.price)
FROM(
	SELECT sales.customer_id, sales.order_date, members.join_date, sales.product_id
	FROM sales
	INNER JOIN members
	ON sales.customer_id = members.customer_id
	WHERE order_date < join_date) AS f
LEFT JOIN menu
	ON f.product_id = menu.product_id
GROUP BY customer_id;
--question 9
SELECT customer_id, SUM(points)
FROM(
	SELECT *,
	CASE
		WHEN product_id=1 THEN price*20
		ELSE price*10
	END AS points
FROM menu) AS f
LEFT JOIN sales
	ON sales.product_id = f.product_id
GROUP BY customer_id;
--QUESTION 10
SELECT sales.customer_id, SUM(CASE
	WHEN menu.product_id = 1 then menu.price*20
	WHEN sales.order_date between dates.join_date and dates.valid_date then menu.price*20
	else menu.price*10
END
) as points
FROM
	(SELECT members.customer_id, members.join_date, DATE(join_date, '+6 days') as valid_date, DATE(join_date, 'start of month','+1 month', '-1 day') as end_of_month
	from members) AS dates
left join sales
	on sales.customer_id = dates.customer_id
left join menu
	on menu.product_id = sales.product_id 
where sales.order_date < dates.end_of_month 
group by sales.customer_id;

--BONUS join all data
SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
	(CASE 
		WHEN sales.order_date >= members.join_date THEN 'Y'
	ELSE 'N'
	END) AS membership
from sales
LEFT JOIN menu
	on sales.product_id = menu.product_id 
left join members
	on sales.customer_id = members.customer_id 