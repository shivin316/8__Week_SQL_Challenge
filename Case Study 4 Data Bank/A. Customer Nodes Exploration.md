#### 1. How many unique nodes are there on the Data Bank system?
```sql
SELECT COUNT(DISTINCT node_id) AS 'n_unique_nodes' FROM details;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/97677f61-7eaa-416a-ad84-f6053219460b)

#### 2. What is the number of nodes per region?
```sql
SELECT r.region_id,r.region_name,COUNT(node_id) AS 'n_nodes' 
FROM regions r
JOIN customer_nodes c ON r.region_id=c.region_id
GROUP BY 1,2
ORDER BY 1,2;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/a8b64b4f-2fa6-4128-929d-2439351ac705)

#### 3. How many customers are allocated to each region?
```sql
SELECT region_id,region_name,COUNT(DISTINCT customer_id) AS 'n_customers' FROM details
GROUP BY 1,2;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/78af7029-79ed-4881-aea9-d557d9430848)

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
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/4f5e7c73-213b-4613-8d19-495e15e3211c)

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
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/076be814-71c3-4c96-8dac-ae7016b304cc)
