WITH calendar AS (
    SELECT
        toDate('2024-12-31') + number AS date_col
    FROM 
        numbers(dateDiff('day', toDate('2024-12-31'), today() + 1))
),
dim AS (
    SELECT DISTINCT 
        od.BD
    FROM 
        StarLightTechnologies.OstatkiDeneg od 
),
full_grid AS (
    SELECT 
        d.BD,
        c.date_col 
    FROM 
        dim d
    CROSS JOIN 
        calendar c
),
ostatki AS (
    SELECT 
        date(od.`ПериодМСК`) AS date_col,
        od.BD,
        sum(od.SummaOstatok) AS ostatok
    FROM
        StarLightTechnologies.OstatkiDeneg od
    GROUP BY 1, 2
)
SELECT 
    f.date_col,
    f.BD,
    coalesce(o.ostatok, 0) AS ostatok,
    lagInFrame(coalesce(o.ostatok, 0), 1, 0) OVER (PARTITION BY f.BD ORDER BY f.date_col) AS ostatok_prev_day
FROM
    full_grid f
LEFT JOIN 
    ostatki o ON f.date_col = o.date_col AND f.BD = o.BD
