
#### 1. What is the unique count and total amount for each transaction type?
```sql
SELECT txn_type,COUNT( DISTINCT customer_id) AS 'unique_count',SUM(txn_amount) AS 'total_amount'
FROM customer_transactions GROUP BY 1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/7542c0bf-a2ee-49ff-a29b-332cf8fee290)

#### 2. What is the average total historical deposit counts and amounts for all customers?
```sql
WITH cte AS (
SELECT customer_id, COUNT(customer_id) AS 'txn_count', AVG(txn_amount) AS 'avg_amount'
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)
SELECT ROUND(AVG(txn_count)) AS avg_deposit_count,ROUND(AVG(avg_amount)) AS 'avg_deposit_amt'
FROM cte;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/790ce73b-4b90-413b-bd3c-bd8caafd14e4)


#### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```sql
WITH cte AS
(SELECT *,MONTH(txn_date) AS 'mth',COUNT(*)OVER(PARTITION BY customer_id,txn_type,MONTH(txn_date)) AS 'cnt' 
FROM customer_transactions)
,
cte1 AS (SELECT * FROM cte where cnt>1 AND txn_type='deposit')

SELECT c1.mth,COUNT(DISTINCT c1.customer_id) AS 'n-customers' 
FROM cte1 c1 JOIN cte c ON c1.customer_id=c.customer_id AND c.txn_type<>'deposit' AND c1.mth=c.mth
GROUP BY 1;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/7a6b72f2-691e-4b5d-9b88-389b658f8d5f)



#### 4. What is the closing balance for each customer at the end of the month?
```sql
CREATE TEMPORARY TABLE deposit_amount AS 
(SELECT DISTINCT customer_id, MONTH(txn_date) AS 'mth',
SUM( CASE WHEN txn_type='deposit' THEN txn_amount ELSE NULL END)AS 'deposit_amount'
FROM customer_transactions WHERE txn_type='deposit'
GROUP BY customer_id,MONTH(txn_date) ORDER BY 1 );
```
**NOT ALL ROWS ARE DISPLAYED**

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/1287acca-bdbb-4038-8f69-c1c89ec59b47)


```sql
CREATE TEMPORARY TABLE removed_amount AS 
(SELECT DISTINCT customer_id, MONTH(txn_date) AS 'mth',
SUM( CASE WHEN txn_type<>'deposit' THEN txn_amount ELSE NULL END) AS 'removed_amount'
FROM customer_transactions WHERE txn_type<>'deposit'
GROUP BY customer_id,MONTH(txn_date) ORDER BY 1 
);
```
**NOT ALL ROWS ARE DISPLAYED**

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/f74b71ec-9c15-420a-91bb-d6034a68ccd2)


```sql
WITH RECURSIVE cte AS (
SELECT d.customer_id,d.mth,SUM(d.deposit_amount-IFNULL(r.removed_amount,0)) OVER (PARTITION BY d.customer_id ORDER BY d.mth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
AS 'amt' , MAX(d.mth) OVER (PARTITION BY d.customer_id) AS 'mmt',
ROW_NUMBER() OVER(PARTITION BY d.customer_id) AS 'rn',COUNT(*) OVER (PARTITION BY d.customer_id) AS 'cnt'
FROM deposit_amount d 
LEFT JOIN removed_amount r ON d.customer_id=r.customer_id AND d.mth=r.mth WHERE d.customer_id
UNION ALL
SELECT customer_id,mth+1 AS 'mth' ,amt,mmt,rn+1 as rn,cnt+1 AS cnt FROM cte WHERE mth<>mmt AND cnt<mmt )

SELECT customer_id,mth AS 'month',amt AS 'closing_balance' FROM cte
ORDER BY 1,2;
```
**NOT ALL ROWS ARE DISPLAYED**

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/1e2fd316-6f89-4786-bcb7-b4e108048264)


#### 5. What is the percentage of customers who increase their closing balance by more than 5%?
```sql
WITH RECURSIVE cte AS (
SELECT d.customer_id,d.mth,SUM(d.deposit_amount-IFNULL(r.removed_amount,0)) OVER (PARTITION BY d.customer_id ORDER BY d.mth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
AS 'amt' , MAX(d.mth) OVER (PARTITION BY d.customer_id) AS 'mmt',
ROW_NUMBER() OVER(PARTITION BY d.customer_id) AS 'rn',COUNT(*) OVER (PARTITION BY d.customer_id) AS 'cnt'
FROM deposit_amount d 
LEFT JOIN removed_amount r ON d.customer_id=r.customer_id AND d.mth=r.mth WHERE d.customer_id
UNION ALL
SELECT customer_id,mth+1 AS 'mth' ,amt,mmt,rn+1 as rn,cnt+1 AS cnt FROM cte WHERE mth<>mmt AND cnt<mmt )
,
cte1 AS (SELECT customer_id,mth AS 'month',amt AS 'closing_balance' FROM cte
ORDER BY 1,2)

,cte2 AS (SELECT *,LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month),(closing_balance-LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month))/LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month) AS 'increase_by_5' 
FROM cte1)

SELECT ROUND(100*COUNT(DISTINCT increase_by_5)/(SELECT COUNT(DISTINCT customer_id) FROM customer_transactions),2) AS 'customer_pct'
FROM cte2 WHERE increase_by_5>5;

```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/74949347-a36f-4a22-a2b3-93a4986e8948)

