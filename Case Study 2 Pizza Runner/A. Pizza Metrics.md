#### 1. How many pizzas were ordered?
```sql
SELECT COUNT(pizza_id) AS 'Number_of_pizza_ordered'
FROM customer_orders_new;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/a5e79e99-e551-4e6b-93df-09d8ebe4dd09)

#### 2. How many unique customer orders were made?
```sql
SELECT COUNT(DISTINCT order_id) AS 'unique_orders'
FROM customer_orders_new;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/ed337e29-7cd4-497a-aa62-092a1ce92bf8)

#### 3. How many successful orders were delivered by each runner?
```sql
SELECT r.runner_id,COUNT( DISTINCT c.order_id) AS 'succesfully_delivered' FROM customer_orders_new c INNER JOIN
runner_orders_new r ON c.order_id=r.order_id 
WHERE r.cancellation IS NULL
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/3f05cfee-3e7d-4ceb-9d6f-104a22df0422)

#### 4. How many of each type of pizza was delivered?
```sql
SELECT c.pizza_id,n.pizza_name,count(c.order_id) AS 'succesfully_delivered' FROM customer_orders_new c INNER JOIN
runner_orders_new r on c.order_id=r.order_id 
INNER JOIN pizza_names n ON n.pizza_id=c.pizza_id
WHERE r.cancellation IS NULL
GROUP BY 1,2
ORDER BY 1,2;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/cdd3bf3d-85b8-4fa5-99b6-b1800f85dd73)

#### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
SELECT c.customer_id,n.pizza_name,COUNT(*) AS 'Count' 
FROM customer_orders_new c INNER JOIN pizza_names n ON c.pizza_id=n.pizza_id
GROUP BY 1,2
ORDER BY 1,2;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/cc2b1ad4-aefa-4dfe-aaab-c5b390e3271d)

#### 6. What was the maximum number of pizzas delivered in a single order?
```sql
WITH cte as (SELECT c.customer_id,n.pizza_name,COUNT(*) AS 'Count' ,DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS 'rk'
FROM customer_orders_new c INNER JOIN pizza_names n ON c.pizza_id=n.pizza_id
GROUP BY 1,2)
SELECT DISTINCT pizza_name,Count FROM cte WHERE rk=1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/a8d0aa70-faff-4e25-a283-05ea85f536d1)

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
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/bee6109c-43c2-4690-8051-015662ec7c7d)

#### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT COUNT(c.pizza_id) AS 'number_of_pizzas_with_both_exclusions_and_extras'
FROM customer_orders_new c INNER JOIN
runner_orders_new r on c.order_id=r.order_id 
WHERE r.cancellation IS NULL AND c.exclusions IS NOT NULL AND c.extras IS NOT NULL;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/bec01365-4342-445b-94f7-a041a5f796d4)

#### 9. What was the total volume of pizzas ordered for each hour of the day?
 ```sql
SELECT HOUR(order_time) AS 'hour_of_day',COUNT(order_id) AS 'pizza_ordered'
FROM customer_orders_new
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/7e39ca9e-d7d5-4cae-8aaf-52013b6214f0)

#### 10. What was the volume of orders for each day of the week?
```sql
SELECT DATE_FORMAT(order_time,'%W') AS 'day',COUNT(order_id) AS 'pizza_ordered'
FROM customer_orders_new
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/af15d643-f8cd-4224-9293-5386157a8d41)

