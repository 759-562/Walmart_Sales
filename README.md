# Walmart_Sales
![](istockphoto-1878347043-612x612.jpg)
## Project Overview

This project is an end-to-end data analysis solution designed to extract critical business insights from Walmart sales data.By utilizing Python for data processing and analysis, SQL for advanced querying, and structured problem solving techniques to solve key business questions.

## Results and Insights

This section will include your analysis findings:
- **Sales Insights**: Key categories, branches with highest sales, and preferred payment methods.
- **Profitability**: Insights into the most profitable product categories and locations.
- **Customer Behavior**: Trends in ratings, payment preferences, and peak shopping 

## QUESTIONS

### 1  What are the different payment methods, and how many transactions and items were sold with each method?

```sql
select payment_method , count(*) as numb_payment
from walmarts
group by payment_method
;
 ```

### 2 : Which category received the highest average rating in each branch

```sql
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
```


### 3 : What is the busiest day of the week for each branch based on transaction volume
```sql
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
```
 
### 4 how many items were sold through each payment method?
```sql
select count(quantity),payment_method
from walmarts
group by payment_method

;
```

### 5 What are the average, minimum, and maximum ratings for each category in each city?
```sql
select city,category,avg(rating),max(rating),min(rating)
from walmarts
 group by City,category
 order by city,category
 ;
 ```

 ### 6 What is the total profit for each category, ranked from highest to lowest?  create new column
 
 ```sql
select category,sum(total_profit) as final_profit
 from( 
 select category, `quantity`*`profit_margin` as total_profit
 from walmarts
 ) as sub3
group by category
order by sum(total_profit) desc
;
```

### 7 : What is the most frequently used payment method in each branch?
```sql
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
```

### 8 : How many transactions occur in each shift (Morning, Afternoon, Evening) across branches
```sql
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
```

### 9 Which branches experienced the largest decrease in revenue compared to the previous year?
```sql
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
```
