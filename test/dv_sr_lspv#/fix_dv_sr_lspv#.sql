select dt.process_id, count(1) cnt
from   dv_sr_lspv#_v dt
where  dt.year_op = 2018
group by dt.process_id
/
delete from dv_sr_lspv# d
where  d.process_id = 976
/
commit
/
