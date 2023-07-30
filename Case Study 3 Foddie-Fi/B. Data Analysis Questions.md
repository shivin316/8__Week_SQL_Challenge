#### 1. How many customers has Foodie-Fi ever had?
```sql
SELECT COUNT(DISTINCT customer_id) AS 'total_customers'
FROM details;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/4b149f4e-1b65-447a-99ac-70e65e13c6b7)


#### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```sql
SELECT MONTH(start_date) AS 'month',MONTHNAME(start_date) AS 'month_name',COUNT(DISTINCT customer_id) AS 'monthly_distribution'
FROM details
WHERE plan_id=0 GROUP BY 1,2 ORDER BY 1,2 ;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/7fe7dfc4-c518-4e24-84dc-93eead246322)

#### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```sql
SELECT p.plan_name,after_2020 FROM 
(SELECT plan_name,COUNT(DISTINCT customer_id) AS 'after_2020' FROM details
WHERE YEAR(start_date)>'2020' GROUP BY 1)c 
RIGHT JOIN plans p ON c.plan_name=p.plan_name;
 ```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/81237777-701f-4db8-a151-6c6df7ad559b)


#### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
SELECT COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn')  THEN customer_id ELSE NULL END) AS 'churn_count',
ROUND((COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn')  THEN customer_id ELSE NULL END)/COUNT(DISTINCT customer_id))*100,1) AS 'churn_pct'
FROM details;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/41046bfb-f222-4a4a-9f85-ad7d01455e6a)


#### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```sql
WITH cte AS (
SELECT * , DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date) AS 'rk' 
FROM details)

SELECT COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn') AND rk=2 THEN customer_id ELSE NULL END) AS 'churn_after_trial_count',
ROUND((COUNT(DISTINCT CASE WHEN plan_name=LOWER('churn') AND rk=2 THEN customer_id ELSE NULL END)/COUNT(DISTINCT customer_id))*100) AS 'churn_after_trial_pct'
FROM cte;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/604d93c8-dd3d-43ee-93ba-cb87046082ee)


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
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/21c17309-0c26-49b7-9919-fe8e05d2f975)


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
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/2546b0e2-6d43-43ce-ade0-94e0ec7dea22)


#### 8. How many customers have upgraded to an annual plan in 2020?
```sql
WITH cte AS (
SELECT * ,DENSE_RANK()OVER(PARTITION BY  customer_id ORDER BY start_date DESC) AS 'rk' 
FROM details WHERE YEAR(start_date)='2020')

SELECT COUNT(DISTINCT customer_id) AS 'annual_plan_count_2020' FROM cte 
WHERE plan_name LIKE '%annual%' AND rk=1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/a36cc7c5-eee8-4935-a377-a634f21dd829)



#### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
WITH cte AS (
SELECT * , DATEDIFF(LEAD(start_date)OVER(PARTITION BY customer_id ORDER BY start_date),start_date) AS 'days'
FROM details
WHERE plan_id = 0 OR plan_id=3)
SELECT ROUND(AVG(days),1) AS 'average_days_to_annual_plan' FROM cte WHERE days IS NOT NULL;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/8553acdc-64db-4070-91aa-e0cfdbfafbfc)


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
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/58b49afa-e7f6-4b2e-8bf3-fd7f32664240)


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
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/a0263529-0e52-4704-9ddc-eb5da4e19d36)

