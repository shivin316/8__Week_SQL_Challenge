#### 1. How many pizzas were ordered?
```sql
SELECT COUNT(pizza_id) AS 'Number_of_pizza_ordered'
FROM customer_orders_new;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/dbe617f4-74ef-4c1f-ad18-69ca6f686000)

#### 2. How many unique customer orders were made?
```sql
SELECT COUNT(DISTINCT order_id) AS 'unique_orders'
FROM customer_orders_new;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/1347a6cb-9732-47fe-aa51-8d27700e2bd6)

#### 3. How many successful orders were delivered by each runner?
```sql
SELECT r.runner_id,COUNT( DISTINCT c.order_id) AS 'succesfully_delivered' FROM customer_orders_new c INNER JOIN
runner_orders_new r ON c.order_id=r.order_id 
WHERE r.cancellation IS NULL
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/868ac54f-b154-4500-a719-673f57f389bf)

#### 4. How many of each type of pizza was delivered?
```sql
SELECT c.pizza_id,n.pizza_name,count(c.order_id) AS 'succesfully_delivered' FROM customer_orders_new c INNER JOIN
runner_orders_new r on c.order_id=r.order_id 
INNER JOIN pizza_names n ON n.pizza_id=c.pizza_id
WHERE r.cancellation IS NULL
GROUP BY 1,2
ORDER BY 1,2;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/c5d6603f-11ef-49ef-b518-37ac514df018)

#### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
SELECT c.customer_id,n.pizza_name,COUNT(*) AS 'Count' 
FROM customer_orders_new c INNER JOIN pizza_names n ON c.pizza_id=n.pizza_id
GROUP BY 1,2
ORDER BY 1,2;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/08fe3245-ebf3-498b-8c96-1dfd84ac3a71)

#### 6. What was the maximum number of pizzas delivered in a single order?
```sql
WITH cte as (SELECT c.customer_id,n.pizza_name,COUNT(*) AS 'Count' ,DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS 'rk'
FROM customer_orders_new c INNER JOIN pizza_names n ON c.pizza_id=n.pizza_id
GROUP BY 1,2)
SELECT DISTINCT pizza_name,Count FROM cte WHERE rk=1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/d6d79905-d709-4e84-9eef-9365eb4bcce7)

#### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
SELECT c.customer_id,
COUNT(CASE WHEN exclusions IS NULL AND extras IS NULL THEN c.order_id ELSE NULL END ) AS 'no_change',
COUNT(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL  THEN c.order_id ELSE NULL END ) AS 'atleast_1_change'
FROM customer_orders_new c INNER JOIN
runner_orders_new r on c.order_id=r.order_id 
WHERE r.cancellation IS NULL 
GROUP BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/f1b7bbe6-b5e8-4776-835a-fbc553c64ad2)

#### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT COUNT(c.pizza_id) AS 'number_of_pizzas_with_both_exclusions_and_extras'
FROM customer_orders_new c INNER JOIN
runner_orders_new r on c.order_id=r.order_id 
WHERE r.cancellation IS NULL AND c.exclusions IS NOT NULL AND c.extras IS NOT NULL;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/64a48130-d9ff-4a65-b416-b613a79b8de3)

#### 9. What was the total volume of pizzas ordered for each hour of the day?
 ```sql
SELECT HOUR(order_time) AS 'hour_of_day',COUNT(order_id) AS 'pizza_ordered'
FROM customer_orders_new
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/3a787a72-e002-4344-add8-085b9832ecaf)

#### 10. What was the volume of orders for each day of the week?
```sql
SELECT DATE_FORMAT(order_time,'%W') AS 'day',COUNT(order_id) AS 'pizza_ordered'
FROM customer_orders_new
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/14ad168d-6518-421c-a1a1-419676b87aa4)
