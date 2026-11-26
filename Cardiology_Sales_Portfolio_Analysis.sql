-- 
-- PHARMACEUTICAL SALES & PERFORMANCE ANALYSIS — CARDIOLOGY (SIMULATED, 2025)
--
-- SQL dialect: SQLite (tested with DB Browser for SQLite).
-- Authoring note: Portfolio version of the analyses practiced in this project.
-- Data: 960 synthetic transaction rows; 192 synthetic monthly targets;
--       4 products; 4 regions; January–December 2025.
-- These are not real pharma-company sales or targets.
-- Source tables expected in the open SQLite database:
--   sales_2025(Transaction_ID, Sale_Date, Product_ID, Region_ID,
--       Units_Sold, Unit_Price_INR, Discount_INR, Return_INR, Net_Sales_INR)
--   targets_2025(Month_Start, Product_ID, Region_ID, Target_INR)
--   Product_Master(Product_ID, Molecule, Therapeutic_Category)
--   Region_Master(Region_ID, Region_Name)
-- Dates use ISO text YYYY-MM-DD; all money amounts are in INR.
--
-- HOW TO USE
-- Open Cardiology_Sales_Analysis_RESTORED.db in DB Browser for SQLite.
-- Open this .sql file in the Execute SQL tab. To inspect one result at a time,
-- select an individual numbered query and choose Execute selected SQL.
-- This file is read-only
--
-- DEFINITIONS
-- Net Sales = Units_Sold * Unit_Price_INR - Discount_INR - Return_INR.
-- Achievement % = 100 * Net Sales / Target.
-- Signed Sales Variance = Net Sales - Target (may be negative).
-- Shortfall = MAX(Target - Net Sales, 0).
-- At annual product/region level, over-target months may offset misses.
-- Cumulative monthly shortfall does NOT allow such offsetting: it sums
-- shortfalls calculated separately at product + region + month grain.
-- ============================================================================

-- 01 | BASIC IMPORT COUNTS
-- Expected: 960 sales rows, 192 target rows, 4 products, 4 regions.
SELECT
    (SELECT COUNT(*) FROM sales_2025) AS sales_transactions,
    (SELECT COUNT(*) FROM targets_2025) AS monthly_target_rows,
    (SELECT COUNT(*) FROM Product_Master) AS products,
    (SELECT COUNT(*) FROM Region_Master) AS regions;

-- 02 | CHECK DUPLICATE KEYS
-- Each transaction ID is unique. Each month/product/region target is unique.
-- Expected: both counts = 0.
SELECT
    (SELECT COUNT(*) FROM (
        SELECT Transaction_ID FROM sales_2025
        GROUP BY Transaction_ID HAVING COUNT(*) > 1
    )) AS duplicate_transaction_ids,
    (SELECT COUNT(*) FROM (
        SELECT Month_Start, Product_ID, Region_ID FROM targets_2025
        GROUP BY Month_Start, Product_ID, Region_ID HAVING COUNT(*) > 1
    )) AS duplicate_target_keys;

-- 03 | CHECK MASTER DATA REFERENCES
-- Unexpected product or region IDs could break dimension-based dashboard filters.
-- Expected: all four counts = 0.
SELECT
    (SELECT COUNT(*) FROM sales_2025 s
        LEFT JOIN Product_Master p ON s.Product_ID = p.Product_ID
        WHERE p.Product_ID IS NULL) AS invalid_sales_product_ids,
    (SELECT COUNT(*) FROM sales_2025 s
        LEFT JOIN Region_Master r ON s.Region_ID = r.Region_ID
        WHERE r.Region_ID IS NULL) AS invalid_sales_region_ids,
    (SELECT COUNT(*) FROM targets_2025 t
        LEFT JOIN Product_Master p ON t.Product_ID = p.Product_ID
        WHERE p.Product_ID IS NULL) AS invalid_target_product_ids,
    (SELECT COUNT(*) FROM targets_2025 t
        LEFT JOIN Region_Master r ON t.Region_ID = r.Region_ID
        WHERE r.Region_ID IS NULL) AS invalid_target_region_ids;

-- 04 | CHECK TRANSACTION CALCULATION
-- Allows <= INR 0.01 rounding difference for individual lines.
-- Expected: 0 discrepancies.
SELECT COUNT(*) AS incorrect_net_sales_rows
FROM sales_2025
WHERE ABS(Net_Sales_INR -
    (Units_Sold * Unit_Price_INR - Discount_INR - Return_INR)) > 0.01;

-- 05 | OVERALL ANNUAL KPIs
-- Sales and targets are aggregated independently (different table grains).
-- Expected net sales 5691000.55, annual target 5664000,
-- achievement ~100.48%, signed variance +27000.55.
WITH sales AS (
    SELECT SUM(Net_Sales_INR) AS actual FROM sales_2025
), targets AS (
    SELECT SUM(Target_INR) AS target FROM targets_2025
)
SELECT
    ROUND(s.actual, 2) AS annual_net_sales_inr,
    t.target AS annual_target_inr,
    ROUND(100.0 * s.actual / NULLIF(t.target, 0), 2) AS achievement_pct,
    ROUND(s.actual - t.target, 2) AS signed_variance_inr
FROM sales s CROSS JOIN targets t;

-- 06 | ANNUAL PRODUCT PERFORMANCE
-- Aggregate before joining so the monthly targets are not repeated for each sale.
WITH sales AS (
    SELECT Product_ID, SUM(Net_Sales_INR) AS actual
    FROM sales_2025 GROUP BY Product_ID
), targets AS (
    SELECT Product_ID, SUM(Target_INR) AS target
    FROM targets_2025 GROUP BY Product_ID
)
SELECT
    t.Product_ID, p.Molecule,
    ROUND(COALESCE(s.actual, 0), 2) AS actual_sales_inr,
    t.target AS sales_target_inr,
    ROUND(100.0 * COALESCE(s.actual, 0) / NULLIF(t.target, 0), 2)
        AS achievement_pct,
    ROUND(MAX(t.target - COALESCE(s.actual, 0), 0), 2)
        AS annual_shortfall_inr
FROM targets t
LEFT JOIN sales s ON t.Product_ID = s.Product_ID
LEFT JOIN Product_Master p ON t.Product_ID = p.Product_ID
ORDER BY achievement_pct ASC;

-- 07 | ANNUAL REGIONAL PERFORMANCE
-- Highest actual sales need not mean highest target achievement.
WITH sales AS (
    SELECT Region_ID, SUM(Net_Sales_INR) AS actual
    FROM sales_2025 GROUP BY Region_ID
), targets AS (
    SELECT Region_ID, SUM(Target_INR) AS target
    FROM targets_2025 GROUP BY Region_ID
)
SELECT
    t.Region_ID, r.Region_Name,
    ROUND(COALESCE(s.actual, 0), 2) AS actual_sales_inr,
    t.target AS sales_target_inr,
    ROUND(100.0 * COALESCE(s.actual, 0) / NULLIF(t.target, 0), 2)
        AS achievement_pct,
    ROUND(MAX(t.target - COALESCE(s.actual, 0), 0), 2)
        AS annual_shortfall_inr
FROM targets t
LEFT JOIN sales s ON t.Region_ID = s.Region_ID
LEFT JOIN Region_Master r ON t.Region_ID = r.Region_ID
ORDER BY achievement_pct DESC;

-- 08 | MONTHLY SALES VERSUS TARGETS
-- One row per month, starting from the monthly target table.
WITH sales AS (
    SELECT SUBSTR(Sale_Date, 1, 7) AS sales_month,
           SUM(Net_Sales_INR) AS actual
    FROM sales_2025
    GROUP BY SUBSTR(Sale_Date, 1, 7)
), targets AS (
    SELECT SUBSTR(Month_Start, 1, 7) AS sales_month,
           SUM(Target_INR) AS target
    FROM targets_2025
    GROUP BY SUBSTR(Month_Start, 1, 7)
)
SELECT
    t.sales_month,
    ROUND(COALESCE(s.actual, 0), 2) AS actual_sales_inr,
    t.target AS target_inr,
    ROUND(100.0 * COALESCE(s.actual, 0) / NULLIF(t.target, 0), 2)
        AS achievement_pct,
    ROUND(MAX(t.target - COALESCE(s.actual, 0), 0), 2)
        AS monthly_portfolio_shortfall_inr
FROM targets t
LEFT JOIN sales s ON t.sales_month = s.sales_month
ORDER BY t.sales_month;

-- 09 | MONTH-OVER-MONTH SALES GROWTH
-- LAG compares each month with the preceding month.
-- January growth = NULL because December 2024 is not in this dataset.
WITH monthly AS (
    SELECT SUBSTR(Sale_Date, 1, 7) AS sales_month,
           SUM(Net_Sales_INR) AS actual
    FROM sales_2025
    GROUP BY SUBSTR(Sale_Date, 1, 7)
), previous AS (
    SELECT sales_month, actual,
           LAG(actual) OVER (ORDER BY sales_month) AS previous_sales
    FROM monthly
)
SELECT
    sales_month,
    ROUND(actual, 2) AS monthly_sales_inr,
    ROUND(previous_sales, 2) AS previous_month_sales_inr,
    ROUND(100.0 * (actual - previous_sales) / NULLIF(previous_sales, 0), 2)
        AS mom_growth_pct
FROM previous
ORDER BY sales_month;

-- 10 | TOP TEN PRODUCT–REGION–MONTH SHORTFALLS
-- Granularity is the EXACT target key: month + product + region.
-- Keep all target rows with a LEFT JOIN, even if a combination has zero sales.
WITH sales AS (
    SELECT SUBSTR(Sale_Date, 1, 7) AS sales_month,
           Product_ID, Region_ID,
           SUM(Net_Sales_INR) AS actual
    FROM sales_2025
    GROUP BY SUBSTR(Sale_Date, 1, 7), Product_ID, Region_ID
)
SELECT
    t.Month_Start, p.Molecule, r.Region_Name,
    t.Target_INR AS target_inr,
    ROUND(COALESCE(s.actual, 0), 2) AS actual_sales_inr,
    ROUND(100.0 * COALESCE(s.actual, 0) / NULLIF(t.Target_INR, 0), 2)
        AS achievement_pct,
    ROUND(MAX(t.Target_INR - COALESCE(s.actual, 0), 0), 2)
        AS shortfall_inr
FROM targets_2025 t
LEFT JOIN sales s
    ON SUBSTR(t.Month_Start, 1, 7) = s.sales_month
    AND t.Product_ID = s.Product_ID AND t.Region_ID = s.Region_ID
LEFT JOIN Product_Master p ON p.Product_ID = t.Product_ID
LEFT JOIN Region_Master r ON r.Region_ID = t.Region_ID
ORDER BY shortfall_inr DESC
LIMIT 10;

-- 11 | RECURRING PRODUCT–REGION UNDERPERFORMANCE
-- Counts months missed; sums only positive shortfalls at the monthly grain.
WITH sales AS (
    SELECT SUBSTR(Sale_Date, 1, 7) AS sales_month,
           Product_ID, Region_ID,
           SUM(Net_Sales_INR) AS actual
    FROM sales_2025
    GROUP BY SUBSTR(Sale_Date, 1, 7), Product_ID, Region_ID
), performance AS (
    SELECT t.Product_ID, t.Region_ID, t.Month_Start, t.Target_INR,
           COALESCE(s.actual, 0) AS actual
    FROM targets_2025 t
    LEFT JOIN sales s
        ON SUBSTR(t.Month_Start, 1, 7) = s.sales_month
        AND t.Product_ID = s.Product_ID AND t.Region_ID = s.Region_ID
)
SELECT
    p.Molecule, r.Region_Name,
    COUNT(*) AS months_analysed,
    SUM(CASE WHEN m.actual < m.Target_INR THEN 1 ELSE 0 END) AS missed_months,
    ROUND(SUM(MAX(m.Target_INR - m.actual, 0)), 2)
        AS cumulative_monthly_shortfall_inr
FROM performance m
LEFT JOIN Product_Master p ON m.Product_ID = p.Product_ID
LEFT JOIN Region_Master r ON m.Region_ID = r.Region_ID
GROUP BY m.Product_ID, m.Region_ID
ORDER BY cumulative_monthly_shortfall_inr DESC;

-- 12 | CUMULATIVE MONTHLY SHORTFALL — DASHBOARD RECONCILIATION
-- Overall annual variance is NOT this number. Calculate each target-grain gap
-- first, then add them, without offset from overachieving combinations.
-- Expected: INR 348218.45 (shows as 348.22K on a Power BI card).
WITH sales AS (
    SELECT SUBSTR(Sale_Date, 1, 7) AS sales_month,
           Product_ID, Region_ID,
           SUM(Net_Sales_INR) AS actual
    FROM sales_2025
    GROUP BY SUBSTR(Sale_Date, 1, 7), Product_ID, Region_ID
)
SELECT
    ROUND(SUM(MAX(t.Target_INR - COALESCE(s.actual, 0), 0)), 2)
        AS cumulative_monthly_shortfall_inr
FROM targets_2025 t
LEFT JOIN sales s
    ON SUBSTR(t.Month_Start, 1, 7) = s.sales_month
    AND t.Product_ID = s.Product_ID AND t.Region_ID = s.Region_ID;

-- 13 | PRODUCT CONTRIBUTION TO ANNUAL NET SALES
-- Contribution % = product sales / all-product annual net sales.
WITH product_sales AS (
    SELECT Product_ID, SUM(Net_Sales_INR) AS net_sales
    FROM sales_2025 GROUP BY Product_ID
), total_sales AS (
    SELECT SUM(Net_Sales_INR) AS net_sales FROM sales_2025
)
SELECT
    p.Molecule,
    ROUND(s.net_sales, 2) AS product_net_sales_inr,
    ROUND(100.0 * s.net_sales / NULLIF(t.net_sales, 0), 2)
        AS portfolio_contribution_pct
FROM product_sales s
JOIN Product_Master p ON s.Product_ID = p.Product_ID
CROSS JOIN total_sales t
ORDER BY portfolio_contribution_pct DESC;

-- Limitations: synthetic data was generated for learning; results are not
-- estimates of real prescribing, territory opportunity or market demand.
-- No causal conclusions or realised business impact can be drawn from it.
