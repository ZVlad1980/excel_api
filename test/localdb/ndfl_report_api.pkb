create or replace package body ndfl_report_api is
  
  --C_DATE_OUT_FMT constant varchar2(20) := 'dd.mm.yyyy';
  
  /**
   * Обвертки обработки ошибок
   */
  procedure fix_exception(p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => p_msg
    );
  end;
  
  
  function is_empty_load(p_year int) return boolean is
    l_result boolean := false;
    l_dummy  int;
  begin
    begin
      select 1
      into   l_dummy
      from   f2ndfl_load_spravki t
      where  rownum = 1
      and    t.kod_na = 1
      and    t.god = p_year;
      --
      select 1
      into   l_dummy
      from   f2ndfl_load_mes t
      where  rownum = 1
      and    t.kod_na = 1
      and    t.god = p_year;
      --
      select 1
      into   l_dummy
      from   f2ndfl_load_itogi t
      where  rownum = 1
      and    t.kod_na = 1
      and    t.god = p_year;
      --
    exception
      when no_data_found then
        l_result := true;
    end;
    return l_result;
  end is_empty_load;
  
  function is_empty_arh(p_year int) return boolean is
    l_result boolean := false;
    l_dummy  int;
  begin
    begin
      select 1
      into   l_dummy
      from   f2ndfl_arh_spravki t
      where  rownum = 1
      and    t.kod_na = 1
      and    t.god = p_year;
      --
      select 1
      into   l_dummy
      from   f2ndfl_arh_mes t
      where  rownum = 1
      and    t.r_sprid in (
               select id
               from   f2ndfl_arh_spravki t
               where  t.kod_na = 1
               and    t.god = p_year
             );
      --
      select 1
      into   l_dummy
      from   f2ndfl_arh_itogi t
      where  rownum = 1
      and    t.r_sprid in (
               select id
               from   f2ndfl_arh_spravki t
               where  t.kod_na = 1
               and    t.god = p_year
             );
      --
    exception
      when no_data_found then
        l_result := true;
    end;
    return l_result;
  end is_empty_arh;
  /**
   * Функция get_report возвращает курсор с данными отчета
   * 
   * @param p_report_code - код отчета
   * @param p_end_date    - конечная дата отчета
   * @param p_report_date - дата, на которую формируется отчет
   *
   */
  function get_report(
    p_report_code   varchar2,
    p_end_date      date,
    p_report_date   date default null
  ) return sys_refcursor is
    --
    l_result      sys_refcursor;
    l_report_code varchar2(100);
    l_year        int;
    --
  begin
    --
    l_report_code := p_report_code;
    dv_sr_lspv_docs_api.set_period(
      p_end_date    => p_end_date,
      p_report_date => p_report_date
    );
    l_year := dv_sr_lspv_docs_api.get_year;
    --
    if p_report_code = 'tax_diff_det_report' then
      dv_sr_lspv_docs_api.set_is_buff;
    else
      dv_sr_lspv_docs_api.unset_is_buff;
      if l_report_code = 'tax_diff_det_report2' then
        l_report_code := 'tax_diff_det_report';
      end if;
    end if;
    --
    case l_report_code
      when 'benefit_no_distribute_amounts' then
        open l_result for
          select sp.gf_person,
                 sp.ssylka,
                 dt.nom_vkl,
                 dt.nom_ips,
                 sp.full_name,
                 dt.shifr_schet,
                 dt.amount_ops - dt.distribute_amount no_distr_amount,
                 dt.amount_ops,
                 dt.distribute_amount
          from   (
                  select dt.nom_vkl,
                         dt.nom_ips,
                         dt.shifr_schet,
                         sum(dt.amount_op) amount_ops,
                         sum(dt.distribute_amount) distribute_amount
                  from   (
                          select dt.nom_vkl,
                                 dt.nom_ips,
                                 dt.shifr_schet,
                                 dt.fk_dv_sr_lspv,
                                 min(dt.addition_id) min_addition_id,
                                 max(dt.src_amount)  amount_op,
                                 sum(case when dt.addition_id > 0 then dt.amount else 0 end) distribute_amount
                          from   dv_sr_lspv_det_v dt
                          where  dt.year_op = l_year
                          and    dt.detail_type = 'BENEFIT'
                          group  by dt.nom_vkl,
                                    dt.nom_ips,
                                    dt.shifr_schet,
                                    dt.fk_dv_sr_lspv
                          having min(dt.addition_id) = -1
                         ) dt
                  group by dt.nom_vkl,
                         dt.nom_ips,
                         dt.shifr_schet
                  having sum(dt.amount_op) <> sum(dt.distribute_amount)
                 ) dt,
                 lateral(
                   select sp.ssylka, sp.gf_person, sp.full_name
                   from   sp_fiz_litz_lspv_v sp
                   where  sp.nom_vkl = dt.nom_vkl
                   and    sp.nom_ips = dt.nom_ips
                 ) sp
          order by sp.full_name, sp.gf_person, dt.shifr_schet;
     --
      when 'benefit_detail_report' then
        open l_result for
          with det as (
            select sl.ssylka_fl,
                   sl.nom_vkl,
                   sl.nom_ips,
                   d#.shifr_schet,
                   to_number(d.addition_code) benefit_code, 
                   sum(d.amount)              amount
            from   dv_sr_lspv_det_t d,
                   dv_sr_lspv#      d#,
                   sp_lspv          sl
            where  1=1
            and    sl.nom_vkl = d#.nom_vkl
            and    sl.nom_ips = d#.nom_ips
            and    d.detail_type = 'BENEFIT'
            and    d.addition_id > 0
            and    d.fk_dv_sr_lspv = d#.id
            and    d#.shifr_schet > 1000
            and    extract(year from d#.date_op) = l_year
            group by sl.ssylka_fl,
                     sl.nom_vkl,
                     sl.nom_ips,
                     d#.shifr_schet, 
                     d.addition_code
          ),
          vych as (
            select lv.ssylka ssylka_fl, lv.vych_kod_gni benefit_code, 
                   (select o.kod_ogr_pv
                    from   kod_ogr_pv             o,
                           payments.taxdeductions@fnd_fondb t
                    where  1=1
                    and    t.payrestrictionid = o.id
                    and    t.code = lv.vych_kod_gni
                   ) shifr_schet,
                   sum(lv.vych_sum) amount
            from   f2ndfl_load_vych lv
            where  lv.kod_na = 1
            and    lv.god = l_year
            and    lv.tip_dox in (1,3)
            and    lv.nom_korr = 0
            group by lv.ssylka, lv.vych_kod_gni
          )
          select sfl.gf_person,
                 nvl(d.ssylka_fl, v.ssylka_fl) ssylka_fl,
                 sfl.nom_vkl,
                 sfl.nom_ips,
                 sfl.full_name,
                 nvl(d.shifr_schet, v.shifr_schet) shifr_schet,
                 nvl(d.benefit_code, v.benefit_code) benefit_code,
                 d.amount         det_amount  ,
                 v.amount         vych_amount ,
                 dv_sr_lspv_det_pkg.get_remains_shifr_schet(l_year, sfl.nom_vkl, sfl.nom_ips, nvl(d.shifr_schet, v.shifr_schet)) remains
          from   det d
                 full outer join vych v
                  on  d.ssylka_fl = v.ssylka_fl
                  and d.benefit_code = v.benefit_code
                 outer apply(
                   select sfl.gf_person, sfl.nom_vkl, sfl.nom_ips, sfl.full_name
                   from   sp_fiz_litz_lspv_v sfl
                   where  sfl.ssylka = nvl(d.ssylka_fl, v.ssylka_fl)
                 ) sfl
          where  1=1
          and    round(coalesce(d.amount, 0), 2) <> round(coalesce(v.amount, 0), 2)
          order by sfl.full_name, sfl.gf_person, nvl(d.shifr_schet, v.shifr_schet), nvl(d.benefit_code, v.benefit_code);
      --
      when 'gf_person_info' then
        if gateway_pkg.get_parameter_num('gf_person') is not null then
          open l_result for
            select 'FIO'     key, 
                   p.fullname || ' (' || to_char(p.birthdate, 'dd.mm.yyyy') || ')'       value
            from   gf_people_v p
            where  p.fk_contragent = gateway_pkg.get_parameter_num('gf_person')
            union all
            select 'GF_PERSON'     key, 
                   gateway_pkg.get_parameter('gf_person') value 
            from   dual;
        end if;
      when 'dv_sr_lspv_detail' then
        if gateway_pkg.get_parameter_num('gf_person') is not null then
          open l_result for
            with w_dv_sr_lspv_docs as(
              select /*+ materialize*/
                     dd.gf_person,
                     dd.ssylka_fl,
                     dd.det_charge_type,
                     dd.nom_vkl,
                     dd.nom_ips,
                     min(dd.date_doc) from_date,
                     max(dd.date_doc) to_date
              from   dv_sr_lspv_docs_t dd
              where  dd.gf_person = gateway_pkg.get_parameter_num('gf_person')
              and    (dd.year_op > (l_year - 2) or dd.year_doc = l_year)
              group by dd.gf_person,
                       dd.ssylka_fl,
                       dd.det_charge_type,
                       dd.nom_vkl,
                       dd.nom_ips
            )
            select dd.ssylka_fl,
                   a.nom_vkl,
                   a.nom_ips,
                   to_char(a.date_op, 'dd.mm.yyyy') date_op,
                   a.det_charge_type,
                   a.charge_type,
                   a.shifr_schet,
                   a.sub_shifr_schet,
                   a.amount,
                   a.ssylka_doc,
                   a.service_doc,
                   a.tax_rate
            from   w_dv_sr_lspv_docs dd,
                   dv_sr_lspv_acc_v  a
            where  1=1
            and    a.date_op between dd.from_date and dd.to_date
            and    case when dd.det_charge_type = 'RITUAL' and a.det_charge_type = dd.det_charge_type then 1 else 1 end = 1
            and    a.nom_ips = dd.nom_ips
            and    a.nom_vkl = dd.nom_vkl
            order by a.date_op, dd.ssylka_fl, a.det_charge_type, a.charge_type;
        end if;
      when 'dv_sr_lspv_docs_detail' then
        if gateway_pkg.get_parameter_num('gf_person') is not null then
          open l_result for
            select dd.ssylka_fl,
                   dd.nom_vkl,
                   dd.nom_ips,
                   to_char(dd.date_op, 'dd.mm.yyyy') date_op,
                   to_char(dd.date_doc, 'dd.mm.yyyy') date_doc,
                   dd.det_charge_type,
                   dd.benefit,
                   dd.revenue,
                   dd.tax,
                   dd.ssylka_doc_op,
                   dd.ssylka_doc,
                   dd.tax_rate
            from   dv_sr_lspv_docs_t dd
            where  1=1
            and    (dd.year_op > (l_year - 2) or dd.year_doc = l_year)
            and    dd.gf_person = gateway_pkg.get_parameter_num('gf_person')
            order by dd.date_op, dd.ssylka_fl, dd.det_charge_type;
        end if;
      when 'synch_error_report' then
        open l_result for
          with w_process as (
            select p.id
            from   dv_sr_lspv_prc_t p
            order by p.created_at desc
            fetch first rows only
          )
          select case when e.type_op = -1 then 'Коррекция' end type_op,
                 substr(e.date_op, 1, 10) date_op,
                 e.ssylka_doc_op,
                 substr(e.date_doc, 1, 10) date_doc,
                 e.ssylka_doc,
                 e.ssylka_fl,
                 e.nom_vkl,
                 e.nom_ips,
                 e.gf_person,
                 e.det_charge_type,
                 e.revenue,
                 e.benefit,
                 e.tax,
                 e.ora_err_mesg$,
                 e.process_id
          from   err$_dv_sr_lspv_docs_t e,
                 w_process              p
          where  e.process_id = p.id
          union all
          select 'Удаление'                 type_op,
                 to_char(d.date_op, 'dd.mm.yyyy')   date_op,
                 to_char(d.ssylka_doc_op),
                 to_char(d.date_doc, 'dd.mm.yyyy')  date_doc,
                 to_char(d.ssylka_doc),
                 to_char(d.ssylka_fl),
                 to_char(d.nom_vkl),
                 to_char(d.nom_ips),
                 to_char(d.gf_person),
                 d.det_charge_type,
                 to_char(d.revenue),
                 to_char(d.benefit),
                 to_char(d.tax),
                 null ora_err_mesg$,
                 to_char(d.process_id)
          from   dv_sr_lspv_docs_t  d,
                 w_process          p
          where  d.delete_process_id = p.id
          and    d.is_delete = 'Y';
      when 'cmp_f2load_arh' then
        dv_sr_lspv_docs_api.set_employees(p_flag => true);
        dv_sr_lspv_docs_api.set_last_only(p_flag => true);
        if not (is_empty_load(l_year) or is_empty_arh(l_year)) then
          open l_result for
            select nvl(lt.nom_spr, ta.nom_spr)               nom_spr,
                   lt.nom_korr                               nom_korr_load,
                   ta.nom_korr                               nom_korr_arh,
                   nvl(lt.gf_person, ta.gf_person)           gf_person,
                   p.fullname                                fullname,
                   lt.revenue                                revenue_load ,
                   lt.benefit                                benefit_load ,
                   lt.tax_calc                               tax_calc_load,
                   lt.tax_retained                           tax_retained_load,
                   ta.revenue                                revenue_arh ,
                   ta.benefit                                benefit_arh ,
                   ta.tax_calc                               tax_calc_arh,
                   ta.tax_retained                           tax_retained_arh,
                   nvl(lt.is_employee, ta.is_employee)       is_employee,
                   nvl(lt.is_participant, ta.is_participant) is_participant
            from   f2ndfl_arh_totals_v ta
              full outer join f2ndfl_load_totals_v lt
               on  lt.nom_spr = ta.nom_spr
               and lt.tax_rate = ta.tax_rate
              left join gf_people_v p
               on  p.fk_contragent = nvl(ta.gf_person, lt.gf_person)
            where  1=1
            and    (
                     abs(coalesce(lt.revenue, 0) - coalesce(ta.revenue, 0)) > .01
                     or
                     abs(coalesce(lt.tax_retained, 0) - coalesce(ta.tax_retained, 0)) > .01
                     or
                     abs(coalesce(lt.benefit, 0) - coalesce(ta.benefit, 0)) > .01
                     or
                     abs(coalesce(lt.tax_calc, 0) - coalesce(ta.tax_calc, 0)) > .01
                   )
            order by p.fullname, nvl(lt.gf_person, ta.gf_person)
            fetch next 100 rows only;
          end if;
      when 'cmp_f2load_docs' then
        dv_sr_lspv_docs_api.set_employees(p_flag => false);
        dv_sr_lspv_docs_api.set_last_only(p_flag => true);
        if not is_empty_load(l_year) then
          open l_result for
            select nvl(lt.gf_person, dp.gf_person)           gf_person,
                   lt.nom_spr                                nom_spr,
                   lt.nom_korr                               nom_korr_lt,
                   null                                      nom_korr_ta,
                   p.fullname                                fullname,
                   lt.revenue                                revenue_load ,
                   lt.benefit                                benefit_load ,
                   lt.tax_calc                               tax_calc_load,
                   lt.tax_retained                           tax_retained_load,
                   dp.revenue                                revenue_docs ,
                   dp.benefit                                benefit_docs ,
                   dp.tax_calc                               tax_calc_docs,
                   dp.tax_retained_83                        tax_retained_docs,
                   lt.is_employee                            is_employee,
                   lt.is_participant                         is_participant
            from   f2ndfl_load_totals_v lt
              full outer join dv_sr_lspv_pers_v dp
               on  lt.gf_person = dp.gf_person
               and not dp.revenue < .01
              left join gf_people_v p
               on  p.fk_contragent = nvl(lt.gf_person, dp.gf_person)
            where  1=1
            and    (
                     abs(coalesce(lt.revenue, 0) - coalesce(dp.revenue, 0)) > .01
                     or
                     abs(coalesce(lt.tax_retained, 0) - coalesce(dp.tax_retained_83, 0)) > .01
                     or
                     abs(coalesce(lt.benefit, 0) - coalesce(dp.benefit, 0)) > .01
                     or
                     abs(coalesce(lt.tax_calc, 0) - coalesce(dp.tax_calc, 0)) > .01
                   )
            order by p.fullname, nvl(lt.gf_person, dp.gf_person)
            fetch next 100 rows only;
          end if;
      when 'cmp_f2arh_docs' then
        dv_sr_lspv_docs_api.set_employees(p_flag => false);
        dv_sr_lspv_docs_api.set_last_only(p_flag => true);
        if not is_empty_arh(l_year) then
          open l_result for
            select ta.nom_spr                                nom_spr,
                   ta.nom_korr                               nom_korr_lt,
                   null                                      nom_korr_ta,
                   nvl(ta.gf_person, dp.gf_person)           gf_person,
                   p.fullname                                fullname,
                   ta.revenue                                revenue_arh ,
                   ta.benefit                                benefit_arh ,
                   ta.tax_calc                               tax_calc_arh,
                   ta.tax_retained                           tax_retained_arh,
                   dp.revenue                                revenue_docs ,
                   dp.benefit                                benefit_docs ,
                   dp.tax_calc                               tax_calc_docs,
                   dp.tax_retained_83                        tax_retained_docs,
                   ta.is_employee                            is_employee,
                   ta.is_participant                         is_participant
            from   f2ndfl_arh_totals_v ta
              full outer join dv_sr_lspv_pers_v dp
               on  ta.gf_person = dp.gf_person
               and dp.exists_revenue = 'Y'
              left join gf_people_v p
               on  p.fk_contragent = nvl(ta.gf_person, dp.gf_person)
            where  1=1
            and    (
                     abs(coalesce(ta.revenue, 0) - coalesce(dp.revenue, 0)) > .01
                     or
                     abs(coalesce(ta.tax_retained, 0) - coalesce(dp.tax_retained_83, 0)) > .01
                     or
                     abs(coalesce(ta.benefit, 0) - coalesce(dp.benefit, 0)) > .01
                     or
                     abs(coalesce(ta.tax_calc, 0) - coalesce(dp.tax_calc, 0)) > .01
                   )
            order by p.fullname, nvl(ta.gf_person, dp.gf_person)
            fetch next 100 rows only;
          end if;
      when 'cmp_f2ndfl_f6_total' then
        dv_sr_lspv_docs_api.set_employees(p_flag => false);
        dv_sr_lspv_docs_api.set_last_only(p_flag => true);
        open l_result for
          select "2NDFL" ndfl2, 
                 "6NDFL" ndfl6, 
                 "2NDFL" - "6NDFL" ndfl_diff
          from   (
                  select 'DUMMY' src,
                         0 fact01,
                         0 fact02,
                         0 fact03
                  from   dual
                  union all
                  select 'NDFL6' src,
                         gp.total_persons,
                         gp.tax_retained,
                         gp.tax_return
                  from   ndfl6_part1_general_v gp
                  union all
                  select 'NDFL2' src,
                         count(distinct lt.gf_person) ,
                         sum(lt.tax_retained)       ,
                         null                       
                  from   f2ndfl_load_totals_v lt
                  group by lt.god
                 ) t
          unpivot(
            fact_val
            for fact in (fact01, fact02, fact03)
          ) up
          pivot(
          sum(fact_val)
            for src in('NDFL2' as "2NDFL", 'NDFL6' as "6NDFL")
          )
          order by fact; --*/
      when 'cmp_f2ndfl_f6_rates' then
        dv_sr_lspv_docs_api.set_employees(p_flag => false);
        dv_sr_lspv_docs_api.set_last_only(p_flag => true);
        open l_result for
          select "NDFL2" ndfl2, 
                 "NDFL6" ndfl6, 
                 round("NDFL2" - "NDFL6", 2) ndfl_diff
          from   (
                  select 'DUMMY' src,
                         case level
                           when 1 then 13
                           when 2 then 30
                           when 3 then 35
                         end tax_rate,
                         0 fact01,
                         0 fact02,
                         0 fact03,
                         0 fact04
                  from   dual
                  connect by level < 3
                  union all
                  select 'NDFL6' src,
                         d.tax_rate,
                         sum(d.revenue) revenue,
                         sum(d.benefit) benefit,
                         sum(d.tax_calc) tax_calc,
                         sum(d.tax_retained) tax_retained
                  from   dv_sr_lspv_pers_v d
                  where  d.exists_revenue = 'Y'
                  group  by d.tax_rate
                  union all
                  select 'NDFL2' src,
                         lt.tax_rate,
                         sum(lt.revenue),
                         sum(lt.benefit),
                         sum(lt.tax_calc),
                         sum(lt.tax_retained)       
                  from   f2ndfl_load_totals_v lt
                  group by lt.tax_rate
                 ) t
          unpivot(
            fact_val
            for fact in (fact01, fact02, fact03, fact04)
          ) up
          pivot(
          sum(fact_val)
            for src in('NDFL2' as "NDFL2", 'NDFL6' as "NDFL6")
          )
          order by tax_rate, fact; --*/
      when 'cmp_f2ndfl_f6_total_arh' then
        dv_sr_lspv_docs_api.set_employees(p_flag => false);
        dv_sr_lspv_docs_api.set_last_only(p_flag => true);
        open l_result for
          select "2NDFL" ndfl2, 
                 "6NDFL" ndfl6, 
                 "2NDFL" - "6NDFL" ndfl_diff
          from   (
                  select 'DUMMY' src,
                         0 fact01,
                         0 fact02,
                         0 fact03
                  from   dual
                  union all
                  select 'NDFL6' src,
                         gp.total_persons,
                         gp.tax_retained,
                         gp.tax_return
                  from   ndfl6_part1_general_v gp
                  union all
                  select 'NDFL2' src,
                         count(distinct lt.nom_spr) ,
                         sum(lt.tax_retained)       ,
                         null                       
                  from   f2ndfl_arh_totals_v lt
                  group by lt.god
                 ) t
          unpivot(
            fact_val
            for fact in (fact01, fact02, fact03)
          ) up
          pivot(
          sum(fact_val)
            for src in('NDFL2' as "2NDFL", 'NDFL6' as "6NDFL")
          )
          order by fact; --*/
      when 'cmp_f2ndfl_f6_rates_arh' then
        dv_sr_lspv_docs_api.set_employees(p_flag => false);
        dv_sr_lspv_docs_api.set_last_only(p_flag => true);
        open l_result for
          select "NDFL2" ndfl2, 
                 "NDFL6" ndfl6, 
                 round("NDFL2" - "NDFL6", 2) ndfl_diff
          from   (
                  select 'DUMMY' src,
                         case level
                           when 1 then 13
                           when 2 then 30
                           when 3 then 35
                         end tax_rate,
                         0 fact01,
                         0 fact02,
                         0 fact03,
                         0 fact04
                  from   dual
                  connect by level < 3
                  union all
                  select 'NDFL6' src,
                         d.tax_rate,
                         sum(d.revenue) revenue,
                         sum(d.benefit) benefit,
                         sum(d.tax_calc) tax_calc,
                         sum(d.tax_retained) tax_retained
                  from   dv_sr_lspv_pers_v d
                  where  d.exists_revenue = 'Y'
                  group  by d.tax_rate
                  union all
                  select 'NDFL2' src,
                         lt.tax_rate,
                         sum(lt.revenue),
                         sum(lt.benefit),
                         sum(lt.tax_calc),
                         sum(lt.tax_retained)       
                  from   f2ndfl_arh_totals_v lt
                  group by lt.tax_rate
                 ) t
          unpivot(
            fact_val
            for fact in (fact01, fact02, fact03, fact04)
          ) up
          pivot(
          sum(fact_val)
            for src in('NDFL2' as "NDFL2", 'NDFL6' as "NDFL6")
          )
          order by tax_rate, fact; --*/
      when 'cmp_f2ndfl_f6_return' then
        dv_sr_lspv_docs_api.set_employees(p_flag => false);
        dv_sr_lspv_docs_api.set_last_only(p_flag => true);
        open l_result for
          select sum(case t.current_year when 'N' then t.tax_returned end) val01, --prev
                 sum(case t.current_year when 'Y' then t.tax_returned end) val02  --curr
          from   ndfl6_tax_returns_v t
          union all
          select sum(dd.tax_83) tax_83,
                 0
          from   dv_sr_lspv_docs_v dd;
      when 'ndfl2_tax_corr' then
        open l_result for
          select case 
                   when coalesce(c.spr_revenue_corr, 0) - coalesce(c.revenue_corr, 0) > .01  or
                        coalesce(c.spr_tax_corr, 0) - coalesce(c.tax_corr, 0) > .01 then 'Требуется корректирующая справка'
                   when c.exists_xml = 'N' then 'Последняя справка не отправлена'
                 end state,
                 c.kod_na,
                 c.year_doc,
                 c.gf_person,
                 c.year_doc,
                 c.gf_person, 
                 c.fio, 
                 c.spr_nom, 
                 c.spr_corr_num, 
                 c.spr_date, 
                 c.spr_revenue, 
                 c.spr_tax, 
                 c.spr_revenue_corr,
                 c.spr_tax_corr, 
                 c.revenue_corr, 
                 c.tax_corr
          from   ndfl2_corr_spr_rep_v c
          order by c.fio, c.year_doc;
      when 'tax_retained_report' then
        open l_result for
          select dc.describe || ', схема ' || ps.name payment_descr,
                 d.tax_retained_13,
                 d.tax_retained_30,
                 null                                 dummy_col,
                 d.tax_wo_corr_13,
                 d.tax_corr_13,
                 d.tax_wo_corr_30,
                 d.tax_corr_30
          from   ndfl_report_tax_retained_v d,
                 sp_det_charge_types_v      dc,
                 sp_pen_schemes_v           ps
          where  1=1
          and    ps.code(+) = d.pen_scheme_code
          and    dc.det_charge_type = d.det_charge_type
          order by 
            case d.det_charge_type when 'PENSION' then 1 when 'RITUAL' then 2 else 3 end,
            d.pen_scheme_code;
      when 'tax_retained_report2' then
        declare
          l_tax_return      number;
          l_tax_return_prev number;
        begin
          select sum(g.tax_return), sum(g.tax_return_prev)
          into   l_tax_return, l_tax_return_prev
          from   ndfl6_part1_general_v g;
          --
          open l_result for
            select 'TAX_RETAINED_DATE' key, (select sum(d.tax_retained) from ndfl6_part2_v d)     value from dual union all
            select 'TAX_NOT_RETAINED'  key, (select sum(d.tax_diff) from dv_sr_lspv_tax_diff_v d) value from dual union all
            select 'TAX_RETURN'        key, l_tax_return                                          value from dual union all
            select 'TAX_RETURN_PREV'   key, l_tax_return_prev                                     value from dual union all
            select 'TAX_RETURN_83'     key, (select sum(d.tax_83) from dv_sr_lspv_docs_v d)       value from dual union all
            select 'TAX_CALC'          key, (select sum(d.tax_calc) from dv_sr_lspv_pers_v d where d.exists_revenue = 'Y')  value from dual;
        end;
      when 'detail_report' then
        open l_result for
          select r.date_op,
                 case when r.first_row = 'Y' and r.revenue > 0 then r.date_op + 1 end transfer_date,
                 case r.first_row when 'Y' then r.revenue       end revenue      ,
                 case r.first_row when 'Y' then r.benefit       end benefit      ,
                 case r.first_row when 'Y' then r.tax           end tax          ,
                 r.date_op                                          date_op_corr ,
                 r.date_corr,
                 r.revenue_corr,
                 r.benefit_corr,
                 r.tax_corr
          from   ndfl6_report_detail_v r
          where  r.date_op <= dv_sr_lspv_docs_api.get_end_date
          order by r.date_op,
                   r.date_corr;
      when 'detail_report_2' then
        open l_result for
          select r.date_op,
                 case when r.first_row = 'Y' and coalesce(tax13, 0) + coalesce(tax30, 0) <> 0 then r.date_op + 1     end date_transfer,
                 r.det_charge_describe,
                 r.pen_scheme,
                 case r.first_row when 'Y' then r.revenue13       end revenue13      ,
                 case r.first_row when 'Y' then r.benefit13       end benefit13      ,
                 case r.first_row when 'Y' then r.tax13           end tax13          ,
                 case r.first_row when 'Y' then r.revenue30       end revenue30      ,
                 case r.first_row when 'Y' then r.tax30           end tax30          ,
                 r.date_op                                            date_op_corr   ,
                 r.date_corr,
                 r.revenue13_corr,
                 r.benefit13_corr,
                 r.tax13_corr,
                 r.revenue30_corr,
                 r.tax30_corr
          from   ndfl6_report_detail2_v r
          where  r.date_op <= dv_sr_lspv_docs_api.get_end_date
          order by r.date_op,
                   r.det_charge_ord_num, 
                   r.pen_scheme, 
                   r.date_corr;
      when 'correcting_report' then
        open l_result for
          select c.quarter_op,
                 c.month_op,
                 c.date_op,
                 c.ssylka_doc_op,
                 c.year_doc,
                 c.quarter_doc,
                 c.date_doc,
                 c.ssylka_doc,
                 c.source_amount,
                 c.amount,
                 c.nom_vkl,
                 c.nom_ips,
                 c.shifr_schet,
                 c.sub_shifr_schet,
                 c.gf_person,
                 c.last_name,
                 c.first_name,
                 c.second_name
          from   ndfl6_report_correcting_v c
          where  coalesce(c.amount, 0) <> 0
          and    c.date_op <= dv_sr_lspv_docs_api.get_end_date
          order by c.date_op, c.last_name, c.first_name, c.second_name, c.nom_vkl, c.nom_ips, c.date_doc, c.shifr_schet, c.sub_shifr_schet;
      when 'error_report' then
        open l_result for
          select r.date_op,
                 r.ssylka_doc,
                 r.nom_vkl,
                 r.nom_ips,
                 r.shifr_schet,
                 r.sub_shifr_schet,
                 r.amount,
                 case r.error_code
                   when 1 then
                     'Отсутствует ссылка на корректирующую операцию'
                   when 2 then
                     'Ошибка возврата: не привязан к исходной или SERVICE_DOC <> -1 или возврат налога без коррекции дохода (выкуп)'
                   when 3 then
                     'Не определен GF_PERSON участника (см. sp_fiz_lits_non_ident_v)'
                   when 4 then
                     'Не определен GF_PERSON получателя пособия (см. vyplach_posob_non_ident_v)'
                   when 5 then
                     'Вторая или более выплата пособия по одному контрагенту'
                   when 6 then
                     'Персональные данные: ' ||
                     case
                       when bitand(power(2, 0), r.error_sub_code) > 0 then 'ФИО'
                     end || ', ' ||
                     case
                       when bitand(power(2, 1), r.error_sub_code) > 0 then 'ДР'
                     end || ', ' ||
                     case
                       when bitand(power(2, 2), r.error_sub_code) > 0 then 'ИНН'
                     end || ', ' ||
                     case
                       when bitand(power(2, 3), r.error_sub_code) > 0 then 'статус резидента'
                     end
                   when 7 then
                     'Операция с отрицательной суммой, не являющаяся коррекцией!'
                   when 8 then
                     'Контрагент не идентифицирован программой UPDATE_GF_PERSON'
                 end err_description,
                 r.fio
          from   dv_sr_lspv_errors_v r
          order by r.error_code, r.gf_person, r.nom_vkl, r.nom_ips, r.shifr_schet, r.SUB_SHIFR_SCHET, r.ssylka_doc;
      when 'tax_diff_report' then
        open l_result for
          select d.gf_person,
                 p.lastname, 
                 p.firstname, 
                 p.secondname, 
                 d.tax_rate,
                 d.accounts_cnt,
                 d.tax_calc,
                 d.tax_retained
          from   dv_sr_lspv_tax_diff_v d,
                 gf_people_v       p
          where  1=1
          and    p.fk_contragent = d.gf_person
          order by d.tax_diff, p.lastname, p.firstname, p.secondname;
      when 'tax_diff_det_report' then
        open l_result for
          select d.gf_person,
                 d.lastname, 
                 d.firstname, 
                 d.secondname,
                 d.ssylka_fl,
                 d.nom_vkl,
                 d.nom_ips, 
                 d.pen_scheme,
                 d.revenue_shifr_schet,
                 d.tax_shifr_schet,
                 d.revenue, 
                 d.benefit, 
                 d.tax,
                 case row_number()over(partition by d.gf_person order by d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips)
                   when 1 then d.tax_retained
                 end tax_retained,
                 case row_number()over(partition by d.gf_person order by d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips)
                   when 1 then d.tax_calc
                 end tax_calc, 
                 case row_number()over(partition by d.gf_person order by d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips)
                   when 1 then d.tax_diff
                 end tax_diff
          from   dv_sr_lspv_tax_diff_det_v d
          order by d.gf_person, d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips;
      when 'tax_diff_from_buf' then
        open l_result for
          select d.gf_person,
                 d.lastname, 
                 d.firstname, 
                 d.secondname,
                 d.ssylka_fl,
                 d.nom_vkl,
                 d.nom_ips, 
                 d.pen_scheme,
                 d.revenue_shifr_schet,
                 d.tax_shifr_schet,
                 d.revenue, 
                 d.benefit, 
                 d.tax,
                 d.tax_retained,
                 d.tax_calc, 
                 d.tax_diff
          from   DV_SR_LSPV_TAX_DIFF_BUF d
          order by d.gf_person, d.pen_scheme, d.nom_vkl, d.nom_ips;
      when 'ndfl6_part1_general_data' then
        open l_result for
          select d.total_persons,
                 d.tax_retained,
                 null tax_not_retained,
                 d.tax_return
          from   ndfl6_part1_general_v d;
      when 'ndfl6_recalc_curr_year' then
        open l_result for
          select t.det_charge_describe || ' сх. ' || t.pen_scheme describe,
                 abs(t.tax_returned) tax_returned
          from   ndfl6_tax_returns_v t
          where  t.current_year = 'Y'
          order  by t.det_charge_ord_num, t.pen_scheme;
      when 'ndfl6_recalc_prev_year' then
        open l_result for
          select t.det_charge_describe || ' сх. ' || t.pen_scheme describe,
                 abs(t.tax_returned) tax_returned
          from   ndfl6_tax_returns_v t
          where  t.current_year = 'N'
          order  by t.det_charge_ord_num, t.pen_scheme;
      when 'ndfl6_part1_rates_data' then
        /*
        TODO: owner="V.Zhuravov" category="Optimize" priority="1 - High" created="28.08.2017"
        text="Доработать курсор"
        */
        open l_result for
          select d.tax_rate,
                 sum(d.revenue)  revenue       ,
                 null            revenue_div   ,
                 sum(d.benefit)  benefit       ,
                 sum(d.tax_calc) tax_calc      ,
                 null            tax_calc_div  ,
                 null            advance_amount
          from   dv_sr_lspv_pers_v d
          where  d.exists_revenue = 'Y'
          group by d.tax_rate
          order by d.tax_rate;
      when 'ndfl6_part1_rates_13_wo_bb' then
        open l_result for
          select t.det_charge_describe,
                 t.pen_scheme,
                 t.revenue,
                 nvl(t.storno_total, 0) storno_total ,
                 nvl(t.storno_q1,    0) storno_q1    ,
                 nvl(t.storno_q2,    0) storno_q2    ,
                 nvl(t.storno_q3,    0) storno_q3    ,
                 nvl(t.storno_q4,    0) storno_q4
          from   ndfl6_part1_rates_13_wo_bb_v t
          order by t.det_charge_ord_num, t.pen_scheme_code;
      when 'ndfl6_part1_rates_13_bb' then
        open l_result for
          select case when row_number()over(order by d.pen_scheme_code) = 1 then d.det_charge_describe end det_charge_describe,
                 d.pen_scheme,
                 d.revenue,
                 d.fix_revenue,
                 nvl(d.source_revenue, 0)   source_revenue,
                 nvl(d.corr_revenue,   0)   corr_revenue,
                 nvl(d.source_revenue, 0) + 
                   nvl(d.corr_revenue, 0) 
                                            diff_revenue,
                 nvl(d.revenue_prev_year,0) revenue_prev_year
          from   ndfl6_part1_rates_13_bb_v d
          order by d.pen_scheme_code;
      when 'ndfl6_part1_rates_30' then
        open l_result for
          select d.det_charge_describe,
                 d.pen_scheme,
                 d.revenue,
                 d.tax_calc,
                 case
                   when d.tax_diff <> 0 then
                     case 
                       when d.tax_diff < 1 then
                         'недоплата'
                       when d.tax_diff > -1 then
                         'переплата'
                     end || ': ' || to_char(abs(d.tax_diff)) || ' руб., см. ниже'
                 end diff_descr
          from   ndfl6_part1_rates_30_v d
          order by d.det_charge_ord_num, d.pen_scheme_code;
      when 'ndfl6_part1_rates_persn' then
        open l_result for
          select gp.lastname,
                 gp.firstname,
                 gp.secondname,
                 gp.tax_calc,
                 gp.tax_retained,
                 gp.tax_diff
          from   ndfl6_part1_rates_30_persns_v gp
          order by gp.lastname,
                   gp.firstname,
                   gp.secondname;
      when 'ndfl6_part2_data' then
        open l_result for
          select d.date_doc,
                 d.revenue,
                 d.tax_retained
          from   ndfl6_part2_v d
          where  coalesce(d.revenue, 0) <> 0 or coalesce(d.tax_retained, 0) <> 0
          order by d.date_doc;
      when 'ndfl6_employees_report' then
        open l_result for
          with emp_with_revenue as (
            select p.gf_person,
                   listagg(dc.describe, ', ') within group(order by dc.order_num) revenue_types,
                   sum(p.revenue) revenue
            from   dv_sr_lspv_docs_pers_v p,
                   sp_det_charge_types_v  dc
            where  dc.det_charge_type(+) = p.det_charge_type
            group  by p.gf_person
            having sum(p.revenue) <> 0
          )
          select emp.familiya,
                 emp.imya,
                 emp.otchestvo,
                 emp.data_rozhd,
                 emp.inn_fl,
                 case
                    when emp.gf_person is not null and exists
                           (select 1
                            from   fnd.sp_fiz_lits sfl
                            where  upper(sfl.familiya) = upper(emp.familiya)
                            and    sfl.gf_person = emp.gf_person
                           ) then
                     'Участник'
                    else
                     'Неучастник'
                  end participant,
                 case
                    when rev.revenue > 0 then
                     'Да'
                    else
                     'Нет'
                  end is_revenue,
                 (select listagg(ps.pen_scheme, ', ') within group(order by ps.pen_scheme)
                  from   (select fl.gf_person, fl.pen_scheme
                          from   sp_fiz_litz_lspv_v fl
                          where  fl.gf_person = emp.gf_person
                          and    upper(fl.last_name) = upper(emp.familiya)
                          and    fl.pen_scheme_code <> 7
                          group  by fl.gf_person, fl.pen_scheme) ps) pen_schemes,
                 rev.revenue_types
          from   f_ndfl_load_spisrab emp, 
                 emp_with_revenue    rev
          where  1 = 1
          and    rev.gf_person(+) = emp.gf_person
          and    emp.god = extract(year from p_end_date)
          order  by emp.familiya, emp.imya, emp.otchestvo, emp.data_rozhd;
      else
        fix_exception('get_report('||l_report_code || '): 6 Неизвестный код отчета');
        raise utl_error_api.G_EXCEPTION;
    end case;
    --
    return l_result;
    --
  exception
    when others then
      --
      fix_exception;
      raise;
      --x_err_msg := nvl(x_err_msg, dbms_utility.format_error_stack || chr(10) || dbms_utility.format_error_backtrace);
  end get_report;
  
end ndfl_report_api;
/
