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
		case when od.EtoDepozit then concat('Депозит',' ',od.Organizatsiya) else od.RaschetniiSchet end as RaschetniiSchet
	FROM 
		StarLightTechnologies.OstatkiDeneg od 
	UNION DISTINCT
	SELECT DISTINCT 
		dd.BD,
		dd.Organizatsiya,
		case when dd.EtoDepozit then concat('Депозит',' ',dd.Organizatsiya) else dd.RaschetniiSchet end as RaschetniiSchet
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
		DATE(od.`ПериодМСК`)-1 as prev_date,
		od.BD,
		od.Organizatsiya,
		coalesce(od.RaschetniiSchet,concat('Депозит',' ',od.Organizatsiya)) as RaschetniiSchet,
        od.SummaOstatok
	from
		StarLightTechnologies.OstatkiDeneg od
),
ostatki1 as(
	select 
		o.date_col,
		o.BD,
		o.Organizatsiya,
		o.RaschetniiSchet,
        sum(coalesce(o1.SummaOstatok,0)) as SummaOstatok_BEGIN,
        sum(coalesce(o.SummaOstatok,0)) as SummaOstatok_END
	from
		ostatki o
	left join 
		ostatki o1 on 
		o.prev_date=o1.date_col AND 
		o.BD =o1.BD AND 
		o.Organizatsiya =o1.Organizatsiya and 
		o.RaschetniiSchet=o1.RaschetniiSchet
	GROUP BY 1, 2, 3, 4
),
postuplenia_viplaty AS (
    SELECT 
        date(dd.PeriodMSK) AS date_col,
        dd.BD,
        dd.Organizatsiya,
        case when dd.EtoDepozit then concat('Депозит',' ',dd.Organizatsiya) else dd.RaschetniiSchet end as RaschetniiSchet,
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
	coalesce(o.SummaOstatok_BEGIN,0) as SummaOstatok_BEGIN,
	coalesce(pv.Postuplenie, 0) as Postuplenie,
	coalesce(pv.Viplata, 0) as Viplata,
	coalesce(o.SummaOstatok_END,0) as SummaOstatok_END
FROM 
	full_grid f
left JOIN 
	ostatki1 o ON 
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
order by 
	f.date_col desc,
	f.BD,
	f.Organizatsiya,
	f.RaschetniiSchet
	
	