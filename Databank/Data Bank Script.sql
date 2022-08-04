--A. Customer Nodes Exploration
--How many unique nodes are there on the Data Bank system?
 select count (distinct node_id)
 from customer_nodes cn; 
--What is the number of nodes per region?
 select region_name, count (distinct node_id) as number_of_nodes
 from customer_nodes cn
 join regions r 
 on r.region_id = cn.region_id 
 group by r.region_name;
--How many customers are allocated to each region?
select r.region_name, count (distinct cn.customer_id) as number_of_customers
from customer_nodes cn
join regions r 
on cn.region_id = r.region_id
group by r.region_name;
--How many days on average are customers reallocated to a different node?
-- after running the query the first time, we see that the numbers are unusually high.
--exploring the data, we see that the end date of some entries are '9999-12-31' so we have to delete them(or correct them if the right data is available)
delete from customer_nodes  
where end_date > '2022-01-01';
-- now we perform our calculations
select avg(end_date - start_date)
from customer_nodes cn;
--What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
select PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY end_date - start_date) as median,
		PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY end_date - start_date) as eightheth_percentile,
		PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY end_date - start_date) as ninthth_percentile
from customer_nodes cn;
--B. Customer Transactions
--What is the unique count and total amount for each transaction type?
select txn_type, count(txn_type) as number_of_transactions, sum(txn_amount) as total_amount
from customer_transactions ct
group by txn_type;
--What is the average total historical deposit counts and amounts for all customers?
select count(txn_type) as number_of_deposits, sum(txn_amount) as total_deposit_amount
from customer_transactions ct
where txn_type = 'deposit';
--For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with month_cte as(select customer_id, date_part('month',txn_date) as txn_month,
	sum(case when txn_type = 'deposit' then 1 else 0 end) as deposits,
	sum(case when txn_type = 'purchase' then 1 else 0 end) as purchases,
	sum(case when txn_type = 'withdrawal' then 1 else 0 end) as withdrawals
from customer_transactions ct
group by customer_id, txn_month
order by customer_id, txn_month)
select txn_month, count(distinct customer_id)
from month_cte
where deposits>1 and (purchases=1 or withdrawals=1)
group by txn_month;
--What is the closing balance for each customer at the end of the month?
with balance_cte as(select customer_id, date_part('month',txn_date) as txn_month,
	sum(case when txn_type = 'deposit' then txn_amount  else -txn_amount end) as net_transactions
from customer_transactions ct
group by customer_id, txn_month
order by customer_id, txn_month)
select customer_id,
	txn_month,
	net_transactions,
	sum(net_transactions) over(partition by customer_id order by txn_month ROWS between unbounded preceding and current ROW) as BALANCE
from balance_cte;
--What is the percentage of customers who increase their closing balance by more than 5%?
--create a row number column to diffrentiate between opening months and the next month and help aggregate
-- also bring down the previous balance to the same row so we cn use it in aggregation
with balance_cte as(select customer_id, date_part('month',txn_date) as txn_month,
	sum(case when txn_type = 'deposit' then txn_amount  else -txn_amount end) as net_transactions
from customer_transactions ct
group by customer_id, txn_month
order by customer_id, txn_month),
aggregate_cte as(select customer_id,
	txn_month,
	net_transactions,
	sum(net_transactions) over(partition by customer_id order by txn_month ROWS between unbounded preceding and current ROW) as BALANCE,
	ROW_NUMBER() OVER(PARTITION BY customer_id) row_num
from balance_cte),
lagged_cte as(SELECT 
    *,
    LAG(balance) OVER (PARTITION BY customer_id ORDER BY txn_month) previous_cb
FROM aggregate_cte)
select SUM(CASE WHEN row_num = 2 AND previous_cb > 0 AND (previous_cb * 1.05)<balance 
            THEN 1 ELSE 0 END ) increase_cb
from lagged_cte;
