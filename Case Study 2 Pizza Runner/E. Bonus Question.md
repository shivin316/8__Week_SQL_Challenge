#### If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

```sql
INSERT INTO pizza_names VALUES(3, 'Supreme');
SELECT * FROM pizza_names;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/27f235fb-bd26-47ee-bf95-77832288bfeb)

```sql
INSERT INTO pizza_recipes
VALUES(3, (SELECT GROUP_CONCAT(topping_id SEPARATOR ', ') FROM pizza_toppings));

SELECT * FROM pizza_recipes;
```
![image](https://github.com/shivin316/8_Week_SQL_Challenge/assets/122541994/3323548d-c065-4520-b0ca-a036b6d7266c)
