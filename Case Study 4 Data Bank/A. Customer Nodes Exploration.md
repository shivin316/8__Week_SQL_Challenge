#### 1. How many unique nodes are there on the Data Bank system?
```sql
SELECT COUNT(DISTINCT node_id) AS 'n_unique_nodes' FROM details;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/a5277a7f-4477-4de8-9165-f34983142740)


#### 2. What is the number of nodes per region?
```sql
SELECT r.region_id,r.region_name,COUNT(node_id) AS 'n_nodes' 
FROM regions r
JOIN customer_nodes c ON r.region_id=c.region_id
GROUP BY 1,2
ORDER BY 1,2;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/e0a06bca-8e90-4b78-84d9-63a0b8a6cbcf)


#### 3. How many customers are allocated to each region?
```sql
SELECT region_id,region_name,COUNT(DISTINCT customer_id) AS 'n_customers' FROM details
GROUP BY 1,2;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/e2f593d0-7736-4023-ab0f-5480461897e1)


#### 4. How many days on average are customers reallocated to a different node?
```sql
WITH cte AS 
( 
SELECT *,LEAD(node_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_node,
LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_node_start_date
FROM customer_nodes)
, 
cte1 AS (
SELECT DATEDIFF(next_node_start_date,start_date) AS 'diff'
FROM cte
)
SELECT ROUND(AVG(diff)) AS 'average_reallocation_days' FROM cte1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/675db4cc-8591-4386-a8ae-45d1fd993239)


#### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```sql
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
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/8e003f19-d055-4b82-8441-f08030c29f8d)
