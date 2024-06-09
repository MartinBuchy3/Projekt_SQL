-- Úkol 2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

CREATE INDEX indx_date_from ON czechia_price (date_from);
CREATE INDEX indx_payroll_year ON czechia_payroll (payroll_year);

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