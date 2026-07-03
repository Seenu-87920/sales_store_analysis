CREATE TABLE sales_store(
transaction_id VARCHAR(15),	
customer_id VARCHAR(15),
customer_name VARCHAR(30),
customer_age INT,
gender VARCHAR(15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode VARCHAR(15),
purchase_date DATE,
time_of_purchase TIME,
status VARCHAR(15)

);

SELECT * FROM sales_store

SET DATEFORMAT dmy
BULK INSERT sales_store
FROM 'C:\Users\srivanas\Downloads\sales_store.csv'
    WITH (
         FIRSTROW=2,
         FIELDTERMINATOR=',',
         ROWTERMINATOR='\n'
         );


--- DATA CLEANING 
SELECT * FROM sales_store
--- for no loss of data we created as sales (for safer side --  backup)
SELECT * INTO sales FROM sales_store

SELECT * FROM sales_store
SELECT * FROM sales ---(BACKUP)

---Data cleaning 

-- step1 : check for dpilicates

SELECT transaction_id,COUNT(*)
FROM sales
GROUP BY transaction_id
HAVING count(transaction_id) >1
---
TXN240646
TXN342128
TXN855235
TXN981773
----

WITH CTE AS (
SELECT *,
      ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id) AS Row_num
FROM sales
)

-- delecting records 
--DELETE FROM CTE 
--WHERE Row_num='2'

SELECT * FROM CTE 
WHERE transaction_id IN ('TXN240646','TXN342128','TXN855235','TXN981773')

-- step 1 completed remove duplicated values / rows

-- step 2: correction of headers 
-- in this quntity is like quantiy and price like prce so we need to do

SELECT * FROM sales

EXEC sp_rename'sales.quantiy','quantity','COLUMN'

EXEC sp_rename'sales.prce','price','COLUMN'

--- step 3: check data types 
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='sales'

--- step 4: null values

-- to check null count and null values


DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
            COUNT(*) AS NullCount
     FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales
     WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
    ' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';

-- Execute the dynamic SQL
EXEC sp_executesql @SQL;


---  treating null values

SELECT *
FROM sales
WHERE transaction_id is null
OR
customer_id is null
or
customer_name is null
or
customer_age is null
or 
gender is null
or 
product_id is null
or 
product_name is null 
or 
product_category is null
or
quantity is null
or 
price is null
or 
payment_mode is null
or 
payment_mode is null
or
purchase_date is null
or 
time_of_purchase is null
or
status is null


DELETE FROM sales
WHERE transaction_id IS NULL

SELECT * FROM sales
where customer_name='Ehsaan Ram'

UPDATE sales
SET customer_id='CUST9494'
WHERE transaction_id='TXN977900'

SELECT * FROM sales
where customer_name='Damini Raju'

UPDATE sales
SET customer_id='CUST1401'
WHERE transaction_id='TXN985663'

SELECT * FROM sales
where customer_id='CUST1003'

UPDATE sales
SET customer_name='Mahika Saini', customer_age='35',gender='Male'
WHERE transaction_id='TXN432798'


SELECT * FROM sales


--STEP 5: DATA CLEANING (in gender one place F / Female like there na so)

SELECT DISTINCT gender
FROM sales

UPDATE sales
SET gender='M'
WHERE gender='Male'

SELECT DISTINCT payment_mode
FROM sales

UPDATE sales
SET payment_mode='Credit Card'
WHERE payment_mode='CC'


UPDATE sales
SET gender='F'
WHERE gender='Female'


---completed data cleaning i.e step 3


--- solving business insights questions

--data analysis--

---1. What are the top 5 most selling products by quantity?

SELECT * FROM sales
SELECT DISTINCT status
from sales

SELECT TOP 5 product_name,SUM(quantity) AS total_quantity_sold
FROM sales
WHERE status='delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC

--BUSINESS problem: we dont know which product are most demand.
-- Businesss impact : helps periortize stock and boost sales through target promotions.

---2. Which product are most frequently cancelled?

SELECT TOP 5 product_name,count(*) AS  total_canceled
FROM sales
WHERE status='cancelled'
GROUP BY product_name
ORDER BY total_canceled DESC

--BUSINESS problem: Frequent cancellations after revenu and coustomer trust.
-- Businesss impact : identify poor performing products to improve quality or remove from catalog.


--3.what time of the day has the  highest number of purchases?

select * from sales
   SELECT
       CASE
          when datepart(hour,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
          when datepart(hour,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
          when datepart(hour,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTRNOON'
          when datepart(hour,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
          END AS time_of_day,
          count(*) AS total_orders
    from sales
    GROUP BY
          CASE
            when datepart(hour,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
            when datepart(hour,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
            when datepart(hour,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTRNOON'
            when datepart(hour,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
            END
ORDER BY total_orders DESC
          
---Bsusiness problem solved :  Find peak sales time.
-- business impacts: Optimizing stuffing ,promotions, and server loads.


--4. who are top 5 highest spending customers?
 
 SELECT * FROM sales

 SELECT TOP 5 customer_name,
    FORMAT(sum(price*quantity),'C0','end-in') as total_spend
 from sales
 GROUP BY customer_name
 order by total_spend DESC

 -- business problem solved : identify VIP customers.
 -- business impact: persnalized offers, loyality awards and retention.


 --5. Which product categories  is generates highest revenu?

 SELECT * FROM sales

 SELECT product_category,
      FORMAT(sum(price*quantity),'C0','end-in') as revenu
 from sales
 group by product_category
 order by sum(price*quantity) desc

 --- BUSINESS problem solved : identify the top performing product catogories.
 --- business imapct: refine product stratagies, supply cahin and promotions
 -------------------- allowing the business to invest more in high margin or high demand categories.


 ---6. What is the return/cancellation rate per  product category?

 select * from sales
 --cancellation
 select  product_category,
       format(count( case when status='cancelled' then 1 end)*100.0/ count(*),'N3')+' %' as cancle_percent
from sales
group by product_category
order by cancle_percent desc

--- returned
select  product_category,
       format(count( case when status='returned' then 1 end)*100.0/ count(*),'N3')+' %' as return_percent
from sales
group by product_category
order by return_percent desc

--business problem solved :  Monitor disstaisfaction trends per category.

-- business imapct: reduce returns,improve product discription/exceptions
--------------------helps identify and fix problems or logistics issues.

---7.What is the most preferred payment mode?

select * from sales

select payment_mode,count(payment_mode) as prefer_mode
from sales
group by payment_mode
order by prefer_mode desc

-- business problem solved : knows  which payment mode customer most use/prefer.
-- business imapct : streamline payment processing, periortize popular mode.

---8. how does the age group affect purchase behaviour?

select * from sales

select min(customer_age), max(customer_age)
from sales
select 
     case
         when customer_age between 18 and 25 then '18-25'
         when customer_age between 26 and 35 then '26-35' 
         when customer_age between 36 and 50 then '36-50'
         else '51+'
     end as customer_age,
      format(sum(price*quantity), 'C0','end-in') as total_purchase
from sales
group by 
         case
         when customer_age between 18 and 25 then '18-25'
         when customer_age between 26 and 35 then '26-35' 
         when customer_age between 36 and 50 then '36-50'
         else '51+'
     end
order by total_purchase desc


---business problem solved: understand customer demographics.

--- business impact: trageted marketing and product recomandations by a group.


-- 9.what's is monthly sales trend?

select * from sales

---method 1

select 
    format(purchase_date,'yyyy-MM') as month_year,
    format(sum(price*quantity),'C0','end-in') as total_sales,
    sum(quantity) as quantity
from sales
group by format(purchase_date,'yyyy-MM')

--- method 2
select * from sales

select 
     --year(purchase_date) as years,
     month(purchase_date) as months,
     format(sum(price*quantity),'C0','end-in') as total_sales,
     sum(quantity) as quantity
from sales
group by month(purchase_date)
order by months


--- business problmed solved: sales fluctuations go noticed
--- business impact: plan inventory and marketing according to seasonal trends.

--10. Are certain genders buying more specific product category?
select * from sales
--method 1
select gender, product_category,count(product_category) as total_purchase
from sales
group by gender,product_category
order by gender

-- method 2

select * from sales

select *
      from( select gender, product_category
from sales
      ) as source_table
pivot(
count(gender)
for gender in ([M],[F])
)as pivot_table

order by product_category

---business poblem solved: gender based product preferences.    
---business imact: persinalized ads,gender focused compsigens.




     









