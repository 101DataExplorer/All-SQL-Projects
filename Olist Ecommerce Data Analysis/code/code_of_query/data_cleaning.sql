

					-- Orders Table


SELECT * FROM olist_ecommerce.orders;


		-- order_purchase_timestamp

		
SELECT order_purchase_timestamp
FROM olist_ecommerce.orders
WHERE order_purchase_timestamp IS NULL OR order_purchase_timestamp = '';

SELECT COUNT(order_purchase_timestamp) -- 0
FROM olist_ecommerce.orders
WHERE order_purchase_timestamp IS NULL OR order_purchase_timestamp = '';



SELECT 
round(
(((AVG(EXTRACT(epoch FROM (order_purchase_timestamp::TIMESTAMP))))/60)/24),2)
FROM olist_ecommerce.orders;
;


				-- order_approved_at

SELECT COUNT(*)    -- 160 NULL values
FROM olist_ecommerce.orders
WHERE order_approved_at IS NULL OR order_approved_at = '';

SELECT order_approved_at
FROM olist_ecommerce.orders
WHERE order_approved_at IS NULL OR order_approved_at = '';

-- getting the average time between 

SELECT 
round(
((AVG(EXTRACT(epoch FROM (order_approved_at::TIMESTAMP - order_purchase_timestamp::TIMESTAMP))
) / 60)/ 60), 2)
FROM olist_ecommerce.orders
;

-- average time spend between order_purchase_timestamp and order_approved_at is 10.42 hours = 11 hours


-- Replacing the NULL value with the average time

UPDATE olist_ecommerce.orders
SET order_approved_at = (order_purchase_timestamp::TIMESTAMP + INTERVAL '11 hour')::TEXT
WHERE order_approved_at IS NULL OR order_approved_at = '';






			        			-- order_delivered_carrier_date
			        
			        
SELECT * FROM olist_ecommerce.orders;
			
SELECT COUNT(*) -- 1783
FROM olist_ecommerce.orders
WHERE order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '';
			
SELECT order_delivered_carrier_date 
FROM olist_ecommerce.orders
WHERE order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '';


-- getting the average time between 


SELECT 
round(
((((AVG(EXTRACT(epoch FROM (order_delivered_carrier_date::TIMESTAMP - order_approved_at::TIMESTAMP))
)) / 60) / 60) / 24), 2)
FROM olist_ecommerce.orders
;

-- average time spend between order_approved_at and order_delivered_carrier_date is 2.81 days = 3 days
-- Replacing the NULL value with the average time

UPDATE olist_ecommerce.orders
SET order_delivered_carrier_date = (order_approved_at::TIMESTAMP + INTERVAL '3 day')::TEXT
WHERE order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '';




							-- order_delivered_customer_date 
			
			
SELECT * FROM olist_ecommerce.orders;
			
SELECT COUNT(*) -- 2965
FROM olist_ecommerce.orders
WHERE order_delivered_customer_date IS NULL OR order_delivered_customer_date = '';
			
SELECT order_delivered_customer_date 
FROM olist_ecommerce.orders
WHERE order_delivered_customer_date IS NULL OR order_delivered_customer_date = '';


-- getting the average time between order_delivered_carrier_date and order_delivered_customer_date


SELECT 
round(
((((AVG(EXTRACT(epoch FROM (order_delivered_customer_date::TIMESTAMP - order_delivered_carrier_date::TIMESTAMP))
)) / 60) / 60) / 24), 2)
FROM olist_ecommerce.orders
;

-- average time spend between order_delivered_carrier_date and order_delivered_customer_date is 9.33 days = 10 days

-- Replacing the NULL value with the average time

UPDATE olist_ecommerce.orders
SET order_delivered_customer_date = (order_delivered_carrier_date::TIMESTAMP + INTERVAL '10 day')::TEXT
WHERE order_delivered_customer_date IS NULL OR order_delivered_customer_date = '';




SELECT * FROM olist_ecommerce.orders;

SELECT order_status, COUNT(*)
FROM olist_ecommerce.orders
GROUP BY 1
ORDER BY 2 DESC
;


SELECT COUNT(*) 
FROM olist_ecommerce.orders
WHERE order_delivered_customer_date IS NOT NULL;


SELECT order_status, order_delivered_customer_date
FROM olist_ecommerce.orders
WHERE order_delivered_customer_date IS NULL
AND order_status = 'delivered';




SELECT order_status, order_purchase_timestamp -- 96478
FROM olist_ecommerce.orders
WHERE order_status = 'delivered'
AND order_purchase_timestamp IS NOT NULL;

SELECT order_status, order_approved_at -- 96464
FROM olist_ecommerce.orders
WHERE order_status = 'delivered'
AND order_approved_at IS NOT NULL;

SELECT order_status, order_delivered_carrier_date -- 96476
FROM olist_ecommerce.orders
WHERE order_status = 'delivered'
AND order_delivered_carrier_date IS NOT NULL;

SELECT order_status, order_delivered_customer_date -- 96470
FROM olist_ecommerce.orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL;


SELECT COUNT(*)
FROM(
SELECT order_status
, order_purchase_timestamp
, order_approved_at
, order_delivered_carrier_date
, order_delivered_customer_date
FROM olist_ecommerce.orders
WHERE order_status = 'delivered'
AND order_purchase_timestamp IS NOT NULL
AND order_approved_at IS NOT NULL
AND order_delivered_carrier_date IS NOT NULL
AND order_delivered_customer_date IS NOT NULL) x
WHERE order_purchase_timestamp IS  NULL
AND order_approved_at IS  NULL
AND order_delivered_carrier_date IS  NULL
AND order_delivered_customer_date IS  NULL
;


SELECT order_status
, order_purchase_timestamp
, order_approved_at
, order_delivered_carrier_date
, order_delivered_customer_date
FROM olist_ecommerce.orders
WHERE order_purchase_timestamp IS NOT NULL
AND order_approved_at IS NULL
AND order_delivered_carrier_date IS NULL
AND order_delivered_customer_date IS NOT NULL;


-- Order Reviews
SELECT * FROM olist_ecommerce.order_reviews;

ALTER TABLE olist_ecommerce.order_reviews
ADD COLUMN english_review_title VARCHAR;

UPDATE olist_ecommerce.order_reviews
SET english_review_title = 'Not recommended'
WHERE review_score = 1;

SELECT  english_review_title
FROM olist_ecommerce.order_reviews
WHERE review_score = 1;


UPDATE olist_ecommerce.order_reviews
SET english_review_title = 'Regular'
WHERE review_score = 2;

SELECT  english_review_title
FROM olist_ecommerce.order_reviews
WHERE review_score = 2;


UPDATE olist_ecommerce.order_reviews
SET english_review_title = 'Satisfied'
WHERE review_score = 3;

SELECT  english_review_title
FROM olist_ecommerce.order_reviews
WHERE review_score = 3;


UPDATE olist_ecommerce.order_reviews
SET english_review_title = 'Recommended'
WHERE review_score = 4;

SELECT  english_review_title
FROM olist_ecommerce.order_reviews
WHERE review_score = 4;


UPDATE olist_ecommerce.order_reviews
SET english_review_title = 'Super Recommended'
WHERE review_score = 5;


SELECT  english_review_title
FROM olist_ecommerce.order_reviews
WHERE review_score = 5;

DELETE FROM olist_ecommerce.geolocation
WHERE geolocation_zip_code_prefix 
in(
	SELECT geolocation_zip_code_prefix
	FROM(
	SELECT geolocation_zip_code_prefix,
	ROW_NUMBER()OVER(PARTITION BY geolocation_zip_code_prefix) AS rnk
	FROM olist_ecommerce.geolocation
	)
	WHERE rnk > 1)
;

SELECT * FROM olist_ecommerce.geolocation;

CREATE TABLE olist_ecommerce.geolocation_backup
AS
SELECT * FROM olist_ecommerce.geolocation;

-- SELECT *
-- FROM olist_ecommerce.geolocation
-- WHERE geolocation_zip_code_prefix = ;
-- são paulo