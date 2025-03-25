--Project description 
--The project describe about the spending habit of customers using credit card with in the time period of 2013 to 2015
--I have used Advance SQL to derive insight from the data such as top cities with highest spends ,highest spend month,
--expense types and cardholder behavior from a dataset containing over 26,000 transactions.
--I have used the dataset on Keggle , link :
--https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india

create database credit_card_transaction

use credit_card_transaction
--drop table credit_card_transaction
--data available for 2013 ,2014,2015
--Silver,Signature,Gold,Platinum
--exploring the dataset
/*
select 
* 
from [dbo].[CC_transactions]

select 
	datepart(year,date) as year
from [dbo].[CC_transactions]
group by datepart(year,date) 

select 
	card_type
from [dbo].[CC_transactions]
group by card_type

select 
	city
from [dbo].[CC_transactions]
group by city
*/

--1- write a query to print top 5 cities with highest spends 
-- and their percentage contribution of total credit card spends 

with city_spend as  --city wise spend
(
select
city
,sum(amount) as spend
,ROW_NUMBER() over(order by sum(amount) desc) as rn
from [dbo].[CC_transactions]
group by city
),

top_5_city_spend as 
(
select 
city
, spend
from city_spend
where rn <=5
),

total_spend as
(select
sum(amount) as total_spend
from [CC_transactions]
)

select 
city as top_city
,spend
,round((spend/total_spend*100),2) as ptc_cont
from top_5_city_spend join total_spend on 1=1

--2- write a query to print highest spend month and amount spent in that month for each card type

with top_spend_month as 
(
select
datepart(month,[transaction_date]) as spend_month
,DATENAME(month,[transaction_date]) as month_name
,datepart(Year,[transaction_date]) as Year
,sum(amount) as spend
,row_number()over(order by sum(amount) desc) as rn
from [CC_transactions]
group by datepart(month,[transaction_date])
	,DATENAME(month,[transaction_date])
	,datepart(Year,[transaction_date])
),

highest_spend_month as 
(
select 
month_name
,year
,spend
from top_spend_month
where rn=1
),

card_type as -- card_type needs to have filter for month jan & year 2015 as this is the highest spend month
(
select 
card_type
,sum(amount) as card_spend
from [CC_transactions]
where datepart(month,transaction_date) =1 and datepart(year,transaction_date) = 2015
group by card_type
)

select 
H.*
,C.*
from highest_spend_month H join card_type C on 1=1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cumm_sum_card as 
(
select 
*
,sum(amount)over(partition by card_type order by [transaction_date],[transaction_id]) as cummulative_sum
from [dbo].[CC_transactions]
),
rank as 
(
select 
*
,rank()over(partition by card_type order by cummulative_sum asc) as rn
from cumm_sum_card
where cummulative_sum >= 1000000
)
select * from rank where rn=1

--4- write a query to find city which had lowest percentage spend for gold card type
with total_spend as
(
select
sum(amount) as total_spend
from [dbo].[CC_transactions]
where card_type='gold'
),

total_spend_city as 
(
select
city
,sum(amount) as total_spend_city
from [dbo].[CC_transactions]
where card_type='gold'
group by city
),

lowest_spend_city as 
(
select
city
,total_spend_city
,(total_spend_city/total_spend)*100 as pct_spend
,ROW_NUMBER()over(order by (total_spend_city/total_spend)*100) as rn
from total_spend join  total_spend_city on 1=1
)

select * from lowest_spend_city 
where rn=1

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with city_data as
(
select distinct
city
,[exp_type]
,sum(amount) as total_spend
,row_number() over(partition by city order by sum(amount) desc ) as rn_highest
,row_number() over(partition by city order by sum(amount) asc ) as rn_lowest

from [CC_transactions]
group by city
,[exp_type]
)

select
city
,max(case when rn_highest = 1 then exp_type end )as highest_expense_type
,max(case when rn_lowest = 1 then exp_type end )as lowest_expense_type
from city_data
group by 
city