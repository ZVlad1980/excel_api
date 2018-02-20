select d.*, rowid
from   dv_sr_lspv_v d
where  d.nom_vkl = 991
and    d.nom_ips = 43933
order by d.data_op
/
select d.*, rowid
from   dv_sr_lspv_acc_v d
where  d.nom_vkl = 991
and    d.nom_ips = 71852
order by d.date_op 
/
select d.*, rowid
from   dv_sr_lspv_acc_v d
where  d.nom_vkl = 991
and    d.nom_ips = 31485
order by d.date_op 
/
select d.*, rowid
from   dv_sr_lspv_acc_v d
where  d.nom_vkl = 991
and    d.nom_ips = 7784
order by d.date_op 
/
