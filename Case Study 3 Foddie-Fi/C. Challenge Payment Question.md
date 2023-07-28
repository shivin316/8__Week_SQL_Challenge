#### The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments

##### Procedure - creating multiple temporary table first and then using recusrive cte to implement the output
```sql
DROP TABLE IF EXISTS subs_plans;
CREATE TEMPORARY TABLE subs_plans AS (
SELECT s.customer_id,s.plan_id,p.plan_name,p.price,s.start_date
FROM subscriptions AS s
JOIN PLANS AS p ON p.plan_id = s.plan_id
);
```
**NOT ALL ROWS ARE DISPLAYED**

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/8caa889b-5ed8-4345-ba5c-98a4e0e3a60a)


```sql
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
```
**NOT ALL ROWS ARE DISPLAYED**

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/3cd6fb0a-8008-4879-8f99-267752f0e61f)


```sql      
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
```
**NOT ALL ROWS ARE DISPLAYED**

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/f1498965-dcbc-4e7b-b6a8-84c775f4401f)


```sql
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
```
**NOT ALL ROWS ARE DISPLAYED**

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/90bd3cff-31b6-4e80-8a2a-aded41473a99)

