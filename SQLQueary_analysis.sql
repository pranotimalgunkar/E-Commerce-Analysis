select * from Orders_table
select  * from Order_items_table
select * from  Customers_review_table
select * from  Customers_table
select * from Payments_table
select * from Products_table
select * from  Sellers_table



---How much total money has the platform made so far, and how has it changed over time?

SELECT 
	SUM(oi.price) AS Total_sales_revenue
FROM 
	Order_items_table oi

---how has it changed over time

SELECT 
    SUM(oi.price) AS Total_sales_revenue,
    YEAR(o.order_purchase_timestamp) AS Years,
    MONTH(o.order_purchase_timestamp) AS Months
FROM
    Orders_table o
JOIN
    Order_items_table oi ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY 
    YEAR(o.order_purchase_timestamp), 
    MONTH(o.order_purchase_timestamp)
ORDER BY 
    Years, Months;


---identofying which city  has highest sales 
SELECT 
    c.customer_state,
    SUM(oi.price)  AS Total_sales_revenue
FROM
    Orders_table o
JOIN 
	Order_items_table oi ON o.order_id = oi.order_id
JOIN
    Customers_table c ON c.customer_id = o.customer_id
WHERE
    o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY Total_sales_revenue DESC;


---Which product categories are the most popular, and how do their sales numbers compare?
SELECT 
    p.product_category_name,
    SUM(oi.price)  AS Total_sales_revenue
FROM
    Order_items_table oi
        JOIN
    Products_table p ON p.product_id = oi.product_id
        JOIN
    Orders_table o ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY p.product_category_name 
ORDER BY Total_sales_revenue DESC;


---What is the average amount spent per order, and how does it change depending on the product category or payment method?
SELECT TOP 10
    p.product_category_name,
    pt.payment_type,
    (SUM(oi.price) / COUNT(DISTINCT o.order_id)) AS AOV
FROM 
    Products_table p
JOIN 
    Order_items_table oi ON oi.product_id = p.product_id
JOIN 
    Payments_table pt ON pt.order_id = oi.order_id
JOIN 
    Orders_table o ON o.order_id = pt.order_id
WHERE 
    o.order_status = 'delivered'
GROUP BY 
    p.product_category_name,
    pt.payment_type
ORDER BY 
    AOV DESC;




--Identify customers with the highest average order value (AOV). = ((sum)Total revenue/(count)Total no of orders)

SELECT TOP 5
    c.customer_id,
    (SUM(oi.price) / COUNT(DISTINCT (o.order_id))) AS AOV
FROM
    Customers_table c
        JOIN
    Orders_table o ON o.customer_id = c.customer_id
        JOIN
    Order_items_table oi ON oi.order_id = o.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY c.customer_id
ORDER BY AOV DESC


----How many active sellers are there on the platform, and does this number go up or down over time?
SELECT COUNT(DISTINCT seller_id) AS total_sellers
FROM Order_items_table;


SELECT
    YEAR(o.order_purchase_timestamp) AS year,
    MONTH(o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT oi.seller_id) AS active_sellers
FROM
    Orders_table o
JOIN 
    Order_items_table oi ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp)
ORDER BY
    year, month;


--What do seller ratings look like overall, and do higher ratings lead to better sales?

SELECT
    oi.seller_id,
    ROUND(AVG(r.review_score), 2) AS avg_seller_rating,
    COUNT(*) AS total_reviews
FROM
    Order_items_table oi
JOIN
    Customers_review_table r ON oi.order_id = r.order_id
GROUP BY
    oi.seller_id
ORDER BY
    avg_seller_rating DESC;

---checking relation with higher ratings and sales 
SELECT
    seller_stats.seller_id,
    seller_stats.avg_seller_rating,
    seller_stats.total_reviews,
    ROUND(SUM(oi.price), 2) AS total_sales
FROM
    (
        SELECT
            oi.seller_id,
            ROUND(AVG(r.review_score), 2) AS avg_seller_rating,
            COUNT(*) AS total_reviews
        FROM
            Order_items_table oi
        JOIN
            Customers_review_table r ON oi.order_id = r.order_id
        GROUP BY
            oi.seller_id
    ) AS seller_stats
JOIN
    Order_items_table oi ON seller_stats.seller_id = oi.seller_id
JOIN
    Orders_table o ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY
    seller_stats.seller_id, seller_stats.avg_seller_rating ,seller_stats.total_reviews
ORDER BY
	avg_seller_rating DESC,
    total_sales DESC;


---Which products sell the most, and how have their sales changed over time?


WITH ranked_sales AS (
    SELECT  
        pt.product_category_name,
        YEAR(o.order_purchase_timestamp) AS years,
        SUM(oi.price) AS total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(o.order_purchase_timestamp)
            ORDER BY SUM(oi.price) DESC
        ) AS rank
    FROM 
        Products_table pt
    JOIN 
        Order_items_table oi ON pt.product_id = oi.product_id
    JOIN 
        Orders_table o ON oi.order_id = o.order_id
    WHERE 
        o.order_status = 'delivered'
    GROUP BY 
        pt.product_category_name,
        YEAR(o.order_purchase_timestamp)    
)

SELECT 
    product_category_name,
    years,
    total_sales
FROM 
    ranked_sales
WHERE 
    rank <= 5
ORDER BY years, total_sales DESC;



---Do customer reviews and ratings help products sell more or perform better on the platform? 
---(Check sales with higher or lower ratings and identify if any correlation is there)
SELECT
    oi.product_id,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(r.review_id) AS total_reviews
FROM
    Order_items_table oi
JOIN
    Customers_review_table r ON oi.order_id = r.order_id
GROUP BY
    oi.product_id

--Check sales with higher or lower ratings
SELECT
	pt.product_category_name,
	oi.product_id,
	ROUND(AVG(c.review_score), 2) AS avg_rating,
	COUNT(c.review_score) AS total_reviews,
	ROUND(SUM(oi.price),2) AS total_sales
FROM
	 Products_table pt
JOIN
	Order_items_table oi ON oi.product_id = pt.product_id
JOIN 
    Orders_table o ON o.order_id = oi.order_id
JOIN 
	Customers_review_table c ON  c.order_id=o.order_id
WHERE 
    o.order_status = 'delivered'
GROUP BY 
	pt.product_category_name,
	oi.product_id
ORDER BY
    total_sales desc;


---
SELECT * FROM Customers_table;

---Find the most loyal customers by calculating their purchase frequency(Total no of orders/ distinct(total no of customers) and total spend.
select min(order_delivered_customer_date), max(order_delivered_customer_date) from Orders_table;

SELECT TOP 10
    c.customer_id,
    (COUNT(o.order_id) / COUNT(DISTINCT (c.customer_id))) AS purchase_freq,
    SUM(oi.price) AS total_spend
FROM
    Customers_table c
        JOIN
    Orders_table o ON o.customer_id = c.customer_id
        JOIN
    Order_items_table oi ON oi.order_id = o.order_id
WHERE
    o.order_delivered_customer_date BETWEEN '2016-10-11 13:46:00' AND '2018-10-17 13:22:00'
GROUP BY c.customer_id
ORDER BY purchase_freq DESC , total_spend DESC;



--Analyze delivery performance by calculating the average delivery time by region.

SELECT 
    c.customer_state,
    c.customer_city,
    ROUND(AVG(DATEDIFF(DAY,o.order_purchase_timestamp, o.order_delivered_customer_date)), 2) AS avg_delivery_time_days
FROM
    Customers_table c
        JOIN
    Orders_table o ON o.customer_id = c.customer_id
WHERE 
    o.order_delivered_customer_date IS NOT NULL AND 
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_estimated_delivery_date) >= 0
GROUP BY c.customer_state , c.customer_city
ORDER BY  avg_delivery_time_days asc;
	
---Calculate Average delivery time 
SELECT  
	(AVG(DATEDIFF(DAY,o.order_purchase_timestamp, o.order_delivered_customer_date))) AS avg_delivery_time_days
FROM  Orders_table o 
WHERE 
    o.order_status = 'delivered'
 

---Identify regions or products with the highest delivered rates. = (No. of Orders delivered/ Total no of orders places) * 100

WITH cte AS (
    SELECT 
        c.customer_state AS Region,
        COUNT(oi.order_id) AS delivered_orders
    FROM Customers_table c 
    JOIN Orders_table o ON c.customer_id = o.customer_id
    JOIN Order_items_table oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
),
cte_total_orders AS (
    SELECT 
        c.customer_state AS Region,
        COUNT(oi.order_id) AS total_orders
    FROM Customers_table c
    JOIN Orders_table o ON c.customer_id = o.customer_id
    JOIN Order_items_table oi ON oi.order_id = o.order_id
    GROUP BY c.customer_state
)
SELECT 
    cte.Region,
    ROUND((CAST(cte.delivered_orders AS FLOAT) / cte_total_orders.total_orders) * 100, 2) AS Delivery_Rate_Percentage
FROM 
    cte 
JOIN 
    cte_total_orders ON cte.Region = cte_total_orders.Region
ORDER BY 
    Delivery_Rate_Percentage DESC;


---Analyze the seasonality of sales to identify peak months.

WITH cte AS (
    SELECT 
        YEAR(o.order_delivered_customer_date) AS years,
        MONTH(o.order_delivered_customer_date) AS months,
        SUM(oi.price) AS Sales
    FROM Orders_table o
    JOIN Order_items_table oi ON oi.order_id = o.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
    GROUP BY 
        YEAR(o.order_delivered_customer_date), 
        MONTH(o.order_delivered_customer_date)
),

cte_rank AS (
    SELECT 
        cte.*, 
        DENSE_RANK() OVER (PARTITION BY cte.years ORDER BY cte.Sales DESC) AS RA
    FROM cte
)

SELECT 
    * 
FROM 
    cte_rank
WHERE 
    RA <= 3
ORDER BY 
    years, RA;

