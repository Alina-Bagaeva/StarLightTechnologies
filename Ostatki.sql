WITH calendar AS (
    SELECT
    	toDate('2024-12-31') + number AS date_col
    FROM 
    	numbers(dateDiff('day', toDate('2024-12-31'), today() + 1))
),
dim AS (
	SELECT DISTINCT 
		od.BD,
		od.Organizatsiya,
		case when od.EtoDepozit then concat('55 счёт',' ',od.Organizatsiya) else od.RaschetniiSchet end as RaschetniiSchet
	FROM 
		StarLightTechnologies.OstatkiDeneg od 
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
ostatki as(
	select 
		DATE(od.`ПериодМСК`) as date_col,
		od.BD,
		od.Organizatsiya,
		coalesce(od.RaschetniiSchet,concat('55 счёт',' ',od.Organizatsiya)) as RaschetniiSchet,
        od.SummaOstatok 
	from
		StarLightTechnologies.OstatkiDeneg od
),
result AS (
	SELECT 
		f.date_col,
		f.BD,
		f.Organizatsiya,
		f.RaschetniiSchet,
		coalesce(o.SummaOstatok,0) AS SummaOstatok 
	FROM 
		full_grid f
	left JOIN 
		ostatki o ON 
		o.date_col=f.date_col AND 
		o.BD =f.BD AND 
		o.Organizatsiya =f.Organizatsiya and 
		o.RaschetniiSchet=f.RaschetniiSchet
	order by f.date_col,f.Organizatsiya,f.RaschetniiSchet
	),
postuplenia_viplaty AS (
    SELECT 
        date(dd.Period) AS date_col,
        dd.BD,
        dd.Organizatsiya,
        case when dd.EtoDepozit then concat('55 счёт',' ',dd.Organizatsiya) else dd.RaschetniiSchet end as RaschetniiSchet,
        SUMIf(dd.Summa, dd.EtoPostuplenie) AS Postuplenie,
        SUMIf(dd.Summa, NOT dd.EtoPostuplenie) AS Viplata
    FROM StarLightTechnologies.DvizhenieDS dd
    GROUP BY 1, 2, 3, 4
)
SELECT 
	r.date_col as date, 
	r.BD as bd,
	r.Organizatsiya,
	r.RaschetniiSchet,
	case 
		when r.date_col='2024-12-31' then 0
		else r.SummaOstatok-coalesce(p.Postuplenie, 0)+coalesce(p.Viplata, 0)
	end as SummaOstatok_BEGIN,
	coalesce(p.Postuplenie, 0) as Postuplenie,
	coalesce(p.Viplata, 0) as Viplata,
	case
		when r.date_col='2024-12-31' then p.Postuplenie
		else r.SummaOstatok
	end as SummaOstatok_END
FROM 
	result r
LEFT JOIN 
	postuplenia_viplaty p ON 
	r.BD =p.BD AND 
	r.Organizatsiya =p.Organizatsiya AND 
	r.RaschetniiSchet =p.RaschetniiSchet AND 
	r.date_col =p.date_col
	
	
	