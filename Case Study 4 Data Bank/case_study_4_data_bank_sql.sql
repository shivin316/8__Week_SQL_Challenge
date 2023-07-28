USE data_bank;
DROP TABLE IF EXISTS details;
CREATE TEMPORARY TABLE details AS
SELECT c.customer_id,r.region_id,r.region_name,c.node_id,c.start_date,c.end_date,t.txn_date,t.txn_type,t.txn_amount
FROM regions r JOIN customer_nodes c ON r.region_id=c.region_id 
JOIN customer_transactions t ON c.customer_id=t.customer_id ORDER BY 1;


--                                                     A. Customer Nodes Exploration
-- Q1. How many unique nodes are there on the Data Bank system?
-- SOLUTION -
SELECT COUNT(DISTINCT node_id) AS 'n_unique_nodes' FROM details;


-- Q2. What is the number of nodes per region?
-- SOLUTION -
SELECT r.region_id,r.region_name,COUNT(node_id) AS 'n_nodes' 
FROM regions r
JOIN customer_nodes c ON r.region_id=c.region_id
GROUP BY 1,2
ORDER BY 1,2;


-- Q3. How many customers are allocated to each region?
-- SOLUTION -
SELECT region_id,region_name,COUNT(DISTINCT customer_id) AS 'n_customers' FROM details
GROUP BY 1,2;


-- Q4. How many days on average are customers reallocated to a different node?
WITH cte AS 
( 
SELECT *,LEAD(node_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_node,
LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_node_start_date
FROM customer_nodes)
, 
cte1 AS (SELECT DATEDIFF(next_node_start_date,start_date) AS 'diff' FROM cte)
SELECT ROUND(AVG(diff)) AS 'average_reallocation_days' FROM cte1;


-- Q5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
-- SOLUTION - 
WITH cte AS 
( 
SELECT c.customer_id,r.region_id,r.region_name,c.node_id,c.start_date,c.end_date,
LEAD(node_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_node,
LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_node_start_date
FROM customer_nodes c
JOIN regions r ON r.region_id=c.region_id)
, 
cte1 AS (SELECT region_name,DATEDIFF(LEAD(start_date) OVER(PARTITION BY customer_id),start_date) AS 'diff'
FROM cte)
,
cte2 AS (SELECT *,ROW_NUMBER() OVER(PARTITION BY region_name ORDER BY diff ASC) AS 'rn',COUNT(diff) OVER (PARTITION BY region_name) AS 'cnt' FROM cte1
 WHERE diff IS NOT NULL ORDER BY 1,2)

SELECT region_name,
SUM(CASE WHEN rn=ROUND(0.50*cnt) THEN diff ELSE 0 END) AS 'median',
SUM(CASE WHEN rn=ROUND(0.80*cnt) THEN diff ELSE 0 END) AS '80_percentile',
SUM(CASE WHEN rn=ROUND(0.95*cnt) THEN diff ELSE 0 END) AS '95_percentile'
FROM cte2 GROUP BY 1 ;

--                                                            B. Customer Transactions

-- Q1. What is the unique count and total amount for each transaction type?
-- SOLUTIION -
SELECT txn_type,COUNT( DISTINCT customer_id) AS 'unique_count',SUM(txn_amount) AS 'total_amount' FROM customer_transactions GROUP BY 1;


-- Q2. What is the average total historical deposit counts and amounts for all customers?
WITH cte AS (
SELECT customer_id, COUNT(customer_id) AS 'txn_count', AVG(txn_amount) AS 'avg_amount'
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)
SELECT ROUND(AVG(txn_count)) AS avg_deposit_count,ROUND(AVG(avg_amount)) AS 'avg_deposit_amt'
FROM cte;


-- Q3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
-- SOLUTIION-
WITH cte AS
(SELECT *,MONTH(txn_date) AS 'mth',COUNT(*)OVER(PARTITION BY customer_id,txn_type,MONTH(txn_date)) AS 'cnt' 
FROM customer_transactions)
,
cte1 AS (SELECT * FROM cte where cnt>1 AND txn_type='deposit')

SELECT c1.mth,COUNT(DISTINCT c1.customer_id) AS 'n-customers' 
FROM cte1 c1 JOIN cte c ON c1.customer_id=c.customer_id AND c.txn_type<>'deposit' AND c1.mth=c.mth
GROUP BY 1;

-- Q4. What is the closing balance for each customer at the end of the month?
-- SOLUTION -
CREATE TEMPORARY TABLE deposit_amount AS 
(SELECT DISTINCT customer_id, MONTH(txn_date) AS 'mth',
SUM( CASE WHEN txn_type='deposit' THEN txn_amount ELSE NULL END)AS 'deposit_amount'
FROM customer_transactions WHERE txn_type='deposit'
GROUP BY customer_id,MONTH(txn_date) ORDER BY 1 );

CREATE TEMPORARY TABLE removed_amount AS 
(SELECT DISTINCT customer_id, MONTH(txn_date) AS 'mth',
SUM( CASE WHEN txn_type<>'deposit' THEN txn_amount ELSE NULL END) AS 'removed_amount'
FROM customer_transactions WHERE txn_type<>'deposit'
GROUP BY customer_id,MONTH(txn_date) ORDER BY 1 
);

WITH RECURSIVE cte AS (
SELECT d.customer_id,d.mth,SUM(d.deposit_amount-IFNULL(r.removed_amount,0)) OVER (PARTITION BY d.customer_id ORDER BY d.mth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
AS 'amt' , MAX(d.mth) OVER (PARTITION BY d.customer_id) AS 'mmt',
ROW_NUMBER() OVER(PARTITION BY d.customer_id) AS 'rn',COUNT(*) OVER (PARTITION BY d.customer_id) AS 'cnt'
FROM deposit_amount d 
LEFT JOIN removed_amount r ON d.customer_id=r.customer_id AND d.mth=r.mth WHERE d.customer_id
UNION ALL
SELECT customer_id,mth+1 AS 'mth' ,amt,mmt,rn+1 as rn,cnt+1 AS cnt FROM cte WHERE mth<>mmt AND cnt<mmt )

SELECT customer_id,mth AS 'month',amt AS 'closing_balance' FROM cte
ORDER BY 1,2;


-- Q5. What is the percentage of customers who increase their closing balance by more than 5%?
-- SOLUTION 

WITH RECURSIVE cte AS (
SELECT d.customer_id,d.mth,SUM(d.deposit_amount-IFNULL(r.removed_amount,0)) OVER (PARTITION BY d.customer_id ORDER BY d.mth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
AS 'amt' , MAX(d.mth) OVER (PARTITION BY d.customer_id) AS 'mmt',
ROW_NUMBER() OVER(PARTITION BY d.customer_id) AS 'rn',COUNT(*) OVER (PARTITION BY d.customer_id) AS 'cnt'
FROM deposit_amount d 
LEFT JOIN removed_amount r ON d.customer_id=r.customer_id AND d.mth=r.mth WHERE d.customer_id
UNION ALL
SELECT customer_id,mth+1 AS 'mth' ,amt,mmt,rn+1 as rn,cnt+1 AS cnt FROM cte WHERE mth<>mmt AND cnt<mmt )
,
cte1 AS (SELECT customer_id,mth AS 'month',amt AS 'closing_balance' FROM cte
ORDER BY 1,2)

,cte2 AS (SELECT *,LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month),(closing_balance-LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month))/LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month) AS 'increase_by_5' 
FROM cte1)



SELECT ROUND(100*COUNT(DISTINCT increase_by_5)/(SELECT COUNT(DISTINCT customer_id) FROM customer_transactions),2) AS 'customer_pct'
FROM cte2 WHERE increase_by_5>5;
