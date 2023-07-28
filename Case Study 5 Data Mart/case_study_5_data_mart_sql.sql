--  1. Data Cleansing Steps

DROP TABLE IF EXISTS weekly_sales_new;
CREATE TEMP TABLE weekly_sales_new AS (
SELECT 	TO_DATE(week_date, 'dd/mm/yy') AS week_day,	
DATE_PART('month', to_date(week_date, 'dd/mm/yy'))::int AS month_number,
DATE_PART('year', to_date(week_date, 'dd/mm/yy'))::int AS calendar_year,
region,platform,
CASE
WHEN segment IS NOT NULL OR segment <> 'null' THEN segment ELSE 'unknown' END AS segment,
CASE WHEN substring(segment, 2, 1) = '1' THEN 'Young Adults'
WHEN substring(segment, 2, 1) = '2' THEN 'Middle Aged'
WHEN substring(segment, 2, 1) = '3'
OR substring(segment, 2, 1) = '4' THEN 'Retirees' ELSE 'unknown' END AS age_band,
CASE
WHEN substring(segment, 1, 1) = 'C' THEN 'Couples'
WHEN substring(segment, 1, 1) = 'F' THEN 'Families' ELSE 'unknown' END AS demographics,
customer_type,transactions,sales,
ROUND((sales ::NUMERIC/ transactions::NUMERIC), 2) AS average_transactions
FROM weekly_sales
);


--                                  2. Data Exploration

-- Q1. What day of the week is used for each week_date value?
-- SOLUTION -
SELECT 	DISTINCT EXTRACT(DOW FROM week_day)::int AS day_of_week,
	TO_CHAR(week_day, 'Day') AS day_of_week_name
 FROM weekly_sales_new;


-- Q2. What range of week numbers are missing from the dataset?
-- SOLUTION -
SELECT generate_series AS missing_weeks FROM (
SELECT * FROM GENERATE_SERIES(1,52,1) 
EXCEPT
SELECT DISTINCT EXTRACT(WEEK FROM week_day) FROM weekly_sales_new ORDER BY 1)x;


-- Q3. How many total transactions were there for each year in the dataset?
-- SOLUTION -
SELECT calendar_year,
COUNT(transactions) AS number_0f_transactions,SUM(transactions) AS total_transactions_amount
FROM weekly_sales_new GROUP BY 1;


--Q4. What is the total sales for each region for each month?
-- SOLUTION -
SELECT region,calendar_year,month_number,SUM(sales) AS total_sales
FROM weekly_sales_new GROUP BY 1,2,3 ORDER BY 1,2,3;


--Q5. What is the total count of transactions for each platform
-- SOLUTION -
SELECT platform,COUNT(transactions) AS number_of_transactions
FROM weeklY_sales_new GROUP BY 1 ORDER BY 1;


-- Q6. What is the percentage of sales for Retail vs Shopify for each month?
-- SOLUTION -
SELECT calendar_year,month_number,
ROUND((100 * retail_sales / (retail_sales + shopify_sales)::NUMERIC), 2) AS retail_sales_pct,
ROUND((100 * shopify_sales / (retail_sales + shopify_sales)::NUMERIC), 2) AS shopify_sales_pct
FROM(
SELECT calendar_year,month_number,
SUM(CASE WHEN platform='Retail' THEN sales ELSE NULL END)AS retail_sales,
SUM(CASE WHEN platform='Shopify' THEN sales ELSE NULL END) AS shopify_sales
FROM weeklY_sales_new GROUP BY 1,2 ORDER BY 1,2)x;


-- Q7. What is the percentage of sales by demographic for each year in the dataset?
-- SOLUTION -
SELECT calendar_year,
ROUND((100 * couples_sales / (couples_sales + families_sales + unknown_sales)::NUMERIC), 2) AS couples_sales_pct,
ROUND((100 * families_sales / (couples_sales + families_sales + unknown_sales)::NUMERIC), 2) AS families_sales_pct,
ROUND((100 * unknown_sales / (couples_sales + families_sales + unknown_sales)::NUMERIC), 2) AS retail_sales_pct
FROM (
SELECT calendar_year,
SUM(CASE WHEN LOWER(demographics)='couples' THEN sales ELSE NULL END) AS couples_sales,
SUM(CASE WHEN LOWER(demographics)='families' THEN sales ELSE NULL END) AS families_sales,
SUM(CASE WHEN LOWER(demographics)='unknown' THEN sales ELSE NULL END) AS unknown_sales
FROM weekly_sales_new GROUP BY 1 ORDER BY 1)x;


-- Q8.Which age_band and demographic values contribute the most to Retail sales?
-- SOLUTION - 
SELECT age_band,demographics,total_sales
FROM
(SELECT age_band,demographics,SUM(sales) AS total_sales,DENSE_RANK() OVER(ORDER BY SUM(sales) DESC) AS rk
FROM weekly_sales_new
WHERE LOWER(platform)='retail'
GROUP BY 1,2
ORDER BY 3 DESC)x WHERE rk=1;


-- Q9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
-- SOLUTION 
SELECT calendar_year,
ROUND(AVG(CASE platform WHEN 'Retail' THEN average_transactions ELSE NULL END), 2) AS retail_transaction_size_average,
ROUND(AVG(CASE platform WHEN 'Shopify' THEN average_transactions ELSE NULL END), 2) AS shopify_transaction_size_average
FROM weekly_sales_new
GROUP BY 1 ORDER BY 1;
-- NO we cannot . The correct method is given below -
SELECT calendar_year,
ROUND(AVG(CASE platform WHEN 'Retail' THEN transactions ELSE NULL END), 2) AS retail_transaction_size_average,
ROUND(AVG(CASE platform WHEN 'Shopify' THEN transactions ELSE NULL END), 2) AS shopify_transaction_size_average
FROM weekly_sales_new
GROUP BY 1
ORDER BY 1;

--                                   3. Before & After Analysis

-- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
-- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
-- Using this analysis approach - answer the following questions:
-- Q1 What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
-- SOLUTION - 
WITH four_week_before AS (
SELECT '2020-06-15' AS base_week,SUM(sales) AS sales_four_week_before
FROM weekly_sales_new
WHERE
week_day BETWEEN TO_CHAR(('2020-06-15'::DATE - INTERVAL '4 week'), 'YYYY-MM-DD')::DATE AND '2020-06-15'::DATE
),
four_week_after AS (
SELECT '2020-06-15' AS base_week,SUM(sales) AS sales_four_week_after
FROM weekly_sales_new
WHERE
week_day BETWEEN '2020-06-15'::DATE AND TO_CHAR(('2020-06-15'::DATE + INTERVAL '4 week'), 'YYYY-MM-DD')::DATE
)


SELECT b.sales_four_week_before,a.sales_four_week_after,
a.sales_four_week_after-b.sales_four_week_before AS change_in_sales,
ROUND(100*(a.sales_four_week_after-b.sales_four_week_before)/(b.sales_four_week_before ::NUMERIC),2) AS pct_change
FROM four_week_before b JOIN four_week_after a ON b.base_week=a.base_week;



--Q2. What about the entire 12 weeks before and after?
-- SOLUTION - 
WITH twelve_week_before AS (
SELECT '2020-06-15' AS base_week,SUM(sales) AS sales_twelve_week_before
FROM weekly_sales_new
WHERE
week_day BETWEEN TO_CHAR(('2020-06-15'::DATE - INTERVAL '12 week'), 'YYYY-MM-DD')::DATE AND '2020-06-15'::DATE
),
twelve_week_after AS (
SELECT '2020-06-15' AS base_week,SUM(sales) AS sales_twelve_week_after
FROM weekly_sales_new
WHERE
week_day BETWEEN '2020-06-15'::DATE AND TO_CHAR(('2020-06-15'::DATE + INTERVAL '12 week'), 'YYYY-MM-DD')::DATE
)


SELECT b.sales_twelve_week_before,a.sales_twelve_week_after,
a.sales_twelve_week_after-b.sales_twelve_week_before AS change_in_sales,
ROUND(100*(a.sales_twelve_week_after-b.sales_twelve_week_before)/(b.sales_twelve_week_before ::NUMERIC),2) AS pct_change
FROM twelve_week_before b JOIN twelve_week_after a ON b.base_week=a.base_week;


--Q3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
-- SOLUTION 
WITH four_week_before_2020 AS (
SELECT '2020-06-15' AS base_week,SUM(sales) AS sales_four_week_before
FROM weekly_sales_new
WHERE
week_day BETWEEN TO_CHAR(('2020-06-15'::DATE - INTERVAL '4 week'), 'YYYY-MM-DD')::DATE AND '2020-06-15'::DATE
),
four_week_after_2020 AS (
SELECT '2020-06-15' AS base_week,SUM(sales) AS sales_four_week_after
FROM weekly_sales_new
WHERE
week_day BETWEEN '2020-06-15'::DATE AND TO_CHAR(('2020-06-15'::DATE + INTERVAL '4 week'), 'YYYY-MM-DD')::DATE
),
four_week_before_2019 AS (
SELECT '2019-06-15' AS base_week,SUM(sales) AS sales_four_week_before
FROM weekly_sales_new
WHERE
week_day BETWEEN TO_CHAR(('2019-06-15'::DATE - INTERVAL '4 week'), 'YYYY-MM-DD')::DATE AND '2019-06-15'::DATE
),
four_week_after_2019 AS (
SELECT '2019-06-15' AS base_week,SUM(sales) AS sales_four_week_after
FROM weekly_sales_new
WHERE
week_day BETWEEN '2019-06-15'::DATE AND TO_CHAR(('2019-06-15'::DATE + INTERVAL '4 week'), 'YYYY-MM-DD')::DATE
),
four_week_before_2018 AS (
SELECT '2018-06-15' AS base_week,SUM(sales) AS sales_four_week_before
FROM weekly_sales_new
WHERE
week_day BETWEEN TO_CHAR(('2018-06-15'::DATE - INTERVAL '4 week'), 'YYYY-MM-DD')::DATE AND '2018-06-15'::DATE
),
four_week_after_2018 AS (
SELECT '2018-06-15' AS base_week,SUM(sales) AS sales_four_week_after
FROM weekly_sales_new
WHERE
week_day BETWEEN '2018-06-15'::DATE AND TO_CHAR(('2018-06-15'::DATE + INTERVAL '4 week'), 'YYYY-MM-DD')::DATE
)

SELECT 2020 AS Year, b.sales_four_week_before,a.sales_four_week_after,
a.sales_four_week_after-b.sales_four_week_before AS change_in_sales,
ROUND(100*(a.sales_four_week_after-b.sales_four_week_before)/(b.sales_four_week_before ::NUMERIC),2) AS pct_change
FROM four_week_before_2020 b JOIN four_week_after_2020 a ON b.base_week=a.base_week
UNION ALL 
SELECT 2019 AS Year,b.sales_four_week_before,a.sales_four_week_after,
a.sales_four_week_after-b.sales_four_week_before AS change_in_sales,
ROUND(100*(a.sales_four_week_after-b.sales_four_week_before)/(b.sales_four_week_before ::NUMERIC),2) AS pct_change
FROM four_week_before_2019 b JOIN four_week_after_2019 a ON b.base_week=a.base_week
UNION ALL
SELECT 2018 AS Year,b.sales_four_week_before,a.sales_four_week_after,
a.sales_four_week_after-b.sales_four_week_before AS change_in_sales,
ROUND(100*(a.sales_four_week_after-b.sales_four_week_before)/(b.sales_four_week_before ::NUMERIC),2) AS pct_change
FROM four_week_before_2018 b JOIN four_week_after_2018 a ON b.base_week=a.base_week;

-- BONUS QUESTION
-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
-- region
-- platform
-- age_band
-- demographic
-- customer_type
-- Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
-- SOLUTION

WITH twelve_week_before AS (
SELECT '2020-06-15' AS base_week,region,platform,age_band,demographics,customer_type,SUM(sales) AS sales_twelve_week_before
FROM weekly_sales_new
WHERE
week_day BETWEEN TO_CHAR(('2020-06-15'::DATE - INTERVAL '12 week'), 'YYYY-MM-DD')::DATE AND '2020-06-15'::DATE
GROUP BY 1,2,3,4,5,6 
),
twelve_week_after AS (
SELECT '2020-06-15' AS base_week,region,platform,age_band,demographics,customer_type,SUM(sales) AS sales_twelve_week_after
FROM weekly_sales_new
WHERE
week_day BETWEEN '2020-06-15'::DATE AND TO_CHAR(('2020-06-15'::DATE + INTERVAL '12 week'), 'YYYY-MM-DD')::DATE
GROUP BY 1,2,3,4,5,6 
)


SELECT b.region,b.platform,b.age_band,b.demographics,b.customer_type,b.sales_twelve_week_before,a.sales_twelve_week_after,
a.sales_twelve_week_after-b.sales_twelve_week_before AS change_in_sales,
ROUND(100*(a.sales_twelve_week_after-b.sales_twelve_week_before)/(b.sales_twelve_week_before ::NUMERIC),2) AS pct_change
FROM twelve_week_before b JOIN twelve_week_after a ON b.base_week=a.base_week AND
b.region = a.region
AND b.platform = a.platform
AND b.age_band = a.age_band
AND b.demographics = a.demographics
AND b.customer_type = a.customer_type
ORDER BY a.sales_twelve_week_after-b.sales_twelve_week_before;
