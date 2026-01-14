-- Создаем календарь дат от 1 января 2025 до сегодняшнего дня включительно
WITH calendar AS (
    SELECT
        toDate('2025-01-01') + number AS date_col
    FROM 
        numbers(dateDiff('day', toDate('2025-01-01'), today() + 1))
),

-- Получаем уникальные комбинации БД, организации и расчетного счета из таблицы OstatkiDeneg2(таблица остатков по Депозитам)
-- Если расчетный счет NULL, заменяем на 'Depozit'
dim AS (
    SELECT DISTINCT 
        od.BD,
        od.Organizatsiya,
        coalesce(od.RaschetniiSchet, 'Depozit') as RaschetniiSchet
    FROM 
        OstatkiDeneg2 od 
),

-- Создаем полную сетку: все комбинации dim × все даты из calendar
-- Это нужно для того, чтобы были все даты для каждой комбинации БД-организация-счет
full_grid AS (
    SELECT 
        d.BD,
        d.Organizatsiya,
        d.RaschetniiSchet,
        c.date_col 
    FROM 
        dim d
    CROSS JOIN 
        calendar c  -- Декартово произведение: каждая запись dim с каждой датой
),

-- Аналогично dim, но для другой таблицы - OstatkiDeneg (табица остатков по р/с)
dim2 AS (
    SELECT DISTINCT 
        od.BD,
        od.Organizatsiya,
        od.RaschetniiSchet
    FROM 
        OstatkiDeneg od 
),

-- Полная сетка для второй таблицы
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

-- Основной результат: заполняем остатки для каждой даты и комбинации
-- Используем last_value для заполнения пропусков: берем последнее известное значение остатка
result AS (
    -- Данные из первой таблицы (OstatkiDeneg2)
    SELECT 
        f.date_col,
        f.BD,
        f.Organizatsiya,
        f.RaschetniiSchet,
        -- Заполняем пропуски в остатках: берем последнее не NULL значение для данной комбинации
        coalesce(last_value(od.SummaOstatok) OVER (
            PARTITION BY f.BD, f.Organizatsiya, f.RaschetniiSchet 
            ORDER BY f.date_col
        ), 0) AS SummaOstatok 
    FROM 
        full_grid f
    LEFT JOIN 
        OstatkiDeneg2 od ON 
        DATE(od.DataOstatkaMesyats) = f.date_col AND  -- Связь по дате
        od.BD = f.BD AND 
        od.Organizatsiya = f.Organizatsiya 
    
    UNION ALL 
    
    -- Данные из второй таблицы (OstatkiDeneg)
    SELECT 
        f.date_col,
        f.BD,
        f.Organizatsiya,
        f.RaschetniiSchet,
        -- Аналогичное заполнение пропусков для второй таблицы
        coalesce(last_value(od.SummaOstatok) OVER (
            PARTITION BY f.BD, f.Organizatsiya, f.RaschetniiSchet 
            ORDER BY f.date_col
        ), 0) AS SummaOstatok 
    FROM 
        full_grid2 f
    LEFT JOIN 
        OstatkiDeneg od ON 
        DATE(od.DataOstatkaMesyats) = f.date_col AND 
        od.BD = f.BD AND 
        od.Organizatsiya = f.Organizatsiya AND 
        od.RaschetniiSchet = f.RaschetniiSchet
),

-- CTE для обработки движения денежных средств (поступления и выплаты)
postuplenia_viplaty AS (
    SELECT 
        date(dd.Period) AS date_col,
        dd.BD,
        dd.Organizatsiya,
        -- Если расчетный счет NULL, заменяем на 'Depozit'
        coalesce(dd.RaschetniiSchet, 'Depozit') as RaschetniiSchet,
        -- Сумма поступлений (где флаг EtoPostuplenie = true)
        SUMIf(dd.Summa, dd.EtoPostuplenie) AS Postuplenie,
        -- Сумма выплат (где флаг EtoPostuplenie = false)
        SUMIf(dd.Summa, NOT dd.EtoPostuplenie) AS Viplata
    FROM DvizhenieDS dd
    GROUP BY 1, 2, 3, 4  -- Группировка по дате, БД, организации и счету
)

-- Финальный запрос: объединяем остатки с движением денежных средств
SELECT 
    r.date_col,
    r.BD,
    r.Organizatsiya,
    r.RaschetniiSchet,
    -- Остаток на конец предыдущего дня (для анализа изменения)
    lagInFrame(r.SummaOstatok) OVER (
        PARTITION BY r.BD, r.Organizatsiya, r.RaschetniiSchet 
        ORDER BY r.date_col
    ) AS SummaOstatok_Prev,
    -- Поступления за день (0 если не было)
    coalesce(p.Postuplenie, 0) as Postuplenie,
    -- Выплаты за день (0 если не было)
    coalesce(p.Viplata, 0) as Viplata,
    -- Остаток на конец дня
    r.SummaOstatok
FROM 
    result r
LEFT JOIN 
    postuplenia_viplaty p ON 
    r.BD = p.BD AND 
    r.Organizatsiya = p.Organizatsiya AND 
    r.RaschetniiSchet = p.RaschetniiSchet AND 
    r.date_col = p.date_col
WHERE r.date_col>='2025-01-31'AND r.date_col<='2025-03-01'
ORDER BY 
    r.BD, 
    r.Organizatsiya,
    r.RaschetniiSchet,
    r.date_col