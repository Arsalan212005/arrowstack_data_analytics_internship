
select * from ravenstack_churn_events;

select * from ravenstack_accounts;

select * from ravenstack_feature_usage;

select * from ravenstack_support_tickets;

select * from ravenstack_subscriptions;

--MULTI-TABLE RELATIONAL SQL QUESTIONS.


--Q1. What are the total unique acccounts, active subscriptions, total active Monthly Recurring Revenue(MRR), total Annual Recurring Revenue(ARR), and overall churn rate?
--Ans. total accounts- 500, active_subscriptions- 4514, active_mrr- 10159608, active_arr- 121915296, churn_rate- 10

--solution
select
count (distinct a.account_id) as total_accounts,
count (distinct s.subscription_id) FILTER (where s.end_date is null) as active_subscriptions,
coalesce (sum (s.mrr_amount) filter (where s.end_date is null), 0) as active_mrr,
coalesce (sum (s.arr_amount) filter ( where s.end_date is null), 0) as active_arr,
round(
100.0 * count(distinct s.subscription_id) filter (where s.churn_flag = true)
/ NULLIF(COUNT(DISTINCT s.subscription_id), 0)
)as churn_rate
from ravenstack_accounts a left join ravenstack_subscriptions s
on a.account_id = s.account_id;



--Q2. Which Plan_tier generates the highest total MRR and average MRR per seat?
--Ans. Enterprise with 7546876 total MRR and 166.68 Average MRR per seat.

--solution
select
plan_tier,
sum(mrr_amount) filter(where end_date is null) as total_mrr,
round(
1.0 * sum(mrr_amount) filter(where end_date is null)
/ nullif(sum(seats) filter(where end_date is null), 0),2
) as avg_mrr_per_seat
from ravenstack_subscriptions
group by plan_tier
order by total_mrr desc limit 1;
)


--Q3. Who are the top 10 Highest-paying Customer accounts by cumulative lifetime MRR?
--Ans.  list of top_rank, highest-paying Customer accounts and cumulative lifetime MRR below:     
1	"A-5b1bcd"	131911
2	"A-d4e0d4"	114777
3	"A-1f0636"	94710
4	"A-5c046d"	83886
5	"A-30b4ca"	75938
6	"A-18793f"	75776
7	"A-c58f49"	70980
8	"A-4814a3"	70644
9	"A-09316c"	70000
10	"A-5a215a"	69687
       
--solution

with highest_customers as 
(select
account_id,
sum(mrr_amount) filter (where end_date is null) as cumulative_lifetime_mrr,
dense_rank() over(order by sum(mrr_amount) filter (where end_date is null) desc) as top_rank from ravenstack_subscriptions
group by account_id)

select top_rank,
account_id as highest_paying_accounts,
cumulative_lifetime_mrr
from highest_customers
where top_rank <= 10
order by top_rank;


--Q4. What are the top reason_code for categories causing cancellations, ranked by total churned accounts and percentage of all churn?
--Ans. below is the list of top reason code, total churned accounts and churned percentage.


"features"	104	19.12
"support"	95	17.46
"budget"	94	17.28
"pricing"	86	15.81
"unknown"	86	15.81
"competitor"79	14.52


--solution

select
reason_code,
count(distinct account_id) as total_churned_account,
round(
100.0 *count(distinct account_id)
/sum(count(distinct account_id)) over(),2) as churned_percentage
from ravenstack_churn_events
group by reason_code
order by total_churned_account desc;


--Q5. Write a query to find the list of account id, account name, feature name, and usage count?
--Ans. list of account id, account name, feature_name, and usage count below.(starting five)

"A-82d8a6"	"Company_444"	"feature_36"	8
"A-eb2fdc"	"Company_216"	"feature_33"	6
"A-bf7919"	"Company_426"	"feature_12"	6
"A-00cac8"	"Company_26"	"feature_21"	11
"A-474ad4"	"Company_261"	"feature_33"	15

--and all many..


--Solution

select distinct a.account_id, a.account_name, c.feature_name, c.usage_count from ravenstack_accounts a
left join ravenstack_subscriptions b 
on a.account_id = b.account_id
left join ravenstack_feature_usage c
on b.subscription_id = c.subscription_id;


--Q6. Write a query to find the total usage count and number of distinct features used by each account, ordered from highest to lowest total usage.
--Ans. total usage count and distinct features are below(top 5)

  1053	38
  1005	38
   993  40
   924 	38
   922  36

--solution
select sum(c.usage_count) as total_usage_count,
count (distinct c.feature_name) as distinct_feature 
from ravenstack_feature_usage c inner join ravenstack_subscriptions s
 on c.subscription_id = s.subscription_id
inner join ravenstack_accounts a
on s.account_id = a.account_id
group by a.account_id
order by total_usage_count desc;





--COHORT RETENTION ANALYSIS. 

--Q1. Find the total Number of accounts that signed up each month.
--Ans. below are the month names and total accounts that signed up each month.

"2023-01-01"	17
"2023-02-01"	18
"2023-03-01"	20
"2023-04-01"	15
"2023-05-01"	26
"2023-06-01"	13
"2023-07-01"	14
"2023-08-01"	16
"2023-09-01"	23
"2023-10-01"	20
"2023-11-01"	25
"2023-12-01"	20
"2024-01-01"	16
"2024-02-01"	13
"2024-03-01"	27
"2024-04-01"	22
"2024-05-01"	22
"2024-06-01"	21
"2024-07-01"	26
"2024-08-01"	21
"2024-09-01"	25
"2024-10-01"	31
"2024-11-01"	32
"2024-12-01"	17


--solution

select date_trunc('month', signup_date) ::date as Month_Name,
count(account_id) as total_accounts
from ravenstack_accounts
group by date_trunc('month', signup_date)
order by Month_Name;



--Q2.Write a query to track monthly product usage for each signup cohort by showing the cohort month, the activity month, and the count of distinct active accounts.
--Ans. below is the list of starting five cohort month, activity month, and distinct active accounts.

"2023-01-01"	"2023-01-01"	16
"2023-01-01"	"2023-02-01"	12
"2023-01-01"	"2023-03-01"	15
"2023-01-01"	"2023-04-01"	16
"2023-01-01"	"2023-05-01"	16


--Solution

select
date_trunc('month', a.signup_date) :: date as cohort_month,
date_trunc('month', c.usage_date)  :: date as activity_month,
count(distinct a.account_id) as distinct_active_accounts
from ravenstack_feature_usage c join ravenstack_subscriptions s
on c.subscription_id = s.subscription_id
join ravenstack_accounts a
on a.account_id = s.account_id
where date_trunc('month', c.usage_date) >= date_trunc('month', a.signup_date)
group by 1,2
order by 1,2;


--Q3. Calculate the Relative month index(month 0, month 1, month 2...) for each cohort activity.
--Ans. starting five cohort month, activity month, relative month index , and total accounts are below.

"2023-01-01"	"2023-01-01"	0	16
"2023-01-01"	"2023-02-01"	1	12
"2023-01-01"	"2023-03-01"	2	15
"2023-01-01"	"2023-04-01"	3	16
"2023-01-01"	"2023-05-01"	4	16


--Solution

select 
date_trunc('month', a.signup_date)::date as cohort_month,
date_trunc('month', c.usage_date)::date as activity_month,
((extract(year from c.usage_date))- extract(year from a.signup_date))*12 
+ (extract (month from c.usage_date) - extract(month from a.signup_date))as Relative_month_index,
count(distinct a.account_id) as total_accounts
from ravenstack_feature_usage c join ravenstack_subscriptions s
on c.subscription_id = s.subscription_id
join ravenstack_accounts a
on a.account_id = s.account_id
where date_trunc('month', c.usage_date)>= date_trunc('month', a.signup_date)
group by 1,2,3
order by 1,2;


--Q4.Calculate the monthly cohort retention percentage for each signup cohort.
--Ans. below are the starting five cohort month, activity month, relative_month_index, total_accounts, cohort_size, and cohort_retention_percentage


"2023-01-01"	"2023-01-01"	0	16	16	100.00
"2023-01-01"	"2023-02-01"	1	12	16	75.00
"2023-01-01"	"2023-03-01"	2	15	16	93.75
"2023-01-01"	"2023-04-01"	3	16	16	100.00
"2023-01-01"	"2023-05-01"	4	16	16	100.00

--solution.
with retention_percentage as (
select
date_trunc('month', a.signup_date):: date as cohort_month,
date_trunc('month', c.usage_date):: date  as activity_month,
((extract(year from c.usage_date))- extract(year from a.signup_date))*12
+ (extract(month from c.usage_date)- extract(month from a.signup_date))as relative_month_index,
count(distinct a.account_id) as total_accounts
from ravenstack_feature_usage c join ravenstack_subscriptions s
on c.subscription_id = s.subscription_id
join ravenstack_accounts a
on a.account_id = s.account_id
where date_trunc('month',c.usage_date)>=date_trunc('month',a.signup_date)
group by 1,2,3
)
select cohort_month,
activity_month,
relative_month_index,
total_accounts,
first_value(total_accounts) over(partition by cohort_month order by relative_month_index) as cohort_size,
round(
(total_accounts :: numeric / first_value(total_accounts) over(partition by cohort_month order by relative_month_index)) *100, 2)
as cohort_retention_percentage from retention_percentage
order by 1,2;