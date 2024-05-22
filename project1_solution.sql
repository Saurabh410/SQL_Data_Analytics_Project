select * from credit_card_transcations

--1-write a query to print top 5 cities with highest spends 
--and their percentage contribution of total credit card spends 
;
with cte1 as (
select city,sum(amount) as total_spend
from credit_card_transcations
group by city)
,total_spent as (select sum(cast(amount as bigint)) as total_amount from credit_card_transcations)
select top 5 cte1.*, round(total_spend*1.0/total_amount * 100,2) as percentage_contribution from 
cte1 inner join total_spent on 1=1
order by total_spend desc

--2- write a query to print highest spend month and amount spent in that month for each card type
with cte as (
select card_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,datepart(year,transaction_date),datepart(month,transaction_date)
--order by card_type,total_spend desc
)
select * from (select *, rank() over(partition by card_type order by total_spend desc) as rn
from cte) a where rn=1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of  1,000,000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from credit_card_transcations
--order by card_type,total_spend desc
)
select * from (select *, rank() over(partition by card_type order by total_spend) as rn  
from cte where total_spend >= 1000000) a where rn=1

--4- write a query to find city which had lowest percentage spend for gold card type
with cte as (
select city,sum(case when card_type='Gold' then amount end) as gold_amount from credit_card_transcations group by city),
cte2 as (select sum(gold_amount) as total_gold from cte)
select top 1 city from (select city,(gold_amount*1.0/total_gold)*100 as per from cte inner join cte2 on 1=1) a order by per


--5- write a query to find percentage contribution of spends by females for each expense type
select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution
from credit_card_transcations
group by exp_type
order by percentage_female_contribution desc;

--6- which card and expense type combination saw highest month over month growth in Jan-2014
with cte as (
select card_type,exp_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
)
select  top 1 *, (total_spend-prev_mont_spend) as mom_growth
from (
select *
,lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc;

--7- during weekends which city has highest total spend to total no of transcations ratio 
select top 1 city , sum(amount)*1.0/count(1) as ratio
from credit_card_transcations
where datepart(weekday,transaction_date) in (1,7)
--where datename(weekday,transaction_date) in ('Saturday','Sunday')
group by city
order by ratio desc;

--8- which city took least number of days to reach its
--500th transaction after the first transaction in that city;

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transcations)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1





























