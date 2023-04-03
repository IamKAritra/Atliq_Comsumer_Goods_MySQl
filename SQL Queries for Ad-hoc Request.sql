use gdb023;


/*1. Provide the list of markets in which customer
	 "Atliq Exclusive" operates its business in the APAC region.*/
     
select distinct market 
from 
	dim_customer 
where 
		customer="Atliq Exclusive"
		and region="APAC";


/*2. What is the percentage of unique product increase 
	 in 2021 vs. 2020? The final output contains these fields,
		 unique_products_2020
		 unique_products_2021 
		 percentage_chg*/
         
select
		count(distinct if(fiscal_year=2020,product_code,null))
        unique_product_2020,
        count(distinct if(fiscal_year=2021,product_code,null))
        unique_product_2021,
        round(abs(count(distinct if(fiscal_year=2020,product_code,null))-
				  count(distinct if(fiscal_year=2021,product_code,null)))/
                  count(distinct if(fiscal_year=2020,product_code,null))*100,2)
		percentage_chg
from fact_sales_monthly;


/*3. Provide a report with all the unique product counts
	 for each segment and sort them in descending order of product counts.
     The final output contains 2 fields, 
		 segment
		 product_count*/
		
select segment,count(product_code) as product_count
from 
	dim_product
group by
		segment
order by 	
		count(product_code)
        desc;


/*4. Follow-up: Which segment had the most increase in 
	 unique products in 2021 vs 2020? The final output contains these fields, 
		 segment 
		 product_count_2020
		 product_count_2021 
		 difference */

select 
		segment,
        count(distinct if(fiscal_year=2020,p.product_code,null)) product_count_2020,
		count(distinct if(fiscal_year=2021,p.product_code,null)) product_count_2021,
        abs(count(distinct if(fiscal_year=2021,p.product_code,null))-
        count(distinct if(fiscal_year=2020,p.product_code,null))) difference
from 
	dim_product p inner join fact_sales_monthly ms using(product_code)
group by 
		segment
order by 
		abs(count(distinct if(fiscal_year=2021,product_code,null))-
        count(distinct if(fiscal_year=2020,product_code,null))) desc;


/*5. Get the products that have the highest and lowest manufacturing costs. 
	 The final output should contain these fields, 
		 product_code 
		 product 
		 manufacturing_cost*/
         
select 
	  p.product_code,product,manufacturing_cost
from 
	fact_manufacturing_cost fm inner join dim_product p using (product_code)
where 
	 manufacturing_cost in
		((select max(manufacturing_cost) from fact_manufacturing_cost),
        (select min(manufacturing_cost) from fact_manufacturing_cost))
order by manufacturing_cost desc;


/*6. Generate a report which contains the top 5 customers 
	 who received an average high pre_invoice_discount_pct 
     for the fiscal year 2021 and in the Indian market. 
     The final output contains these fields, 
		 customer_code 
		 customer 
		 average_discount_percentage*/

         
select 
	  fp.customer_code,customer,concat((round(pre_invoice_discount_pct*100,2)),"%") average_discount_percentage
from 
	fact_pre_invoice_deductions fp inner join dim_customer c using (customer_code)
where 
	 pre_invoice_discount_pct > 
			(select avg(pre_invoice_discount_pct) 
            from fact_pre_invoice_deductions fp inner join dim_customer c using (customer_code)) 
            and market="india" and fiscal_year=2021
order by 
		pre_invoice_discount_pct desc
limit 5;


/*7. Get the complete report of the Gross sales amount for the customer 
“Atliq Exclusive” for each month . This analysis helps to get an idea 
of low and high-performing months and take strategic decisions. 
The final report contains these columns: 
	Month 
	Year 
	Gross sales Amount*/

select 
	  monthname(ms.date) Month ,year(ms.date) Year,sum(sold_quantity*gross_price)  `Gross sales Amount`
from 
	fact_gross_price gp inner join fact_sales_monthly ms on gp.product_code=ms.product_code
						inner join dim_customer c on ms.customer_code = c.customer_code
where 
	  customer="Atliq Exclusive"
group by 
		year(ms.date),month(ms.date)
order by 
		year(date) asc;

/*A error is poping with this query showing
	-- Error Code: 1055. Expression #1 of SELECT list is not in GROUP BY
	   clause and contains nonaggregated column 'gdb023.ms.date' 
       which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by
       This is because how mysql handle group by clause to avoid this error we can use this command */
 SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- OR

select 
	  monthname(ms.date) Month ,year(ms.date) Year,sum(sold_quantity*gross_price)  `Gross sales Amount`
from 
	fact_gross_price gp inner join fact_sales_monthly ms on gp.product_code=ms.product_code
						inner join dim_customer c on ms.customer_code = c.customer_code
where 
	  customer="Atliq Exclusive"
group by 
		year(ms.date),month(ms.date),monthname(ms.date)
order by 
		year(date) asc;
        

/*8. In which quarter of 2020, got the maximum total_sold_quantity? 
	 The final output contains these fields sorted by the total_sold_quantity,
		Quarter 
		total_sold_quantity*/


select 
		case
			when month in (9,10,11) then 'Q1'
			when month in (12,1,2) then 'Q2'
            when month in (3,4,5) then 'Q3'
            else 'Q4' end as Quarter,round(sum(total_quantity)/1000000,2) `total_sold_quantity_in_mln`
from 
	(select month(date) month,sum(sold_quantity) total_quantity 
	 from fact_sales_monthly 
	 where fiscal_year = 2020 
     group by month(date)) as a
group by Quarter
order by sum(total_quantity) desc;


/*9. Which channel helped to bring more gross sales in the fiscal year 2021 
	 and the percentage of contribution? The final output contains these fields,
		 channel 
		 gross_sales_mln 
		 percentage*/

select 
	  channel,gross_sales_mln,round(gross_sales_mln/sum(gross_sales_mln) over ()*100,2) percentage
from 
	(select 
			channel,round(sum(gross_price * sold_quantity)/1000000,2) gross_sales_mln
	 from fact_sales_monthly ms inner join fact_gross_price gp using (product_code) 
								inner join dim_customer c using(customer_code) 
	 where 
			ms.fiscal_year = 2021
	 group by channel
	 order by round(sum(gross_price * sold_quantity)/1000000,2) desc) a;
     
 /*10. Get the Top 3 products in each division that have a high total_sold_quantity
	   in the fiscal_year 2021? The final output contains these fields,
			   division 
			   product_code*/    
               
               
SELECT division, product_code, CONCAT(product, ' (', variant, ')') Product, total_sold_quantity, rank_order
FROM (
    SELECT division, p.product_code, product, variant,
           SUM(sold_quantity) total_sold_quantity,
           RANK() OVER (PARTITION BY division ORDER BY SUM(sold_quantity) DESC) rank_order
    FROM fact_sales_monthly ms
    INNER JOIN dim_product p USING (product_code)
    WHERE fiscal_year = 2021
    GROUP BY division, p.product_code, product, variant
) a
WHERE rank_order IN (1, 2, 3);
