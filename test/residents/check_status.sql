select extract(year from a.date_op) year,
       a.nom_vkl,
       a.nom_ips,
       a.shifr_schet,
       a.sub_shifr_schet,
       sum(a.amount) amount
from   dv_sr_lspv_acc_v a
where  a.nom_vkl = 257
and    a.nom_ips = 37
and    a.date_op > to_date(20170101, 'yyyymmdd')
and    a.charge_type = 'TAX'
group by extract(year from a.date_op),
       a.nom_vkl,
       a.nom_ips,
       a.shifr_schet,
       a.sub_shifr_schet
order by year, a.shifr_schet, a.sub_shifr_schet
/
select *
from   sp_tax_residents_v    nn
