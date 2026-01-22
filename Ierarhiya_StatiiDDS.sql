CREATE OR REPLACE VIEW StatiDvizheniyaDenezhnykhSredstv_Hierarchy_View AS
select 
    coalesce(t.root_folder, coalesce(t.folder_1, sdds.Naimenovanie)) as root_folder,
    coalesce(t.folder_1, sdds.Naimenovanie) as folder,
    sdds.Naimenovanie as StatyaDDS,
    sdds.StatyaID
from 
    `StatiDvizheniyaDenezhnykhSredstv` sdds
left join 
    (
        select 
            sdds.Naimenovanie as root_folder,
            sdds.StatyaID as root_id,
            sdds1.Naimenovanie as folder_1,
            sdds1.StatyaID as folder_id
        from 
            `StatiDvizheniyaDenezhnykhSredstv` sdds
        left join 
            `StatiDvizheniyaDenezhnykhSredstv` sdds1 on 
            sdds1.GruppaStatiID = sdds.StatyaID and sdds1.EtoGruppa 
        where 
            sdds.GruppaStati is null and sdds.EtoGruppa 
    ) t on 
    sdds.GruppaStatiID = t.folder_id 
where 
    not sdds.EtoGruppa;