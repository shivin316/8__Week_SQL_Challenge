USE pizza;

DROP TABLE IF EXISTS pizza_recipes_new;
CREATE TEMPORARY TABLE pizza_recipes_new AS
WITH RECURSIVE
  unwound AS (
    SELECT *
      FROM pizza_recipes
    UNION ALL
    SELECT pizza_id, regexp_replace(toppings, '^[^,]*,', '') toppings
      FROM unwound
      WHERE toppings LIKE '%,%'
  )
  SELECT pizza_id, regexp_replace(toppings, ',.*', '') toppings
    FROM unwound
    ORDER BY 1
;
  
DROP TABLE IF EXISTS runner_orders_new ;
CREATE TEMPORARY TABLE runner_orders_new AS
(SELECT 
  order_id, 
  runner_id,  
  CASE
	  WHEN pickup_time LIKE 'null' THEN NULL
	  ELSE CAST(pickup_time AS DATETIME)
	  END AS pickup_time,
  CASE
	  WHEN distance LIKE 'null' THEN NULL
	  WHEN distance LIKE '%km' THEN CAST(TRIM('km' from distance) AS FLOAT)
	  ELSE CAST(distance AS FLOAT)
    END AS distance,
  CASE
	  WHEN duration LIKE 'null' or '' THEN NULL
	  WHEN duration LIKE '%mins' THEN CAST(TRIM('mins' from duration) AS UNSIGNED)
	  WHEN duration LIKE '%minute' THEN CAST(TRIM('minute' from duration) AS UNSIGNED)
	  WHEN duration LIKE '%minutes' THEN CAST(TRIM('minutes' from duration) AS UNSIGNED)
	  ELSE CAST(duration AS UNSIGNED)
	  END AS duration,
  CASE
	  WHEN cancellation LIKE '' or cancellation LIKE 'null' THEN NULL
	  ELSE cancellation
	  END AS cancellation
FROM runner_orders);

DROP TABLE IF EXISTS customer_orders_new ;
CREATE TEMPORARY TABLE customer_orders_new AS
(SELECT ROW_NUMBER() OVER(ORDER BY order_id) AS 'rn',
  order_id, 
  customer_id, 
  pizza_id, 
  CASE
	  WHEN exclusions IS null OR exclusions LIKE 'null' OR exclusions LIKE '' THEN NULL
	  ELSE exclusions
	  END AS exclusions,
  CASE
	  WHEN extras IS NULL or extras LIKE 'null' or extras Like '' THEN NULL
	  ELSE extras
	  END AS extras,
	order_time
FROM customer_orders);


DROP TABLE IF EXISTS customer_orders_split;
CREATE TEMPORARY TABLE customer_orders_split AS 
WITH RECURSIVE
  unwound AS (
    SELECT *
      FROM customer_orders_new
    UNION ALL
    SELECT rn,order_id,customer_id,pizza_id, regexp_replace(exclusions, '^[^,]*,', '') exclusions,regexp_replace(extras, '^[^,]*,', '') extras, order_time
      FROM unwound
      WHERE exclusions LIKE '%,%' or extras LIKE '%,%'
  )
  SELECT rn,order_id,customer_id,pizza_id, regexp_replace(exclusions, ',.*', '') exclusions,regexp_replace(extras, ',.*', '') extras,order_time
    FROM unwound
    ORDER BY 1;
    

--                                                         A. PIZZA METRICS 
-- Q1. How many pizzas were ordered?
-- SOLUTION -
SELECT COUNT(pizza_id) AS 'Number_of_pizza_ordered' FROM customer_orders_new;


-- Q2. How many unique customer orders were made?
-- SOLUTION -
SELECT COUNT(DISTINCT order_id) AS 'unique_orders' FROM customer_orders_new;


-- Q3. How many successful orders were delivered by each runner?
-- SOLUTION -
SELECT r.runner_id,COUNT( DISTINCT c.order_id) AS 'succesfully_delivered' FROM customer_orders_new c INNER JOIN
runner_orders_new r ON c.order_id=r.order_id 
WHERE r.cancellation IS NULL
GROUP BY 1
ORDER BY 1;


-- Q4. How many of each type of pizza was delivered?
-- SOLUTION -
SELECT c.pizza_id,n.pizza_name,count(c.order_id) AS 'succesfully_delivered' FROM customer_orders_new c INNER JOIN
runner_orders_new r on c.order_id=r.order_id 
INNER JOIN pizza_names n ON n.pizza_id=c.pizza_id
WHERE r.cancellation IS NULL
GROUP BY 1,2
ORDER BY 1,2;


-- Q5. How many Vegetarian and Meatlovers were ordered by each customer?
-- SOLUTION -
SELECT c.customer_id,n.pizza_name,COUNT(*) AS 'Count' 
FROM customer_orders_new c INNER JOIN pizza_names n ON c.pizza_id=n.pizza_id
GROUP BY 1,2
ORDER BY 1,2;


-- Q6. What was the maximum number of pizzas delivered in a single order?
-- SOLUTION -
WITH cte as (SELECT c.customer_id,n.pizza_name,COUNT(*) AS 'Count' ,DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS 'rk'
FROM customer_orders_new c INNER JOIN pizza_names n ON c.pizza_id=n.pizza_id
GROUP BY 1,2)
SELECT DISTINCT pizza_name,Count FROM cte WHERE rk=1;


-- Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- SOLUTION -
SELECT c.customer_id,
COUNT(CASE WHEN exclusions IS NULL AND extras IS NULL THEN c.order_id ELSE NULL END ) AS 'no_change',
COUNT(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL  THEN c.order_id ELSE NULL END ) AS 'atleast_1_change'
FROM customer_orders_new c INNER JOIN
runner_orders_new r on c.order_id=r.order_id 
WHERE r.cancellation IS NULL 
GROUP BY 1;


-- Q8. How many pizzas were delivered that had both exclusions and extras?
-- SOLUTION-
SELECT COUNT(c.pizza_id) AS 'number_of_pizzas_with_both_exclusions_and_extras'
FROM customer_orders_new c INNER JOIN
runner_orders_new r on c.order_id=r.order_id 
WHERE r.cancellation IS NULL AND c.exclusions IS NOT NULL AND c.extras IS NOT NULL;


-- Q9. What was the total volume of pizzas ordered for each hour of the day?
-- SOLUTION -
SELECT HOUR(order_time) AS 'hour_of_day',COUNT(order_id) AS 'pizza_ordered'
FROM customer_orders_new
GROUP BY 1
ORDER BY 1;


-- Q10. What was the volume of orders for each day of the week?
-- SOLUTION -
SELECT DATE_FORMAT(order_time,'%W') AS 'day',COUNT(order_id) AS 'pizza_ordered'
FROM customer_orders_new
GROUP BY 1
ORDER BY 1;

--                                                 B.  Runner and Customer Experience 

-- Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- SOLUTION -
WITH cte AS(
SELECT *,IF(DATEDIFF(registration_date,'2021-01-01')=0,1,CEIL(DATEDIFF(registration_date,'2021-01-01')/6)) AS 'wk' FROM runners)
,
cte1 AS (SELECT *, FIRST_VALUE(registration_date) OVER (PARTITION BY wk ORDER BY registration_date) AS 'start_week' FROM cte)
SELECT start_week,COUNT(DISTINCT runner_id) AS 'runners_signup'
FROM cte1
GROUP BY 1 
ORDER BY 1;


-- Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- SOLUTION  - 
SELECT r.runner_id,ROUND(AVG(TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time))) AS 'average_time(minutes)'
FROM runner_orders_new r JOIN customer_orders_new c ON r.order_id=c.order_id
GROUP BY 1 
ORDER BY 1;


-- Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT y AS 'number_of_pizzas', ROUND(AVG(t)) AS 'average_prep_time' FROM
(SELECT r.order_id,COUNT(c.order_id) AS y,TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time) AS 't'
FROM runner_orders_new r JOIN customer_orders_new c ON r.order_id=c.order_id
GROUP BY 1,3 ORDER BY 1)x
GROUP BY 1;


-- Q4. What was the average distance travelled for each customer?
-- SOLUTION -
SELECT c.customer_id,ROUND(AVG(r.distance),1) AS 'average_distance(km)'
FROM runner_orders_new r JOIN customer_orders_new c ON r.order_id=c.order_id
GROUP BY 1;


-- Q5. What was the difference between the longest and shortest delivery times for all orders?
-- SOLUTION - 
SELECT MAX(duration)-MIN(duration) AS 'difference(minutes)' FROM runner_orders_new;


-- Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- SOLUTION - 
SELECT r.runner_id,c.customer_id,r.order_id,COUNT(c.order_id) AS'pizza_delivered',r.distance,r.duration, 
ROUND((r.distance/r.duration)*60,2) AS 'average_speed'
FROM runner_orders_new r JOIN customer_orders_new c ON r.order_id=c.order_id 
WHERE r.cancellation IS NULL
GROUP BY 1,2,3,5,6 
ORDER BY 1;


-- Q7. What is the successful delivery percentage for each runner?
-- SOLUTION -
SELECT runner_id,
ROUND((COUNT(CASE WHEN cancellation IS NULL THEN order_id ELSE NULL END)/COUNT(order_id))*100,2) AS 'success_pct'
FROM runner_orders_new 
GROUP BY 1;


--                                                    C. Ingredient Optimisation 

-- Q1. What are the standard ingredients for each pizza?
-- SOLUTION
SELECT DISTINCT c.pizza_id,pn.pizza_name,topping_name 
FROM customer_orders_new c 
JOIN pizza_recipes_new pr ON c.pizza_id=pr.pizza_id 
JOIN pizza_toppings pt ON pr.toppings=pt.topping_id
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id
ORDER BY 1;

-- Q2. What was the most commonly added extra?
-- SOLUTION -
WITH cte AS
(SELECT extras,DENSE_RANK()OVER(ORDER BY COUNT(extras) DESC) AS 'rk' FROM customer_orders_split  
GROUP BY 1 HAVING extras IS NOT NULL)
SELECT topping_name FROM pizza_toppings
WHERE topping_id = (SELECT extras FROM cte WHERE rk= 1);


--Q3. What was the most common exclusion?
-- SOLUTION -
WITH cte AS
(SELECT exclusions,DENSE_RANK()OVER(ORDER BY COUNT(exclusions) DESC) AS 'rk' FROM customer_orders_split  
GROUP BY 1)
SELECT topping_name FROM pizza_toppings
WHERE topping_id = (SELECT exclusions FROM cte WHERE rk= 1);


-- Q4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

-- SOLUTION -
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


-- Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table 
-- and add a 2x in front of any relevant ingredients
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


-- Q6 . What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
-- SOLUTION -
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

--                                                                 D. Pricing and Ratings
-- Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
--     how much money has Pizza Runner made so far if there are no delivery fees?
-- SOLUTION -
SELECT (COUNT(CASE WHEN pn.pizza_name='Meatlovers' THEN c.order_id ELSE NULL END)*12 + 
COUNT(CASE WHEN pn.pizza_name='Vegetarian' THEN c.order_id ELSE NULL END)*10) AS 'total_earning'
FROM customer_orders_new c 
JOIN pizza_names pn ON c.pizza_id=pn.pizza_id
JOIN runner_orders_new r ON c.order_id=r.order_id
WHERE cancellation IS NULL;


-- Q2. What if there was an additional $1 charge for any pizza extras?
-- SOLUTION -
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


-- Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
-- how would you design an additional table for this new dataset
-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- SOLUTION 
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


-- Q4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id ,order_id,runner_id,rating,order_time,pickup_time,Time between order and pickup,Delivery duration,Average speed,Total number of pizzas
-- SOLUTION 

SELECT DISTINCT c.customer_id,c.order_id,rg.rating,r.runner_id,c.order_time,r.pickup_time,TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time) AS 'Time between order and pickup',
r.duration,ROUND((r.distance/r.duration)*60,1) AS 'avg_speed',COUNT(c.pizza_id) OVER(PARTITION BY c.order_id) AS 'number_of_pizzas'
FROM customer_orders_new c
JOIN runner_orders_new r ON c.order_id=r.order_id
JOIN ratings rg ON c.order_id=rg.order_id 
WHERE r.cancellation IS NULL;


-- Q5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and 
-- each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
-- SOLUTION - 
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

--                                                            BONUS QUESTION
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

INSERT INTO pizza_names VALUES(3, 'Supreme');
SELECT * FROM pizza_names;

INSERT INTO pizza_recipes
VALUES(3, (SELECT GROUP_CONCAT(topping_id SEPARATOR ', ') FROM pizza_toppings));
SELECT * FROM pizza_recipes;
