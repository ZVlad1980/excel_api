create or replace view sp_ogr_pv_benefits_v as
  with w_benefits as (
    select 'A' source_table,
           t.rid_td                          tdappid,
           t.ssylka_td                       pt_rid,
           t.nom_vkl,
           t.nom_ips,
           t.ssylka_fl,
           t.kod_ogr_pv                      shifr_schet,
           t.nach_deistv                     start_date,
           t.okon_deistv                     end_date,
           extract(year from t.nach_deistv)  start_year,
           extract(year from t.okon_deistv)  end_year,
           t.primech
    from   sp_ogr_pv_arh t
    where  t.kod_ogr_pv > 1000
    union all
    select 'C' source_table,
           t.rid_td                          tdappid,
           t.ssylka_td                       pt_rid,
           t.nom_vkl,
           t.nom_ips,
           t.ssylka_fl,
           t.kod_ogr_pv                      shifr_schet,
           t.nach_deistv                     start_date,
           t.okon_deistv                     end_date,
           extract(year from t.nach_deistv)  start_year,
           extract(year from t.okon_deistv)  end_year,
           t.primech
    from   sp_ogr_pv    t
    where  t.kod_ogr_pv > 1000
  )
  select t.source_table,
         t.pt_rid,
         t.tdappid,
         t.nom_vkl,
         t.nom_ips,
         t.ssylka_fl,
         t.shifr_schet,
         t.start_year,
         t.end_year,
         trunc(min(t.start_date), 'MM') start_date,
         last_day(max(t.end_date))   end_date
  from   w_benefits t
  group by t.source_table,
           t.pt_rid,
           t.tdappid,
           t.nom_vkl,
           t.nom_ips,
           t.ssylka_fl,
           t.shifr_schet,
           t.start_year,
           t.end_year
/
