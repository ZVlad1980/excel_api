insert into dv_sr_lspv_det_t(
  id,
  fk_dv_sr_lspv,
  --fk_dv_sr_lspv_trg,
  amount,
  addition_code,
  addition_id
)
select a.id,
       a.id,
       a.benefit_amount,
       a.benefit_code,
       a.pt_rid
from   dv_sr_lspv_benefits_v a
where  1=1
--
and    a.year_op = 2018
and    a.amount <> 0
and    a.date_op <= to_date(20180131, 'yyyymmdd')
--group by a.benefit_code_cnt
--order by a.date_op, a.nom_vkl, a.nom_ips, a.shifr_schet
/
