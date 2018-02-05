create or replace view taxdeductions_v as
  select t_sop.nom_vkl,
         t_sop.nom_ips,
         t_sop.kod_ogr_pv shifr_schet,
         t_sop.ssylka_fl,
         sfl.gf_person    fk_contragent,
         t_sop.rid_td,
         t_ptd.startdate,
         t_ptd.enddate,
         t_sop.ssylka_td,
         t_ptd.tdid,
         t_td.code        benefit_code,
         t_td.amount,
         t_td.upper_income,
         t_td.name,
         sum(t_td.amount)over(partition by t_sop.ssylka_fl, t_sop.kod_ogr_pv) amount_all
  from   sp_fiz_lits sfl
  inner  join (
           select t_sop.nom_vkl,
                  t_sop.nom_ips,
                  t_sop.ssylka_fl,
                  t_sop.rid_td,
                  t_sop.ssylka_td,
                  t_sop.kod_ogr_pv
           from   sp_ogr_pv t_sop
           group by t_sop.nom_vkl,
                  t_sop.nom_ips,
                  t_sop.ssylka_fl,
                  t_sop.rid_td,
                  t_sop.ssylka_td,
                  t_sop.kod_ogr_pv
         ) t_sop
  on     sfl.ssylka = t_sop.ssylka_fl
  left   join payments.participant_taxdeductions t_ptd
  on     t_ptd.tdappid = t_sop.rid_td
  and    t_ptd.rid = t_sop.ssylka_td
  left   join payments.taxdeductions t_td
  on     t_td.rid = t_ptd.tdid
/
