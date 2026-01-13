WITH calendar AS (
    SELECT
    	toDate('2025-01-01') + number AS date_col
    FROM 
    	numbers(dateDiff('day', toDate('2025-01-01'), today() + 1))
),
dim AS (
	SELECT DISTINCT 
		od.BD,
		od.Organizatsiya,
		coalesce(od.RaschetniiSchet, 'Depozit') as RaschetniiSchet
	FROM 
		OstatkiDeneg2 od 
),
full_grid AS (
	SELECT 
		d.BD,
		d.Organizatsiya,
		d.RaschetniiSchet,
		c.date_col 
	FROM 
		dim d
	CROSS JOIN 
		calendar c
),
dim2 AS (
	SELECT DISTINCT 
		od.BD,
		od.Organizatsiya,
		od.RaschetniiSchet
	FROM 
		OstatkiDeneg od 
),
full_grid2 AS (
	SELECT 
		d.BD,
		d.Organizatsiya,
		d.RaschetniiSchet,
		c.date_col 
	FROM 
		dim2 d
	CROSS JOIN 
		calendar c
),
result AS (
	SELECT 
		f.date_col,
		f.BD,
		f.Organizatsiya,
		f.RaschetniiSchet,
        coalesce(last_value(od.SummaOstatok) OVER (
		        PARTITION BY f.BD, f.Organizatsiya, f.RaschetniiSchet 
		        ORDER BY f.date_col
        ),0) AS SummaOstatok 
	FROM 
		full_grid f
	LEFT JOIN 
		OstatkiDeneg2 od ON 
		DATE(od.DataOstatkaMesyats)=f.date_col AND 
		od.BD =f.BD AND 
		od.Organizatsiya =f.Organizatsiya 	
	UNION ALL 
		SELECT 
		f.date_col,
		f.BD,
		f.Organizatsiya,
		f.RaschetniiSchet,
        coalesce(last_value(od.SummaOstatok) OVER (
		        PARTITION BY f.BD, f.Organizatsiya, f.RaschetniiSchet 
		        ORDER BY f.date_col
        ),0) AS SummaOstatok 
	FROM 
		full_grid2 f
	LEFT JOIN 
		OstatkiDeneg od ON 
		DATE(od.DataOstatkaMesyats)=f.date_col AND 
		od.BD =f.BD AND 
		od.Organizatsiya =f.Organizatsiya AND 
		od.RaschetniiSchet =f.RaschetniiSchet
),
postuplenia_viplaty AS (
    SELECT 
        date(dd.Period) AS date_col,
        dd.BD,
        dd.Organizatsiya,
        coalesce(dd.RaschetniiSchet, 'Depozit') as RaschetniiSchet,
        SUMIf(dd.Summa, dd.EtoPostuplenie) AS Postuplenie,
        SUMIf(dd.Summa, NOT dd.EtoPostuplenie) AS Viplata
    FROM DvizhenieDS dd
    GROUP BY 1, 2, 3, 4
)
SELECT 
	r.date_col,
	r.BD,
	r.Organizatsiya,
	r.RaschetniiSchet,
	lagInFrame(r.SummaOstatok) OVER (
	    PARTITION BY r.BD, r.Organizatsiya, r.RaschetniiSchet 
	    ORDER BY r.date_col
	) AS SummaOstatok_Prev,
	coalesce(p.Postuplenie, 0) as Postuplenie,
	coalesce(p.Viplata, 0) as Viplata,
	r.SummaOstatok
FROM 
	result r
LEFT JOIN 
	postuplenia_viplaty p ON 
	r.BD =p.BD AND 
	r.Organizatsiya =p.Organizatsiya AND 
	r.RaschetniiSchet =p.RaschetniiSchet AND 
	r.date_col =p.date_col 
WHERE r.date_col>='2025-01-31'AND r.date_col<='2025-03-01'
ORDER  BY 
	r.BD, r.Organizatsiya,r.RaschetniiSchet,r.date_col;

SELECT 
        date(dd.Period) AS date_col,
        dd.BD,
        dd.Organizatsiya,
        coalesce(dd.RaschetniiSchet, 'Depozit') as RaschetniiSchet,
        SUMIf(dd.Summa, dd.EtoPostuplenie) AS Postuplenie,
        SUMIf(dd.Summa, NOT dd.EtoPostuplenie) AS Viplata
    FROM DvizhenieDS dd
    WHERE date(dd.Period)>='2025-01-31'AND date(dd.Period)<='2025-03-01'
    GROUP BY 1, 2, 3, 4
	 
	 
	 
	 
