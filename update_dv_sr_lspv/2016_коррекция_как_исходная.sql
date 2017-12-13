--NOM_VKL, NOM_IPS, DATA_OP, SHIFR_SCHET, SUB_SHIFR_SCHET, SSYLKA_DOC
select *
--БЫЛО 20171209
--1	1376	1021	10.10.2016	5600	723602	1	0	382216
--СТАЛО
--1	1376	1021	10.10.2016	5600	723602	1	0	728680
from   dv_sr_lspv d
where  1=1
and    d.ssylka_doc = 723602
and    d.sub_shifr_schet = 0
and    d.shifr_schet = 1021
and    d.nom_ips = 1376
and    d.nom_vkl = 1
and    d.data_op = to_date('10.10.2016', 'dd.mm.yyyy')
/*
update dv_sr_lspv d
set    d.service_doc = 728680
where  1=1
and    d.ssylka_doc = 723602
and    d.sub_shifr_schet = 0
and    d.shifr_schet = 1021
and    d.nom_ips = 1376
and    d.nom_vkl = 1
and    d.data_op = to_date('10.10.2016', 'dd.mm.yyyy')
*/
--NOM_VKL, NOM_IPS, DATA_OP, SHIFR_SCHET, SUB_SHIFR_SCHET, SSYLKA_DOC
select *
--БЫЛО 20171209
--1 1376  1021  10.10.2016  5600  723602  1 0 382216
--СТАЛО
--1 1376  1021  10.10.2016  5600  723602  1 0 734224
from   dv_sr_lspv d
where  1=1
and    d.ssylka_doc = 728684
and    d.sub_shifr_schet = 0
and    d.shifr_schet = 1021
and    d.nom_ips = 6183
and    d.nom_vkl = 75
and    d.data_op = to_date('10.11.2016', 'dd.mm.yyyy')
/*
update dv_sr_lspv d
set    d.service_doc = 734224
where  1=1
and    d.ssylka_doc = 728684
and    d.sub_shifr_schet = 0
and    d.shifr_schet = 1021
and    d.nom_ips = 6183
and    d.nom_vkl = 75
and    d.data_op = to_date('10.11.2016', 'dd.mm.yyyy')
*/

