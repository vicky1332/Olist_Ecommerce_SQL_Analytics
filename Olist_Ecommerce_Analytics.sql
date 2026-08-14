CREATE DATABASE olist;
USE olist;

-- Customers
CREATE TABLE customers (
    customer_id CHAR(32) PRIMARY KEY,
    customer_unique_id CHAR(32) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- Orders
CREATE TABLE orders (
    order_id CHAR(32) PRIMARY KEY,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

-- Sellers
CREATE TABLE sellers (
    seller_id CHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- Products
CREATE TABLE products (
    product_id CHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g DECIMAL(10,2),
    product_length_cm DECIMAL(10,2),
    product_height_cm DECIMAL(10,2),
    product_width_cm DECIMAL(10,2)
); 

-- Order_Items
CREATE TABLE order_items (
    order_id CHAR(32),
    order_item_id INT,
    product_id CHAR(32),
    seller_id CHAR(32),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),

    PRIMARY KEY(order_id, order_item_id)
);

-- Order_Payments
CREATE TABLE order_payments (
    order_id CHAR(32),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2),

    PRIMARY KEY(order_id, payment_sequential)
);

-- Order_Reviews
CREATE TABLE order_reviews (
    review_id CHAR(32),
    order_id CHAR(32),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

-- Geoloaction
CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(12,8),
    geolocation_lng DECIMAL(12,8),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);

-- Product Category Translation
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE products
ADD CONSTRAINT fk_products_category
FOREIGN KEY (product_category_name)
REFERENCES product_category_name_translation(product_category_name);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_products
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_sellers
FOREIGN KEY (seller_id)
REFERENCES sellers(seller_id);

ALTER TABLE order_payments
ADD CONSTRAINT fk_order_payments_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE order_reviews
ADD CONSTRAINT fk_order_reviews_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- Business Overview
-- 1. How many customers, sellers, products, categories, and orders does Olist have?
select count(customer_id) as total_customers from customers;
select count(seller_id) as total_sellers from sellers;
select count(product_id) as total_products from products;
select count(order_id) as total_orders from orders;
select count(product_category_name) as total_categories from product_category_name_translation;

-- 2. What time period does the dataset cover?
select date(min(order_purchase_timestamp)) as first_date,
	   date(max(order_purchase_timestamp)) as last_date,
       round(datediff(max(order_purchase_timestamp),min(order_purchase_timestamp)) / 365,2) as time_period_yrs from orders;

-- 3. How are orders distributed by status?
with order_distribution as 
(select order_status, count(order_id) as order_count
from orders
group by order_status)

select order_status, order_count, 
round(order_count * 100.0 / (select count(*) from orders),2) as order_percentage
from order_distribution
order by order_percentage desc;

-- 4. Which product categories have the highest number of products?
select pc.product_category_name_english, 
count(p.product_id) as product_count
from product_category_name_translation pc
join products p 
on pc.product_category_name = p.product_category_name
group by pc.product_category_name_english
order by product_count desc
limit 10;

-- 5. Which sellers have listed the highest number of unique products?
select seller_id, 
count(distinct product_id) as unique_products
from order_items
group by seller_id
order by unique_products desc
limit 10;

-- Sales & Revenue Analysis
-- 6. What is the average order value (AOV) across the platform?
with aov as
(select order_id, 
sum(payment_value) as total_payment_value
from order_payments
group by order_id)

select round(avg(total_payment_value),2) as avg_order_value
from aov;

-- 7. Which product categories generate the highest revenue?
select pc.product_category_name_english, 
sum(od.price) as total_revenue
from product_category_name_translation pc
join products p 
on pc.product_category_name = p.product_category_name
join order_items od
on p.product_id = od.product_id
group by pc.product_category_name_english
order by total_revenue desc
limit 10;

-- 8. Which customers have spent the most money on the platform?
select c.customer_id, 
sum(op.payment_value) as money_spent
from customers c 
join orders o 
on c.customer_id = o.customer_id 
join order_payments op 
on o.order_id = op.order_id 
group by c.customer_id 
order by money_spent desc
limit 10;

-- 9. Which sellers generate the highest revenue?
select seller_id, 
sum(price) as total_revenue
from order_items
group by seller_id
order by total_revenue desc
limit 10;

-- 10. Which states generate the highest sales revenue?
select c.customer_state, 
sum(op.payment_value) as total_sales 
from customers c 
join orders o 
on c.customer_id = o.customer_id 
join order_payments op 
on o.order_id = op.order_id 
group by c.customer_state 
order by total_sales desc
limit 10;

-- 11. Which product categories have the highest average selling price?
select pc.product_category_name_english, 
avg(od.price) as avg_sp
from product_category_name_translation pc
join products p 
on pc.product_category_name = p.product_category_name
join order_items od 
on p.product_id = od.product_id
group by pc.product_category_name_english
order by avg_sp desc
limit 10;

-- 12. Which product categories have sold the highest number of units?
select pc.product_category_name_english, 
count(od.product_id) as units_sold
from product_category_name_translation pc
join products p 
on pc.product_category_name = p.product_category_name
join order_items od 
on p.product_id = od.product_id
group by pc.product_category_name_english
order by units_sold desc
limit 10;

-- 13. Which sellers have sold the highest number of units?
select seller_id, 
count(product_id) as units_sold
from order_items
group by seller_id
order by units_sold desc
limit 10;

-- Order & Time Analysis
-- 14. Which months have the highest number of orders?
select month(order_purchase_timestamp) as month, 
monthname(order_purchase_timestamp) as month_name, 
count(order_id) as no_of_orders
from orders 
group by month, month_name 
order by month;

-- 15. On which day of the week are the most orders placed?
select dayname(order_purchase_timestamp) as weekday, 
count(order_id) as no_of_orders
from orders 
group by weekday
order by no_of_orders desc
limit 1;

-- 16. What is the average delivery time (in days) for completed orders?
select avg(datediff(date(order_delivered_customer_date),date(order_purchase_timestamp))) as avg_delivery_time 
from orders
where order_status = "delivered";

-- 17. Which states have the longest average delivery time?
select c.customer_state,
avg(datediff(order_delivered_customer_date,order_purchase_timestamp)) as avg_delivery_time 
from customers c 
join orders o 
on c.customer_id = o.customer_id
where order_status = "delivered"
group by c.customer_state 
order by avg_delivery_time desc;

-- 18. Which sellers have the fastest average delivery time?
select od.seller_id,
avg(datediff(o.order_delivered_customer_date,o.order_purchase_timestamp)) as avg_delivery_time 
from order_items od
join orders o 
on od.order_id = o.order_id
where o.order_status = "delivered"
group by od.seller_id
order by avg_delivery_time
limit 10;

-- 19. Which product categories have the longest average delivery time?
select pc.product_category_name_english, 
avg(datediff(o.order_delivered_customer_date,o.order_purchase_timestamp)) as avg_delivery_time 
from product_category_name_translation pc
join products p 
on pc.product_category_name = p.product_category_name
join order_items od 
on p.product_id = od.product_id
join orders o 
on od.order_id = o.order_id
where o.order_status = 'delivered'
group by pc.product_category_name_english
order by avg_delivery_time desc;

-- Payment Analysis
-- 20. Which payment methods are used the most?
select payment_type,
count(order_id) as frequency 
from order_payments
group by payment_type 
order by frequency desc;

-- 21. What is the average number of installments used for each payment method?
select payment_type,
avg(payment_installments) as avg_installments
from order_payments
group by payment_type 
order by avg_installments desc;

-- Customer Analysis
-- 22. Which customers have placed the highest number of orders?
select customer_id, 
count(order_id) as order_count 
from orders 
group by customer_id 
order by order_count desc;

-- 23. What is the average order value for each customer?
with order_totals as
(select order_id, 
sum(payment_value) as order_total
from order_payments
group by order_id)

select o.customer_id,
avg(order_total) as avg_order_value 
from orders o 
join order_totals ot
on o.order_id = ot.order_id 
group by o.customer_id 
order by avg_order_value desc 
limit 10;

-- Seller Analysis
-- 24. Which sellers have the highest average order value?
with order_totals as
(select seller_id,order_id, 
sum(price) as order_total 
from order_items 
group by seller_id,order_id)

select od.seller_id, 
avg(order_total) as avg_order_value 
from order_items od 
join order_totals ot 
on od.order_id = ot.order_id 
group by od.seller_id 
order by avg_order_value desc 
limit 10;

-- Review & Customer Satisfaction Analysis
-- 25. Which product categories have the highest average review score?
select pc.product_category_name_english,
avg(r.review_score) as avg_review_score 
from product_category_name_translation pc 
join products p 
on pc.product_category_name = p.product_category_name 
join order_items od 
on p.product_id = od.product_id 
join orders o 
on od.order_id = o.order_id
join order_reviews r 
on o.order_id = r.order_id
group by pc.product_category_name_english
order by avg_review_score desc;

-- 26. Which sellers have the highest average review score?
select od.seller_id, 
avg(r.review_score) as avg_review_score
from order_items od
join orders o 
on od.order_id = o.order_id
join order_reviews r 
on o.order_id = r.order_id
group by od.seller_id
order by avg_review_score desc;

-- 27. Which states have the highest average review score?
select c.customer_state, 
avg(r.review_score) as avg_review_score
from customers c
join orders o 
on c.customer_id = o.customer_id
join order_reviews r 
on o.order_id = r.order_id
group by c.customer_state
order by avg_review_score desc;

-- Time-Based Sales Analysis
-- 28. Which months generate the highest sales revenue?
select year(order_purchase_timestamp) as year, month(o.order_purchase_timestamp) as month, monthname(o.order_purchase_timestamp) as month_name,
sum(op.payment_value) as sales_amount
from orders o 
join order_payments op 
on o.order_id = op.order_id 
group by year, month, month_name
order by sales_amount desc;

-- 29. Which months have the highest average order value?
with order_totals as
(select order_id,
sum(payment_value) as order_total
from order_payments
group by order_id)

select year(order_purchase_timestamp) as year, month(o.order_purchase_timestamp) as month, monthname(o.order_purchase_timestamp) as month_name,
avg(order_total) as avg_order_value 
from orders o 
join order_totals ot 
on o.order_id = ot.order_id 
group by year, month, month_name 
order by avg_order_value desc;

-- Payment Revenue Analysis
-- 30. Which payment method generates the highest total revenue?
select payment_type, 
sum(payment_value) as total_revenue 
from order_payments
group by payment_type
order by total_revenue desc;

-- 31. Which customer states have the highest Average Order Value (AOV)?
with order_totals as
(select order_id,
sum(payment_value) as order_total
from order_payments
group by order_id)

select c.customer_state,
avg(order_total) as avg_order_value 
from customers c 
join orders o 
on c.customer_id = o.customer_id
join order_totals ot 
on o.order_id = ot.order_id 
group by c.customer_state 
order by avg_order_value desc;

-- Product & Category Performance
-- 32. Which product categories have the highest average revenue per order?
with cat_order_totals as
(select p.product_category_name, od.order_id,
sum(od.price) as cat_revenue
from products p
join order_items od
on p.product_id = od.product_id
group by p.product_category_name, od.order_id)

select pc.product_category_name_english,
avg(cat_revenue) as avg_revenue
from product_category_name_translation pc 
join cat_order_totals ct 
on pc.product_category_name = ct.product_category_name
group by pc.product_category_name_english 
order by avg_revenue desc;

-- Seller & Customer Relationship Analysis
-- 33. Which sellers have processed the highest number of distinct orders?
select seller_id, 
count(distinct order_id) as order_count 
from order_items 
group by seller_id 
order by order_count desc
limit 10;

-- 34. Which customers have purchased from the highest number of distinct sellers?
select o.customer_id,
count(distinct od.seller_id) as seller_count 
from orders o 
join order_items od 
on o.order_id = od.order_id 
group by o.customer_id
order by seller_count desc
limit 10;

-- 35. Which sellers sell products in the highest number of distinct product categories?
select od.seller_id, 
count(distinct p.product_category_name) as product_cat_count
from order_items od 
join products p 
on od.product_id = p.product_id 
group by od.seller_id 
order by product_cat_count desc
limit 10;

-- 36. Which product categories are purchased by the highest number of distinct customers?
select pc.product_category_name_english, 
count(distinct o.customer_id) as customer_count
from product_category_name_translation pc
join products p 
on pc.product_category_name = p.product_category_name
join order_items od 
on p.product_id = od.product_id
join orders o 
on od.order_id = o.order_id
group by pc.product_category_name_english
order by customer_count desc
limit 10;

-- Quality & Benchmark Analysis
-- 37. Which sellers have the highest average review score? (Minimum 50 reviewed orders)
select od.seller_id, 
avg(r.review_score) as avg_review_score 
from order_items od 
join orders o
on od.order_id = o.order_id 
join order_reviews r
on o.order_id = r.order_id
group by od.seller_id 
having count(distinct od.order_id) >= 50
order by avg_review_score desc;

-- 38. Which customer states generate the highest average review score? (Minimum 100 reviewed orders)
select c.customer_state,
avg(r.review_score) as avg_review_score
from customers c 
join orders o 
on c.customer_id = o.customer_id
join order_reviews r
on o.order_id = r.order_id
group by c.customer_state
having count(o.order_id) >= 100
order by avg_review_score desc;

-- 39. Which payment methods have the highest average order value?
with order_totals as
(select order_id,
sum(payment_value) as order_total 
from order_payments
group by order_id)

select op.payment_type,
avg(ot.order_total) as avg_order_value 
from order_payments op 
join order_totals ot 
on op.order_id = ot.order_id 
group by op.payment_type 
order by avg_order_value desc;

-- Freight & Delivery Analysis
-- 40. Which sellers generate the highest total freight (shipping) charges?
select seller_id,
sum(freight_value) as shipping_charges 
from order_items 
group by seller_id 
order by shipping_charges desc
limit 10;

-- 41. Which product categories have the longest average delivery time?
select pc.product_category_name_english,
avg(datediff(o.order_delivered_customer_date,o.order_purchase_timestamp)) as avg_delivery_time
from product_category_name_translation pc 
join products p 
on pc.product_category_name = p.product_category_name
join order_items od 
on p.product_id = od.product_id 
join orders o 
on od.order_id = o.order_id
WHERE o.order_delivered_customer_date is not null
group by pc.product_category_name_english
order by avg_delivery_time desc;

-- 42. Which months have the highest average delivery time?
select month(order_purchase_timestamp) as month,
avg(datediff(order_delivered_customer_date,order_purchase_timestamp)) as avg_delivery_time
from orders 
where order_delivered_customer_date is not null
group by month 
order by avg_delivery_time desc;

-- 43. Which sellers have the highest average freight cost per order? (Minimum 50 orders)
with totals as
(select seller_id, order_id, 
sum(freight_value) as total_freight 
from order_items 
group by seller_id, order_id)

select seller_id, 
avg(total_freight) as avg_freight 
from totals 
group by seller_id 
having count(distinct order_id) >= 50 
order by avg_freight desc
limit 10;

-- 44. Which customers place orders with the highest average number of items per order? (Minimum 5 orders)
with totals as
(select o.customer_id, o.order_id, 
count(od.order_item_id) as total 
from orders o 
join order_items od 
on o.order_id = od.order_id 
group by o.customer_id, o.order_id)

select customer_id, 
avg(total) as avg_items 
from totals 
group by customer_id 
having count(distinct order_id) >= 5 
order by avg_items desc;

-- Delivery Performance Analysis
-- 45. Which customer states experience the highest average delivery delay?
select c.customer_state, 
avg(datediff(o.order_delivered_customer_date,o.order_estimated_delivery_date)) as avg_delay_days 
from customers c 
join orders o 
on c.customer_id = o.customer_id 
where o.order_status = "delivered"
and o.order_delivered_customer_date > o.order_estimated_delivery_date
group by c.customer_state 
order by avg_delay_days desc;

-- 46. Which sellers handle the highest number of delivered orders? (Minimum 50 delivered orders)
select od.seller_id, 
count(o.order_id) as delivered_orders 
from order_items od 
join orders o 
on od.order_id = o.order_id 
where o.order_status = "delivered" 
group by od.seller_id 
having count(distinct o.order_id) >= 50
order by delivered_orders desc
limit 10;

-- 47. Which sellers have the shortest average delivery time? (Minimum 50 delivered orders)
select od.seller_id, 
avg(datediff(o.order_delivered_customer_date,o.order_purchase_timestamp)) as avg_delivery_time 
from order_items od 
join orders o 
on od.order_id = o.order_id
where o.order_status = "delivered"
group by od.seller_id 
having count(distinct o.order_id) >= 50
order by avg_delivery_time
limit 10;

-- 48. Which months had the highest percentage of delayed deliveries?
select year(order_purchase_timestamp) as year, month(order_purchase_timestamp) as month, 
round(count(distinct case
					when order_delivered_customer_date > order_estimated_delivery_date
                    then order_id
                    end) * 100.0 / 
	  count(distinct order_id),2) as delayed_percentage
from orders
where order_status = 'delivered'
group by year, month 
order by delayed_percentage desc;

-- Delivery Impact & Customer Retention
-- 49. Do delayed deliveries receive lower average review scores?
select 
case
when o.order_delivered_customer_date > o.order_estimated_delivery_date then "Delayed"
else "On-Time" end as delivery_status,
count(o.order_id) as total_orders, 
round(avg(r.review_score),2) as avg_review_score 
from orders o 
join order_reviews r 
on o.order_id = r.order_id
where o.order_status = "delivered" 
group by delivery_status 
order by avg_review_score desc;

-- 50. Which customers have the longest gap between their first and last purchase? (Minimum 2 orders)
select c.customer_unique_id,
min(o.order_purchase_timestamp) as first_purchase,
max(o.order_purchase_timestamp) as last_purchase,
datediff(max(o.order_purchase_timestamp),min(o.order_purchase_timestamp)) as purchase_gap
from customers c 
join orders o 
on c.customer_id = o.customer_id
group by c.customer_unique_id 
having count(o.order_id) >= 2 
order by purchase_gap desc;

-- Revenue Contribution Analysis
-- 51. Which customer states contribute the highest percentage of total revenue?
select c.customer_state, 
sum(op.payment_value) as state_revenue, 
(select sum(payment_value) from order_payments) as total_revenue, 
round(sum(op.payment_value) * 100.0 / (select sum(payment_value) from order_payments),2) as percentage_contribution 
from customers c
join orders o 
on c.customer_id = o.customer_id  
join order_payments op 
on o.order_id = op.order_id 
group by c.customer_state 
order by percentage_contribution desc;

-- Advanced SQL & Window Functions
-- 52. Rank the product categories by total revenue.
with result as
(select pc.product_category_name_english,
sum(od.price) as total_revenue 
from product_category_name_translation pc
join products p 
on pc.product_category_name = p.product_category_name
join order_items od 
on p.product_id = od.product_id 
group by pc.product_category_name_english)

select *,
dense_rank() over(order by total_revenue desc) as revenue_rank 
from result;

-- 53. Top Performing Seller in Each State
with sellers as
(select c.customer_state, od.seller_id,
sum(od.price) as total_sales
from customers c 
join orders o 
on c.customer_id = o.customer_id 
join order_items od 
on o.order_id = od.order_id
group by c.customer_state, od.seller_id),

ranked_sellers as 
(select * , 
dense_rank() over (partition by customer_state order by total_sales desc) as drank 
from sellers)

select * from ranked_sellers 
where drank = 1;

-- 54. What are the top 3 revenue-generating product categories in each state?
with revenue as
(select c.customer_state, pc.product_category_name_english,
sum(od.price) as product_revenue 
from customers c 
join orders o 
on c.customer_id = o.customer_id 
join order_items od 
on o.order_id = od.order_id
join products p 
on od.product_id = p.product_id 
join product_category_name_translation pc 
on p.product_category_name = pc.product_category_name 
group by c.customer_state, pc.product_category_name_english),

top_revenue as
(select *,
dense_rank() over (partition by customer_state order by product_revenue desc) as drank
from revenue)

select * from top_revenue 
where drank <= 3;

-- 55. How did total revenue change compared to the previous month?
with monthly_revenue as
(select date_format(order_purchase_timestamp, '%Y-%m') as yearmonth,
sum(op.payment_value) as revenue 
from orders o 
join order_payments op 
on o.order_id = op.order_id
group by yearmonth), 

prev_revenue as
(select *, lag(revenue) over(order by yearmonth) as prev_month_revenue
from monthly_revenue) 

select *, 
round((revenue - prev_month_revenue) * 100.0 / (prev_month_revenue ),2) as growth_rate 
from prev_revenue;

-- 56. Are we getting more orders each month?
with monthly_orders as
(select date_format(order_purchase_timestamp, '%Y-%m') as yearmonth,
count(order_id) as month_orders
from orders 
group by yearmonth), 

prev_orders as
(select *, lag(month_orders) over(order by yearmonth) as prev_month_orders
from monthly_orders) 

select *, 
round((month_orders - prev_month_orders) * 100.0 / (prev_month_orders ),2) as growth_rate 
from prev_orders;

-- 57. What is the latest order placed by each customer?
with latest as
(select customer_id, order_id, order_purchase_timestamp,
row_number() over (partition by customer_id order by order_purchase_timestamp desc) as row_no
from orders)

select customer_id, order_id, order_purchase_timestamp
from latest 
where row_no = 1;

-- 58. Find the top 5 customers by total spending, along with their total order value.
with order_value as
(select c.customer_unique_id, 
sum(op.payment_value) as total_spending 
from customers c
join orders o 
on c.customer_id = o.customer_id 
join order_payments op 
on o.order_id = op.order_id 
group by c.customer_unique_id),

spending_rank as
(select *, 
dense_rank() over(order by total_spending desc) as sp_rank 
from order_value)

select customer_unique_id, total_spending
from spending_rank 
where sp_rank <= 5;

-- 59. Find the top 3 highest-spending customers within each customer city.
with city_spending as
(select c.customer_city, c.customer_unique_id,
sum(op.payment_value) as total_spending 
from customers c
join orders o 
on c.customer_id = o.customer_id 
join order_payments op 
on o.order_id = op.order_id 
group by c.customer_city, c.customer_unique_id),

spending_rank as
(select *, 
dense_rank() over (partition by customer_city order by total_spending desc) as drank 
from city_spending)

select customer_city, customer_unique_id, total_spending, drank
from spending_rank 
where drank <= 3;
 
-- 60. For each customer, find their previous order's total value, the current order's total value, and the difference between the two.
with order_values as
(select c.customer_unique_id, o.order_id, o.order_purchase_timestamp,
sum(op.payment_value) as order_value
from customers c
join orders o
on c.customer_id = o.customer_id
join order_payments op
on o.order_id = op.order_id
group by c.customer_unique_id, o.order_id, o.order_purchase_timestamp),

previous_orders as
(select *,
lag(order_value) over (partition by customer_unique_id order by order_purchase_timestamp) as prev_order_value
from order_values)

select customer_unique_id, order_id, order_purchase_timestamp, order_value, prev_order_value,
order_value - prev_order_value as difference
from previous_orders
where prev_order_value is not null;

-- 61. For each month, calculate the monthly revenue and the cumulative revenue from the beginning of the dataset up to that month.
with monthly_revenue as
(select date_format(o.order_purchase_timestamp, '%Y-%m') as yearmonth,
sum(op.payment_value) as monthly_revenue
from orders o
join order_payments op
on o.order_id = op.order_id
group by date_format(o.order_purchase_timestamp, '%Y-%m'))

select yearmonth, monthly_revenue,
sum(monthly_revenue) over(order by yearmonth) as cumulative_revenue
from monthly_revenue
order by yearmonth;

-- 62. For each customer, calculate their total spending and what percentage of the overall Olist revenue they contributed.
with customer_spending as
(select c.customer_unique_id,
sum(op.payment_value) as total_spending
from customers c
join orders o
on c.customer_id = o.customer_id
join order_payments op
on o.order_id = op.order_id
group by c.customer_unique_id)

select customer_unique_id, total_spending,
round((total_spending / sum(total_spending) over()) * 100, 2) as revenue_contribution_pct
from customer_spending
order by total_spending desc;

-- 63. Divide customers into 4 spending groups (quartiles), from lowest-spending to highest-spending customers.
with customer_spending as
(select c.customer_unique_id,
sum(op.payment_value) as total_spending
from customers c
join orders o
on c.customer_id = o.customer_id
join order_payments op
on o.order_id = op.order_id
group by c.customer_unique_id)

select customer_unique_id, total_spending,
ntile(4) over (order by total_spending) as spending_quartile
from customer_spending
order by total_spending;

-- 64. For each customer, calculate their total spending and compare it with the average spending of customers in their state.
with customer_spending as
(select c.customer_unique_id, c.customer_state,
sum(op.payment_value) as total_spending
from customers c
join orders o
on c.customer_id = o.customer_id
join order_payments op
on o.order_id = op.order_id
group by c.customer_unique_id, c.customer_state),

state_avg as
(select *,
avg(total_spending) over (partition by customer_state) as state_avg_spending
from customer_spending)

select customer_unique_id, customer_state, total_spending, state_avg_spending,
round(total_spending - state_avg_spending, 2) as difference
from state_avg
order by customer_state, total_spending desc;

-- 65. For each month, calculate the percentage of customers who are repeat customers — customers who had placed an order before that month.
with customer_orders as
(select c.customer_unique_id,
date_format(o.order_purchase_timestamp, '%Y-%m') as yearmonth,
min(o.order_purchase_timestamp) over(partition by c.customer_unique_id) as first_order_date
from customers c
join orders o
on c.customer_id = o.customer_id),

monthly_customers as
(select yearmonth,
count(distinct customer_unique_id) as total_customers,
count(distinct case
when first_order_date < str_to_date(concat(yearmonth, '-01'), '%Y-%m-%d')
then customer_unique_id end) as repeat_customers
from customer_orders
group by yearmonth)

select yearmonth, total_customers, repeat_customers,
round((repeat_customers / total_customers) * 100, 2) as repeat_customer_pct
from monthly_customers
order by yearmonth;

-- 66. For each customer, calculate total orders, total spending, average order value, first order date, latest order date, and spending rank within their city.
with customer_orders as
(select c.customer_unique_id, c.customer_city,
count(distinct o.order_id) as total_orders,
sum(op.payment_value) as total_spending,
avg(op.payment_value) as avg_order_value,
min(o.order_purchase_timestamp) as first_order_date,
max(o.order_purchase_timestamp) as latest_order_date
from customers c
join orders o
on c.customer_id = o.customer_id
join order_payments op
on o.order_id = op.order_id
group by c.customer_unique_id, c.customer_city),

customer_rank as
(select *,
dense_rank() over(
partition by customer_city
order by total_spending desc
) as spending_rank
from customer_orders)

select customer_unique_id, customer_city, total_orders,
round(total_spending, 2) as total_spending,
round(avg_order_value, 2) as avg_order_value,
first_order_date,
latest_order_date,
spending_rank
from customer_rank
order by customer_city, spending_rank;