<p align='center'>
<img src= "https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/82e8dbb4-a634-4e25-9c17-ac645bb1e330)" width ='500'>
</p>



<h1>Introduction</h1>

Clique Bait is not like your regular online seafood store - the founder and CEO Danny, was also a part of a digital data analytics team and wanted to expand his knowledge into the seafood industry!

In this case study - you are required to support Danny’s vision and analyse his dataset and come up with creative solutions to calculate funnel fallout rates for the Clique Bait online store.

<h1>Dataset</h1>

For this case study there is a total of 5 datasets which you will need to combine to solve all of the questions.

**Users** - Customers who visit the Clique Bait website are tagged via their cookie_id.

**Events** - Customer visits are logged in this events table at a cookie_id level and the event_type and page_id values can be used to join onto relevant satellite tables to obtain further information about each event.
The sequence_number is used to order the events within each visit.

**Event Identifier** - The event_identifier table shows the types of events which are captured by Clique Bait’s digital data systems.

**Campaign Identifier** - This table shows information for the 3 campaigns that Clique Bait has ran on their website so far in 2020.

**Page Hierarchy** - This table lists all of the pages on the Clique Bait website which are tagged and have data passing through from user interaction events.

<h1>Entity Relationship Diagram</h1>

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/f7dda6da-4b62-4915-b3b0-3db5039f1c92)



<h1>DBMS used</h1>

PostgreSQL 15.3
