<p align ='center'>
<img src ="https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/ce913542-7bb4-405f-bcf3-977e01144917" width='500'>
</p>


<h1>Introduction</h1>

Data Mart is Danny’s latest venture and after running international operations for his online supermarket that specialises in fresh produce - Danny is asking for your support to analyse his sales performance.

In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.

Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.

The key business question he wants you to help him answer are the following:

What was the quantifiable impact of the changes introduced in June 2020?
Which platform, region, segment and customer types were the most impacted by this change?
What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?

<h1>Dataset</h1>

For this case study there is only a single table: weekly_sales

Additional Details about the Dataset:

- **International Operations:** Data Mart operates in multiple regions using a multi-region strategy, indicating a global presence.

- **Retail and Online Platforms:** Data Mart serves its customers through both retail and online platforms, utilizing a Shopify storefront.

- **Customer Segment and Customer_Type:** The dataset includes personal age and demographics information of customers, categorized by customer segments and types, which is shared with Data Mart.

- **Transactions and Sales:** The dataset contains two key metrics: "transactions" represents the count of unique purchases made through Data Mart, while "sales" represents the actual dollar amount of those purchases.

- **Week_Date Aggregation:** Each record in the dataset represents an aggregated slice of the underlying sales data rolled up into a "week_date" value, which signifies the start of the sales week. This allows for weekly analysis and reporting of sales data.



<h1>Entity Relationship Diagram</h1>

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/e0e341a9-c2bf-4cb3-9125-22948718ced2)


please note that there is only this one table - hence why it looks a little bit lonely!

<h1>DBMS USED</h1>

PostgreSQL 15.3
