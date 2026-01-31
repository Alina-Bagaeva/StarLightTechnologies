WITH calendar AS (
    SELECT
    	toDate('2024-12-31') + number AS date_col
    FROM 
    	numbers(dateDiff('day', toDate('2024-12-31'), today() + 1))
),
dim_accounts AS (
	SELECT DISTINCT 
		od.BD,
		od.Organizatsiya,
		case when od.EtoDepozit then concat('55 счёт',' ',od.Organizatsiya) else od.RaschetniiSchet end as RaschetniiSchet
	FROM 
		StarLightTechnologies.OstatkiDeneg od 
	UNION DISTINCT
	SELECT DISTINCT 
		dd.BD,
		dd.Organizatsiya,
		case when dd.EtoDepozit then concat('55 счёт',' ',dd.Organizatsiya) else dd.RaschetniiSchet end as RaschetniiSchet
	FROM 
		StarLightTechnologies.DvizhenieDS dd 
),
full_grid AS (
	SELECT 
		d.BD,
		d.Organizatsiya,
		d.RaschetniiSchet,
		c.date_col 
	FROM 
		dim_accounts d
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
	f.date_col as date,
	f.BD as bd,
	f.Organizatsiya as Organizatsiya,
	f.RaschetniiSchet as RaschetniiSchet,
	coalesce(case 
		when o.date_col='2024-12-31' then 0
		else o.SummaOstatok-coalesce(pv.Postuplenie, 0)+coalesce(pv.Viplata, 0)
	end,0) as SummaOstatok_BEGIN,
	coalesce(pv.Postuplenie, 0) as Postuplenie,
	coalesce(pv.Viplata, 0) as Viplata,
	coalesce(case
		when o.date_col='2024-12-31' then pv.Postuplenie
		else o.SummaOstatok
	end,0) as SummaOstatok_END
FROM 
	full_grid f
left JOIN 
	ostatki o ON 
	o.date_col=f.date_col AND 
	o.BD =f.BD AND 
	o.Organizatsiya =f.Organizatsiya and 
	o.RaschetniiSchet=f.RaschetniiSchet
left join 
	postuplenia_viplaty pv on
	pv.date_col=f.date_col AND 
	pv.BD =f.BD AND 
	pv.Organizatsiya =f.Organizatsiya and 
	pv.RaschetniiSchet=f.RaschetniiSchet


	
	
	
	