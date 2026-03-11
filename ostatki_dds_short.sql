WITH 
calendar AS (
    SELECT 
    	toDate('2024-12-31') + number AS date_col
    FROM 
    	numbers(dateDiff('day', toDate('2024-12-31'), today() + 1))
),
organizations AS (
    SELECT DISTINCT 
    	Organizatsiya 
    FROM 
    	StarLightTechnologies.OstatkiDeneg
    union All
    SELECT DISTINCT 
    	Organizatsiya 
    FROM 
    	StarLightTechnologies.DvizhenieDS
), 
movement_root_folders AS (
    SELECT DISTINCT
		case 
    		when dd.StatyaDDS='Внутреннее перемещение денежных средств'
    		then dd.StatyaDDS
    		when g.root_folder is null
    		then 'не известна'
    		else g.root_folder
    	end AS root_folder
    FROM 
    	StarLightTechnologies.DvizhenieDS dd
    LEFT JOIN 
    	StarLightTechnologies.StatiDDS_Hierarchy g 
    	ON dd.StatyaDDSID = g.StatyaID
), 
movement_types AS (
    SELECT 'Поступление' AS type_value
    UNION ALL
    SELECT 'Выплата' AS type_value
),
remainder_types AS (
    SELECT 'Остаток на начало' AS type_value
    UNION ALL
    SELECT 'Остаток на конец' AS type_value
), 
movement_combinations AS (
    SELECT 
        c.date_col AS date_col,
        o.Organizatsiya AS Organizatsiya,
        r.root_folder AS root_folder,
        t.type_value AS type_value
    FROM calendar c
    CROSS JOIN organizations o
    CROSS JOIN movement_root_folders r
    CROSS JOIN movement_types t
), 
remainder_combinations AS (
    SELECT 
        c.date_col AS date_col,
        o.Organizatsiya AS Organizatsiya,
        ' ' AS root_folder,
        t.type_value AS type_value
    FROM calendar c
    CROSS JOIN organizations o
    CROSS JOIN remainder_types t
), 
all_combinations AS (
    SELECT 
    	date_col, 
    	Organizatsiya, 
    	root_folder, 
    	type_value 
    FROM 
    	movement_combinations
    UNION ALL
    SELECT 
    	date_col, 
    	Organizatsiya, 
    	root_folder, 
    	type_value 
    FROM 
    	remainder_combinations
), 
ostatki AS (
    SELECT 
        toDate(od.`ПериодМСК`) AS date_col,
        toDate(od.`ПериодМСК`) - 1 AS prev_date,
        od.BD,
        od.Organizatsiya,
        coalesce(od.RaschetniiSchet, concat('Депозит', ' ', od.Organizatsiya)) AS RaschetniiSchet,
        od.SummaOstatok
    FROM StarLightTechnologies.OstatkiDeneg od
),
ostatki1 AS (
    SELECT 
        o.date_col,
        o.Organizatsiya,
        'Остаток на начало' AS type_value,
        sum(coalesce(o1.SummaOstatok, 0)) AS summa
    FROM ostatki o
    LEFT JOIN ostatki o1 ON 
        o.prev_date = o1.date_col 
        AND o.BD = o1.BD 
        AND o.Organizatsiya = o1.Organizatsiya 
        AND o.RaschetniiSchet = o1.RaschetniiSchet
    GROUP BY 1, 2, 3
    UNION ALL
    SELECT 
        o.date_col,
        o.Organizatsiya,
        'Остаток на конец' AS type_value,
        sum(coalesce(o.SummaOstatok, 0)) AS summa
    FROM ostatki o
    GROUP BY 1, 2, 3
),
original_aggregated AS (
    SELECT
        toDate(dd.PeriodMSK) AS date_col,
        case 
    		when dd.StatyaDDS='Внутреннее перемещение денежных средств'
    		then dd.StatyaDDS
    		when g.root_folder is null
    		then 'не известна'
    		else g.root_folder
    	end AS root_folder,
        dd.Organizatsiya,
        CASE
            WHEN dd.EtoPostuplenie THEN 'Поступление'
            ELSE 'Выплата'
        END AS type_value,
        sum(dd.Summa) AS summa
    FROM StarLightTechnologies.DvizhenieDS dd 
    LEFT JOIN StarLightTechnologies.StatiDDS_Hierarchy g ON dd.StatyaDDSID = g.StatyaID
    GROUP BY 1, 2, 3, 4
    UNION ALL
    SELECT
        o.date_col,
        ' ' AS root_folder,
        o.Organizatsiya,
        o.type_value,
        o.summa
    FROM ostatki1 o
)
SELECT
    ac.date_col,
    case
    	when ac.root_folder like '%Госпошлина%' or ac.root_folder like '%Движение ДС по вкладам%' or ac.root_folder like '%Единый налоговый платеж%' 
    	then 'Операционная деятельность'
    	else ac.root_folder 
    end as root_folder,
    ac.Organizatsiya,
    ac.type_value,
    coalesce(oa.summa, 0) AS summa
FROM all_combinations ac
LEFT JOIN original_aggregated oa ON 
    ac.date_col = oa.date_col
    AND ac.root_folder = oa.root_folder
    AND ac.Organizatsiya = oa.Organizatsiya
    AND ac.type_value = oa.type_value
ORDER BY ac.date_col, ac.Organizatsiya, ac.root_folder, ac.type_value