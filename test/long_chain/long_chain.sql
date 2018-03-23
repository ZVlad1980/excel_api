select *
from   dv_sr_lspv_acc_v a
where  a.nom_vkl = 991
and    a.nom_ips = 9286
and    a.year_op >= 2017
order by a.date_op, a.shifr_schet
