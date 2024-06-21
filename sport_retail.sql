DROP DATABASE IF EXISTS sport_retail;
CREATE DATABASE sport_retail;

USE sport_retail;

-- Count the total number of products, along with the number of non-missing values in description, listing_price, and last_visited
SELECT
  COUNT(i.product_id) AS total_rows, -- Count all rows
  COUNT(i.description) AS count_description,
  COUNT(f.listing_price) AS count_listing_price,
  COUNT(t.last_visited) AS count_last_visited
FROM info i
LEFT JOIN traffic t ON t.product_id = i.product_id
LEFT JOIN finance f ON f.product_id = i.product_id;


-- Find out how listing_price varies between Adidas and Nike products.
SELECT brands.brand,
       finance.listing_price,
       COUNT(finance.product_id) AS product_count -- Count the number of products for each brand-price combination
FROM brands
INNER JOIN finance
  ON finance.product_id = brands.product_id
WHERE finance.listing_price > 0 -- Filter for products with a listing price greater than 0
GROUP BY brands.brand, finance.listing_price
ORDER BY finance.listing_price ASC;



-- Create labels for products grouped by price range and brand.
SELECT
  b.brand,
  COUNT(f.product_id) AS product_count,
  SUM(f.revenue) AS total_revenue,
  CASE WHEN f.listing_price < 50 THEN 'Budget' -- Assign price category based on listing price
    WHEN f.listing_price >= 50 AND f.listing_price < 80 THEN 'Average'
    WHEN f.listing_price >= 80 AND f.listing_price < 150 THEN 'Expensive'
    ELSE 'Elite' END AS price_category
FROM finance AS f
INNER JOIN brands AS b 
ON f.product_id = b.product_id
WHERE b.brand IS NOT NULL -- Filter for brands with a name (not NULL)
GROUP BY b.brand, price_category 
ORDER BY total_revenue ASC; -- Order results by total revenue in descending order (lowest to highest)

-- Calculate the average discount offered by brand.
SELECT
  b.brand,
  AVG(discount) AS average_discount  -- Calculate the average discount
FROM finance AS f
INNER JOIN brands AS b 
  ON f.product_id = b.product_id
GROUP BY b.brand;

-- Split description into bins in increments of one hundred characters, and calculate average rating by for each bin.
SELECT
  FLOOR(LENGTH(i.description) / 100) * 100 AS description_length,  -- Bin size (multiple of 100 characters)
  ROUND(AVG(r.rating), 2) AS average_rating -- Average rating within each bin
FROM info AS i
INNER JOIN reviews AS r 
  ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;

-- Count the number of reviews per brand per month.
SELECT
  EXTRACT(MONTH FROM t.last_visited) AS month, -- Extract month from last visit date
  b.brand,
  COUNT(*) AS review_count -- Count of reviews
FROM brands AS b
INNER JOIN traffic AS t 
  ON b.product_id = t.product_id
INNER JOIN reviews AS r 
  ON t.product_id = r.product_id
WHERE EXTRACT(MONTH FROM t.last_visited) IS NOT NULL -- Filter for visits with month data
GROUP BY EXTRACT(MONTH FROM t.last_visited), b.brand -- Group by month and brand for counting
ORDER BY b.brand, month;

-- Create the footwear CTE, then calculate the number of products and average revenue from these items.
WITH footwear AS (  -- Define a temporary named result set called "footwear"
  SELECT i.description, f.revenue
  FROM info AS i
  INNER JOIN finance AS f 
    ON i.product_id = f.product_id
  WHERE i.description LIKE '%shoe%' -- Filter for descriptions containing "shoe"
      OR i.description LIKE '%trainer%'
      OR i.description LIKE '%foot%'
      AND i.description IS NOT NULL -- Ensure descriptions are not empty to avoid calculation errors
)
SELECT -- Select data from the "footwear" result set
  COUNT(*) AS num_products,
  ROUND(AVG(revenue), 3) AS average_revenue -- Calculate the average revenue, rounded to 3 decimal places
FROM footwear;

-- Copy the code used to create footwear then use a filter to return only products that are not in the CTE.
WITH footwear AS (
  SELECT i.description, f.revenue
  FROM info AS i
  INNER JOIN finance AS f 
    ON i.product_id = f.product_id
  WHERE i.description LIKE '%shoe%'
      OR i.description LIKE '%trainer%'
      OR i.description LIKE '%foot%'
      AND i.description IS NOT NULL
)

SELECT -- Select data, but this uses the original "info" and "finance" tables (not the filtered "footwear")
  COUNT(*) AS num_products,
  ROUND(AVG(revenue), 3) AS average_revenue
FROM info AS i
LEFT JOIN finance AS f on i.product_id = f.product_id
WHERE i.description NOT IN (SELECT description FROM footwear);