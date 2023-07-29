<p align='center'>
<img src="https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/73a5dea0-f354-4393-8b3e-3127e8d3a242" width='500'>
</p>

<h1>Introduction</h1>

Subscription based businesses are super popular and Danny realised that there was a large gap in the market - he wanted to create a new streaming service that only had food related content - something like Netflix but with only cooking shows!

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.

<h1>Datasets</h1>

Sure, here's the rephrased version in bullet points:

**plans Table:**

- Contains data on 5 customer plans offered by Foodie-Fi: Basic plan, Pro plan, Trial plan, Churn plan, and Annual Pro plan.
- Basic Plan: Customers have limited access and can only stream videos. It costs $9.90 per month.
- Pro Plan: Customers have unlimited watch time, can download videos for offline viewing, and can choose either a monthly subscription starting at $19.90 or an annual subscription priced at $199.
- Trial Plan: Customers can sign up for a 7-day free trial, which automatically continues with the Pro monthly subscription plan unless they cancel, downgrade to Basic, or upgrade to an Annual Pro plan during the trial.
- Churn Plan: When customers cancel their Foodie-Fi service, they will have a churn plan record with a null price, but their access will continue until the end of the billing period.

**subscriptions Table:**

- Stores customer subscriptions, indicating the start date of their specific plan_id.
- Downgrades or cancellations from a Pro plan will keep the higher plan in place until the current billing period ends, with the start_date reflecting the actual plan change date.
- Upgrading from Basic to Pro or Annual Pro plan takes effect immediately.
- Customers who churn will retain access until the end of their current billing period, but the start_date will technically be the day they decided to cancel their service.

- <h1>Entity Relationship Diagram</h1>

![image](https://github.com/shivin316/8__Week_SQL_Challenge/assets/122541994/63ded15f-c771-4736-9fbf-6445e2cd0dce)


<h1>DBMS used</h1>

MySQL 8.0
