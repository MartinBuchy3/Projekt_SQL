-- Úkol 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
SELECT 	
		cp.payroll_year AS 'Period',
		cpib.name AS 'Branch',
		AVG(cp.value) AS 'Average wage',
		CASE 
			WHEN LAG(AVG(cp.value)) OVER (PARTITION BY cpib.name ORDER BY cp.payroll_year) > AVG(cp.value) THEN 'Dropped'
			WHEN LAG(AVG(cp.value)) OVER (PARTITION BY cpib.name ORDER BY cp.payroll_year) < AVG(cp.value) THEN 'Grew'
			WHEN cp.payroll_year = '2000' THEN 'Base year'
			ELSE 'Without major change'
		END AS 'Trend'
FROM czechia_payroll AS cp 
JOIN czechia_payroll_industry_branch AS cpib ON cp.industry_branch_code = cpib.code
WHERE cp.value_type_code = '5958'
GROUP BY cp.payroll_year, cpib.name
ORDER BY cpib.name, cp.payroll_year;


-- Úkol 2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

CREATE INDEX idx_date_from ON czechia_price (date_from);
CREATE INDEX idx_payroll_year ON czechia_payroll (payroll_year);

WITH comparable_years AS (
    SELECT 
        YEAR(MIN(cp.date_from)) AS first_year,
        YEAR(MAX(cp.date_from)) AS last_year
    FROM czechia_price AS cp
    JOIN czechia_payroll AS cpay ON YEAR(cp.date_from) = cpay.payroll_year
)
, avg_wage AS (
    SELECT
        cpay.payroll_year AS year,
        AVG(cpay.value) AS avg_wage
    FROM czechia_payroll AS cpay
    JOIN comparable_years AS cy ON cpay.payroll_year = cy.first_year OR cpay.payroll_year = cy.last_year
    GROUP BY cpay.payroll_year
)
, prices AS (
    SELECT
        YEAR(cp.date_from) AS year,
        cpc.name AS category_name,
        AVG(cp.value) AS avg_price
    FROM czechia_price AS cp
    JOIN czechia_price_category AS cpc ON cp.category_code = cpc.code
    JOIN comparable_years AS cy ON YEAR(cp.date_from) = cy.first_year OR YEAR(cp.date_from) = cy.last_year
    WHERE cpc.code IN ('114201', '111301')
    GROUP BY year, cpc.name
)
SELECT
    aw.year,
    round(aw.avg_wage) AS 'Avarage wage',
    pri.category_name AS 'Item',
    round (pri.avg_price) AS 'Price per 1l/1kg',
    round (aw.avg_wage / pri.avg_price) AS 'quantity for avg wage'
FROM avg_wage AS aw
JOIN prices AS pri ON aw.year = pri.year
ORDER BY aw.year, pri.category_name;


-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
CREATE INDEX idx_date_from ON czechia_price (date_from);

WITH yearly_avg_prices AS (
    SELECT
        YEAR(cp.date_from) AS year,
        cpc.name AS category_name,
        AVG(cp.value) AS avg_price
    FROM czechia_price AS cp
    JOIN czechia_price_category AS cpc ON cp.category_code = cpc.code
    GROUP BY year, cpc.name
)
, price_increase AS (
    SELECT
        cur.year AS year,
        cur.category_name,
        cur.avg_price AS current_price,
        prev.avg_price AS previous_price,
        ((cur.avg_price - prev.avg_price) / prev.avg_price) * 100 AS pct_increase
    FROM yearly_avg_prices cur
    JOIN yearly_avg_prices prev ON cur.category_name = prev.category_name AND cur.year = prev.year + 1
)
, avg_price_increase AS (
    SELECT
        category_name,
        AVG(pct_increase) AS avg_pct_increase
    FROM price_increase
    GROUP BY category_name
)
SELECT
    category_name,
    avg_pct_increase,
    RANK() OVER (ORDER BY avg_pct_increase ASC) AS rank
FROM avg_price_increase
ORDER BY avg_pct_increase ASC
LIMIT 10;

-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
CREATE INDEX idx_date_from ON czechia_price (date_from);
CREATE INDEX idx_payroll_year ON czechia_payroll (payroll_year);
WITH yearly_avg_prices AS (
    SELECT
        YEAR(cp.date_from) AS year,
        AVG(cp.value) AS avg_price
    FROM czechia_price AS cp
    GROUP BY year
)
, yearly_avg_wages AS (
    SELECT
        cpay.payroll_year AS year,
        AVG(cpay.value) AS avg_wage
    FROM czechia_payroll AS cpay
    GROUP BY cpay.payroll_year
)
, price_increase AS (
    SELECT
        cur.year AS year,
        cur.avg_price AS current_price,
        prev.avg_price AS previous_price,
        ((cur.avg_price - prev.avg_price) / prev.avg_price) * 100 AS pct_increase_price
    FROM yearly_avg_prices cur
    JOIN yearly_avg_prices prev ON cur.year = prev.year + 1
)
, wage_increase AS (
    SELECT
        cur.year AS year,
        cur.avg_wage AS current_wage,
        prev.avg_wage AS previous_wage,
        ((cur.avg_wage - prev.avg_wage) / prev.avg_wage) * 100 AS pct_increase_wage
    FROM yearly_avg_wages cur
    JOIN yearly_avg_wages prev ON cur.year = prev.year + 1
)
SELECT
    p.year,
    p.pct_increase_price,
    w.pct_increase_wage,
    p.pct_increase_price - w.pct_increase_wage AS diff
FROM price_increase AS p
JOIN wage_increase AS w ON p.year = w.year
WHERE (p.pct_increase_price - w.pct_increase_wage) > 10;
