                                                --Data Exploration and Cleansing

-- Q1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
-- SOLUTION -
ALTER TABLE interest_metrics
ALTER COLUMN month_year TYPE DATE
USING TO_DATE(month_year, 'MM-YYYY');

SELECT  table_name, column_name, data_type 
FROM information_schema.columns WHERE 
table_name = 'interest_metrics'
AND column_name='month_year' ;


-- Q2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
-- SOLUTION 
SELECT month_year,COUNT(*) AS count_of_records FROM interest_metrics
GROUP BY 1 ORDER BY 1 IS NULL ASC;


-- Q3. What do you think we should do with these null values in the fresh_segments.interest_metrics
-- SOLUTION - we should drop them 
SELECT COUNT(*)
FROM interest_metrics
WHERE month_year IS NULL;

SELECT *
FROM interest_metrics
WHERE month_year IS NULL;


-- Q4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
-- SOLUTION -
WITH not_in_map AS (
SELECT DISTINCT interest_id::INTEGER FROM interest_metrics 
EXCEPT
SELECT DISTINCT id FROM interest_map )
,
not_in_metrics AS (
SELECT DISTINCT id FROM interest_map
EXCEPT
SELECT DISTINCT interest_id::INTEGER FROM interest_metrics )

SELECT COUNT(mp.interest_id) AS not_in_map , COUNT(me.id) AS not_in_metrics
FROM not_in_map mp JOIN not_in_metrics me ON 1=1;
 
 
--Q5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
-- SOLUTION -
SELECT id,COUNT(*) AS count_per_id,COUNT(*) OVER() AS total_number_0f_id
FROM interest_map 
GROUP BY 1 ORDER  BY 1;



-- Q6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
-- SOLUTION- 
SELECT * FROM interest_map WHERE id=21246;
SELECT * FROM interest_metrics WHERE interest_id::INTEGER=21246;
-- We should use inner join using condition that month and year IS NOT NULL . we should get 10 rows of data

SELECT me.*,mp.interest_name,mp.interest_summary,mp.created_at,mp.last_modified
FROM interest_metrics me JOIN interest_map mp ON me.interest_id::NUMERIC=mp.id
WHERE me.interest_id ::INTEGER=21246 AND me._month IS NOT NULL AND me._year IS NOT NULL;


-- Q7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
-- SOLUTION
SELECT COUNT(*) AS number_of_records
FROM interest_metrics me JOIN interest_map mp ON me.interest_id::NUMERIC=mp.id AND me.month_year<mp.created_at
WHERE  me._month IS NOT NULL AND me._year IS NOT NULL;

SELECT me.month_year,mp.created_at
FROM interest_metrics me JOIN interest_map mp ON me.interest_id::NUMERIC=mp.id AND me.month_year<mp.created_at
WHERE  me._month IS NOT NULL AND me._year IS NOT NULL;
-- yes they are valid since month_year is an aggregated column for month of a particular year



                                                  -- Interest Analysis
-- Q1. Which interests have been present in all month_year dates in our dataset?
-- SOLUTION - 
WITH cte AS (
SELECT interest_id,COUNT(DISTINCT month_year) FROM interest_metrics
GROUP BY 1 HAVING COUNT(DISTINCT month_year) = ( SELECT COUNT(DISTINCT month_year) FROM interest_metrics)
)
SELECT COUNT(interest_id) AS number_of_interests
FROM cte;


--Q2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
-- SOLUTION 
WITH cte AS (
SELECT interest_id,COUNT(DISTINCT month_year) AS total_months FROM interest_metrics
WHERE month_year IS NOT NULL
GROUP BY 1
)
,
cte1 AS (
SELECT total_months, COUNT(*) AS number_of_interests
FROM cte GROUP BY 1)
,
cum_pct AS (
SELECT * ,
ROUND((SUM(number_of_interests) OVER (ORDER BY total_months DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / SUM(number_of_interests) OVER () * 100), 1) AS cumulative_pct
FROM cte1 ORDER BY 1)

SELECT * FROM cum_pct WHERE cumulative_pct>=90;




-- Q3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
-- SOLUTION - 6 is the threshold
WITH cte AS (
SELECT interest_id,COUNT(DISTINCT month_year) AS total_months FROM interest_metrics
WHERE month_year IS NOT NULL
GROUP BY 1
HAVING COUNT(DISTINCT month_year)>=6
)

SELECT COUNT(*) AS excluded_data_points  
FROM interest_metrics
WHERE interest_id NOT IN 
( SELECT DISTINCT interest_id FROM cte
);



-- Q4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
-- SOLUTION -

WITH cte AS (
SELECT interest_id,COUNT(DISTINCT month_year) AS total_months FROM interest_metrics
WHERE month_year IS NOT NULL
GROUP BY 1
HAVING COUNT(DISTINCT month_year)>=6
)
,
excl AS (
SELECT month_year, COUNT(*) AS excluded_data_points   
FROM interest_metrics
WHERE interest_id NOT IN 
( SELECT DISTINCT interest_id FROM cte
)
GROUP BY 1 ORDER BY 1)
,
incl AS (
SELECT month_year, COUNT(*) AS included_data_points   
FROM interest_metrics
WHERE interest_id IN 
( SELECT DISTINCT interest_id FROM cte
)
GROUP BY 1 ORDER BY 1)


SELECT incl.*,excl.excluded_data_points,
ROUND(100 * excl.excluded_data_points/(excl.excluded_data_points+incl.included_data_points)::NUMERIC,2 ) AS exclude_pct
FROM incl JOIN excl ON incl.month_year=excl.month_year;

-- Since exclude perecent is very low for each month year removing those data point will not bring larger change to dataset and business can focus on those interest_id 
-- where customer are largely interested 

-- Q5. After removing these interests - how many unique interests are there for each month?
-- SOLUTION - 

WITH cte AS (
SELECT interest_id,COUNT(DISTINCT month_year) AS total_months FROM interest_metrics
WHERE month_year IS NOT NULL
GROUP BY 1
HAVING COUNT(DISTINCT month_year)>=6
)

SELECT month_year, COUNT(*) AS included_data_points   
FROM interest_metrics
WHERE interest_id IN 
( SELECT DISTINCT interest_id FROM cte
)
GROUP BY 1 ORDER BY 1;


                                                      -- Segment Analysis
-- Q1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
--SOLUTION 
DROP TABLE IF EXISTS filtered_im;
CREATE TEMP TABLE filtered_im AS 
WITH cte AS (
SELECT interest_id,COUNT(DISTINCT month_year) AS total_months FROM interest_metrics
WHERE month_year IS NOT NULL
GROUP BY 1
HAVING COUNT(DISTINCT month_year)>=6
)
SELECT *
FROM interest_metrics
WHERE interest_id  IN 
( SELECT DISTINCT interest_id FROM cte
);

SELECT im.month_year,im.interest_id,mp.interest_name,MAX(im.composition) AS top_10_composition
FROM filtered_im im JOIN interest_map mp ON im.interest_id::INTEGER=mp.id
GROUP BY 1,2,3 ORDER BY 4 DESC LIMIT 10;

SELECT im.month_year,im.interest_id,mp.interest_name,MIN(im.composition) AS bottom_10_composition
FROM filtered_im im JOIN interest_map mp ON im.interest_id::INTEGER=mp.id
GROUP BY 1,2,3 ORDER BY 4 ASC LIMIT 10;



--Q2. Which 5 interests had the lowest average ranking value?
-- SOLUTION - IN ranking numerically lower value means better ranking and larger value means low ranking hence i used ORDER BY DESC
SELECT im.interest_id,mp.interest_name,ROUND(avg(im.ranking),2) AS avg_ranking 
FROM filtered_im im JOIN interest_map mp ON im.interest_id::INTEGER=mp.id
GROUP  BY 1,2
ORDER BY 3 DESC LIMIT 5;



-- Q3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
-- SOLUTION -
WITH cte AS (
SELECT im.interest_id,mp.interest_name,ROUND(STDDEV(im.percentile_ranking)::numeric, 2) AS std_dev,
DENSE_RANK() OVER (ORDER BY STDDEV(im.percentile_ranking) DESC) AS rk
FROM filtered_im im JOIN interest_map mp ON im.interest_id::INTEGER=mp.id
GROUP  BY 1,2
)
SELECT *FROM cte WHERE rk <= 5;



--Q4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
-- SOLUTION -

WITH cte AS (
SELECT im.interest_id,mp.interest_name,ROUND(STDDEV(im.percentile_ranking)::numeric, 2) AS std_dev,
DENSE_RANK() OVER (ORDER BY STDDEV(im.percentile_ranking) DESC) AS rk
FROM filtered_im im JOIN interest_map mp ON im.interest_id::INTEGER=mp.id
GROUP  BY 1,2
)
,
cte1 AS (
SELECT * FROM cte WHERE rk <= 5)
,
cte2 AS (
SELECT im.month_year,im.interest_id,mp.interest_name,im.percentile_ranking,
DENSE_RANK() OVER (PARTITION BY im.month_year ORDER BY percentile_ranking DESC) AS maxrk ,
DENSE_RANK() OVER (PARTITION BY im.month_year ORDER BY percentile_ranking) AS minrk 
FROM filtered_im im JOIN interest_map mp ON im.interest_id::INTEGER=mp.id 
WHERE im.interest_id IN (SELECT interest_id FROM cte1)
)

SELECT a.month_year,a.interest_id,a.interest_name,a.percentile_ranking AS max_pctile_rank, b.percentile_ranking AS min_pctile_rank
FROM cte2 a JOIN cte2 b ON a.month_year=b.month_year AND a.maxrk=b.minrk
WHERE a.maxrk=1 ORDER BY 1;


-- Q5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?
--SOLUTION -
SELECT im.month_year,im.interest_id,mp.interest_name,MAX(im.composition) AS top_10_composition
FROM filtered_im im JOIN interest_map mp ON im.interest_id::INTEGER=mp.id
GROUP BY 1,2,3 ORDER BY 4 DESC LIMIT 10;
--  Based off of the highest composition values, the average customer appears to be majority work comes first travelers. products or services related to traveling should be shown to these customers


                                                     --INDEX ANALYSIS

-- The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

-- Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

DROP TABLE IF EXISTS im_avg_comp;

CREATE TEMPORARY TABLE im_avg_comp AS
SELECT month_year, interest_id, composition, index_value, ROUND((composition / index_value)::NUMERIC, 2) AS composition_average,ranking,
percentile_ranking
FROM interest_metrics WHERE month_year IS NOT NULL;



-- Q1. What is the top 10 interests by the average composition for each month?
-- SOLUTION -
WITH cte AS (
SELECT month_year,interest_id,composition_average,
DENSE_RANK() OVER (PARTITION BY month_year ORDER BY composition_average DESC) AS rk
FROM im_avg_comp
)

SELECT c.month_year,c.interest_id,mp.interest_name,c.composition_average
FROM cte c JOIN interest_map mp ON c.interest_id::INTEGER = mp.id
WHERE rk <=10 ORDER BY 1;

-- Q2. For all of these top 10 interests - which interest appears the most often?
-- SOLUTION -
WITH cte AS (
SELECT month_year,interest_id,composition_average,
DENSE_RANK() OVER (PARTITION BY month_year ORDER BY composition_average DESC) AS rk
FROM im_avg_comp
)
,
cte1 AS (
SELECT c.month_year,c.interest_id,mp.interest_name,c.composition_average
FROM cte c JOIN interest_map mp ON c.interest_id::INTEGER = mp.id
WHERE rk <=10 ORDER BY 1)
,
cte2 AS (
SELECT interest_name,COUNT(*) AS cnt ,DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rk 
FROM cte1 GROUP BY 1)

SELECT interest_name,cnt FROM cte2 WHERE rk=1;


--Q3. What is the average of the average composition for the top 10 interests for each month?
-- SOLUTION -
WITH cte AS (
SELECT month_year,interest_id,composition_average,
DENSE_RANK() OVER (PARTITION BY month_year ORDER BY composition_average DESC) AS rk
FROM im_avg_comp
)

SELECT month_year,ROUND(avg(composition_average),2) AS avg_of_composition_average
FROM cte WHERE rk <=10  GROUP BY 1 ORDER BY 1;



-- Q4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
-- SOLUTION

WITH cte AS (
SELECT month_year,interest_id,composition_average,
DENSE_RANK() OVER (PARTITION BY month_year ORDER BY composition_average DESC) AS rk
FROM im_avg_comp
),
cte1 AS (
SELECT c.month_year, mp.interest_name, c.composition_average,
ROUND((AVG(c.composition_average) OVER (ORDER BY c.month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)), 2) AS comp_3_month_moving_avg,
LAG(mp.interest_name) OVER (ORDER BY c.month_year) AS intst_1_month_ago,
LAG(c.composition_average) OVER (ORDER BY c.month_year) AS comp_1_month_ago,
LAG(mp.interest_name, 2) OVER (ORDER BY c.month_year) AS intst_2_month_ago,
LAG(c.composition_average) OVER (ORDER BY c.month_year) AS comp_2_month_ago
FROM cte  c
JOIN interest_map  mp ON c.interest_id::INTEGER = mp.id
WHERE rk = 1
)
SELECT month_year,interest_name,composition_average AS max_index_composition,comp_3_month_moving_avg AS "3_month_moving_avg",
CONCAT(intst_1_month_ago , ' : ' , comp_1_month_ago) AS "1_month_ago",
CONCAT(intst_2_month_ago , ' : ' , comp_2_month_ago) AS "2_months_ago"
FROM cte1 WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';




-- Q5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?
-- Seasonal changes could be the reason
