/*
select *
from   ERR$_DV_SR_LSPV_DET_T
*/
select d.*
from   (select d.*,
               count(1)over(partition by d.fk_dv_sr_lspv) cnt,
               rowid
        from   dv_sr_lspv_det_v d --        where  d.addition_id is null
       ) d
where  d.cnt > 1
/
select *
from   dv_sr_lspv_det_v dt
where  dt.year_op = 2018
and    dt.charge_type = 'BENEFIT'
and    not exists (
         select 1
         from   sp_ogr_pv_v p
         where  p.pt_rid = dt.addition_id
       )
