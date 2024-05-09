------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ SAN MARTIN'S STORE SALES ANALYSIS -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- CREATING A DATABASE
CREATE DATABASE sales_project;

-- USING A DATABASE
USE sales_project;

-- READING ALL THE DATA STORED IN DIFFERENT TABLES (There are total 6 tables)
SELECT * FROM Sales;
SELECT * FROM Products;
SELECT * FROM Customers;
SELECT * FROM Stores;
SELECT * FROM Locations;
SELECT * FROM Sales_agents;



-------------------------------------------------------------- FEATURE CONSTRUCTION ---------------------------------------------------------------------

-- Adding column 'DAY' which extracts day name from order date
ALTER TABLE Sales 
ADD Day varchar(10);

UPDATE Sales SET Day = DATENAME(WEEKDAY, [Order Date])
FROM Sales;



------------------------------------------------------------------ PRELIMINARY ANALYSES ----------------------------------------------------------------------------

--- 1. Number of customers  
SELECT DISTINCT count([Customer Key])
FROM Customers;

--- 2. Number of PRODUCTS   
SELECT DISTINCT count([Product Key])
FROM Products;

--- 3. Number of Stores     
SELECT DISTINCT count([Store Key])
FROM Stores;

--- 4. Number of Locations WHERE stores are located 
SELECT DISTINCT count([Region Key])
FROM Locations;

--- 5. Number of Transactions
SELECT count([Order Date])
FROM Sales;

--- 6. Number of Sales agents
SELECT DISTINCT count([Sales Agent Key])
FROM Sales_agents;

------------------------------------------------------------ CHECKING MISSING VALUES ------------------------------------------------------------------

---7. Checking if we have customer details of all the customers who make transactions 
SELECT DISTINCT Sales.[Customer Key] FROM Sales
LEFT JOIN Customers on sales.[Customer Key] = Customers.[Customer Key]
WHERE Customers.[Customer Key] IS NULL;

---8. Checking if we have product details of all the products bought 
SELECT DISTINCT Sales.[Product Key] FROM Sales
LEFT JOIN Products on sales.[Product Key] = Products.[Product Key]
WHERE Products.[Product Key] IS NULL;

---9. Checking if we have details of all the sales agents who helped making transactions 
SELECT DISTINCT Sales.[Sales Agent Key] FROM Sales
LEFT JOIN Sales_agents on sales.[Sales Agent Key] = Sales_agents.[Sales Agent Key]
WHERE Sales_agents.[Sales Agent Key] IS NULL;

---10. Checking if we have details of all the locations WHERE transactions were made
SELECT DISTINCT Sales.[Region Key] FROM Sales
LEFT JOIN Locations on sales.[Region Key] = Locations.[Region Key]
WHERE Locations.[Region Key] IS NULL;


------------------------------------------------------------------- SALES ANALYSIS ----------------------------------------------------------------------------------

---11. How many orders, customers, products, sales agents, stores and location involved in transactions made.
SELECT COUNT(*) AS num_orders, COUNT(DISTINCT [Customer Key]) as num_customers, COUNT(DISTINCT [Product Key]) as num_products, 
       COUNT( DISTINCT [Sales Agent Key]) as num_agents, COUNT(DISTINCT [Store Key]) as num_stores, COUNT(DISTINCT [Region Key]) AS num_location
FROM Sales;

--- This query shows that the data contains 14059 orders for 6954 customers comprising 246 products sold by 9 agents FROM 150 stores located in 149 regions.

---12. Number of orders per customer and sales agent
SELECT (COUNT(*)/COUNT(DISTINCT [Customer Key])) as order_per_customer, (COUNT(*)/COUNT(DISTINCT [Sales Agent Key])) as order_per_agent
FROM Sales;

-- So, there are about 2 orders per customer and about 1562 orders per sales agent.



---------------------------------------------------------------- TIME-BASED ANALYSIS -------------------------------------------------------------------------------------

---1. Total Sales over Time
SELECT [Order Date], sum(Sales.sales) as total_sales
FROM Sales
GROUP BY [Order Date]
ORDER BY [Order Date];

---2. Sales Growth Rate
SELECT [Order Date], sum(Sales.sales) as total_sales, 
	   round(((sum(sales) - lag(sum(sales), 1) OVER (ORDER BY [Order Date]))/  lag(sum(sales), 1) OVER (ORDER BY [Order Date]))*100,0) 
	   as growth_rate
FROM Sales
GROUP BY [Order Date]
ORDER BY [Order Date];

---3. Average Sales
SELECT round(avg(sales),2) as Jan_avg_sales
FROM Sales;


----------------------------------------------------------------- CUSTOMER SEGMENTATION --------------------------------------------------------------------------

--1(a.)Customer Segmentation based on Purchase Frequency - 

SELECT c.Customers, count(*) as purchase_freq, 
        CASE
			WHEN count(*) > 5 THEN 'Prime Customers'
			WHEN count(*) BETWEEN 2 AND 5 THEN 'Active Customers'
			ELSE 'One-time Customers'
		END AS segment
FROM Sales s JOIN Customers c on c.[Customer Key] = s.[Customer Key]
group by c.Customers
ORDER BY purchase_freq desc;

--1(b.)  Distribution of Purchase Frequency Segment

SELECT  (CASE 
			WHEN num_orders > 5 THEN 'Prime Customers'
			WHEN num_orders BETWEEN 2 AND 5 THEN 'Active Customers'
			ELSE 'One-time Customers' END) AS Frequency, COUNT(*) as num_customers
FROM    (SELECT Sales.[Customer Key], COUNT(*) as num_orders 
		 FROM Sales JOIN Customers on sales.[Customer Key] = Customers.[Customer Key] 
		 group by sales.[Customer Key]) o
GROUP BY  (CASE WHEN num_orders > 5 THEN 'Prime Customers'
        WHEN num_orders BETWEEN 2 AND 5 THEN 'Active Customers'
		ELSE 'One-time Customers' END) 
ORDER BY num_customers desc;


--2(a.)Customer Segmentation based on Total Amount Spent -
SELECT c.Customers, sum(s.Sales) as total_sales, 
		CASE
			WHEN sum(s.Sales) > 15000 THEN 'Big Spenders'
			WHEN sum(s.Sales) BETWEEN 8000 AND 15000 THEN 'Average Spenders'
			ELSE 'Penny Spenders'
		END AS segment
FROM Sales s JOIN Customers c on c.[Customer Key] = s.[Customer Key]
GROUP BY c.Customers
ORDER BY total_sales desc;


-- 2(b.) Distribution Of Total Spend Segment
SELECT segment, count(segment) as num_customers
FROM (select c.Customers, sum(s.Sales) as total_sales, 
		CASE
			WHEN sum(s.Sales) > 15000 THEN 'Big Spenders'
			WHEN sum(s.Sales) BETWEEN 8000 AND 15000 THEN 'Average Spenders'
			ELSE 'Penny Spenders'
		END AS segment
	  FROM Sales s JOIN Customers c on c.[Customer Key] = s.[Customer Key]
	  group by c.Customers) g
GROUP BY segment;


---3. Average purchase value
SELECT avg(sales) FROM sales;


---4. Average Purchase Value of each customer
SELECT C.Customers, avg(s.sales) as avg_purchase_value
FROM Sales S JOIN Customers C ON S.[Customer Key] = C.[Customer Key]
group by c.Customers
ORDER BY avg_purchase_value desc;


--- 5. Customer segmentation- above and below avg purchase value
SELECT c.Customers, case when avg(sales) > (SELECT avg(sales) FROM sales) then 'Above_average'
                         ELSE 'Below_average' END as purchase_value
FROM Sales s JOIN Customers c on s.[Customer Key] = c.[Customer Key]
GROUP BY c.Customers;


---6. Count of above/below average segments
SELECT purchase_value, count(purchase_value) as num_customers
FROM (SELECT c.Customers, case 
							when avg(sales) > (SELECT avg(sales) FROM sales) then 'Above_average'
							ELSE 'Below_average' end as purchase_value
		FROM Sales s JOIN Customers c on s.[Customer Key] = c.[Customer Key]
		group by c.Customers) p
GROUP BY purchase_value;


------------------------------------------------------------------ REGIONAL ANALYSIS -------------------------------------------------------------------------

-- 1. Regional Sales Performance- Sales by Region

WITH total_profit AS (SELECT SUM(Profit) as total_profit FROM Sales), 
     total_sales AS (SELECT SUM(Sales) as total_sales FROM Sales)

SELECT  l.Region, 
		COUNT(DISTINCT s.[Store Key]) as number_of_stores,
		COUNT(DISTINCT s.[Product Key]) as number_of_products, 
		SUM(s.Quantity) as total_quantity,
		COUNT(DISTINCT s.[Customer Key]) as number_of_customers, 
		ROUND(sum(s.sales),0) as total_sales, 
		ROUND(SUM(s.Sales) * 100 / (SELECT total_sales FROM total_sales),2) as sales_perc, 
		ROUND(SUM(s.Profit),0) as total_profit,
		ROUND(SUM(s.Profit) * 100 / (SELECT total_profit FROM total_profit),2) as profit_perc

FROM Sales s JOIN Locations l on s.[Region Key] = l.[Region Key]
GROUP BY l.Region
ORDER BY total_sales desc; 




--------------------------------------------------------------- STORE PERFORMANCE ANALYSIS -----------------------------------------------------------------------------------------

---- 1. Total/Average Sales for each store

SELECT sales.[Store Key], Stores.stores , sum(Sales.sales) as total_sales, avg(Sales.sales) as avg_sales
FROM Sales JOIN Stores on sales.[Store Key] = Stores.[Store Key]
GROUP BY sales.[Store Key], Stores.stores
ORDER BY total_sales desc;

-- Tienda Peleas de Abajo store saw the highest sales volume.


--- 2. Total/Average Sales for each location

SELECT Sales.[Region Key], Locations.Region, sum(Sales.sales) as total_sales, ROUND(AVG(Sales.Sales),2) as avg_sales
FROM Sales JOIN Locations on Sales.[Region Key] = Locations.[Region Key]
GROUP BY Sales.[Region Key], Locations.Region
ORDER BY total_sales desc;

-- The Aragon region recorded the highest sales


---3. Sales performance by Sales Agents

SELECT sales.[Sales Agent Key], Sales_agents.[Sales Agent Name],sum(Sales.sales) as total_sales
FROM Sales JOIN Sales_agents on sales.[Sales Agent Key] = Sales_agents.[Sales Agent Key]
GROUP BY sales.[Sales Agent Key], Sales_agents.[Sales Agent Name]
ORDER BY total_sales desc;

-- RZ-874(Juanito Pacheco Quintero) achieved the highest sales record


-------------------------------------------------------------- PRODUCT PERFORMANCE ANALYSIS ------------------------------------------------------------------------------------------------------

--1. Best-selling Products- Top N Products by Sales 

SELECT TOP 10 P.Products, SUM(S.SALES) AS total_sales
FROM Sales S JOIN Products P ON S.[Product Key] = P.[Product Key]
GROUP BY P.Products
ORDER BY total_sales desc;


--2. Best-selling Product category - Top N Product category by Sales

SELECT P.[Products Category], SUM(S.SALES) AS total_sales
FROM Sales S JOIN Products P ON S.[Product Key] = P.[Product Key]
GROUP BY P.[Products Category]
ORDER BY total_sales desc;

--3. Profitability of Each Product - Product Contribution Margin

SELECT P.Products, sum(S.Sales) as Total_sales, SUM(S.[Unit Cost] * S.Quantity) AS Total_Var_Cost, 
	   ROUND((SUM(S.Sales) - SUM(S.[Unit Cost] * S.Quantity)) / SUM(S.Sales) * 100,0) as Profit_contribution
FROM Sales S JOIN Products P ON S.[Product Key] = P.[Product Key]
GROUP BY P.Products
ORDER BY Profit_contribution desc;


--4. Product Category Distribution

SELECT
    P.[Products Category] AS ProductCategory,
    COUNT(*) AS ProductCount,
    FLOOR((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ())) AS CategoryDistributionPercentage
FROM
    sales S JOIN Products P on S.[Product Key] = p.[Product Key] 
GROUP BY
    P.[Products Category];


--5. Top Products with Highest Quantity Sold
SELECT P.Products, SUM(S.Quantity) as total_qty
FROM Sales S JOIN Products P ON S.[Product Key] = P.[Product Key]
GROUP BY P.Products
ORDER BY total_qty desc;



----------------------------------------------------------- TIME TO FULFILLMENT ANALYSIS-----------------------------------------------------------------------


--1. Order Processing Time - Average Time to Fulfill an Order
SELECT Avg(DATEDIFF(Day, [Order Date], [Shipping date]))
FROM Sales;


--2. Order Processing Time - Average time to fulfill an order based on each Store
SELECT St.stores, Avg(DATEDIFF(Day, [Order Date], [Shipping date]))
FROM Sales S JOIN Stores St on S.[Store Key] = St.[Store Key]
Group by st.Stores;



--------------------------------------------------------------------- COST ANALYSIS -------------------------------------------------------------------------------------

--1. Cost of Goods Sold (COGS)
SELECT sum(cost) as total_cost, avg(cost) as avg_cost
FROM Sales;

---2. Gross profit Margin
SELECT (sum(Sales) - sum(cost)) * 100 / sum(sales) as goss_profit_margin 
FROM Sales;





------------------------------------------------------------------- QUANTITY ANALYSIS ---------------------------------------------------------------------------

--1. Quantity Trends Over Time
SELECT [Order Date], sum(Quantity) as total_quantity
FROM Sales
GROUP BY [Order Date]
Order by [Order Date];


--2 Average Quantity bought 
SELECT avg(Quantity) as avg_quantity
FROM Sales;


---3. Total Quantity bought by each customer
SELECT c.Customers, sum(S.Quantity) as total_quantity
FROM sales S JOIN Customers C on S.[Customer Key] = c.[Customer Key]
GROUP BY  c.[Customers]
ORDER BY total_quantity desc;


---4. Top Stores with highest quantity sold

SELECT st.Stores, sum(s.Quantity) as total_qty
FROM Sales s JOIN Stores st on s.[Store Key] = st.[Store Key]
GROUP BY st.Stores
ORDER BY total_qty desc;




-------------------------------------------------------------------SALES AGENT PERFORMANCE ANALYSIS---------------------------------------------------------------------------

---1. BEST PERFROMING SALES AGENTS- TOTAL SALES
SELECT TOP 3 SA.[Sales Agent Name], ROUND(SUM(S.Sales),2) as total_sales
FROM Sales S JOIN Sales_agents SA ON S.[Sales Agent Key] = SA.[Sales Agent Key]
GROUP BY SA.[Sales Agent Name]
ORDER BY total_sales DESC;

---2. BEST PERFROMING SALES AGENTS- TOTAL PROFIT
SELECT TOP 3 SA.[Sales Agent Name], ROUND(SUM(S.Profit),2) as total_profit
FROM Sales S JOIN Sales_agents SA ON S.[Sales Agent Key] = SA.[Sales Agent Key]
GROUP BY SA.[Sales Agent Name]
ORDER BY total_profit DESC;

---3. SALES AGENT WITH HIGHEST NUMBER OF UNIQUE PRODUCTS SOLD
SELECT SA.[Sales Agent Name], COUNT(DISTINCT P.Products) AS NUM_PRODUCTS
FROM Sales S 
		JOIN Sales_agents SA ON S.[Sales Agent Key] = SA.[Sales Agent Key]
		JOIN Products P ON S.[Product Key] = P.[Product Key]
GROUP BY SA.[Sales Agent Name]
ORDER BY NUM_PRODUCTS DESC;

---4. SALES AGENT ASSOCIATED WITH HOW MANY STORES
SELECT SA.[Sales Agent Name], COUNT(DISTINCT ST.Stores) AS NUM_STORES
FROM Sales S 
		JOIN Sales_agents SA ON S.[Sales Agent Key] = SA.[Sales Agent Key]
		JOIN Stores ST ON S.[Store Key] = ST.[Store Key]
GROUP BY SA.[Sales Agent Name]
ORDER BY NUM_STORES DESC;

---5. NUMBER OF ORDERS TAKEN BY EACH SALES AGENT
SELECT SA.[Sales Agent Name], Count(*) as num_orders
FROM Sales S JOIN Sales_agents SA ON S.[Sales Agent Key] = SA.[Sales Agent Key]
GROUP BY SA.[Sales Agent Name]
ORDER BY num_orders DESC;



------------------------------------------------------------------ CREATING VIEWS --------------------------------------------------------------------------------

--1. VIEW TO RETRIEVE SALES REVENUE AND PROFIT EARNED BY EACH SALES AGENT ON EACH PRODUCT CATEGORY

CREATE VIEW SAgent_prod_cat_performance 
AS
SELECT SA.[Sales Agent Name], P.[Products Category] , SUM(S.Sales) as total_sales, SUM(S.Profit) as total_profit
FROM Sales S 
	JOIN Sales_agents SA ON S.[Sales Agent Key] = SA.[Sales Agent Key]
	JOIN Products P ON S.[Product Key] = P.[Product Key]
GROUP BY SA.[Sales Agent Name], P.[Products Category];

--- Retrieving data from View

SELECT * FROM SAgent_prod_cat_performance S
WHERE S.[Sales Agent Name] = 'Toño Prado-Arco'
ORDER BY total_sales DESC, total_profit DESC;


--2. VIEW TO RETRIVE ORDER COUNT, TOTAL SALES AND TOTAL PROFIT FOR EACH STORE NAME AND ITS LOCATION(REGION) 
CREATE VIEW store_loc_analysis AS
SELECT L.Region, ST.Stores, count(*) as num_orders, sum(S.sales) as total_sales, sum(S.Profit) as total_profit
FROM Sales S JOIN Stores ST ON S.[Store Key] = ST.[Store Key] 
JOIN Locations L ON S.[Region Key] = L.[Region Key]
GROUP BY L.Region, ST.Stores;


-- EXECUTING A VIEW-- IN DIFFERENT WAYS:
-- A.) TO FIND TOP 5 STORES WITH THEIR LOCATION BY MAX NUMBER OF ORDERS

SELECT TOP 5 sl.Stores, sl.Region, sl.num_orders
FROM store_loc_analysis sl
ORDER BY sl.num_orders DESC;

-- B.) TO FIND TOP 5 STORES WITH THEIR LOCATION BY HIGHEST SALES REVENUE

SELECT TOP 5 sl.Stores, sl.Region, sl.total_sales
FROM store_loc_analysis sl
ORDER BY sl.total_sales DESC;

-- c.) TO FIND TOP 5 STORES WITH THEIR LOCATION BY HIGHEST PROFIT EARNED

SELECT TOP 5 sl.Stores, sl.Region, sl.total_profit
FROM store_loc_analysis sl
ORDER BY sl.total_profit DESC;



--------------------------------------------------------------CREATING STORED PROCEDURES-------------------------------------------------------------------------

-- 1. STORED PROCEDURE TO RETRIEVE DETAILS OF HIGH-VALUED TRANSACTIONS ( > 9000 sales per transaction)

CREATE PROCEDURE high_valued_transactions AS
BEGIN
	SELECT S.[Order Date], C.Customers, P.Products, S.Quantity, S.Sales, S.Profit
	FROM Sales S JOIN Products P ON S.[Product Key] = P.[Product Key]
				 JOIN Customers C ON S.[Customer Key] = C.[Customer Key]
				 JOIN Sales_agents SA ON S.[Sales Agent Key] = SA.[Sales Agent Key]
				 JOIN Stores ST ON S.[Store Key] = ST.[Store Key]
				 JOIN Locations L ON S.[Region Key] = L.[Region Key]
	WHERE S.Sales > 9000
END
-- EXECUTING STORED PROCEDURE
EXEC high_valued_transactions;

-- 2. STORED PROCEDURE TO RETRIEVE DETAILS OF MEDIUM-VALUED TRANSACTIONS ( BETWEEN 5000 AND 9000 sales per transaction)

CREATE PROCEDURE medium_valued_transactions AS
BEGIN
	SELECT S.[Order Date], C.Customers, P.Products, S.Quantity, S.Sales, S.Profit
	FROM Sales S JOIN Products P ON S.[Product Key] = P.[Product Key]
				 JOIN Customers C ON S.[Customer Key] = C.[Customer Key]
				 JOIN Sales_agents SA ON S.[Sales Agent Key] = SA.[Sales Agent Key]
				 JOIN Stores ST ON S.[Store Key] = ST.[Store Key]
				 JOIN Locations L ON S.[Region Key] = L.[Region Key]
	WHERE S.Sales BETWEEN 5000 AND 9000
END
-- EXECUTING STORED PROCEDURE
EXEC medium_valued_transactions;


-- 3. STORED PROCEDURE TO RETRIEVE DETAILS OF LOW-VALUED TRANSACTIONS ( < 5000 sales per transaction)

CREATE PROCEDURE low_valued_transactions AS
BEGIN
	SELECT S.[Order Date], C.Customers, P.Products, S.Quantity, S.Sales, S.Profit
	FROM Sales S JOIN Products P ON S.[Product Key] = P.[Product Key]
				 JOIN Customers C ON S.[Customer Key] = C.[Customer Key]
				 JOIN Sales_agents SA ON S.[Sales Agent Key] = SA.[Sales Agent Key]
				 JOIN Stores ST ON S.[Store Key] = ST.[Store Key]
				 JOIN Locations L ON S.[Region Key] = L.[Region Key]
	WHERE S.Sales < 5000
END
-- EXECUTING STORED PROCEDURE
EXEC low_valued_transactions;

--4. NESTED STORED PROCEDURE CONTAINING ABOVE 3 PROCEDURES
CREATE PROCEDURE valued_transactions(@value VARCHAR(7))
AS
BEGIN
	DECLARE @procedure AS VARCHAR(30)
	SET @procedure = CASE
	WHEN @value = 'high' THEN 'high_valued_transactions'
	WHEN @value = 'medium' THEN 'medium_valued_transactions'
	ELSE 'low_valued_transactions' END 
	EXEC @procedure
END

--- EXECUTING STORED PROCEDURE
EXEC valued_transactions 'high'


------------------------------------------------------------------ END ------------------------------------------------------------------------------------------