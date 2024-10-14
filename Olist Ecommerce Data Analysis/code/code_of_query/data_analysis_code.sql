
--  **Customer Analysis**

-- 1. What are the top 10 cities with the highest number of customers?

SELECT customer_city, count_of_customer FROM
(
SELECT customer_city, COUNT(DISTINCT customer_unique_id) AS count_of_customer,
DENSE_RANK()OVER(ORDER BY COUNT(customer_id) DESC) AS rnk
FROM olist_ecommerce.customers
GROUP BY 1) customer_count
WHERE rnk <= 10;

-- 2. What are the top 10 states with the highest number of customers?

SELECT customer_state, count_of_customer FROM
(
SELECT customer_state, COUNT(DISTINCT customer_unique_id) AS count_of_customer,
DENSE_RANK()OVER(ORDER BY COUNT(customer_id) DESC) AS rnk
FROM olist_ecommerce.customers
GROUP BY 1
) customer_count
WHERE rnk <= 10;

-- 3. What is the top city with highest number of customers in each state 

SELECT customer_state, customer_city, highest_customer_count_by_city
FROM
(
SELECT customer_state, customer_city, 
COUNT(DISTINCT customer_unique_id) AS highest_customer_count_by_city,
DENSE_RANK()OVER(PARTITION BY customer_state ORDER BY COUNT(DISTINCT customer_unique_id) DESC) AS rnk
FROM olist_ecommerce.customers
GROUP BY 1,2) customer_count
WHERE rnk = 1;

-- **Order Analysis**

-- 4. How has the order status distribution changed over time?

-- This query is written as per estimated delivery time
SELECT 
EXTRACT( YEAR FROM (CAST(order_estimated_delivery_date AS TIMESTAMP))) AS YEAR,
order_status, COUNT(order_id) AS order_count
FROM olist_ecommerce.orders
GROUP BY 1,2
ORDER BY 1;


-- **Order Timing Analysis**

-- 5. What is the average time between order purchase and approval?

SELECT 
concat(
(round(
(AVG(EXTRACT(epoch FROM (order_approved_at::TIMESTAMP - order_purchase_timestamp::TIMESTAMP)) 
) / 60 / 60), 2))::TEXT,' ', 'minutes'
)
AS average_time_between_order_purchase_and_approval
FROM olist_ecommerce.orders ;

-- 6. What is the average delivery time from order approval to customer delivery?

SELECT 
concat(
(round((((AVG(EXTRACT(epoch FROM (order_delivered_customer_date::TIMESTAMP - order_purchase_timestamp::TIMESTAMP))) / 60) / 60) / 24),2) ):: TEXT,
' ', 'days'
)
AS average_time_from_order_approval_to_customer_delivery

FROM olist_ecommerce.orders
WHERE order_purchase_timestamp IS NOT NULL
AND order_delivered_customer_date IS NOT NULL ;



-- **Order Volume Trends**

--  7. How does the number of orders vary by month and year?

SELECT * FROM olist_ecommerce.orders;

SELECT *,
DENSE_RANK()OVER(PARTITION BY YEAR ORDER BY count_of_orders DESC) AS "rank"
FROM(
	SELECT 
	EXTRACT(YEAR FROM order_purchase_timestamp::TIMESTAMP ) as YEAR
	,to_char(order_purchase_timestamp::TIMESTAMP, 'Mon') as MONTH
	,COUNT(*) AS count_of_orders
	FROM olist_ecommerce.orders
	GROUP BY 1,2
	ORDER BY 3 DESC)
;

--  8. What are the peak months for order placements?

SELECT YEAR, MONTH, count_of_orders
FROM
(
	SELECT *,
	DENSE_RANK()OVER(PARTITION BY YEAR ORDER BY count_of_orders DESC) AS "rank"
	FROM(
		SELECT 
		EXTRACT(YEAR FROM order_purchase_timestamp::TIMESTAMP ) as YEAR
		,to_char(order_purchase_timestamp::TIMESTAMP, 'Mon') as MONTH
		,COUNT(*) AS count_of_orders
		FROM olist_ecommerce.orders
		GROUP BY 1,2
		ORDER BY 3 DESC)
)
WHERE "rank" = 1
;


-- **Order Item Insights**

-- 9. What is the average number of items per order?

SELECT AVG(COUNT) AS avg_number_of_items
FROM(
	SELECT order_id, COUNT(order_item_id) AS COUNT
	FROM olist_ecommerce.order_items
	GROUP BY 1)
;

-- 10.Which products have the highest sales volume?

SELECT product_id, product_category_name_english, sales_volumn
FROM(
	SELECT oi.product_id
	,pcnt.product_category_name_english
	,COUNT(*) AS sales_volumn
	,DENSE_RANK()OVER(ORDER BY COUNT(*)DESC) AS rnk
	from olist_ecommerce.order_items oi
	JOIN olist_ecommerce.products p
	on oi.product_id = p.product_id
	JOIN olist_ecommerce.product_category_name_translation pcnt
	on p.product_category_name = pcnt.product_category_name
	GROUP BY 1,2
	ORDER BY 3 DESC)
WHERE rnk = 1
;


-- **Payment Analysis**

-- 11. What is the distribution of payment types used by customers?

SELECT payment_type, COUNT(payment_type) AS no_of_customer_used
FROM olist_ecommerce.order_payments
GROUP BY 1
ORDER BY 2 DESC;

-- 12. What is the average payment value and how does it vary by payment type


WITH avg_payment AS(
SELECT AVG(payment_value) AS average_payment FROM olist_ecommerce.order_payments
)
SELECT payment_type, 
AVG(payment_value) AS average_payment_by_payment_type,
(SELECT average_payment FROM avg_payment) AS average_payment
FROM olist_ecommerce.order_payments
WHERE payment_type != 'not_defined'
GROUP BY 1
ORDER BY 2 DESC;


-- **Review Score Analysis**

-- 13. What is the distribution of review scores?

SELECT english_review_title,review_score, COUNT(1) AS count_of_reviews
FROM olist_ecommerce.order_reviews
GROUP BY 1 , 2
ORDER BY 3 DESC
;

-- 14. How do review scores correlate with delivery times?


WITH review_score_delivery_time AS(
		SELECT _or.order_id
		, _or.review_score
		, _or.english_review_title
		,
		round((((EXTRACT
		(epoch FROM (o.order_delivered_customer_date::TIMESTAMP - o.order_purchase_timestamp::TIMESTAMP)) / 60) / 60) / 24)
		, 2) AS delivery_time_in_days
		
		FROM olist_ecommerce.order_reviews _or
		JOIN olist_ecommerce.orders o
		on _or.order_id = o.order_id
)

SELECT english_review_title, review_score, round(AVG(delivery_time_in_days),2) AS avg_delivery_time_in_days
FROM review_score_delivery_time
GROUP BY 1,2
ORDER BY 3
;


-- **Product Category Analysis**

-- 15. Which product categories have the highest sales?

SELECT product_category_name_english, total_sales  
FROM
(
	SELECT pcnt.product_category_name_english, 
	SUM(oi.price) AS total_sales,
	DENSE_RANK()OVER(ORDER BY SUM(oi.price) DESC) AS "rank"
	FROM olist_ecommerce.products p
	JOIN olist_ecommerce.order_items oi
	on p.product_id = oi.product_id
	JOIN olist_ecommerce.product_category_name_translation pcnt
	on p.product_category_name = pcnt.product_category_name
	GROUP BY 1)
WHERE "rank" = 1
;

-- 16. What is the average product rating by category?

SELECT pcnt.product_category_name_english, 
round(AVG(ore.review_score),2) AS avg_reveiw_score
FROM olist_ecommerce.order_items oi
JOIN olist_ecommerce.order_reviews ore
on oi.order_id = ore.order_id
JOIN olist_ecommerce.products p
on oi.product_id = p.product_id
JOIN olist_ecommerce.product_category_name_translation pcnt
on p.product_category_name = pcnt.product_category_name
GROUP BY 1
ORDER BY 2 DESC
;


-- **Product Dimension Analysis**

-- 17. What are the top 10 heaviest and lightest products?

WITH heaviest_products_cte AS(
		SELECT p.product_id AS heaviest_products , p.product_weight_g,
		pcnt.product_category_name_english,
		ROW_NUMBER()OVER(ORDER BY p.product_weight_g DESC) AS "rank"
		FROM olist_ecommerce.products p
		JOIN olist_ecommerce.product_category_name_translation pcnt
		on p.product_category_name = pcnt.product_category_name
		WHERE product_weight_g IS NOT NULL
	),

lightest_products_cte AS(
		SELECT p.product_id AS lightest_products, p.product_weight_g,
		pcnt.product_category_name_english,
		ROW_NUMBER()OVER(ORDER BY product_weight_g ASC) AS "rank"
		FROM olist_ecommerce.products p
		JOIN olist_ecommerce.product_category_name_translation pcnt
		on p.product_category_name = pcnt.product_category_name
		WHERE product_weight_g IS NOT NULL
		ORDER BY 2 ASC
	)

SELECT hp.heaviest_products, hp.product_category_name_english, hp.product_weight_g, lp.lightest_products, lp.product_category_name_english,
lp.product_weight_g
FROM heaviest_products_cte hp
JOIN lightest_products_cte lp
on hp."rank" = lp."rank"
WHERE hp."rank" <= 10 AND lp."rank" <= 10
;



-- **Seller Performance Analysis**

-- 18. Which sellers have the highest sales volume?

SELECT seller_id, sales_volume
FROM(
	SELECT seller_id, COUNT(product_id) AS sales_volume,
	DENSE_RANK()OVER(ORDER BY COUNT(product_id) DESC) "rank"
	FROM olist_ecommerce.order_items
	GROUP BY 1)
WHERE "rank" = 1
;

-- 19. Top 10 sellers with least average delivery time


SELECT seller_id, average_delivery_time_in_days
FROM
(
	SELECT oi.seller_id, 
	round(AVG(((EXTRACT( epoch FROM( o.order_delivered_customer_date::TIMESTAMP - 
	o.order_approved_at::TIMESTAMP )) / 60 )/ 60) / 24),2) AS average_delivery_time_in_days,
						 
	DENSE_RANK()OVER(ORDER BY (AVG(((EXTRACT( epoch FROM(o.order_delivered_customer_date::TIMESTAMP - 
	o.order_approved_at::TIMESTAMP )) / 60 )/ 60) / 24)
	) ASC) AS "rank"
	
	FROM olist_ecommerce.order_items oi
	JOIN olist_ecommerce.orders o
	on oi.order_id = o.order_id
	GROUP BY 1
)
WHERE "rank" <= 10
;


-- **Seller Location Analysis**

-- 20. How are sellers distributed across different cities?

SELECT seller_city, COUNT(seller_id) AS number_of_sellers
FROM olist_ecommerce.sellers
GROUP BY 1
ORDER BY 2 DESC;

-- How are sellers distributed across different states?

SELECT seller_state, COUNT(seller_id) AS number_of_sellers
FROM olist_ecommerce.sellers
GROUP BY 1
ORDER BY 2 DESC;

--     - What are the top cities with the highest number of sellers?

SELECT * FROM olist_ecommerce.sellers;

SELECT seller_city, number_of_sellers
FROM(
SELECT seller_city, COUNT(seller_id) AS number_of_sellers,
DENSE_RANK()OVER(ORDER BY COUNT(seller_id) DESC) AS "rank"
FROM olist_ecommerce.sellers
GROUP BY 1
)
WHERE "rank" = 1
;

-- 21. How does customer location influence order frequency and volume?


SELECT c.customer_city, AVG(geo.geolocation_lat) AS average_lat,
AVG(geo.geolocation_lng) AS average_lng ,COUNT(o.order_id) AS count_of_orders
FROM olist_ecommerce.customers c
JOIN olist_ecommerce.orders o
on c.customer_id = o.customer_id
JOIN olist_ecommerce.geolocation geo
on c.customer_state = geo.geolocation_state
GROUP BY 1
ORDER BY 4 DESC
;
-- There is no influence of customer location on order frequencey



-- **Geolocation and Delivery Correlation**
-- 22. How does geolocation (latitude and longitude) affect delivery times and shipping costs?


SELECT c.customer_city, AVG(g.geolocation_lat) AS average_lat,
AVG(g.geolocation_lng) AS average_lng,

round((((AVG(EXTRACT(epoch FROM (o.order_delivered_customer_date::TIMESTAMP
- o.order_approved_at::TIMESTAMP))
) / 60) / 60) / 24), 2)
AS average_delivery_time_in_days,
AVG(oi.freight_value) AS average_shipping_cost

FROM olist_ecommerce.customers c
JOIN olist_ecommerce.geolocation g
on c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
JOIN olist_ecommerce.orders o
on c.customer_id = o.customer_id
JOIN olist_ecommerce.order_items oi
on o.order_id = oi.order_id
GROUP BY 1
ORDER BY 5 ASC;

-- Both average delivery time and average shipping cost is not influnenced by the average lat and average lng


-- 23. Are there specific regions with consistently higher or lower delivery performance?

SELECT customer_state, "year", count_of_orders
FROM(
SELECT c.customer_state,
EXTRACT(YEAR FROM (o.order_delivered_customer_date::TIMESTAMP)) AS "year",
COUNT(o.order_id) AS count_of_orders,
ROW_NUMBER()OVER(PARTITION BY c.customer_state) AS "rank"
FROM olist_ecommerce.orders o
JOIN olist_ecommerce.customers c
on o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY 1,2)
;

-- Almost all states has consistently higher delivery performance



-- 24. Are there specific product categories that receive consistently higher or lower review scores?

SELECT pcnt.product_category_name_english, 
avg(or_.review_score) AS average_order_review_score
FROM olist_ecommerce.order_reviews or_
JOIN olist_ecommerce.order_items oi
on or_.order_id = oi.order_id
JOIN olist_ecommerce.products p
on oi.product_id = p.product_id
JOIN olist_ecommerce.product_category_name_translation pcnt
on p.product_category_name = pcnt.product_category_name
GROUP BY 1
ORDER BY 2 DESC;


-- **Seller and Payment Correlation**

-- 25. How does the choice of payment method vary by seller?

SELECT op.payment_type, COUNT(DISTINCT s.seller_id) AS count_of_sellers
FROM olist_ecommerce.order_payments op
JOIN olist_ecommerce.order_items oi
on op.order_id = oi.order_id
JOIN olist_ecommerce.sellers s
on oi.seller_id = s.seller_id
GROUP BY 1
ORDER BY 2 DESC;



