WITH calculated_data AS (
    SELECT
        Data,
        Organizatsiya,
        -- Исходные колонки
        _2110, _2120, _2340, _2350, _2410,
        _2210, _2220, _2310, _2320, _2330,
        _2411, _2412, _2420, _2460, _2510, _2520, _2530,
        _2900, _2910,
        -- Вычисляемые колонки (все нужные суммы)
        (_2110 + _2120) AS _2100,
        (_2110 + _2120 + _2210 + _2220) AS _2200, 
        (_2110 + _2120 + _2210 + _2220 + _2310 + _2320 + _2330 + _2340 + _2350) AS _2300, 
        (_2110 + _2120 + _2210 + _2220 + _2310 + _2320 + _2330 + _2340 + _2350 + _2410 + _2420) AS _2400,
        (_2110 + _2120 + _2210 + _2220 + _2310 + _2320 + _2330 + _2340 + _2350 + _2410 + _2420 + _2510 + _2520 + _2530) AS _2500
    FROM StarLightTechnologies.OOFR
),
long AS (
    SELECT
        Data,
        Organizatsiya,
        parameter AS Parameter,
        value AS Value
    FROM calculated_data
    ARRAY JOIN
        [
            '_2110', '_2120', '_2340', '_2350', '_2410',
            '_2210', '_2220', '_2310', '_2320', '_2330',
            '_2411', '_2412', '_2420', '_2460', '_2510', '_2520', '_2530',
            '_2900', '_2910', '_2100', '_2200', '_2300', '_2400', '_2500'
        ] AS parameter,
        [
            _2110, _2120, _2340, _2350, _2410,
            _2210, _2220, _2310, _2320, _2330,
            _2411, _2412, _2420, _2460, _2510, _2520, _2530,
            _2900, _2910, _2100, _2200, _2300, _2400, _2500
        ] AS value
)
SELECT
    cur.Data,
    cur.Organizatsiya,
    cur.Parameter,
    cur.Value,
    coalesce(prev.Value,0) AS Value_prev_year
FROM long AS cur
LEFT JOIN long AS prev
    ON  prev.Organizatsiya = cur.Organizatsiya
    AND prev.Parameter     = cur.Parameter
    AND toDate(prev.Data) = toDate(cur.Data) - INTERVAL 1 YEAR;