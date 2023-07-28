#### If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

```sql
INSERT INTO pizza_names VALUES(3, 'Supreme');
SELECT * FROM pizza_names;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/844829ae-bca3-42c8-ae93-9fa3fc087a5a)


```sql
INSERT INTO pizza_recipes
VALUES(3, (SELECT GROUP_CONCAT(topping_id SEPARATOR ', ') FROM pizza_toppings));

SELECT * FROM pizza_recipes;
```
![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/bbdb25a0-026b-4e92-8c6d-f122b5cdaa20)

