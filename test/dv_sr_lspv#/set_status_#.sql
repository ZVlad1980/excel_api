select count(1)
from   dv_sr_lspv#_v d
--update dv_sr_lspv#_v d set d.status = 'N'
where  d.year_op = 2018
and    d.date_op = to_date(20180110, 'yyyymmdd')
and    d.shifr_schet > 1000
and    d.status = 'N'
/
select *
from   dv_sr_lspv_det_v dt
where  dt.year_op = 2018
and    dt.date_op = to_date(20180110, 'yyyymmdd')
/
