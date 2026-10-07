-- ============================================================
-- Regional Growth Analysis - Task 30
-- VEDA TECHNOLOGY Internship
-- Author: Archana - Data Analytics Track
-- Objective: Compare region growth rates over time
-- Dataset: Superstore
-- ============================================================

-- ============================================
-- SECTION 1: Explore the Dataset
-- ============================================

-- Check table structure
-- DESCRIBE superstore;
-- or
-- SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'superstore';

-- View sample data
-- SELECT * FROM superstore LIMIT 10;

-- Check available regions
SELECT DISTINCT Region
FROM superstore
ORDER BY Region;

-- Check date range
SELECT
    MIN(Order_Date) as Earliest_Order,
    MAX(Order_Date) as Latest_Order
FROM superstore;

-- ============================================
-- SECTION 2: Sales by Region and Year
-- ============================================

-- Total sales by region
SELECT
    Region,
    SUM(Sales) as Total_Sales,
    COUNT(*) as Order_Count,
    ROUND(AVG(Sales), 2) as Average_Order_Value
FROM superstore
GROUP BY Region
ORDER BY Total_Sales DESC;

-- Sales by region and year
SELECT
    Region,
    YEAR(Order_Date) as Year,
    SUM(Sales) as Total_Sales,
    COUNT(*) as Order_Count,
    ROUND(AVG(Sales), 2) as Average_Order_Value
FROM superstore
GROUP BY Region, YEAR(Order_Date)
ORDER BY Region, Year;

-- ============================================
-- SECTION 3: Year-over-Year Growth Rates
-- ============================================

-- Using Common Table Expression (CTE) for YoY growth
WITH YearlySales AS (
    SELECT
        Region,
        YEAR(Order_Date) as Year,
        SUM(Sales) as Total_Sales
    FROM superstore
    GROUP BY Region, YEAR(Order_Date)
),
SalesWithPrevious AS (
    SELECT
        curr.Region,
        curr.Year,
        curr.Total_Sales as Current_Sales,
        prev.Total_Sales as Previous_Sales,
        prev.Year as Previous_Year
    FROM YearlySales curr
    LEFT JOIN YearlySales prev
        ON curr.Region = prev.Region
        AND curr.Year = prev.Year + 1
)
SELECT
    Region,
    Year,
    Previous_Year,
    ROUND(Previous_Sales, 2) as Previous_Sales,
    ROUND(Current_Sales, 2) as Current_Sales,
    ROUND(Current_Sales - Previous_Sales, 2) as Absolute_Change,
    ROUND(
        CASE
            WHEN Previous_Sales = 0 THEN 0
            ELSE ((Current_Sales - Previous_Sales) / Previous_Sales) * 100
        END, 2
    ) as Growth_Rate_Percentage
FROM SalesWithPrevious
WHERE Previous_Sales IS NOT NULL
ORDER BY Region, Year;

-- ============================================
-- SECTION 4: Quarterly Growth Analysis
-- ============================================

-- Sales by region, year, and quarter
SELECT
    Region,
    YEAR(Order_Date) as Year,
    QUARTER(Order_Date) as Quarter,
    CONCAT(YEAR(Order_Date), '-Q', QUARTER(Order_Date)) as Period,
    SUM(Sales) as Total_Sales,
    COUNT(*) as Order_Count
FROM superstore
GROUP BY Region, YEAR(Order_Date), QUARTER(Order_Date)
ORDER BY Region, Year, Quarter;

-- Quarterly growth rates
WITH QuarterlySales AS (
    SELECT
        Region,
        YEAR(Order_Date) as Year,
        QUARTER(Order_Date) as Quarter,
        CONCAT(YEAR(Order_Date), '-Q', QUARTER(Order_Date)) as Period,
        SUM(Sales) as Total_Sales
    FROM superstore
    GROUP BY Region, YEAR(Order_Date), QUARTER(Order_Date)
),
QuarterlyGrowth AS (
    SELECT
        curr.Region,
        curr.Period as Current_Period,
        curr.Total_Sales as Current_Sales,
        prev.Period as Previous_Period,
        prev.Total_Sales as Previous_Sales,
        ROUND(
            CASE
                WHEN prev.Total_Sales = 0 THEN 0
                ELSE ((curr.Total_Sales - prev.Total_Sales) / prev.Total_Sales) * 100
            END, 2
        ) as Growth_Rate_Percentage
    FROM QuarterlySales curr
    LEFT JOIN QuarterlySales prev
        ON curr.Region = prev.Region
        AND (
            (curr.Year = prev.Year AND curr.Quarter = prev.Quarter + 1)
            OR (curr.Year = prev.Year + 1 AND curr.Quarter = 1 AND prev.Quarter = 4)
        )
)
SELECT * FROM QuarterlyGrowth
WHERE Previous_Sales IS NOT NULL
ORDER BY Region, Current_Period;

-- ============================================
-- SECTION 5: Growth Statistics by Region
-- ============================================

-- Average annual growth rate by region
WITH YearlySales AS (
    SELECT
        Region,
        YEAR(Order_Date) as Year,
        SUM(Sales) as Total_Sales
    FROM superstore
    GROUP BY Region, YEAR(Order_Date)
),
YearlyGrowth AS (
    SELECT
        curr.Region,
        curr.Year,
        curr.Total_Sales as Current_Sales,
        prev.Total_Sales as Previous_Sales,
        ROUND(
            CASE
                WHEN prev.Total_Sales = 0 THEN 0
                ELSE ((curr.Total_Sales - prev.Total_Sales) / prev.Total_Sales) * 100
            END, 2
        ) as Growth_Rate_Percentage
    FROM YearlySales curr
    LEFT JOIN YearlySales prev
        ON curr.Region = prev.Region
        AND curr.Year = prev.Year + 1
)
SELECT
    Region,
    ROUND(AVG(Growth_Rate_Percentage), 2) as Average_Annual_Growth_Rate,
    ROUND(STDDEV(Growth_Rate_Percentage), 2) as Growth_Volatility,
    MIN(Growth_Rate_Percentage) as Minimum_Growth,
    MAX(Growth_Rate_Percentage) as Maximum_Growth
FROM YearlyGrowth
WHERE Previous_Sales IS NOT NULL
GROUP BY Region
ORDER BY Average_Annual_Growth_Rate DESC;

-- ============================================
-- SECTION 6: Small-Base Effect Detection
-- ============================================

-- Identify regions with small initial sales (small-base effect)
WITH FirstYearSales AS (
    SELECT
        Region,
        YEAR(Order_Date) as Year,
        SUM(Sales) as Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY Region ORDER BY YEAR(Order_Date)) as Year_Num
    FROM superstore
    GROUP BY Region, YEAR(Order_Date)
)
SELECT
    Region,
    Year as First_Year,
    ROUND(Total_Sales, 2) as Initial_Sales,
    CASE
        WHEN Total_Sales < 100000 THEN 'Small Base - Growth may be misleading'
        WHEN Total_Sales < 200000 THEN 'Medium Base'
        ELSE 'Large Base - Growth is reliable'
    END as Base_Effect_Assessment
FROM FirstYearSales
WHERE Year_Num = 1
ORDER BY Total_Sales;

-- ============================================
-- SECTION 7: Regional Performance Summary
-- ============================================

-- Comprehensive regional summary
WITH RegionalStats AS (
    SELECT
        Region,
        SUM(Sales) as Total_Sales,
        COUNT(*) as Total_Orders,
        MIN(YEAR(Order_Date)) as First_Year,
        MAX(YEAR(Order_Date)) as Last_Year,
        COUNT(DISTINCT YEAR(Order_Date)) as Years_Active
    FROM superstore
    GROUP BY Region
),
YearlyGrowth AS (
    SELECT
        Region,
        ROUND(
            AVG(
                CASE
                    WHEN LAG(SUM(Sales)) OVER (PARTITION BY Region ORDER BY YEAR(Order_Date)) > 0
                    THEN ((SUM(Sales) - LAG(SUM(Sales)) OVER (PARTITION BY Region ORDER BY YEAR(Order_Date)))
                          / LAG(SUM(Sales)) OVER (PARTITION BY Region ORDER BY YEAR(Order_Date))) * 100
                    ELSE 0
                END
            ), 2
        ) as Avg_Growth_Rate
    FROM superstore
    GROUP BY Region, YEAR(Order_Date)
)
SELECT
    rs.Region,
    ROUND(rs.Total_Sales, 2) as Total_Sales,
    rs.Total_Orders,
    rs.First_Year,
    rs.Last_Year,
    rs.Years_Active,
    ROUND(rs.Total_Sales / rs.Years_Active, 2) as Avg_Annual_Sales,
    yg.Avg_Growth_Rate
FROM RegionalStats rs
LEFT JOIN YearlyGrowth yg ON rs.Region = yg.Region
ORDER BY rs.Total_Sales DESC;

-- ============================================
-- SECTION 8: Month-over-Month Growth (Optional)
-- ============================================

-- Monthly sales by region
SELECT
    Region,
    YEAR(Order_Date) as Year,
    MONTH(Order_Date) as Month,
    CONCAT(YEAR(Order_Date), '-', MONTH(Order_Date)) as YearMonth,
    SUM(Sales) as Total_Sales
FROM superstore
GROUP BY Region, YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Region, Year, Month;

-- ============================================
-- SECTION 9: Top Performing Products by Region
-- ============================================

-- Top 5 products by sales in each region
WITH RegionProductSales AS (
    SELECT
        Region,
        Product_Name,
        SUM(Sales) as Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY Region ORDER BY SUM(Sales) DESC) as Rank
    FROM superstore
    GROUP BY Region, Product_Name
)
SELECT
    Region,
    Product_Name,
    ROUND(Total_Sales, 2) as Total_Sales
FROM RegionProductSales
WHERE Rank <= 5
ORDER BY Region, Rank;

-- ============================================
-- SECTION 10: Export Queries for Excel
-- ============================================

-- Growth table for Excel export
-- Copy this result and paste into Excel
WITH YearlySales AS (
    SELECT
        Region,
        YEAR(Order_Date) as Year,
        SUM(Sales) as Total_Sales
    FROM superstore
    GROUP BY Region, YEAR(Order_Date)
),
SalesWithPrevious AS (
    SELECT
        curr.Region,
        curr.Year,
        curr.Total_Sales as Current_Sales,
        prev.Total_Sales as Previous_Sales,
        prev.Year as Previous_Year
    FROM YearlySales curr
    LEFT JOIN YearlySales prev
        ON curr.Region = prev.Region
        AND curr.Year = prev.Year + 1
)
SELECT
    Region,
    Year,
    Previous_Year,
    ROUND(Previous_Sales, 2) as Previous_Sales,
    ROUND(Current_Sales, 2) as Current_Sales,
    ROUND(Current_Sales - Previous_Sales, 2) as Absolute_Change,
    ROUND(
        CASE
            WHEN Previous_Sales = 0 THEN 0
            ELSE ((Current_Sales - Previous_Sales) / Previous_Sales) * 100
        END, 2
    ) as Growth_Rate_Percentage
FROM SalesWithPrevious
WHERE Previous_Sales IS NOT NULL
ORDER BY Region, Year;

-- ============================================================
-- NOTES:
-- 1. Replace 'superstore' with your actual table name
-- 2. Adjust date functions based on your SQL dialect (MySQL, PostgreSQL, SQL Server)
-- 3. For MySQL: Use YEAR(), QUARTER(), MONTH()
-- 4. For PostgreSQL: Use EXTRACT(YEAR FROM), EXTRACT(QUARTER FROM), EXTRACT(MONTH FROM)
-- 5. For SQL Server: Use YEAR(), DATEPART(QUARTER), DATEPART(MONTH)
-- 6. For SQLite: Use strftime('%Y', Order_Date) for year extraction
-- ============================================================
