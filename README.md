# Pharmaceutical Sales & Performance Analysis
### Cardiology portfolio | January–December 2025 | **SIMULATED DATA**

Project Status: Completed and Published
Completed a simulated pharmaceutical sales analysis using Excel, SQL and Power BI. Validated selected KPIs and dashboard filters, documented five findings and published a public portfolio website with the dashboard screenshot, supporting dataset, SQL queries and recommendations.

> **Data transparency:** All sales transactions and targets are synthetic, created for an educational portfolio project. They do not represent a pharmaceutical company's actual sales, prescriptions, market share, or results. No employer or client data were used.

## Business question
**Which pharmaceutical products and regions are missing sales targets, and where should the business focus?**

### Intended users and decisions
- **National Sales Head:** identify underperforming products and regions; prioritise further investigation and resource reviews.
- **Regional Sales Manager:** review regional performance, monthly target achievement, and recurring gaps by product.

## Tools and scope
- **Microsoft Excel:** built initial data structure, data dictionary, KPI exercises, and preliminary data quality checks.
- **SQLite + DB Browser for SQLite:** analysed sales/targets using commented SQL queries (`GROUP BY`, `JOIN`, CTEs, `CASE`, and `LAG`).
- **Power BI Desktop:** created a model with shared product, region, and month dimensions; DAX measures; KPI cards; charts; and slicers.

**Analysis window:** 2025 (12 months)  
**Products:** Telmisartan 40 mg, Amlodipine 5 mg, Atorvastatin 10 mg, and Metoprolol Succinate ER 25 mg  
**Reporting regions:** North, South, East, and West  
**Data volume:** 960 simulated sales transactions; 192 simulated monthly target records (4 products × 4 regions × 12 months).  
**Currency:** INR.

## Data model and method

The model retains **two separate fact tables**:

| Table | What one row represents | Key columns |
|---|---|---|
| `sales_2025` / `Sales_2025` | One synthetic sales transaction | `Transaction_ID`, `Sale_Date`, `Product_ID`, `Region_ID` |
| `targets_2025` / `Targets_2025` | One monthly target for one product in one region | `Month_Start`, `Product_ID`, `Region_ID` |

Product and region master tables identify the medicines and reporting regions. In Power BI, a shared `Dim_Month` table filters both fact tables, alongside the product and region master tables. All three dimensions have one-to-many relationships to both fact tables.

**Avoiding double-counting:** Sales transactions are aggregated to the same product–region–month level as targets *before* comparing them. The model does not directly join individual sales transactions to monthly target records.

### KPI definitions

| KPI | Definition |
|---|---|
| Net Sales | `Units_Sold × Unit_Price_INR − Discount_INR − Return_INR`, then summed |
| Sales Target | Sum of assigned monthly target amounts |
| Target Achievement (%) | `Net Sales / Sales Target × 100` |
| Signed Sales Variance | `Net Sales − Sales Target` |
| Cumulative Monthly Shortfall | Sum of `MAX(Target − Sales, 0)` for **each product–region–month** |
| Month-over-Month Sales Growth (%) | `(Current month sales − Previous month sales) / Previous month sales × 100` |
| Product Sales Contribution (%) | `Product net sales / Portfolio net sales × 100` |

Cumulative monthly shortfall **cannot** be inferred from the annual variance: one month's overachievement must not cancel a different month's shortfall when measuring recurring gaps.

## Data quality and reconciliation

Excel checks completed: 960 transaction rows, 192 target rows, no blank sales cells, no negative net sales, no duplicate transaction IDs, no duplicate month–product–region target combinations, and no net-sales formula discrepancies. SQL scripts also include checks for invalid product/region references.

The annual KPI SQL query was run and reconciled with the Power BI dashboard. The Power BI dashboard was also checked unfiltered and with a **West + Telmisartan** slicer selection; the slicers were then cleared and the PBIX saved.

## Results from simulated data

| Annual portfolio KPI | Value |
|---|---:|
| Net Sales | ₹56,91,000.55 |
| Sales Target | ₹56,64,000.00 |
| Target Achievement | **100.48%** |
| Signed Sales Variance | **+₹27,000.55** |
| Cumulative Product–Region–Month Shortfall | **₹3,48,218.45** |

### Five findings
1. **The annual target was achieved, but gaps remained:** overall achievement was 100.48%, while cumulative product–region–month shortfalls totalled ₹3.48 lakh.
2. **Metoprolol and Atorvastatin missed annual product targets:** achievement was 97.91% and 98.16%, respectively.
3. **East and North missed annual regional targets:** achievement was 99.68% and 99.75%, respectively. West and South exceeded their annual regional targets.
4. **June was the weakest month for target achievement:** 94.13%, a ₹27,488.95 monthly portfolio-level shortfall, and −8.59% month-over-month sales growth.
5. **Recurring gaps identified priority combinations:** Atorvastatin–East had ₹36,651.25 in cumulative monthly shortfalls across 7 missed months; Metoprolol–West had ₹36,545.70 across 7; **Metoprolol–South missed 8 months**, with ₹33,781.49 in cumulative shortfalls.

### Recommendations (proposed, not implemented)
1. **Investigate Metoprolol–South first for recurring underperformance:** 8 missed months out of 12 suggests a persistent pattern, although other combinations had larger monetary gaps.
2. **Review Atorvastatin–East and Metoprolol–West:** these had the largest cumulative monetary shortfalls among the combinations highlighted.
3. **Monitor monthly exceptions and investigate June:** track achievement, cumulative shortfalls, and missed-month frequency; use inventory, doctor coverage, and sales-activity evidence if available to understand possible drivers.

**Observed pattern is not proof of cause:** This synthetic dataset does not establish *why* a product or region underperformed.

## Deliverables and how to explore
- [View Portfolio Website](https://aanchal-70.github.io/pharmaceutical-sales-analysis/)
- [View Power BI Dashboard Screenshot](dashboard_overview.png)
- [Read Findings & Recommendations](Pharmaceutical_Sales_Findings_2025.pdf)
- [Explore Commented SQL Queries](Cardiology_Sales_Portfolio_Analysis.sql)
- [Download Simulated Excel Dataset](Cardiology_2025_SIMULATED_DataPack.xlsx)

The public dashboard is presented as a screenshot.
The interactive Power BI report has not been published online.

All sales and target data are simulated.

## Assumptions and limitations

- Transactions, discounts, returns, targets, product-level differences, and regional patterns are simulated. They cannot support real-world market or prescribing claims.
- The dataset covers only four molecules, four broad simulated regions, and one calendar year; it does not include territory subdivisions, doctor visits, field-force activity, competitors, stockouts, profitability, or expenditure.
- Product/region/month target-setting assumptions are artificial; no actual company target-setting methodology is implied.
- Some validation checks cover structural or arithmetic consistency, not external accuracy or realism. No recommendations were implemented and no business impact is claimed.
- The online portfolio, public link, and signed-out/mobile access still need to be prepared and tested.

## Reproduction (local)

1. Open the synthetic Excel data pack or import the two CSV fact tables and product/region masters into SQLite.
2. Open `Cardiology_Sales_Portfolio_Analysis.sql` in DB Browser for SQLite. Run numbered `SELECT` statements individually (Query 05 returns the annual KPI values above).
3. Open the PBIX in Power BI Desktop. Confirm that the model keeps sales and targets as separate fact tables filtered by common dimensions.
4. With filters cleared, compare dashboard KPIs to the annual SQL results. Test region/product slicers and reset filters.

---
**Portfolio emphasis:** Business problem definition, data grain and quality, SQL analysis, DAX measures, dashboard validation, and evidence-based recommendations — not claimed financial impact.
