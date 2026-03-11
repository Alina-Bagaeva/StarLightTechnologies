WITH
calculated_data AS (
    SELECT
        Data,
        Organizatsiya,
        _1150, _1170, _1210, _1240, _1250,
        _1300, _1410, _1450, _1510, _1520, _1550,
        (_1150 + _1170 + _1210 + _1240 + _1250) AS _1600,
        (_1300 + _1410 + _1450 + _1510 + _1520 + _1550) AS _1700
    FROM StarLightTechnologies.Balans
),
long AS (
    SELECT
        Data,
        Organizatsiya,
        parameter AS Parameter,
        value AS Value
    FROM calculated_data
    ARRAY JOIN
        ['_1150','_1170','_1210','_1240','_1250','_1300','_1410','_1450','_1510','_1520','_1550','_1600','_1700'] AS parameter,
        [_1150, _1170, _1210, _1240, _1250, _1300, _1410, _1450, _1510, _1520, _1550, _1600, _1700] AS value
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
