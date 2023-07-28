#### 1. What are the standard ingredients for each pizza?
```sql
SELECT DISTINCT c.pizza_id,pn.pizza_name,topping_name 
FROM customer_orders_new c 
JOIN pizza_recipes_new pr ON c.pizza_id=pr.pizza_id 
JOIN pizza_toppings pt ON pr.toppings=pt.topping_id
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id
ORDER BY 1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/b282d7e9-cab3-44d8-86ef-6acd30119bd7)

#### 2. What was the most commonly added extra?
```sql
WITH cte AS
(SELECT extras,DENSE_RANK()OVER(ORDER BY COUNT(extras) DESC) AS 'rk' FROM customer_orders_split  
GROUP BY 1 HAVING extras IS NOT NULL)
SELECT topping_name FROM pizza_toppings
WHERE topping_id = (SELECT extras FROM cte WHERE rk= 1);
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/bd3f81f9-8fa7-401c-834c-e68e0466e1db)

#### 3. What was the most common exclusion?
```sql
WITH cte AS
(SELECT exclusions,DENSE_RANK()OVER(ORDER BY COUNT(exclusions) DESC) AS 'rk' FROM customer_orders_split  
GROUP BY 1)
SELECT topping_name FROM pizza_toppings
WHERE topping_id = (SELECT exclusions FROM cte WHERE rk= 1);
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/f68b770a-cb60-4929-9185-936b9023b304)

#### 4. Generate an order item for each record in the customers_orders table in the format of one of the following: Meat Lovers, Meat Lovers - Exclude Beef, Meat Lovers - Extra Bacon, Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
```sql
WITH cte AS (
SELECT c.rn,c.order_id,c.customer_id,c.pizza_id,pn.pizza_name,GROUP_CONCAT(DISTINCT c.exclusions),
GROUP_CONCAT(DISTINCT ecpt.topping_name) AS 'excluded',
GROUP_CONCAT(DISTINCT c.extras),GROUP_CONCAT(DISTINCT expt.topping_name) AS 'extraname'
FROM customer_orders_split c 
JOIN pizza_recipes_new pr ON c.pizza_id=pr.pizza_id 
JOIN pizza_toppings pt ON pr.toppings=pt.topping_id 
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id
LEFT JOIN pizza_toppings ecpt ON c.exclusions=ecpt.topping_id
LEFT JOIN pizza_toppings expt ON c.extras=expt.topping_id
GROUP BY 1,2,3,4,5)
,cte1 AS(
SELECT n.order_id,n.customer_id,n.pizza_id,n.exclusions,excluded,n.extras,extraname,pizza_name
FROM customer_orders_new n LEFT JOIN  cte ON n.rn=cte.rn)

SELECT  order_id,customer_id,pizza_id,exclusions,extras,
CASE WHEN exclusions IS NULL AND extras IS NULL THEN pizza_name
WHEN exclusions IS NOT NULL AND extras is NOT NULL THEN CONCAT(pizza_name,' exclude ',excluded,' with extra ',extraname)
WHEN exclusions IS NOT NULL AND extras IS NULL THEN CONCAT (pizza_name,' exclude ', excluded )
WHEN exclusions IS NULL AND extras IS NOT NULL THEN CONCAT (pizza_name,' with extra ', extraname )
ELSE NULL END AS 'order_item' FROM cte1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/ba21881b-f8e2-4284-900f-5a2cab1eeab7)

#### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
```sql
DROP TABLE IF EXISTS initial_ingredients;
CREATE TEMPORARY TABLE initial_ingredients AS
(SELECT c.rn ,c.order_id,c.customer_id,c.pizza_id,pn.pizza_name,pr.toppings,c.order_time,pt.topping_name
FROM customer_orders_split c 
JOIN pizza_recipes_new pr ON c.pizza_id=pr.pizza_id 
JOIN pizza_toppings pt ON pr.toppings=pt.topping_id 
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id);

DROP TABLE IF EXISTS excluded_ingredients;
CREATE TEMPORARY TABLE excluded_ingredients AS(
SELECT DISTINCT c.rn ,c.order_id,c.customer_id,c.pizza_id,pn.pizza_name,c.exclusions AS 'toppings',c.order_time,ecpt.topping_name
FROM customer_orders_split c 
JOIN pizza_recipes_new pr ON c.pizza_id=pr.pizza_id 
JOIN pizza_toppings pt ON pr.toppings=pt.topping_id 
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id
LEFT JOIN pizza_toppings ecpt ON c.exclusions=ecpt.topping_id
WHERE c.exclusions IS NOT NULL);

DROP TABLE IF EXISTS extra_ingredients;
CREATE TEMPORARY TABLE extra_ingredients
(SELECT DISTINCT c.rn ,c.order_id,c.customer_id,c.pizza_id,pn.pizza_name,c.extras AS 'toppings',c.order_time,expt.topping_name
FROM customer_orders_split c 
JOIN pizza_recipes_new pr ON c.pizza_id=pr.pizza_id 
JOIN pizza_toppings pt ON pr.toppings=pt.topping_id 
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id 
LEFT JOIN pizza_toppings expt ON c.extras=expt.topping_id
WHERE c.extras IS NOT NULL);

WITH cte AS
(SELECT * FROM initial_ingredients
EXCEPT
SELECT * FROM excluded_ingredients
UNION ALL
SELECT * FROM extra_ingredients)
,
cte1 AS (SELECT *,COUNT(topping_name) OVER (PARTITION BY rn,order_id,customer_id,pizza_id,order_time,topping_name) AS 'cnt',
CONCAT(COUNT(topping_name) OVER (PARTITION BY rn,order_id,customer_id,pizza_id,order_time,topping_name),'x',topping_name) AS 'qty' 
FROM cte ORDER BY 1,cnt DESC ,topping_name)

SELECT rn,order_id,customer_id,pizza_id,order_time,
CONCAT(pizza_name,': ',GROUP_CONCAT(DISTINCT qty ORDER BY cnt DESC,topping_name SEPARATOR ',' ) )AS 'ingredients' 
FROM cte1 GROUP BY rn,order_id,customer_id,pizza_id,pizza_name,order_time;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/05fd9a86-c3a6-44fb-9612-15b3cc4c98de)

#### 6 . What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```sql
WITH cte AS
(SELECT * FROM initial_ingredients 
EXCEPT
SELECT * FROM excluded_ingredients
UNION ALL
SELECT * FROM extra_ingredients)
,cte1 AS (SELECT toppings,topping_name,COUNT(toppings) AS 'count',cancellation FROM cte JOIN runner_orders_new r ON cte.order_id=r.order_id 
GROUP BY 1,2,4 HAVING cancellation IS NULL
ORDER BY 3 DESC)
SELECT topping_name,count FROM cte1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/9886a5cb-2852-468d-b7d4-860a2fe27cd5)

