select * from walmarts
;

select count(*) from walmarts
;

select payment_method ,
count(*) as total,
sum(count(*)) over (order by count(*) desc ) as runing_sum
from walmarts
group by payment_method ;

select Branch, count(*)
from walmarts
group by Branch
;

-- 1  What are the different payment methods, and how many transactions and items were sold with each method?

select payment_method , count(*) as numb_payment
from walmarts
group by payment_method
;

-- 2  Which category received the highest average rating in each branch
select *
from
( select
Branch,category,avg(rating) as avg_r,
rank() over(partition by Branch order by avg(rating) desc) as rank_
from walmarts
group by 1,2
) as sub
where rank_ = 1
;


-- 3 : What is the busiest day of the week for each branch based on transaction volume

 select *
 from(
 select
 Branch,
 dayname(str_to_date(date, '%d/%m/%Y')) as day_in_week,
 count(*) as no_transactions,
 rank() over(partition by Branch order by count(*) desc) as rank_is
 from walmarts
 group by Branch,day_in_week
 order by Branch,no_transactions desc
 ) as sub2
 where rank_is = 1
 ;
 
 -- 4 how many items were sold through each payment method?
select count(quantity),payment_method
from walmarts
group by payment_method

;

-- 5 What are the average, minimum, and maximum ratings for each category in each city?

select city,category,avg(rating),max(rating),min(rating)
from walmarts
 group by City,category
 order by city,category
 ;
 
 -- 6 What is the total profit for each category, ranked from highest to lowest?  create new column
 
 
select category,sum(total_profit) as final_profit
 from( 
 select category, `quantity`*`profit_margin` as total_profit
 from walmarts
 ) as sub3
group by category
order by sum(total_profit) desc
;

-- 7 : What is the most frequently used payment method in each branch?
select Branch,payment_method,frequency
from 
(
select Branch,
payment_method,count(*) as frequency,
dense_rank() over (partition by Branch order by count(*) desc) as ranking
from walmarts
group by Branch,payment_method
) as s3
where ranking = 1
;

-- 8 : How many transactions occur in each shift (Morning, Afternoon, Evening) across branches

update walmarts
SET shift = CASE
    WHEN STR_TO_DATE(`time`, '%H:%i:%s') BETWEEN STR_TO_DATE('06:00:00', '%H:%i:%s') AND STR_TO_DATE('11:59:59', '%H:%i:%s') THEN 'Morning'
    WHEN STR_TO_DATE(`time`, '%H:%i:%s') BETWEEN STR_TO_DATE('12:00:00', '%H:%i:%s') AND STR_TO_DATE('17:59:59', '%H:%i:%s') THEN 'Afternoon'
    WHEN STR_TO_DATE(`time`, '%H:%i:%s') BETWEEN STR_TO_DATE('18:00:00', '%H:%i:%s') AND STR_TO_DATE('23:59:59', '%H:%i:%s') THEN 'Evening'
    ELSE 'Night'
END
;

select shift,count(invoice_id) as total_sale
from walmarts
group by shift
;


-- 9 Which branches experienced the largest decrease in revenue compared to the previous year?

WITH branch_year_revenue AS (
  SELECT
    Branch,
    YEAR(`date`) AS year,
    SUM(total) AS total_revenue
  FROM walmarts
  GROUP BY Branch, YEAR(`date`)
),
latest_year AS (
  SELECT MAX(year) AS max_year FROM branch_year_revenue
),
revenue_with_lag AS (
  SELECT
    byr.Branch,
    byr.year,
    byr.total_revenue AS current_year_revenue,
    LAG(byr.total_revenue) OVER (PARTITION BY byr.Branch ORDER BY byr.year) AS previous_year_revenue
  FROM branch_year_revenue byr
),
revenue_diff AS (
  SELECT
    Branch,
    year,
    current_year_revenue,
    previous_year_revenue,
    ROUND(current_year_revenue - previous_year_revenue, 2) AS revenue_difference
  FROM revenue_with_lag
  WHERE previous_year_revenue IS NOT NULL
)
SELECT *
FROM revenue_diff
WHERE year = (SELECT max_year FROM latest_year)
ORDER BY revenue_difference ASC  -- ascending to get biggest negative (max decrease)
LIMIT 1;

