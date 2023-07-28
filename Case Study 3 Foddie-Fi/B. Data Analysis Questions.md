#### 1. How many customers has Foodie-Fi ever had?
```sql
SELECT COUNT(DISTINCT customer_id) AS 'total_customers'
FROM details;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/d5c3b247-1c2d-4803-9bf4-feff5a3ad709)

#### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```sql
SELECT MONTH(start_date) AS 'month',MONTHNAME(start_date) AS 'month_name',COUNT(DISTINCT customer_id) AS 'monthly_distribution'
FROM details
WHERE plan_id=0 GROUP BY 1,2 ORDER BY 1,2 ;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/17ed7771-45a0-4f57-861e-92bc4e3c75f5)

#### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```sql
SELECT p.plan_name,after_2020 FROM 
(SELECT plan_name,COUNT(DISTINCT customer_id) AS 'after_2020' FROM details
WHERE YEAR(start_date)>'2020' GROUP BY 1)c 
RIGHT JOIN plans p ON c.plan_name=p.plan_name;
 ```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/0a965352-31c7-4b78-882e-ac9e88aef371)

#### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
SELECT COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn')  THEN customer_id ELSE NULL END) AS 'churn_count',
ROUND((COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn')  THEN customer_id ELSE NULL END)/COUNT(DISTINCT customer_id))*100,1) AS 'churn_pct'
FROM details;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/27272456-044c-4283-b541-71498b87d671)

#### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```sql
WITH cte AS (
SELECT * , DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date) AS 'rk' 
FROM details)

SELECT COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn') AND rk=2 THEN customer_id ELSE NULL END) AS 'churn_after_trial_count',
ROUND((COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn') AND rk=2 THEN customer_id ELSE NULL END)/COUNT(DISTINCT customer_id))*100) AS 'churn_after_trial_pct'
FROM cte;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/c2c5083e-41b1-48f6-adb7-23844e1607cf)

#### 6. What is the number and percentage of customer plans after their initial free trial?
```sql
WITH cte AS (
SELECT * ,DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date) AS 'rk' 
FROM details)

SELECT plan_name,COUNT(DISTINCT CASE WHEN plan_name<>LOWER('trial') AND rk =2 THEN customer_id ELSE NULL END) AS 'after_trial_count',
ROUND((COUNT(DISTINCT CASE WHEN plan_name<>LOWER('trial') AND rk =2 THEN customer_id ELSE NULL END))/
(SELECT COUNT(DISTINCT customer_id) AS 'total_customers' FROM subscriptions)*100,1) AS 'after_trial_pct'
FROM cte 
WHERE plan_name<>'trial'
GROUP BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/45bd91de-a706-45cb-9e72-2e8172faa9d3)

#### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
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
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/2e18bc69-ce7e-4657-8d67-27fcf8e1cf51)

#### 8. How many customers have upgraded to an annual plan in 2020?
```sql
WITH cte AS (
SELECT * ,DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date DESC) AS 'rk' 
FROM details WHERE YEAR(start_date)='2020')

SELECT COUNT(DISTINCT customer_id) AS 'annual_plan_count_2020' FROM cte 
WHERE plan_name LIKE '%annual%' AND rk=1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/04b00b18-66d1-4a3f-9a3f-250d8b7495e1)

#### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
WITH cte AS (
SELECT * , DATEDIFF(LEAD(start_date)OVER(PARTITION BY customer_id ORDER BY start_date),start_date) AS 'days'
FROM details
WHERE plan_id = 0 OR plan_id=3)
SELECT ROUND(AVG(days),1) AS 'average_days_to_annual_plan' FROM cte WHERE days IS NOT NULL;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/b80fda89-c536-4815-aa2c-f1b010b1f5f9)

#### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```sql
WITH cte AS (
SELECT *,DATEDIFF(LEAD(start_date)OVER(PARTITION BY customer_id ORDER BY start_date),start_date) AS 'days'
FROM details
WHERE plan_id = 0 OR plan_id=3)
,cte1 AS (SELECT *,FLOOR(days/30) AS 'period' , FLOOR(days/30)*30 AS 'd' FROM cte where days IS NOT NULL)

SELECT CONCAT((period *30) + 1, ' - ', (period + 1) * 30, ' days ') AS 'days_range', COUNT(days) AS 'total'
FROM cte1
GROUP BY d,1
ORDER BY d;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/d8ca5ca8-8e24-4762-a5a3-dbc5e1c131c0)

#### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
WITH cte AS 
(SELECT * ,DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date DESC) AS 'rk' , 
COUNT(plan_id) OVER (PARTITION BY customer_id) AS cnt
FROM details 
WHERE YEAR(start_date)='2020' 
AND plan_id = 2 OR plan_id=1)

SELECT COUNT(DISTINCT customer_id) AS 'downgraded_from_pro_to_basic_monthly_2020'
FROM cte 
WHERE plan_id=1 AND rk=1 AND cnt=2;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/a3f65e94-b2e9-4357-be7e-63735b0e6177)
