create or replace view sp_tax_residents_src_v as
  with tax_30_w as (
    select extract(month from d.date_op) month,
           sum(case d.tax_rate
                 when 30 then
                  d.tax
               end) tax_30,
           d.gf_person
    from   dv_sr_lspv_docs_t d
    where  1 = 1
    and    d.tax_rate = 30
    and    d.is_delete is null
    and    d.date_op between to_date(dv_sr_lspv_docs_api.get_year || '0101', 'yyyymmdd') and
           to_date(dv_sr_lspv_docs_api.get_year || '1231', 'yyyymmdd')
    group  by extract(month from d.date_op),
              d.gf_person
  ),
  pers_month_w as (
    select m.month,
           p.gf_person
    from   (select t.gf_person from tax_30_w t group by gf_person) p,
           (select level month from dual connect by level < 13)  m
  ),  
  tax_30_accum_w as (
    select pm.month,
           pm.gf_person,
           t.tax_30,
           case sum(coalesce(t.tax_30, 0)) over(partition by pm.gf_person order by pm.month ROWS UNBOUNDED PRECEDING) 
             when 0 then
               0
             else 1
           end is_tax_30
    from   pers_month_w pm,
           tax_30_w     t
    where  1=1
    and    t.month(+) = pm.month
    and    t.gf_person(+) = pm.gf_person
  ),
  tax_30_brd as (
    select t.month,
           t.gf_person,
           t.tax_30,
           case t.is_tax_30
             when 1 then
               case
                 when nvl(lag(t.is_tax_30)over(partition by t.gf_person order by t.month), 0) = 0 then
                   0
                 when nvl(lead(t.is_tax_30)over(partition by t.gf_person order by t.month), 0) = 0 then
                   1
               end
           end tax_30_brd
    from   tax_30_accum_w t
  ),
  tax_30_grp as (
    select t.month,
           t.gf_person,
           row_number()over(partition by t.gf_person, t.tax_30_brd order by t.month, t.tax_30_brd) grp_num
    from   tax_30_brd t
    where  t.tax_30_brd is not null
  ),  tax_30_period as (
    select t.gf_person,
           min(t.month) start_month,
           max(t.month) end_month
    from   tax_30_grp t
    group by t.gf_person, t.grp_num
  )
  select p.gf_person fk_contragent,
         to_date(lpad(p.start_month, 2, '0') || dv_sr_lspv_docs_api.get_year, 'mmyyyy') start_date,
         add_months(to_date(lpad(p.end_month, 2, '0') || dv_sr_lspv_docs_api.get_year, 'mmyyyy'), 1) - 1 end_date
  from   tax_30_period p
/
