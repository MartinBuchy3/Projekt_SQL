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
    p.YEAR AS Year,
    CONCAT (FORMAT (p.pct_increase_price, 2), '%') AS Price_increase_percentage,
    CONCAT (FORMAT (w.pct_increase_wage, 2), '%') AS Wage_increase_percentage,
    CONCAT (FORMAT (p.pct_increase_price - w.pct_increase_wage, 2), '%') AS Difference
FROM price_increase AS p
JOIN wage_increase AS w ON p.year = w.year
WHERE (p.pct_increase_price - w.pct_increase_wage) > 10;