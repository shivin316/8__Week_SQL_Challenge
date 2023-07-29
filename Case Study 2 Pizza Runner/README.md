<p align='center'>
<img src ="https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/e74bf0f6-2d7c-4e96-afee-e3fe82d8873a" width='500'>
</p>

<h1>Introduction</h1>

Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

<h1>Dataset</h1>

- **runners:** Contains data about the registration_date for each new runner.

- **customer_orders:** Captures customer pizza orders with individual rows for each pizza in the order. The pizza_id corresponds to the type of pizza, exclusions represent ingredient_id values to be removed from the pizza, and extras represent ingredient_id values to be added to the pizza.

- **runner_orders:** Stores information about orders assigned to runners. Not all orders are fully completed and can be canceled. The pickup_time is the timestamp when the runner arrives at Pizza Runner headquarters to pick up freshly cooked pizzas. The distance and duration fields indicate the distance and time taken by the runner to deliver the order to the respective customer.

- **pizza_names:** Contains data on the available pizza options at Pizza Runner - either Meat Lovers or Vegetarian.

- **pizza_recipes:** Each pizza_id is associated with a standard set of toppings used as part of the pizza recipe.

- **pizza_toppings:** This table includes all topping_name values with their corresponding topping_id value.

<h1>Data Cleaning</h1>

**Customer_orders table:**

- Exclusions Column:
  - Remove blank spaces and null values.

**Runner_orders table:**

- Pickup_time Column:
  - Address null values.

- Distance Column:
  - Address null values.
  - Strip the unit 'km' from values.

- Duration Column:
  - Address null values.
  - Strip 'minutes', 'mins', and 'minute' from values.

- Cancellation Column:
  - Remove blank spaces and null values.
 
<h1>Entity Relationship Diagram</h1>

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/ddb835b6-0afa-4e40-9f6e-6dc98391562c)

<h1>DBMS used</h1>

MySQL 8.0
