USE foodie_fi;
  
DROP TABLE IF EXISTS details;
CREATE TEMPORARY TABLE details AS
SELECT s.customer_id,s.plan_id,p.plan_name,p.price,s.start_date
FROM subscriptions s
LEFT JOIN plans p on p.plan_id = s.plan_id;
  
  --                                                           A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
-- SOLUTION -
SELECT * FROM details
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19);

-- Client #1: upgraded to the basic monthly subscription within their 7 day trial period.
-- Client #2: upgraded to the pro annual subscription within their 7 day trial period.
-- Client #11: cancelled their subscription within their 7 day trial period.
-- Client #13: upgraded to the basic monthly subscription within their 7 day trial period and upgraded to pro annual 3 months later.
-- Client #15: upgraded to the pro annual subscription within their 7 day trial period and cancelled the following month.
-- Client #16: upgraded to the basic monthly subscription after their 7 day trial period and upgraded to pro annual almost 5 months later.
-- Client #18: upgraded to the pro monthly subscription within their 7 day trial period.
-- Client #19: upgraded to the pro monthly subscription within their 7 day trial period and upgraded to pro annual 2 months later.




--                                                B. Data Analysis Questions
-- Q1. How many customers has Foodie-Fi ever had?
-- SOLUTION -
SELECT COUNT(DISTINCT customer_id) AS 'total_customers' FROM details;


-- Q2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
-- SOLUTION - 
SELECT MONTH(start_date) AS 'month',MONTHNAME(start_date) AS 'month_name',COUNT(DISTINCT customer_id) AS 'monthly_distribution' FROM details
WHERE plan_id=0 GROUP BY 1,2 ORDER BY 1,2 ;


-- Q3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
-- SOLUTION -
SELECT p.plan_name,after_2020 FROM 
(SELECT plan_name,COUNT(DISTINCT customer_id) AS 'after_2020' FROM details
WHERE YEAR(start_date)>'2020' GROUP BY 1)c 
RIGHT JOIN plans p ON c.plan_name=p.plan_name;
 
 
-- Q4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
-- SOLUTION -
SELECT COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn')  THEN customer_id ELSE NULL END) AS 'churn_count',
ROUND((COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn')  THEN customer_id ELSE NULL END)/COUNT(DISTINCT customer_id))*100,1) AS 'churn_pct'
FROM details;


-- Q5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte AS (
SELECT * , DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date) AS 'rk' 
FROM details)

SELECT COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn') AND rk=2 THEN customer_id ELSE NULL END) AS 'churn_after_trial_count',
ROUND((COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn') AND rk=2 THEN customer_id ELSE NULL END)/COUNT(DISTINCT customer_id))*100) AS 'churn_after_trial_pct'
FROM cte;


-- Q6. What is the number and percentage of customer plans after their initial free trial?
-- SOLUTION-
WITH cte AS (
SELECT * ,DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date) AS 'rk' 
FROM details)

SELECT plan_name,COUNT(DISTINCT CASE WHEN plan_name<>LOWER('trial') AND rk =2 THEN customer_id ELSE NULL END) AS 'after_trial_count',
ROUND((COUNT(DISTINCT CASE WHEN plan_name<>LOWER('trial') AND rk =2 THEN customer_id ELSE NULL END))/
(SELECT COUNT(DISTINCT customer_id) AS 'total_customers' FROM subscriptions)*100,1) AS 'after_trial_pct'
FROM cte 
WHERE plan_name<>'trial'
GROUP BY 1;


-- Q7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- SOLUTION -
WITH cte AS (
SELECT * ,LEAD(start_date)OVER(PARTITION BY  customer_id ORDER BY start_date) AS 'latest_plan' 
FROM details
WHERE start_date<='2020-12-31')

SELECT plan_id,plan_name,COUNT(DISTINCT customer_id) AS 'count',
ROUND((COUNT(DISTINCT customer_id))/
(SELECT COUNT(DISTINCT customer_id) AS 'total_customers' FROM subscriptions)*100,1) AS 'pct'
FROM cte 
WHERE latest_plan IS NULL
GROUP BY 1,2
ORDER BY 1;


-- Q8. How many customers have upgraded to an annual plan in 2020?
-- SOLUTION - 
WITH cte AS (
SELECT * ,DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date DESC) AS 'rk' 
FROM details WHERE YEAR(start_date)='2020')

SELECT COUNT(DISTINCT customer_id) AS 'annual_plan_count_2020' FROM cte 
WHERE plan_name LIKE '%annual%' AND rk=1;


-- Q9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- SOLUTION - 
WITH cte AS (
SELECT * , DATEDIFF(LEAD(start_date)OVER(PARTITION BY customer_id ORDER BY start_date),start_date) AS 'days'
FROM details
WHERE plan_id = 0 OR plan_id=3)
SELECT ROUND(AVG(days),1) AS 'average_days_to_annual_plan' FROM cte WHERE days IS NOT NULL;


-- Q10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- SOLUTION -
WITH cte AS (
SELECT *,DATEDIFF(LEAD(start_date)OVER(PARTITION BY customer_id ORDER BY start_date),start_date) AS 'days'
FROM details
WHERE plan_id = 0 OR plan_id=3)
,cte1 AS (SELECT *,FLOOR(days/30) AS 'period' , FLOOR(days/30)*30 AS 'd' FROM cte where days IS NOT NULL)

SELECT CONCAT((period *30) + 1, ' - ', (period + 1) * 30, ' days ') AS 'days_range', COUNT(days) AS 'total'
FROM cte1
GROUP BY d,1
ORDER BY d;


-- Q11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
-- SOLUTION -
WITH cte AS 
(SELECT * ,DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date DESC) AS 'rk' , 
COUNT(plan_id) OVER (PARTITION BY customer_id) AS cnt
FROM details 
WHERE YEAR(start_date)='2020' 
AND plan_id = 2 OR plan_id=1)

SELECT COUNT(DISTINCT customer_id) AS 'downgraded_from_pro_to_basic_monthly_2020'
FROM cte 
WHERE plan_id=1 AND rk=1 AND cnt=2;


--                                                      C. Challenge Payment Question
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions 
-- table with the following requirements:
-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments

-- SOLUTION - 
DROP TABLE IF EXISTS subs_plans;
CREATE TEMPORARY TABLE subs_plans AS (
SELECT s.customer_id,s.plan_id,p.plan_name,p.price,s.start_date
FROM subscriptions AS s
JOIN PLANS AS p ON p.plan_id = s.plan_id
);


DROP TABLE IF EXISTS cust_pay;
CREATE TEMPORARY TABLE cust_pay AS
(SELECT customer_id,plan_id,plan_name,start_date,
CASE
WHEN plan_id = 1 THEN 9.90
WHEN plan_id = 2 THEN 19.90
WHEN plan_id = 3 THEN 199.00
ELSE 0 END AS amount,
lead(plan_name) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
FROM subs_plans
WHERE plan_id <> 0
AND start_date BETWEEN '2020-01-01' AND '2020-12-31');
	
        
DROP TABLE IF EXISTS one_more;
CREATE TEMPORARY TABLE one_more AS            
(SELECT customer_id,plan_id,plan_name,amount,start_date,
CASE
WHEN next_plan IS NULL AND plan_id != 3 THEN '2020-12-31'
WHEN plan_id = 2 AND next_plan = 'pro annual' THEN (DATE_SUB(LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) ,INTERVAL 1 MONTH))
WHEN next_plan = 'churn' OR next_plan = 'pro monthly' OR next_plan = 'pro annual' 
THEN LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date)
WHEN plan_id = 3 THEN start_date END AS end_date,
next_plan
FROM cust_pay);


WITH RECURSIVE cte AS (
SELECT customer_id,plan_id,plan_name,start_date AS payment_date,end_date,amount,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS rn1,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date desc) AS rn2 
FROM one_more  WHERE customer_id IN (1, 2, 13, 15, 16, 18, 19) 
UNION ALL 
SELECT customer_id,	plan_id,plan_name, DATE_ADD(payment_date, INTERVAL 1 MONTH) AS 'payment_date', end_date,
amount,rn1,rn2 FROM cte WHERE  plan_id<>4 AND end_date>payment_date )

SELECT customer_id,plan_id,plan_name,payment_date,
CASE
WHEN rn1 > rn2 AND LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY payment_date) < plan_id 
AND EXTRACT(MONTH FROM lag(payment_date) OVER (PARTITION BY customer_id ORDER BY payment_date)) = extract(MONTH FROM payment_date) 
THEN amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY payment_date)
ELSE amount END AS amount,
ROW_NUMBER() OVER (PARTITION BY customer_id) AS payment_ord
FROM cte 
WHERE  YEAR(payment_date)=2020 AND DATEDIFF(end_date,payment_date)>=0 AND plan_id<>4
ORDER BY customer_id;
