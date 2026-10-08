-- E-Commerce Sales Analysis using SQL
-- Database: MySQL 8+
-- Dataset: synthetic sample e-commerce orders generated for this project.

CREATE DATABASE IF NOT EXISTS ecommerce_sales;
USE ecommerce_sales;

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    customer_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_pct DECIMAL(5,2),
    total_amount DECIMAL(12,2),
    payment_method VARCHAR(30),
    status VARCHAR(30),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Load data:
-- In MySQL Workbench, import the three CSV files into their respective tables,
-- or replace the following section with your preferred CSV import method.

-- ============================================================
-- ANALYSIS QUERIES
-- ============================================================

-- 1. Basic order count
SELECT COUNT(*) AS total_orders
FROM orders;

-- 2. Total revenue from non-cancelled orders
SELECT ROUND(SUM(total_amount), 2) AS total_revenue
FROM orders
WHERE status <> 'Cancelled';

-- 3. Revenue by product category
SELECT
    p.category,
    ROUND(SUM(o.total_amount), 2) AS revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.status <> 'Cancelled'
GROUP BY p.category
ORDER BY revenue DESC;

-- 4. Top 10 products by revenue
SELECT
    p.product_name,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.total_amount), 2) AS revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.status <> 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- 5. Monthly revenue
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    ROUND(SUM(total_amount), 2) AS revenue
FROM orders
WHERE status <> 'Cancelled'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

-- 6. Average order value
SELECT
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM orders
WHERE status <> 'Cancelled';

-- 7. Revenue by city
SELECT
    c.city,
    COUNT(o.order_id) AS orders,
    ROUND(SUM(o.total_amount), 2) AS revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status <> 'Cancelled'
GROUP BY c.city
ORDER BY revenue DESC;

-- 8. Payment method analysis
SELECT
    payment_method,
    COUNT(*) AS orders,
    ROUND(SUM(total_amount), 2) AS revenue
FROM orders
WHERE status <> 'Cancelled'
GROUP BY payment_method
ORDER BY revenue DESC;

-- 9. Customers with more than 3 completed orders
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(o.order_id) AS completed_orders,
    ROUND(SUM(o.total_amount), 2) AS customer_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status <> 'Cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) > 3
ORDER BY customer_revenue DESC;

-- 10. Products whose revenue is above the average product revenue
WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(o.total_amount) AS revenue
    FROM products p
    JOIN orders o ON p.product_id = o.product_id
    WHERE o.status <> 'Cancelled'
    GROUP BY p.product_id, p.product_name
)
SELECT
    product_name,
    ROUND(revenue, 2) AS revenue
FROM product_revenue
WHERE revenue > (SELECT AVG(revenue) FROM product_revenue)
ORDER BY revenue DESC;

-- 11. Rank products within each category using a window function
WITH product_sales AS (
    SELECT
        p.category,
        p.product_name,
        SUM(o.total_amount) AS revenue
    FROM products p
    JOIN orders o ON p.product_id = o.product_id
    WHERE o.status <> 'Cancelled'
    GROUP BY p.category, p.product_name
)
SELECT
    category,
    product_name,
    ROUND(revenue, 2) AS revenue,
    DENSE_RANK() OVER (
        PARTITION BY category
        ORDER BY revenue DESC
    ) AS category_rank
FROM product_sales
ORDER BY category, category_rank;

-- 12. Running monthly revenue using a window function
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(total_amount) AS revenue
    FROM orders
    WHERE status <> 'Cancelled'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(revenue) OVER (ORDER BY month),
        2
    ) AS cumulative_revenue
FROM monthly_sales
ORDER BY month;

-- 13. Cancellation rate
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS cancellation_rate_pct
FROM orders;

-- 14. Find the highest-value completed order
SELECT
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    p.product_name,
    o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
WHERE o.status <> 'Cancelled'
ORDER BY o.total_amount DESC
LIMIT 1;
