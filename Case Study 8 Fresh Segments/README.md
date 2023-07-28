<p align = 'center'>
<img src = "https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/addccdb1-9833-45ed-b281-9f2358f2307e" width='500'>
</p>

<h1>Introduction</h1>

Danny created Fresh Segments, a digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base.

Clients share their customer lists with the Fresh Segments team who then aggregate interest metrics and generate a single dataset worth of metrics for further analysis.

In particular - the composition and rankings for different interests are provided for each client showing the proportion of their customer list who interacted with online assets related to each interest for each month.

Danny has asked for your assistance to analyse aggregated metrics for an example client and provide some high level insights about the customer list and their interests.

<h1>Datasets</h1>

For this case study there is a total of 2 datasets which you will need to use to solve the questions.

**Interest Metrics**
- This table contains information about aggregated interest metrics for a specific major client of Fresh Segments which makes up a large proportion of their customer base.

- Each record in this table represents the performance of a specific interest_id based on the client’s customer base interest measured through clicks and interactions with specific targeted advertising content.

**Interest Map**
This mapping table links the interest_id with their relevant interest information. You will need to join this table onto the previous interest_details table to obtain the interest_name as well as any details about the summary information.

<h1>Entity Relationship Diagram</h1>

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/39943559-5d99-4658-bb59-c649382d783b)


<h1>DBMS used</h1>

PostgreSQL 15.3
