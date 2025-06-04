-- CLEAN DATA

-- CUSTOMERS TABLE CLEANING 

Select *
from customers;

-- check for nulls - (none found)

select *
from customers
where CustomerID is null
or CustomerName is null
or Region is null
or SignupDate is null;


-- check for duplicates - (none found)

select CustomerID, CustomerName, Region, SignupDate, count(*)
from customers
group by CustomerID, CustomerName, Region, SignupDate
having count(*) > 1;

-- check for any duplicates in the primary key - (none found)

select CustomerID, count(*)
from customers
group by CustomerID
having count(*) > 1;

-- change date to date format

-- create backup column
alter table customers add column SignupDate_backup Varchar(255);

update customers set SignupDate_backup = SignupDate;


update customers
set SignupDate = str_to_date(SignupDate, '%Y/%m/%d');

alter table customers
modify column SignupDate Datetime;


-- PRODUCTS TABLE CLEANING

select *
from products;

-- check for nulls - (none found)

select *
from products
where ProductID is null
or ProductName is null
or Category is null
or Price is null;

-- check for duplicates - (none found)

select ProductID, ProductName, Category, Price, count(*)
from products
group by ProductID, ProductName, Category, Price
having count(*) > 1;

-- check for any duplicates in the primary key - (none found)

select ProductID, count(*)
from products
group by ProductID
having count(*) > 1;

-- TRANSACTIONAL TABLE CLEANING

select *
from transactional;

-- check for nulls - (none found)

select *
from transactional
where TransactionID is null
or CustomerID is null
or ProductID is null
or TransactionDate is null
or Quantity is null
or Price is null
or TotalValue is null;

-- check for duplicates - (none found)

select TransactionID, CustomerID, ProductID, TransactionDate, Quantity, Price, TotalValue, count(*)
from transactional
group by TransactionID, CustomerID, ProductID, TransactionDate, Quantity, Price, TotalValue
having count(*) > 1;

-- check for any duplicates in the primary key - (none found)

select TransactionID, count(*)
from transactional
group by TransactionID
having count(*) > 1;

-- change date to date format

-- create backup column
alter table transactional add column TransactionDate Varchar(255);

update transactional set TransactionDate_backup = TransactionDate;

update transactional
set TransactionDate = str_to_date(TransactionDate, '%Y/%m/%d');

alter table transactional
modify column TransactionDate Datetime;


-- DATA ANALYSIS 


-- Monthly Revenue Trend

SELECT
  DATE_FORMAT(TransactionDate, '%Y-%m') AS Month,
  round(SUM(TotalValue),2) AS Revenue
FROM transactional
GROUP BY DATE_FORMAT(TransactionDate, '%Y-%m')
ORDER BY DATE_FORMAT(TransactionDate, '%Y-%m');

-- Monthly Order Volume 

SELECT
  DATE_FORMAT(TransactionDate, '%Y-%m') AS Month,
  COUNT(TransactionID) AS Orders
FROM transactional
GROUP BY DATE_FORMAT(TransactionDate, '%Y-%m')
ORDER BY DATE_FORMAT(TransactionDate, '%Y-%m');

-- Total Revenue

SELECT
  round(SUM(TotalValue),2) AS Total_Revenue
FROM transactional;

-- Average Order Value (AOV)

SELECT
  ROUND(SUM(TotalValue) / COUNT(TransactionID), 2) AS AOV
FROM transactional;

-- Retention Rate

WITH order_counts AS (
  SELECT CustomerID, COUNT(*) AS OrderCount
  FROM transactional
  GROUP BY CustomerID
)
SELECT
  ROUND((SELECT COUNT(*) FROM order_counts WHERE OrderCount > 1) * 100.0 /
        (SELECT COUNT(*) FROM order_counts), 2) AS RetentionRate;
        

-- Signup-to-First Purchase Conversion Rate

WITH first_purchase AS (
  SELECT CustomerID, MIN(TransactionDate) AS FirstPurchaseDate
  FROM transactional
  GROUP BY CustomerID
)
SELECT
  ROUND((SELECT COUNT(*) FROM first_purchase) * 100.0 /
        (SELECT COUNT(*) FROM customers), 2) AS SignupToPurchaseRate;


-- Sales by Product Category

SELECT
  p.Category,
  ROUND(SUM(t.TotalValue), 2) AS Revenue
FROM transactional t
JOIN products p ON t.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY Revenue DESC;

-- Sales by Region

SELECT
  c.Region,
  p.Category,
  ROUND(SUM(t.TotalValue), 2) AS Revenue,
  SUM(t.Quantity) AS UnitsSold
FROM transactional t
JOIN customers c ON t.CustomerID = c.CustomerID
JOIN products p ON t.ProductID = p.ProductID
GROUP BY c.Region, p.Category;

--  Signup-to-First Purchase Bucketed (Lag Buckets)

WITH first_purchase AS (
  SELECT CustomerID, MIN(TransactionDate) AS FirstPurchaseDate
  FROM transactional
  GROUP BY CustomerID
),
lag_data AS (
  SELECT
    c.CustomerID,
    DATEDIFF(fp.FirstPurchaseDate, c.SignupDate) AS DaysToPurchase
  FROM customers c
  JOIN first_purchase fp ON c.CustomerID = fp.CustomerID
)
SELECT
  CASE
    WHEN DaysToPurchase <= 7 THEN '0–7 days'
    WHEN DaysToPurchase <= 30 THEN '8–30 days'
    WHEN DaysToPurchase <= 60 THEN '31–60 days'
    ELSE '60+ days'
  END AS ConversionBucket,
  COUNT(*) AS Customers
FROM lag_data
GROUP BY ConversionBucket
ORDER BY ConversionBucket;

-- Top Products by Revenue / Units sold

SELECT
  p.ProductName,
  p.Category,
  ROUND(SUM(t.TotalValue), 2) AS Revenue,
  SUM(t.Quantity) AS UnitsSold
FROM transactional t
JOIN products p ON t.ProductID = p.ProductID
JOIN customers c ON t.CustomerID = c.CustomerID
WHERE t.TransactionDate BETWEEN '2023-01-01' AND '2023-12-31'
  AND c.Region = 'Asia'  -- Replace or remove this line if not filtering by region
GROUP BY p.ProductName, p.Category
ORDER BY Revenue DESC
LIMIT 10;