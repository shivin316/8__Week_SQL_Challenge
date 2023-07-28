use dinner;

  
  
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- SOLUTION -
SELECT customer_id,SUM(price) AS 'total_amount'
FROM sales s INNER JOIN  menu m ON s.product_id=m.product_id 
GROUP BY 1;


-- 2. How many days has each customer visited the restaurant?
-- SOLUTION -
SELECT customer_id,COUNT(DISTINCT order_date) AS 'days_visited' FROM sales GROUP BY 1;


-- 3. What was the first item from the menu purchased by each customer?
-- SOLUTION - 
SELECT customer_id,GROUP_CONCAT( DISTINCT product_name) AS 'first item(s)' FROM
(SELECT s.customer_id,m.product_id,m.product_name,DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as 'rk'
FROM sales s INNER JOIN menu m ON s.product_id=m.product_id )x
WHERE rk=1
GROUP BY 1 ;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- SOLUTION -
SELECT product_id,product_name,number_of_orders FROM 
( SELECT m.product_id,m.product_name,COUNT(s.customer_id)  AS 'number_of_orders',
DENSE_RANK() OVER (ORDER BY COUNT(s.customer_id) DESC) AS 'rk'
FROM sales s INNER JOIN  menu m ON s.product_id=m.product_id 
GROUP BY 1,2 )x 
WHERE rk=1;


-- 5. Which item was the most popular for each customer?
-- SOLUTION - 
SELECT customer_id,GROUP_CONCAT(product_name) as 'most_popular_item(s)',number_of_orders FROM
(SELECT s.customer_id,m.product_id,m.product_name,COUNT(m.product_id) AS 'number_of_orders',
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(m.product_id) DESC) AS 'rk'
from sales s INNER JOIN  menu m ON s.product_id=m.product_id 
GROUP BY 1,2,3)x
WHERE rk=1
GROUP BY 1,3;


-- 6. Which item was purchased first by the customer after they became a member?
-- SOLUTION--
SELECT customer_id,GROUP_CONCAT(product_name) AS 'first_after_joining' FROM
(SELECT s.customer_id,m.product_id,m.product_name,s.order_date,ms.join_date,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS 'rk'
FROM members ms INNER JOIN sales s ON ms.customer_id =s.customer_id AND ms.join_date<s.order_date 
INNER JOIN menu m on s.product_id=m.product_id)x
WHERE rk=1
GROUP BY 1;


-- 7. Which item was purchased just before the customer became a member?
-- SOLUTION 
SELECT customer_id,GROUP_CONCAT(product_name) AS 'just_before_joining' FROM
(SELECT s.customer_id,m.product_id,m.product_name,s.order_date,ms.join_date,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS 'rk'
FROM members ms INNER JOIN sales s ON ms.customer_id =s.customer_id AND ms.join_date>s.order_date 
INNER JOIN menu m on s.product_id=m.product_id)x
WHERE rk=1
GROUP BY 1;


-- 8. What is the total items and amount spent for each member before they became a member?
-- SOLUTION -
SELECT s.customer_id,COUNT(m.product_id) AS 'total_items',SUM(m.price) AS 'total_amount'
FROM members ms INNER JOIN sales s ON ms.customer_id =s.customer_id AND ms.join_date>s.order_date
INNER JOIN menu m on s.product_id=m.product_id
GROUP BY 1 ORDER BY 1;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- SOLUTION - 
WITH cte as 
(SELECT s.customer_id,m.product_id,m.product_name,SUM(m.price) as 'spent'
FROM sales s INNER JOIN  menu m ON s.product_id=m.product_id 
GROUP BY 1,2,3)

SELECT customer_id,
SUM(CASE WHEN product_name='sushi' THEN spent*20
ELSE spent*10 END) AS 'points'
FROM cte
GROUP BY 1;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- SOLUTION -
WITH cte as (SELECT s.customer_id,m.product_id,m.product_name,m.price,s.order_date,ms.join_date,
CASE WHEN DATEDIFF(s.order_date,ms.join_date)<7 AND s.order_date>=ms.join_date THEN 'first_week' ELSE 'not_first_week' END as 'what_week'
FROM members ms INNER JOIN sales s ON ms.customer_id=s.customer_id
INNER JOIN  menu m ON s.product_id=m.product_id
WHERE MONTH(order_date)=1 ORDER BY 1)
,
cte1 as (SELECT customer_id, product_id,product_name,what_week,SUM(price) AS 'spent' FROM cte GROUP BY 1,2,3,4 ORDER BY 1)

SELECT customer_id,
SUM(CASE WHEN what_week='first_week' THEN spent*20 
WHEN what_week<>'first_week' AND product_name='sushi' THEN spent*20
ELSE spent*10 END) AS 'points'
FROM cte1 GROUP BY 1 ORDER BY 1;


-- BONUS QUESTION 1. Join All The Things
-- SOLUTION - 
SELECT s.customer_id,s.order_date,m.product_name,m.price,
CASE WHEN s.order_date>=ms.join_date THEN 'Y' ELSE 'N' END as 'member'
FROM members ms RIGHT JOIN sales s ON ms.customer_id=s.customer_id
INNER JOIN  menu m ON s.product_id=m.product_id
ORDER BY 1,2,3;


-- BONUS QUESTION 2. Danny also requires further information about the ranking of customer products, but he purposely does not need 
-- the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the 
-- loyalty program
-- SOLUTION -
WITH cte as (
SELECT s.customer_id,s.order_date,m.product_name,m.price,
CASE WHEN s.order_date>=ms.join_date THEN 'Y' ELSE 'N' END as 'member',
ROW_NUMBER() OVER (ORDER BY s.customer_id,s.order_date,m.product_name) AS 'rn'
FROM members ms RIGHT JOIN sales s ON ms.customer_id=s.customer_id
INNER JOIN  menu m ON s.product_id=m.product_id
)
,
cte1 as (SELECT *,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS 'ranking'
FROM cte WHERE member='Y')

SELECT cte.customer_id,cte.order_date,cte.product_name,cte.price,cte.member,cte1.ranking 
FROM cte LEFT JOIN cte1 on cte.customer_id=cte1.customer_id AND cte.rn=cte1.rn;
