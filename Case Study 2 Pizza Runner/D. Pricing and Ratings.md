#### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes how much money has Pizza Runner made so far if there are no delivery fees?
```sql
SELECT (COUNT(CASE WHEN pn.pizza_name='Meatlovers' THEN c.order_id ELSE NULL END)*12 + 
COUNT(CASE WHEN pn.pizza_name='Vegetarian' THEN c.order_id ELSE NULL END)*10) AS 'total_earning'
FROM customer_orders_new c 
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id
JOIN runner_orders_new r ON c.order_id=r.order_id
WHERE cancellation IS NULL;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/15635ff1-184b-41b6-90a9-0b799896ca7b)

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
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/c0e47867-f1ae-4547-b064-9cf09ebf6f32)

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
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/586da535-774b-4074-925d-cf2ef08dc241)

#### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? customer_id ,order_id,runner_id,rating,order_time,pickup_time,Time between order and pickup,Delivery duration,Average speed,Total number of pizzas
```sql
SELECT DISTINCT c.customer_id,c.order_id,rg.rating,r.runner_id,c.order_time,r.pickup_time,TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time) AS 'Time between order and pickup',
r.duration,ROUND((r.distance/r.duration)*60,1) AS 'avg_speed',COUNT(c.pizza_id) OVER(PARTITION BY c.order_id) AS 'number_of_pizzas'
FROM customer_orders_new c
JOIN runner_orders_new r ON c.order_id=r.order_id
JOIN ratings rg ON c.order_id=rg.order_id 
WHERE r.cancellation IS NULL;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/cf17c12b-14a0-41b6-bae5-ae1721b8d795)

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
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/cce8acbb-09b6-4c7e-91b8-09fb00026b00)
