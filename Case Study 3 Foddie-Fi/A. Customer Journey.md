#### Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey. Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
```sql
SELECT * FROM details
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19);
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/4e55c493-566a-45a8-a4b6-4a0b930927fc)

- Client #1: upgraded to the basic monthly subscription within their 7 day trial period.

- Client #2: upgraded to the pro annual subscription within their 7 day trial period.

- Client #11: cancelled their subscription within their 7 day trial period.

- Client #13: upgraded to the basic monthly subscription within their 7 day trial period and upgraded to pro annual 3 months later.

- Client #15: upgraded to the pro annual subscription within their 7 day trial period and cancelled the following month.

- Client #16: upgraded to the basic monthly subscription after their 7 day trial period and upgraded to pro annual almost 5 months later.

- Client #18: upgraded to the pro monthly subscription within their 7 day trial period.

- Client #19: upgraded to the pro monthly subscription within their 7 day trial period and upgraded to pro annual 2 months later.
