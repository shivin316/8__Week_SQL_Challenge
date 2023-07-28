                             -- High Level Sales Analysis
-- Q1.What was the total quantity sold for all products?
-- SOLUTION -
SELECT SUM(qty) AS total_qty_sold
FROM sales;


-- Q2.What is the total generated revenue for all products before discounts?
-- SOLUTION -
SELECT SUM(qty*price) AS pre_discount_revenue FROM sales;


--Q3. What was the total discount amount for all products?
-- SOLUTION - 
SELECT ROUND(SUM(qty*price*discount*0.01)) AS total_discount_amount FROM sales;

--                                    Transaction Analysis

-- Q1. How many unique transactions were there?
-- SOLUTION - 
SELECT COUNT(DISTINCT txn_id) AS number_of_unique_transactions FROM sales;


-- Q2. What is the average unique products purchased in each transaction?
-- SOLUTION -

SELECT ROUND(AVG(number_of_products)) AS avg_unique_products_purchased
FROM(
SELECT txn_id,COUNT(DISTINCT prod_id) AS number_of_products
FROM sales GROUP BY 1)x;


-- Q3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
-- SOLUTION -
WITH revenue AS (
SELECT txn_id,ROUND(SUM((qty * price) - (qty * price * 0.01 * discount)), 1) AS revenue FROM sales
GROUP BY 1 )
SELECT
PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY revenue) AS revenue_25th_percentile,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY revenue) AS revenue_50th_percentile,
PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY revenue) AS revenue_75th_percentile
FROM revenue;


--Q4. What is the average discount value per transaction?
-- 
SELECT ROUND(AVG(total_discount),2) AS avg_discount_value
FROM(
SELECT txn_id,SUM(qty*price*0.01*discount) AS total_discount
FROM sales GROUP BY 1)x;


--Q5. What is the percentage split of all transactions for members vs non-members?
-- SOLUTION -
WITH cte AS (
SELECT DISTINCT txn_id
CASE WHEN member iS True THEN 'Member' ELSE 'Non-member' END AS member_status
FROM
sales
),
cte1 AS (
SELECT
member_status,COUNT(*) AS number_of_transactions FROM cte GROUP BY 1
)
SELECT member_status, number_of_transactions,
ROUND((100 * number_of_transactions::NUMERIC / SUM(number_of_transactions) OVER ()), 1) AS transaction_percentage
FROM cte1 ORDER BY 2 DESC;


-- Q6. What is the average revenue for member transactions and non-member transactions?
-- SOLUTION 
WITH cte AS (
SELECT txn_id,qty,price,discount,(qty * price) - (qty * price * 0.01 * discount ) AS rev,
CASE WHEN member iS True THEN 'Member' ELSE 'Non-member' END AS member_status
FROM
sales
),
cte1 AS (
SELECT member_status ,SUM(rev) AS total_revenue ,COUNT(*) AS cnt 
FROM cte GROUP BY 1 )

SELECT member_status,ROUND(total_revenue/cnt::NUMERIC,2) AS average_revenue FROM cte1;


                                             -- Product Analysis
--Q1. What are the top 3 products by total revenue before discount?
-- SLUTION - 
SELECT p.product_name,SUM((s.qty*s.price)) AS pre_discount_revenue FROM sales s
JOIN product_details p ON s.prod_id=p.product_id
GROUP BY 1 ORDER BY 2 DESC LIMIT 3;


-- Q2. What is the total quantity, revenue and discount for each segment?
-- SOLUTION-
SELECT p.segment_name,SUM(qty) AS total_qty, ROUND(SUM((s.price*s.qty)-(s.price*s.qty*0.01*s.discount))) AS total_revenue ,
ROUND(SUM(s.price*s.qty*0.01*s.discount)) AS total_discount FROM sales s 
JOIN product_details p ON s.prod_id=p.product_id
GROUP BY 1 ORDER BY 1;


--Q3. What is the top selling product for each segment?
-- SOLUTION -
WITH cte AS (SELECT p.segment_name,p.product_name,SUM(qty) AS total_qty_sold,
DENSE_RANK()OVER(PARTITION BY p.segment_name ORDER BY SUM(qty) DESC) AS rk  
FROM sales s 
JOIN product_details p ON s.prod_id=p.product_id
GROUP BY 1,2)
SELECT segment_name,product_name,total_qty_sold FROM cte WHERE rk=1
;


--Q4. What is the total quantity, revenue and discount for each category?
-- SOLUTION -
SELECT p.category_name,SUM(qty) AS total_qty, ROUND(SUM((s.price*s.qty)-(s.price*s.qty*0.01*s.discount))) AS total_revenue ,
ROUND(SUM(s.price*s.qty*0.01*s.discount)) AS total_discount FROM sales s 
JOIN product_details p ON s.prod_id=p.product_id
GROUP BY 1 ORDER BY 1;


--Q5. What is the top selling product for each category?
-- SOLUTION -
WITH cte AS (SELECT p.category_name,p.product_name,SUM(qty) AS total_qty_sold,
DENSE_RANK()OVER(PARTITION BY p.category_name ORDER BY SUM(qty) DESC) AS rk  
FROM sales s 
JOIN product_details p ON s.prod_id=p.product_id
GROUP BY 1,2)
SELECT category_name,product_name,total_qty_sold FROM cte WHERE rk=1
;


--Q6. What is the percentage split of revenue by product for each segment?
-- SOLUTION
WITH cte AS (
SELECT p.segment_name,p.product_name,ROUND(SUM((s.price*s.qty)-(s.price*s.qty*0.01*s.discount))) AS total_revenue
FROM sales s 
JOIN product_details p ON s.prod_id=p.product_id
GROUP BY 1,2)
SELECT segment_name,product_name,ROUND(100*(total_revenue/SUM(total_revenue) OVER(PARTITION BY segment_name)::NUMERIC),2) AS pct
FROM cte ORDER BY 1,3 DESC;


-- Q7. What is the percentage split of revenue by segment for each category?
-- SOLUTION -
WITH cte AS (
SELECT p.category_name,p.segment_name,ROUND(SUM((s.price*s.qty)-(s.price*s.qty*0.01*s.discount))) AS total_revenue
FROM sales s 
JOIN product_details p ON s.prod_id=p.product_id
GROUP BY 1,2)
SELECT category_name,segment_name,ROUND(100*(total_revenue/SUM(total_revenue) OVER(PARTITION BY category_name)::NUMERIC),2) AS pct
FROM cte ORDER BY 1,3 DESC;


--Q8. What is the percentage split of total revenue by category?
--SOLUTION -
WITH cte AS (
SELECT p.category_name,ROUND(SUM((s.price*s.qty)-(s.price*s.qty*0.01*s.discount))) AS total_revenue
FROM sales s 
JOIN product_details p ON s.prod_id=p.product_id
GROUP BY 1)
SELECT category_name,ROUND(100*(total_revenue/SUM(total_revenue) OVER()::NUMERIC),2) AS pct
FROM cte ORDER BY 2 DESC;


-- Q9.What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
-- SOLUTION -
WITH cte AS(
SELECT p.product_name ,COUNT(*) AS cnt FROM sales s
JOIN product_details p ON s.prod_id=p.product_id
GROUP BY 1)
SELECT product_name,ROUND(100*(cnt/(SELECT COUNT(DISTINCT txn_id) FROM sales)::NUMERIC),2) AS penetration_pct
FROM cte ORDER BY 2 DESC;


--Q10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
-- SOLUTION -
WITH cte AS (
SELECT p.product_id,p.product_name,s.txn_id FROM sales s
JOIN product_details p ON s.prod_id=p.product_id
ORDER BY 3
),
cte1 AS (
SELECT c1.product_name AS p1,c2.product_name AS p2,c3.product_name AS p3,COUNT(*) AS cnt
FROM cte c1 JOIN cte c2 ON c1.txn_id=c2.txn_id AND c1.product_id>c2.product_id
JOIN cte c3 ON c2.txn_id=c3.txn_id AND c2.product_id>c3.product_id
GROUP BY 1,2,3
ORDER BY 4 DESC LIMIT 1
)
SELECT CONCAT(p1,' with ',p2,' and ',p3) AS combination,cnt FROM cte1;


                                                           -- BONUS QUESTION
														   
-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
-- SOLUTION - 
SELECT * FROM product_hierarchy;
SELECT * FROM product_prices;
SELECT * FROM product_details;

WITH cte AS (
SELECT pp.product_id,pp.price,
CASE WHEN ph.parent_id IN(1,3,4) THEN 1 ELSE 2 END AS category_id,
CASE WHEN ph.parent_id = 3 THEN 3
WHEN ph.parent_id = 4 THEN 4
WHEN ph.parent_id = 5 THEN 5
WHEN ph.parent_id = 6 THEN 6
END AS segment_id, pp.id AS style_id,
CASE WHEN ph.parent_id IN(1,3,4) THEN 'Womens' ELSE 'Mens' END AS category_name,
CASE WHEN ph.parent_id = 3 THEN 'Jeans'
WHEN ph.parent_id = 4 THEN 'Jacket'
WHEN ph.parent_id = 5 THEN 'Shirt'
WHEN ph.parent_id = 6 THEN 'Socks'
END AS segment_name,ph.level_text AS style_name
FROM product_hierarchy AS ph
JOIN product_prices AS pp ON ph.id = pp.id)

SELECT product_id,price,CONCAT(style_name,' ',segment_name,' - ',category_name) AS product_name,
category_id,segment_id,style_id,category_name,segment_name,style_name FROM cte;
