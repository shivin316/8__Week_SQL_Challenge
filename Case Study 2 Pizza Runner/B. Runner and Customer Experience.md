#### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
WITH cte AS(
SELECT *,IF(DATEDIFF(registration_date,'2021-01-01')=0,1,CEIL(DATEDIFF(registration_date,'2021-01-01')/6)) AS 'wk' FROM runners
)
,
cte1 AS (
SELECT *, FIRST_VALUE(registration_date) OVER (PARTITION BY wk ORDER BY registration_date) AS 'start_week' FROM cte
)
SELECT start_week,COUNT(DISTINCT runner_id) AS 'runners_signup'
FROM cte1
GROUP BY 1 
ORDER BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/d1f75007-baee-4358-8cdc-0c0069f88e23)

#### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
SELECT r.runner_id,ROUND(AVG(TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time))) AS 'average_time(minutes)'
FROM runner_orders_new r JOIN customer_orders_new c ON r.order_id=c.order_id
GROUP BY 1 
ORDER BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/1f7afe47-ab00-409b-a750-d42f587e7e5a)

#### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
SELECT y AS 'number_of_pizzas', ROUND(AVG(t)) AS 'average_prep_time' FROM
(SELECT r.order_id,COUNT(c.order_id) AS y,TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time) AS 't'
FROM runner_orders_new r JOIN customer_orders_new c ON r.order_id=c.order_id
GROUP BY 1,3 ORDER BY 1)x
GROUP BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/196ab09b-5dab-44d8-a9b6-97b101bab4e0)

#### 4. What was the average distance travelled for each customer?
```sql
SELECT c.customer_id,ROUND(AVG(r.distance),1) AS 'average_distance(km)'
FROM runner_orders_new r JOIN customer_orders_new c ON r.order_id=c.order_id
GROUP BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/0e60b70d-3581-49e9-9a05-5c7beb81bc82)

#### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
SELECT MAX(duration)-MIN(duration) AS 'difference(minutes)'
FROM runner_orders_new;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/dc21fe70-ac29-4cee-bf98-087cd67f4405)

#### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
SELECT r.runner_id,c.customer_id,r.order_id,COUNT(c.order_id) AS'pizza_delivered',r.distance,r.duration, 
ROUND((r.distance/r.duration)*60,2) AS 'average_speed'
FROM runner_orders_new r JOIN customer_orders_new c ON r.order_id=c.order_id 
WHERE r.cancellation IS NULL
GROUP BY 1,2,3,5,6 
ORDER BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/35e87cca-a05a-4185-b6f8-2e9fcc744d6f)


#### 7. What is the successful delivery percentage for each runner?
```sql
SELECT runner_id,
ROUND((COUNT(CASE WHEN cancellation IS NULL THEN order_id ELSE NULL END)/COUNT(order_id))*100,2) AS 'success_pct'
FROM runner_orders_new 
GROUP BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/bb4a5620-5709-4717-b1d4-9621c28078a6)
