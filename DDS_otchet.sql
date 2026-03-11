select
	dd.Period,
    coalesce(dd.RaschetniiSchet,concat('55 счёт',' ',dd.Organizatsiya)) as RaschetniiSchet,
    coalesce(g.root_folder,'не известна') as root_folder,
    coalesce(g.folder,'не известна') as folder,
    coalesce(g.folder1,'не известна') as folder1,
    coalesce(g.StatyaDDS,'не известна') as StatyaDDS,
    dd.Kontragent,
    dd.Organizatsiya,
    dd.Podrazdelenie,
    dd.Summa,
    dd.ParametrPeriodDen,
    dd.EtoPostuplenie,
    dd.BD,
    dd.EtoDepozit,
    dd.VidDvizheniy,
    dd.PeriodMSK
from 
    StarLightTechnologies.DvizhenieDS dd 
left join 
    StarLightTechnologies.StatiDDS_Hierarchy g on 
    dd.StatyaDDSID = g.StatyaID