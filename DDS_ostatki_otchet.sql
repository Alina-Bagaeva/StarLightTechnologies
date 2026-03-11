WITH calendar AS (
    SELECT
    	toDate('2024-12-31') + number AS date_col
    FROM 
    	numbers(dateDiff('day', toDate('2024-12-31'), today() + 1))
),
dim_accounts AS (
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
		dim_accounts d
	CROSS JOIN 
		calendar c
),
ostatki as(
	select 
		DATE(od.`ПериодМСК`) as date_col,
		od.BD,
        sum(od.SummaOstatok) as ostatok
	from
		StarLightTechnologies.OstatkiDeneg od
	group by 
		DATE(od.`ПериодМСК`),od.BD
), 
ostatki_end as (
	select 
		f.date_col,
		f.BD,
		coalesce(o.ostatok,0) as ostatok
	from 
		full_grid f
	left JOIN 
		ostatki o ON 
		o.date_col=f.date_col AND 
		o.BD =f.BD
),
ostatki_full as (
	select 
		o.date_col,
		o.BD,
		coalesce(o1.ostatok,0) as SummaOstatok_BEGIN,
		o.ostatok as SummaOstatok_END
	from 
		ostatki_end o
	left join
		ostatki_end o1 on 
		o.BD =o1.BD and 
		o.date_col - INTERVAL 1 DAY =o1.date_col 
),
postuplenia_viplaty AS (
	select
	    date(dd.PeriodMSK) as date_col,
	    coalesce(g.root_folder,'не известна') as root_folder,
	    coalesce(g.folder,'не известна') as folder,
	    coalesce(g.folder1,'не известна') as folder1,
	    coalesce(g.StatyaDDS,'не известна') as StatyaDDS,
	    dd.BD,
	    case 
	    	when dd.EtoPostuplenie
	    	then 'Поступление'
	    	else 'Оплата'
	    end as vid,
	    dd.Summa
	from 
	    StarLightTechnologies.DvizhenieDS dd 
	left join 
	    StarLightTechnologies.StatiDDS_Hierarchy g on 
	    dd.StatyaDDSID = g.StatyaID
 )
 select 
 	pv.date_col as date_col,
 	pv.BD as BD,
 	pv.vid as vid,
 	pv.root_folder as root_folde,
 	pv.folder as folder,
 	pv.folder1 as folder1,
 	pv.StatyaDDS as StatyaDDS,
 	pv.Summa  as Summa
 from 
 	postuplenia_viplaty pv
 union all 
 select 
 	o.date_col as date_col,
 	o.BD as BD,
 	'Остатки на начало' as vid, 
 	'' as root_folder,
 	''as folder,
 	'' as folder1,
 	'' as StatyaDDS,
 	o.SummaOstatok_BEGIN as Summa
 from
 	ostatki_full o
 union all 
 select 
 	o.date_col as date_col,
 	o.BD as BD,
 	'Остатки на конец' as vid, 
 	'' as root_folder,
 	'' as folder,
 	'' as folder1,
 	'' as StatyaDDS,
 	o.SummaOstatok_END as Summa
 from
 	ostatki_full o
 	
 
 
 
 
 