begin
  dv_sr_lspv_docs_api.set_period(
    p_end_date    => to_date(20161231, 'yyyymmdd'),
    p_report_date => sysdate
  );
end;
/
select *
from   dv_sr_lspv_docs_t d
where  d.gf_person = 1431857
order by date_op
/
select dd.*--sum(dd.revenue_curr_year), sum(dd.benefit_curr_year), (sum(dd.revenue_curr_year) - sum(dd.benefit_curr_year)) * .13
            from   dv_sr_lspv_docs_v dd
            where  dd.gf_person = 1431857
 --s.fk_contragent
            --group by dd.gf_person
            order by date_op
/
select *
from   dv_sr_lspv_acc_v ds
where  ds.nom_vkl = 991
and    ds.nom_ips = 72333
and    extract(year from ds.date_op) > 2015
order by ds.date_op
/
select *
from   f2ndfl_arh_spravki  sa
where  (sa.kod_na,
       sa.god,
       sa.nom_spr) in (
        select sa2.kod_na,
               sa2.god,
               sa2.nom_spr
        from   f2ndfl_arh_spravki  sa2
        where  sa2.id = 285332
        )
/

select sa.nom_spr, ls.*
from   f2ndfl_load_spravki  sa,
       f2ndfl_load_itogi    ls
where  1=1
and    ls.nom_korr = sa.nom_korr
and    ls.ssylka = sa.ssylka 
and    ls.god = sa.god
and    ls.kod_na = sa.kod_na
and    (sa.kod_na,
       sa.god,
       sa.nom_spr) in (
        select sa2.kod_na,
               sa2.god,
               sa2.nom_spr
        from   f2ndfl_arh_spravki  sa2
        where  sa2.id = 285332
        )
/
select sum(li2.sgd_sum             )  revenue,
                sum(li2.sgd_sum - li2.sum_obl) benefit,
                sum(li2.sum_obl_ni          )  tax_calc,
                sum(li2.sum_obl_nu          )  tax_retained
         from   f2ndfl_load_spravki sp,
                f2ndfl_load_itogi   li2
         where  1=1
         --
         and    li2.tip_dox      = sp.tip_dox
         and    li2.nom_korr     = sp.nom_korr
         and    li2.ssylka       = sp.ssylka
         and    li2.god          = sp.god
         and    li2.kod_na       = sp.kod_na
         --
         and    sp.tip_dox = 9
         and    sp.nom_korr = 0--s.nom_korr
         and    sp.nom_spr = '085332'--s.nom_spr
         and    sp.god = 2016--s.god
         and    sp.kod_na = 1--s.kod_na
         --and    s.employee = 1
         group by li2.tip_dox ,
                  li2.nom_korr,
                  li2.ssylka  ,
                  li2.god     ,
                  li2.kod_na
