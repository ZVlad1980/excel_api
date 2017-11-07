create or replace view ndfl2_corr_spr_v as
  with corr_w as (
    select /*+ materialize*/
           d.gf_person,
           d.year_doc,
           fl.last_name,
           fl.first_name,
           fl.second_name,
           fl.birth_date,
           sum(d.revenue)    revenue,
           sum(d.tax_return) tax_return
    from   dv_sr_lspv_docs_v  d,
           sp_fiz_litz_lspv_v fl
    where  1=1
    and    fl.ssylka = d.ssylka_fl
    and    d.is_tax_return = 'Y'
    and    d.year_op <> d.year_doc
    group by d.gf_person,
             d.year_doc,
             fl.last_name,
             fl.first_name,
             fl.second_name,
             fl.birth_date
  ),
  ndfl_all_w as (
    select ns.fk_contragent,
           ns.god          ,
           s.id            spr_id,
           s.r_xmlid,
           s.kod_na,
           s.nom_spr,
           s.nom_korr,
           s.data_dok,
           row_number() over(partition by s.kod_na, s.god, s.nom_spr order by s.data_dok) row_num,
           count(1) over(partition by s.kod_na, s.god, s.nom_spr)                          row_cnt
    from   f2ndfl_arh_nomspr   ns,
           f2ndfl_arh_spravki  s
    where  1=1
    --
    and    s.kod_na = ns.kod_na
    and    s.god = ns.god
    and    s.nom_spr = ns.nom_spr
    --
    and    ns.flag_otmena = 0
    and    ns.kod_na = 1
  ),
  ndfl_w as (
    select n.fk_contragent,
           n.god          ,
           n.spr_id,
           n.kod_na,
           case when n.row_num = n.row_cnt then n.r_xmlid  end r_xml_id,
           case when n.row_num = n.row_cnt then n.nom_spr  end nom_spr,
           case when n.row_num = n.row_cnt then n.nom_korr end nom_korr,
           case when n.row_num = n.row_cnt then n.data_dok end data_dok,
           n.row_num
    from   ndfl_all_w n
    where  n.row_num in (1, n.row_cnt)
  )
  select c.gf_person,
         c.year_doc,
         c.last_name,
         c.first_name,
         c.second_name,
         c.birth_date,
         c.revenue        revenue_corr,
         c.tax_return     tax_corr,
         case when max(n.r_xml_id) is not null then 'Y' else 'N' end exists_xml,
         max(n.nom_spr)   spr_nom,
         max(n.nom_korr)  spr_corr_num,
         max(n.data_dok)  spr_date,
         sum(case when n.row_num = 1 then t.sgd_sum end)     revenue, --общий доход доход по первой справке
         sum(case when n.row_num = 1 then t.sum_obl_nu end)  tax_retained, --налог удержанный
         sum(case when n.row_num <> 1 then t.sgd_sum end)    revenue_last, --общий доход по последней справке
         sum(case when n.row_num <> 1 then t.sum_obl_nu end) tax_retained_last --налог удержанный по последней справке
  from   corr_w           c,
         ndfl_w           n,
         F2NDFL_ARH_ITOGI t
  where  1=1
  and    t.r_sprid(+) = n.spr_id
  and    n.fk_contragent(+) = c.gf_person
  and    n.god(+)           = c.year_doc
  group by c.gf_person,
           c.year_doc,
           c.last_name,
           c.first_name,
           c.second_name,
           c.birth_date,
           c.revenue,
           c.tax_return
/
           
