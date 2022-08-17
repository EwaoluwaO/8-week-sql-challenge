select
	discount ,(1-(discount/100::numeric))*(price*qty) actual_revenue, price*qty potential_revenue, discount*price*qty/100::numeric discount
from
	"Balanced Tree".balanced_tree.sales s ;
	--High Level Sales Analysis
	--1What was the total quantity sold for all products?
select
	d.product_name, count(*)
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details d on
	d.product_id = s.prod_id
group by d.product_name;
	--2What is the total generated revenue for all products before discounts?
select
	d.product_name , sum(d.price*qty) total_sales
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details d on
	d.product_id = s.prod_id
group by d.product_name;
	--3What was the total discount amount for all products?
select
	 sum(discount*price*qty/100::numeric) total_discount
from "Balanced Tree".balanced_tree.sales s;
	--Transaction Analysis
--1How many unique transactions were there?
select
	count(distinct txn_id)
from
	"Balanced Tree".balanced_tree.sales s;
	--2What is the average unique products purchased in each transaction?
with transactionscte as(select
	txn_id,
	count(distinct prod_id) unique_items
from
	"Balanced Tree".balanced_tree.sales s
group by txn_id)
select avg(Unique_items)
from transactionscte;
	--3What are the 25th, 50th and 75th percentile values for the revenue per transaction?
with transactions as(select
	txn_id,
	sum((1-(discount/100::numeric))*price*qty) revenue
from
	"Balanced Tree".balanced_tree.sales s
group by
	txn_id)
select
	percentile_disc(0.25) within group (order by revenue) twentyfifth_percentile,
	percentile_disc(0.5) within group (order by revenue) median,
	percentile_disc(0.75) within group (order by revenue) seventyfifth_percentile
from 
	transactions;
	--3What is the average discount value per transaction?
with transactionscte as(
select txn_id, sum(discount*qty*price/100::numeric) value
from "Balanced Tree".balanced_tree.sales s
group by txn_id)
select
	avg(value) discount_avg
from
	transactionscte;
	--4What is the percentage split of all transactions for members vs non-members?
with membership as(select
	txn_id ,"member", count(prod_id) 
from
	"Balanced Tree".balanced_tree.sales s
group by txn_id, "member"),
aggregate as(select
	sum(case when "member" is true then 1 else 0 end) member_txn,
	sum(case when "member" is not true then 1 else 0 end) non_member_txn,
	count(*) total_txn
from
	membership)
select
	round(100 * member_txn / total_txn::numeric, 2) mem_percent,
	round(100 * non_member_txn / total_txn::numeric, 2) non_mem_percent
from
	aggregate;
	--5What is the average revenue for member transactions and non-member transactions?
with membership as(select
	txn_id ,"member", sum((1-(discount/100::numeric))*price*qty) tot_rev 
from
	"Balanced Tree".balanced_tree.sales s
group by txn_id, "member")
select
	"member", 
	round(avg(tot_rev),2)
from
	membership
group by "member"

--Product Analysis
--What are the top 3 products by total revenue before discount?
select
	pd.product_name,
	sum(s.price * s.qty) revenue
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details pd on
	pd.product_id = s.prod_id
group by
	pd.product_name 
order by revenue desc 
limit 3;
	--What is the total quantity, revenue and discount for each segment?
select
	pd.segment_name ,
	count(s.prod_id) total_quantity,
	sum((s.price*s.qty)-(s.price * qty * discount / 100)) total_revenue,
	sum(s.price * qty * discount / 100) total_discount
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details pd on
	pd.product_id = s.prod_id
group by
	pd.segment_name;
	--What is the top selling product for each segment?
with countcte as(select
	pd.segment_name ,
	pd.product_name ,
	count(s.prod_id) total_quantity
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details pd on
	pd.product_id = s.prod_id
group by
	pd.segment_name, pd.product_name 
order by total_quantity),
ranks as(select 
	segment_name,
	product_name,
	total_quantity,
	rank () OVER(PARTITION BY segment_name ORDER BY total_quantity desc) ranking
from countcte
group by segment_name, product_name, total_quantity)
select *
from ranks
where ranking=1;
	--What is the total quantity, revenue and discount for each category?
select
	pd.category_name, count(s.prod_id) quantity, sum((1-(discount/100::numeric))*s.price*s.qty) total_revenue, sum(discount/100::numeric*s.price*s.qty) discount_total 
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details pd on
	pd.product_id = s.prod_id
group by pd.category_name; 
	--What is the top selling product for each category?
with rankingcte as(
select
	pd.category_name,
	pd.product_name ,
	count(s.prod_id) sales ,
	rank() over(partition by pd.category_name
order by
	count(s.prod_id) desc ) prank
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details pd on
	pd.product_id = s.prod_id
group by
	pd.category_name,
	pd.product_name)
select
	category_name,
	product_name,
	sales
from rankingcte
where prank=1;
	--What is the percentage split of revenue by product for each segment?
with revenuecte as(
select
	sum(case when pd.segment_id = 3 then s.price * s.qty else 0 end) jeans_rev,
	sum(case when pd.segment_id = 4 then s.price * s.qty else 0 end) jacket_rev,
	sum(case when pd.segment_id = 5 then s.price * s.qty else 0 end) shirt_rev,
	sum(case when pd.segment_id = 6 then s.price * s.qty else 0 end) socks_rev,
	sum(s.price * s.qty) total_rev
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details pd on
	pd.product_id = s.prod_id)
select
	round(100 * jeans_rev / total_rev::numeric,2) jeans_percentage,
	round(100 * jacket_rev / total_rev::numeric,2) jacket_percentage,
	round(100 * shirt_rev / total_rev::numeric,2) shirt_percentage,
	round(100 * socks_rev / total_rev::numeric,2) sock_percentage
from
	revenuecte;
	--What is the percentage split of revenue by segment for each category?
with revenuecte as(select
	sum(case when pd.category_id = 1 and pd.segment_id = 3 then s.price * s.qty else 0 end) womens_jeans,
	sum(case when pd.category_id = 1 and pd.segment_id = 4 then s.price * s.qty else 0 end) womens_jackets,
	sum(case when pd.category_id = 2 and pd.segment_id = 5 then s.price * s.qty else 0 end) mens_shirts,
	sum(case when pd.category_id = 2 and pd.segment_id = 6 then s.price * s.qty else 0 end) mens_socks,
	sum(s.price*s.qty) total_rev
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details pd 
on
	pd.product_id = s.prod_id)
select
	round(100 * womens_jeans/total_rev::numeric,2) womens_jeans_pct,
	round(100*womens_jackets/total_rev::numeric,2) womens_jackets_pct,
	round(100*mens_shirts/total_rev::numeric,2) mens_shirts_pct,
	round(100*mens_socks/total_rev::numeric,2) mens_socks_pct
from revenuecte                                      

	--What is the percentage split of total revenue by category?
with revenuecte as(
select
	sum(case when pd.category_id = 1 then s.price * s.qty else 0 end) womens_rev,
	sum(case when pd.category_id = 2 then s.price * s.qty else 0 end) mens_rev,
	sum(s.price * s.qty) total_rev
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details pd 
on
	pd.product_id = s.prod_id)
select
	round(100 * mens_rev / total_rev::numeric, 2) womens_percent,
	round(100 * womens_rev / total_rev::numeric, 2) mens_percent
from
	revenuecte;
	--What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
with purchasescte as(
select
	pd.product_name,
	count(distinct s.txn_id) cart_adds
from
	"Balanced Tree".balanced_tree.sales s
left join "Balanced Tree".balanced_tree.product_details pd on
	pd.product_id = s.prod_id
group by
	pd.product_name)
select
	*,
	round(cart_adds /(select count(distinct txn_id)from "Balanced Tree".balanced_tree.sales s2)::numeric, 2) penetration
from
	purchasescte;
	--What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
select
	s.txn_id ,
	pd.product_name
into
	temp table combinations_table
from
	"Balanced Tree".balanced_tree.sales s
join "Balanced Tree".balanced_tree.product_details pd on
	s.prod_id = pd.product_id;
select * from combinations_table

with sample as(
select
	a.txn_id ,
	a.product_name one,
	b.product_name two,
	COUNT(*) countForCombination
from
	combinations_table a
inner join combinations_table b
on
	a.txn_id = b.txn_id
	and a.product_name < b.product_name
group by
	a.txn_id,
	a.product_name ,
	b.product_name
order by
	countForCombination desc)
select
	one,
	two,
	c.product_name three,
	count(*) combinations
from
	sample d
inner join combinations_table c
on
	d.txn_id = c.txn_id
	and d.two < c.product_name
group by
	one,
	two,
	three
order by
	combinations desc
limit 3;
