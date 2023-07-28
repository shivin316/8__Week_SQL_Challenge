                                                     -- DIGITAL ANALYSIS
-- Using the available datasets - answer the following questions using a single query for each one:

-- Q1. How many users are there?
-- SOLUTION - 
SELECT COUNT(DISTINCT user_id) AS number_of_users FROM users;


-- Q2. How many cookies does each user have on average?
-- SOLUTION -
SELECT ROUND(AVG(cookies_count),2) AS cookies_average
FROM(
SELECT  user_id,COUNT(*) AS cookies_count FROM users GROUP BY 1)x;


-- Q3. What is the unique number of visits by all users per month?
-- SOLUTION -
SELECT TO_CHAR(event_time,'MONTH') AS month_name, COUNT(DISTINCT cookie_id) AS unique_visits
FROM events
GROUP BY EXTRACT (MONTH FROM event_time),1
ORDER BY EXTRACT (MONTH FROM event_time),1 ;


-- Q4. What is the number of events for each event type?
-- SOLUTION - 
SELECT e.event_type,ei.event_name,COUNT(e.event_type) AS number_of_events
FROM events e JOIN event_identifier ei ON e.event_type=ei.event_type
GROUP BY 1,2 
ORDER BY 1,2;


-- Q5. What is the percentage of visits which have a purchase event?
-- SOLUTION -
SELECT ROUND(100*(COUNT(CASE WHEN event_type=3 THEN visit_id ELSE NULL END)::NUMERIC/COUNT(DISTINCT visit_id)::NUMERIC),2)
AS purchase_event_pct
FROM events
;


-- Q6. What is the percentage of visits which view the checkout page but do not have a purchase event?
-- SOLUTION -
WITH non_purchase_event AS (SELECT DISTINCT visit_id FROM events
EXCEPT 
SELECT DISTINCT visit_id FROM events
WHERE event_type=3)

SELECT ROUND(100*COUNT(np.visit_id)/(SELECT COUNT( DISTINCT visit_id) FROM events WHERE page_id=12):: NUMERIC,2)
AS checkout_but_no_purchase_pct 
FROM 
non_purchase_event np JOIN events e ON np.visit_id=e.visit_id
JOIN page_hierarchy ph ON e.page_id=ph.page_id WHERE e.page_id=12;


--Q7. What are the top 3 pages by number of views?
--  SOLUTION -
SELECT e.page_id,ph.page_name,COUNT(e.page_id) AS number_of_views
FROM events e JOIN page_hierarchy AS ph ON e.page_id = ph.page_id
WHERE e.event_type = 1
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3;


-- Q8. What is the number of views and cart adds for each product category?
-- SOLUTION -
WITH n_views AS (
SELECT ph.product_category, COUNT(visit_id) AS number_of_views
FROM events e JOIN page_hierarchy ph ON e.page_id=ph.page_id 
WHERE e.event_type = 1 AND product_category IS NOT NULL
GROUP BY 1),
cart_add AS (
SELECT ph.product_category, COUNT(visit_id) AS added_to_cart
FROM events e JOIN page_hierarchy ph ON e.page_id=ph.page_id 
WHERE e.event_type = 2 AND product_category IS NOT NULL
GROUP BY 1
)
SELECT n.product_category,n.number_of_views,c.added_to_cart
FROM n_views n JOIN cart_add c ON n.product_category=c.product_category;


-- Q9. What are the top 3 products by purchases?
-- SOLUTION -
WITH purchases AS (
SELECT visit_id FROM events WHERE event_type = 3
)
SELECT ph.page_name AS product,
COUNT(CASE WHEN e.event_type = 2 THEN 1 ELSE NULL END) AS top_3
FROM page_hierarchy  ph JOIN events e ON e.page_id = ph.page_id
JOIN purchases  p ON e.visit_id = p.visit_id
WHERE ph.product_category IS NOT NULL
AND ph.page_name NOT in('1', '2', '12', '13')
AND p.visit_id = e.visit_id
GROUP BY 1
ORDER BY top_3 DESC LIMIT 3;

                                                       -- Product Funnel Analysis
-- Using a single SQL query - create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?


CREATE TEMP TABLE new_product_table AS (
WITH product_view AS (
SELECT e.page_id,ph.page_name AS product ,COUNT(e.page_id) AS number_of_views
FROM events e JOIN page_hierarchy AS ph ON e.page_id = ph.page_id
WHERE e.event_type = 1 AND ph.product_category IS NOT NULL
GROUP BY 1,2
ORDER BY 1
),
cart_added AS (
SELECT e.visit_id,e.page_id,ph.page_name AS product, COUNT(visit_id)OVER(PARTITION BY e.page_id,ph.page_name) AS added_to_cart
FROM events e JOIN page_hierarchy ph ON e.page_id=ph.page_id 
WHERE e.event_type = 2 AND product_category IS NOT NULL
ORDER BY 2
),
non_purchase_event AS (
SELECT DISTINCT visit_id FROM events
EXCEPT 
SELECT DISTINCT visit_id FROM events
WHERE event_type=3)
,
abandoned_count AS (
SELECT c.page_id,c.product,COUNT(c.visit_id) AS abandon_num
FROM cart_added c JOIN non_purchase_event np ON c.visit_id=np.visit_id
GROUP BY 1,2
ORDER BY 1
),
purchases AS (
SELECT visit_id FROM events WHERE event_type = 3
),
purchase_count AS (
SELECT ph.page_id,ph.page_name AS product,
COUNT(CASE WHEN e.event_type = 2 THEN 1 ELSE NULL END) AS purchased_count
FROM page_hierarchy  ph JOIN events e ON e.page_id = ph.page_id
JOIN purchases  p ON e.visit_id = p.visit_id
WHERE ph.product_category IS NOT NULL
AND ph.page_name NOT in('1', '2', '12', '13')
AND p.visit_id = e.visit_id
GROUP BY 1,2
ORDER BY 1)

SELECT DISTINCT v.page_id,v.product,v.number_of_views,c.added_to_cart,a.abandon_num,pc.purchased_count
FROM product_view v
JOIN cart_added c ON v.product=c.product
JOIN abandoned_count a ON c.product=a.product
JOIN purchase_count pc ON a.product=pc.product
ORDER BY 1,2);

SELECT * FROM new_product_table;

-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

CREATE TEMP TABLE new_product_category_table AS (
WITH product_category_view AS (
SELECT ph.product_category ,COUNT(e.page_id) AS number_of_views
FROM events e JOIN page_hierarchy AS ph ON e.page_id = ph.page_id
WHERE e.event_type = 1 AND ph.product_category IS NOT NULL
GROUP BY 1
ORDER BY 1
),
cart_added AS (
SELECT e.visit_id,ph.product_category ,COUNT(visit_id)OVER(PARTITION BY ph.product_category) AS added_to_cart
FROM events e JOIN page_hierarchy ph ON e.page_id=ph.page_id 
WHERE e.event_type = 2 AND product_category IS NOT NULL
ORDER BY 2
),
non_purchase_event AS (
SELECT DISTINCT visit_id FROM events
EXCEPT 
SELECT DISTINCT visit_id FROM events
WHERE event_type=3)
,
abandoned_count AS (
SELECT c.product_category,COUNT(c.visit_id) AS abandon_num
FROM cart_added c JOIN non_purchase_event np ON c.visit_id=np.visit_id
GROUP BY 1
ORDER BY 1
)	
,
purchases AS (
SELECT visit_id FROM events WHERE event_type = 3
),
purchase_count AS (
SELECT ph.product_category,
COUNT(CASE WHEN e.event_type = 2 THEN 1 ELSE NULL END) AS purchased_count
FROM page_hierarchy ph JOIN events e ON e.page_id = ph.page_id
JOIN purchases  p ON e.visit_id = p.visit_id
WHERE ph.product_category IS NOT NULL
AND ph.page_name NOT in('1', '2', '12', '13')
AND p.visit_id = e.visit_id
GROUP BY 1
ORDER BY 1)

SELECT DISTINCT v.product_category,v.number_of_views,c.added_to_cart,a.abandon_num,pc.purchased_count
FROM product_category_view v
JOIN cart_added c ON v.product_category=c.product_category
JOIN abandoned_count a ON c.product_category=a.product_category
JOIN purchase_count pc ON a.product_category=pc.product_category
ORDER BY 1);

SELECT * FROM new_product_category_table;

-- Use your 2 new output tables - answer the following questions:
-- Q1. Which product had the most views, cart adds and purchases?
-- SOLUTION 
WITH cte AS (
SELECT *,DENSE_RANK() OVER(ORDER BY number_of_views DESC ) AS rk1,
DENSE_RANK() OVER(ORDER BY added_to_cart DESC ) AS rk2,
DENSE_RANK() OVER(ORDER BY abandon_num DESC ) AS rk3,
DENSE_RANK() OVER(ORDER BY purchased_count DESC ) AS rk4
FROM new_product_table)

SELECT cte.product AS most_viewed, cte1.product AS most_added_to_cart,cte2.product AS most_purchased
FROM cte 
JOIN cte cte1 ON cte.rk1 = cte1.rk2
JOIN cte cte2 ON cte1.rk2=cte2.rk4
WHERE cte.rk1=1;


-- Q2. Which product was most likely to be abandoned?
-- SOLUTION -
SELECT product AS most_likely_to_abandon FROM
(SELECT * ,DENSE_RANK() OVER(ORDER BY abandon_num DESC ) AS rk 
FROM new_product_table )x WHERE rk=1;


-- Q3. Which product had the highest view to purchase percentage?
-- SOLUTION -
SELECT product,view_to_purchase_pct FROM
(SELECT *,ROUND(100*(purchased_count/number_of_views ::NUMERIC),2) AS view_to_purchase_pct,
DENSE_RANK() OVER(ORDER BY ROUND(100*(purchased_count/number_of_views ::NUMERIC),2) DESC ) AS rk 
FROM new_product_table)x WHERE rk=1;


-- Q4. What is the average conversion rate from view to cart add?
-- SOLUTION - 
SELECT ROUND(AVG(100 *added_to_cart/number_of_views ::NUMERIC), 2) AS view_to_cart_add_percentage
FROM new_product_table;


-- Q5. What is the average conversion rate from cart add to purchase?
-- SOLUTION - 
SELECT ROUND(AVG(100 * purchased_count/added_to_cart ::NUMERIC), 2) AS cart_to_purchase_percentage
FROM new_product_table;


                                                 -- Campaigns Analysis
--   Generate a table that has 1 single row for every unique visit_id record and has the following columns
-- user_id
-- visit_id
-- visit_start_time: the earliest event_time for each visit
-- page_views: count of page views for each visit
-- cart_adds: count of product cart add events for each visit
-- purchase: 1/0 flag if a purchase event exists for each visit
-- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-- impression: count of ad impressions for each visit
-- click: count of ad clicks for each visit
-- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
CREATE TEMP TABLE campaign_analysis AS (
WITH cte AS (
SELECT u.user_id,e.visit_id,MIN(start_date) AS visit_start_time,
COUNT(DISTINCT e.page_id) AS page_views,
COUNT(CASE WHEN e.event_type =2 THEN 1 ELSE NULL END) AS cart_adds,
COUNT(CASE WHEN e.event_type =4 THEN 1 ELSE NULL END) AS impression,
COUNT(CASE WHEN e.event_type=5 THEN 1 ELSE NULL END) AS click
FROM users u JOIN events e ON u.cookie_id=e.cookie_id
GROUP BY 1,2)
,
purchases AS (
SELECT DISTINCT visit_id FROM events WHERE event_type = 3)
,
if_purchased AS (
SELECT *,CASE WHEN visit_id IN (SELECT visit_id FROM purchases) THEN 1 ELSE 0 END AS purchase
FROM cte)
,
campaign AS (
SELECT ifp.*,c.campaign_name FROM if_purchased ifp
LEFT JOIN campaign_identifier c
ON ifp.visit_start_time BETWEEN c.start_date AND c.end_date )
,
product AS (
SELECT e.visit_id,STRING_AGG( ph.page_name, ', ' ORDER BY e.sequence_number) AS products
FROM events e  JOIN page_hierarchy ph
ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
AND e.event_type=2
GROUP BY 1
)
SELECT c.user_id,c.visit_id,c.visit_start_time,c.page_views,c.cart_adds,c.purchase,c.campaign_name,c.impression,c.click,p.products
FROM campaign c
JOIN product p ON c.visit_id = p.visit_id);

SELECT * FROM campaign_analysis;

--Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.
-- Some ideas you might want to investigate further include:
-- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
-- SOLUTION -
WITH impressions  AS (
SELECT CASE WHEN impression= 1 THEN 'Yes' ELSE 'No' END AS impressions, COUNT(*) AS number_of_visits,
ROUND(AVG(page_views)) AS avg_page_views,
ROUND(AVG(cart_adds)) AS avg_cart_adds, SUM(purchase) AS total_purchase
FROM campaign_analysis
GROUP BY 1
)
SELECT impressions,number_of_visits,avg_page_views,avg_cart_adds,
ROUND((100 * total_purchase / number_of_visits::NUMERIC), 1) AS purchase_pct
FROM impressions
ORDER BY 2;



-- Does clicking on an impression lead to higher purchase rates?
-- SOLUTION -
WITH impressions  AS (
SELECT CASE WHEN impression= 1 THEN 'Yes' ELSE 'No' END AS impressions, COUNT(*) AS number_of_visits,
ROUND(AVG(page_views)) AS avg_page_views,
ROUND(AVG(cart_adds)) AS avg_cart_adds, SUM(purchase) AS total_purchase
FROM campaign_analysis
GROUP BY 1
)
SELECT impressions,ROUND((100 * total_purchase / number_of_visits::NUMERIC), 1) AS purchase_pct
FROM impressions
ORDER BY 2;



-- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
-- SOLUTION -
WITH clicks  AS (
SELECT CASE WHEN click= 1 THEN 'ad_is_clicked' 
WHEN click = 0 AND impression =1 THEN 'watched_the_ad'
WHEN impression=0 THEN 'No_ads' ELSE NULL END AS clicks, COUNT(*) AS number_of_visits,
ROUND(AVG(page_views)) AS avg_page_views,
ROUND(AVG(cart_adds)) AS avg_cart_adds, SUM(purchase) AS total_purchase
FROM campaign_analysis
WHERE campaign_name IS NOT NULL
GROUP BY 1
)
SELECT clicks,number_of_visits,avg_page_views,avg_cart_adds,
ROUND((100 * total_purchase / number_of_visits::NUMERIC), 1) AS purchase_pct
FROM clicks
ORDER BY 2;



-- What metrics can you use to quantify the success or failure of each campaign compared to eachother?
-- SOLUTION -
WITH metrics AS (
SELECT CASE WHEN campaign_name IS NULL THEN 'No Campaign' ELSE campaign_name END AS campaigns,
COUNT(*) AS number_of_visits,SUM(purchase) AS total_purchase,
ROUND(AVG(page_views)) AS avg_page_views,
ROUND(AVG(cart_adds)) AS avg_cart_adds
FROM campaign_analysis
GROUP BY 1
)
SELECT campaigns,number_of_visits,avg_page_views,avg_cart_adds,
ROUND((100 * total_purchase / number_of_visits::NUMERIC), 1) AS purchase_pct
FROM
metrics;
