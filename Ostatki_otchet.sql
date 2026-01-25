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
ostatki as(
	select 
		date(od.`ПериодМСК`) as date_col,
		od.BD,
	    sum(od.SummaOstatok) as ostatok
	from
		StarLightTechnologies.OstatkiDeneg od
	group by 1,2
)
select 
	f.date_col,
	f.BD,
	coalesce(o.ostatok,0) as ostatok
from
	full_grid f
left join 	
	ostatki o on 
	f.date_col=o.date_col and 
	f.BD=o.BD
	