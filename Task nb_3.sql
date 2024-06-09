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
    category_name AS Item_description,
    CONCAT(FORMAT(avg_pct_increase, 2), '%') AS Increase_percentage,
    RANK() OVER (ORDER BY avg_pct_increase ASC) AS Rank
FROM avg_price_increase
ORDER BY avg_pct_increase ASC
LIMIT 10;