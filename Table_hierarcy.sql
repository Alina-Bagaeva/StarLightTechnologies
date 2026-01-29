TRUNCATE TABLE IF EXISTS StarLightTechnologies.StatiDDS_Hierarchy SYNC;

SET enable_analyzer = 1;

CREATE TABLE StarLightTechnologies.StatiDDS_Hierarchy (
    root_folder String,
    folder String,
    StatyaDDS String,
    StatyaID UUID
) ENGINE = MergeTree
ORDER BY (full_path, StatyaID);

INSERT INTO StarLightTechnologies.StatiDDS_Hierarchy
WITH gruppa AS (
    SELECT 
        s.Naimenovanie as Gruppa,
        s.StatyaID as Gruppa_id,
        s.GruppaStatiID as Parent_id
    FROM StatiDvizheniyaDenezhnykhSredstv s
    WHERE s.EtoGruppa
),
stati AS (
    SELECT
        s.Naimenovanie as Satya,
        s.GruppaStatiID as Parent_id,
        s.GruppaStati,
        s.StatyaID
    FROM StatiDvizheniyaDenezhnykhSredstv s
    WHERE NOT s.EtoGruppa
)
SELECT
    coalesce(g2.Gruppa, coalesce(g1.Gruppa, coalesce(g.Gruppa, st.Satya))) as root_folder,
    coalesce(g1.Gruppa, coalesce(g.Gruppa, st.Satya)) as folder,
    coalesce(g.Gruppa, st.Satya) as folder1,
    st.Satya as StatyaDDS,
    st.StatyaID
FROM stati st
LEFT JOIN gruppa g ON st.Parent_id = g.Gruppa_id
LEFT JOIN gruppa g1 ON g.Parent_id = g1.Gruppa_id
LEFT JOIN gruppa g2 ON g1.Parent_id = g2.Gruppa_id;
