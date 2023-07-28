
#### 1. What is the unique count and total amount for each transaction type?
```sql
SELECT txn_type,COUNT( DISTINCT customer_id) AS 'unique_count',SUM(txn_amount) AS 'total_amount'
FROM customer_transactions GROUP BY 1;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/92256d11-9d59-450a-8245-3327d54a155c)

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
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/89911bd7-8962-4a30-96ad-0d758c31c138)

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
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/9cea2558-cad6-4559-88da-5bd66d296f9d)

#### 4. What is the closing balance for each customer at the end of the month?
```sql
CREATE TEMPORARY TABLE deposit_amount AS 
(SELECT DISTINCT customer_id, MONTH(txn_date) AS 'mth',
SUM( CASE WHEN txn_type='deposit' THEN txn_amount ELSE NULL END)AS 'deposit_amount'
FROM customer_transactions WHERE txn_type='deposit'
GROUP BY customer_id,MONTH(txn_date) ORDER BY 1 );
```
**NOT ALL ROWS ARE DISPLAYED**

![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/d4d21598-c084-4c67-b54f-57219eeba1d5)

```sql
CREATE TEMPORARY TABLE removed_amount AS 
(SELECT DISTINCT customer_id, MONTH(txn_date) AS 'mth',
SUM( CASE WHEN txn_type<>'deposit' THEN txn_amount ELSE NULL END) AS 'removed_amount'
FROM customer_transactions WHERE txn_type<>'deposit'
GROUP BY customer_id,MONTH(txn_date) ORDER BY 1 
);
```
**NOT ALL ROWS ARE DISPLAYED**

![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/48b9688c-76da-44ae-850d-ba381b2f5f74)

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

![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/a7f36704-1f43-40bc-9920-ed12df482f32)

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
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/c9d56b35-d93c-4c79-bef5-737b02223d32)
