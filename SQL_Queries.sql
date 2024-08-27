#Q1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select 
customer,
market,
region
from dim_customer where customer = "Atliq Exclusive" and region = "APAC"
group by market;

#Q2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg
	
with cte1 as (
select count(distinct(product_code)) as up_20
from fact_sales_monthly where fiscal_year = 2020),
cte2 as 
(select count(distinct(product_code)) as up_21
from fact_sales_monthly where fiscal_year = 2021)
select 
cte1.up_20 as unique_products_2020,
cte2.up_21 as unique_products_2021,
round((cte2.up_21 - cte1.up_20)*100/cte1.up_20,2) as pct_change
from cte1, cte2;

#Q3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count

select
distinct(segment) as segment,
count(product) as product_count
from dim_product
group by segment
order by product_count desc;

#Q4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference
	
with cte1 as (
select
segment as segment,
count(distinct(p.product_code)) as product_count_2020
from dim_product p
join fact_sales_monthly s
on p.product_code = s.product_code
where s.fiscal_year = '2020'
group by p.segment, s.fiscal_year
),
cte2 as (
select
segment as segment,
count(distinct(p.product_code)) as product_count_2021
from dim_product p
join fact_sales_monthly s
on p.product_code = s.product_code
where s.fiscal_year = '2021'
group by p.segment, s.fiscal_year
) 
select 
cte1.segment as segment,
cte1.product_count_2020 as product_count_2020,
cte2.product_count_2021 as product_count_2021,
(cte2.product_count_2021-cte1.product_count_2020) as difference
from cte1,cte2
where cte1.segment = cte2.segment
order by difference desc;

#Q5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
product_code
product
manufacturing_cost
	
(select 
m.product_code as product_code,
p.product as product,
m.manufacturing_cost as manufacturing_cost
from dim_product p
join fact_manufacturing_cost m
on p.product_code = m.product_code
order by m.manufacturing_cost desc
limit 1)
union
(select 
m.product_code as product_code,
p.product as product,
m.manufacturing_cost as manufacturing_cost
from dim_product p
join fact_manufacturing_cost m
on p.product_code = m.product_code
order by m.manufacturing_cost asc
limit 1);

#Q6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
	
SELECT 
pre.customer_code as customer_code,
c.customer as customer,
round(avg(pre.pre_invoice_discount_pct)*100,2) as average_discount_percentage
from fact_pre_invoice_deductions pre
join dim_customer c
using (customer_code)
where c.market = 'India' and pre.fiscal_year = '2021'
group by pre.customer_code, pre.fiscal_year, c.customer
order by average_discount_percentage desc
limit 5;

#Q7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions. The final report contains these columns:
Month
Year
Gross sales Amount
	
select 
concat(monthname(s.date) , ' (', year(s.date), ')') as month,
s.fiscal_year as year,
round(sum(s.sold_quantity*g.gross_price),2) as gross_sales_amount
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code
join dim_customer c
on s.customer_code = c.customer_code
where c.customer = "Atliq Exclusive"
group by month, s.fiscal_year
order by s.fiscal_year;

#Q8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
	
select 
get_fiscal_quarter(date) as quarter,
round(sum(sold_quantity)/1000000,2) as total_sold_quantity_in_mln
from fact_sales_monthly
where fiscal_year = 2020
group by quarter
order by total_sold_quantity_in_mln desc;

#Q9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage

with cte1 as (
SELECT 
c.channel,
sum(s.sold_quantity*g.gross_price) as total_sales
from fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code
join fact_gross_price g
on s.product_code = g.product_code
where s.fiscal_year = '2021'
group by c.channel
order by total_sales desc)
select 
channel,
round(total_sales/1000000,2) as gross_sales_in_mln,
round((total_sales/sum(total_sales) over()) *100,2) as percentage
from cte1;


#Q10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
	
with cte1 as (
select
	p.division,
    p.product_code,
	p.product,
    sum(s.sold_quantity) as total_sold_quantity
from fact_sales_monthly s
join dim_product p
on p.product_code = s.product_code
where s.fiscal_year = '2021'
group by p.product, p.division, s.product_code),
cte2 as (
select 
division,
product_code,
product,
total_sold_quantity,
dense_rank() over(partition by division order by total_sold_quantity desc) as rank_order
from cte1 )
select 
cte1.division,
cte1.product_code,
cte1.product,
cte2.total_sold_quantity,
cte2.rank_order
from cte1
join cte2
on cte1.product_code = cte2.product_code
where cte2.rank_order in (1,2,3);

#'top_n_products_in_2021' is a stored procedure created for the above request(Q10). This gives the same output as the above query.
call top_n_products_in_2021(3, 2021);
