#### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes how much money has Pizza Runner made so far if there are no delivery fees?
```sql
SELECT (COUNT(CASE WHEN pn.pizza_name='Meatlovers' THEN c.order_id ELSE NULL END)*12 + 
COUNT(CASE WHEN pn.pizza_name='Vegetarian' THEN c.order_id ELSE NULL END)*10) AS 'total_earning'
FROM customer_orders_new c 
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id
JOIN runner_orders_new r ON c.order_id=r.order_id
WHERE cancellation IS NULL;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/81a063d9-6beb-4869-be84-fd68b5d0fce0)

#### 2. What if there was an additional $1 charge for any pizza extras?
```sql
CREATE TEMPORARY TABLE rn AS 
(SELECT * FROM runner_orders_new);

SELECT SUM(total_earning) AS 'total_earning' FROM
(SELECT (COUNT(CASE WHEN pn.pizza_name='Meatlovers' THEN c.order_id ELSE NULL END)*12 +
COUNT(CASE WHEN pn.pizza_name='Vegetarian' THEN c.order_id ELSE NULL END)*10) AS 'total_earning'
FROM customer_orders_new c 
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id
JOIN runner_orders_new r ON c.order_id=r.order_id
WHERE cancellation IS NULL
UNION ALL 
SELECT COUNT(*) AS 'extra_charge' FROM extra_ingredients ei JOIN rn r ON ei.order_id=r.order_id
WHERE cancellation IS NULL)x;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/6a6bbd85-d7dc-4157-9010-b94ad4f79218)

#### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
```sql
SELECT DISTINCT order_id FROM runner_orders_new WHERE cancellation IS NULL;
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings (
order_id INTEGER PRIMARY KEY,
rating INTEGER
);
INSERT INTO ratings VALUES
(1,4),
(2,3),
(3,1),
(4,5),
(5,2),
(7,3),
(8,4),
(10,4);

SELECT * FROM ratings;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/85fb5c4e-9315-481b-b90c-cc8129601514)

#### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? customer_id ,order_id,runner_id,rating,order_time,pickup_time,Time between order and pickup,Delivery duration,Average speed,Total number of pizzas
```sql
SELECT DISTINCT c.customer_id,c.order_id,rg.rating,r.runner_id,c.order_time,r.pickup_time,TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time) AS 'Time between order and pickup',
r.duration,ROUND((r.distance/r.duration)*60,1) AS 'avg_speed',COUNT(c.pizza_id) OVER(PARTITION BY c.order_id) AS 'number_of_pizzas'
FROM customer_orders_new c
JOIN runner_orders_new r ON c.order_id=r.order_id
JOIN ratings rg ON c.order_id=rg.order_id 
WHERE r.cancellation IS NULL;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/368ee974-a02b-4c1a-bfb0-f0e76b75cdb4)

#### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```sql
SELECT ROUND(SUM(total_earning)) AS 'overall_earning' FROM
(
SELECT (
COUNT(CASE WHEN pn.pizza_name='Meatlovers' THEN c.order_id ELSE NULL END)*12 + 
COUNT(CASE WHEN pn.pizza_name='Vegetarian' THEN c.order_id ELSE NULL END)*10 
) AS 'total_earning'
FROM customer_orders_new c 
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id
JOIN runner_orders_new r ON c.order_id=r.order_id
WHERE cancellation IS NULL
UNION ALL
SELECT  -SUM(distance)*0.3*2 AS 'paid_to_driver' FROM rn WHERE cancellation IS NULL
)x;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/4338bc12-9295-4829-bdbb-fca72f840cca)

