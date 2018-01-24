create or replace package body ndfl2_report_api is

  -- Private type declarations
  /**
   * Обвертки обработки ошибок
   */
  procedure fix_exception(p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => p_msg
    );
  end;
  
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
    p_year          int,
    p_report_date   date default null
  ) return sys_refcursor is
    --
    l_result      sys_refcursor;
    l_report_code varchar2(100);
    --
  begin
    --
    l_report_code := p_report_code;
    dv_sr_lspv_docs_api.set_period(
      p_year        => p_year,
      p_report_date => p_report_date
    );
    --
    case l_report_code
      when 'f2_full_namesake' then
        --источник запроса: fxndfl_util.SovpDan_Kontragentov
        open l_result for
          select ns.caid fk_contragent,
                 ls.ssylka,
                 ls.tip_dox,
                 ls.inn_fl,
                 ls.grazhd,
                 ls.familiya,
                 ls.imya,
                 ls.otchestvo,
                 ls.data_rozhd,
                 ls.kod_ud_lichn,
                 ls.ser_nom_doc,
                 ls.status_np,
                 case ns.sum_code
                   when 1 then 'ИНН'
                   when 2 then 'УДЛ'
                   when 3 then 'ИНН+УДЛ'
                   when 4 then 'ФИОД'
                   when 5 then 'ФИОД+ИНН'
                   when 6 then 'ФИОД+УДЛ'
                   when 7 then 'всё'
                   else null
                 end er_tip
          from   f2ndfl_load_spravki ls
          inner  join (
                       select kod_na,
                               god,
                               ssylka,
                               tip_dox,
                               flag_otmena,
                               sum(sovp_code) sum_code,
                               min(fk_contragent) caid
                       from   (select *
                                from   (select ns.kod_na,
                                               ns.god,
                                               ns.ssylka,
                                               ns.tip_dox,
                                               ns.flag_otmena,
                                               ns.fk_contragent,
                                               1 sovp_code,
                                               count(*) over(partition by ls.inn_fl) cf,
                                               count(*) over(partition by ls.inn_fl, ns.fk_contragent) ck,
                                               count(*) over(partition by ls.inn_fl, ns.ui_person) cu
                                        from   f2ndfl_load_spravki ls
                                        inner  join f2ndfl_arh_nomspr ns
                                        on     ns.kod_na = ls.kod_na
                                        and    ns.god = ls.god
                                        and    ns.ssylka = ls.ssylka
                                        and    ns.tip_dox = ls.tip_dox
                                        and    ns.flag_otmena = 0
                                        and    ls.nom_korr = 0
                                        where  ls.inn_fl is not null
                                        and    ls.god = p_year)
                                where  cf <> cu
                               union
                                select *
                                from   (select ns.kod_na,
                                               ns.god,
                                               ns.ssylka,
                                               ns.tip_dox,
                                               ns.flag_otmena,
                                               ns.fk_contragent,
                                               2 sovp_code,
                                               count(*) over(partition by ls.ser_nom_doc) cf,
                                               count(*) over(partition by ls.ser_nom_doc, ns.fk_contragent) ck,
                                               count(*) over(partition by ls.ser_nom_doc, ns.ui_person) cu
                                        from   f2ndfl_load_spravki ls
                                        inner  join f2ndfl_arh_nomspr ns
                                        on     ns.kod_na = ls.kod_na
                                        and    ns.god = ls.god
                                        and    ns.ssylka = ls.ssylka
                                        and    ns.tip_dox = ls.tip_dox
                                        and    ns.flag_otmena = 0
                                        and    ls.nom_korr = 0
                                        where  ls.god = p_year)
                                where  cf <> cu
                               union
                                select *
                                from   (select ns.kod_na,
                                               ns.god,
                                               ns.ssylka,
                                               ns.tip_dox,
                                               ns.flag_otmena,
                                               ns.fk_contragent,
                                               4 sovp_code,
                                               count(*) over(partition by ls.familiya, ls.imya, ls.otchestvo, ls.data_rozhd) cf,
                                               count(*) over(partition by ls.familiya, ls.imya, ls.otchestvo, ls.data_rozhd, ns.fk_contragent) ck,
                                               count(*) over(partition by ls.familiya, ls.imya, ls.otchestvo, ls.data_rozhd, ns.ui_person) cu
                                        from   f2ndfl_load_spravki ls
                                        inner  join f2ndfl_arh_nomspr ns
                                        on     ns.kod_na = ls.kod_na
                                        and    ns.god = ls.god
                                        and    ns.ssylka = ls.ssylka
                                        and    ns.tip_dox = ls.tip_dox
                                        and    ns.flag_otmena = 0
                                        and    ls.nom_korr = 0
                                        where  ls.god = p_year)
                                where  cf <> cu
                                )
                       group  by kod_na,
                                  god,
                                  ssylka,
                                  tip_dox,
                                  flag_otmena
                       ) ns
          on     ns.kod_na = ls.kod_na
          and    ns.god = ls.god
          and    ns.ssylka = ls.ssylka
          and    ns.tip_dox = ls.tip_dox
          and    ns.flag_otmena = 0
          and    ls.nom_korr = 0
          order  by ns.sum_code desc,
                    case ns.sum_code
                      when 1 then 'ИНН'
                      when 2 then 'УДЛ'
                      when 3 then 'ИНН+УДЛ'
                      when 4 then 'ФИОД'
                      when 5 then 'ФИОД+ИНН'
                      when 6 then 'ФИОД+УДЛ'
                      when 7 then 'всё'
                      else null
                    end,
                    ls.grazhd,
                    ls.familiya,
                    ls.imya,
                    ls.otchestvo,
                    ls.data_rozhd;
      when 'f2_error_report' then
        --источник запроса: fxndfl_util.OshibDan_vSpravke
        open l_result for
          select ns.fk_contragent,
                 ls.ssylka,
                 ls.tip_dox,
                 ls.inn_fl,
                 ls.grazhd,
                 ls.familiya,
                 ls.imya,
                 ls.otchestvo,
                 ls.data_rozhd,
                 ls.kod_ud_lichn,
                 ls.ser_nom_doc,
                 ls.status_np,
                 ls.einfo
          from   (select 1 ecode,
                         'ГРАЖДАНСТВО не задано' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    grazhd is null
                 union
                  select 2 ecode,
                         'ГРАЖДАНСТВО РФ не соответствует УЛ' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    grazhd = 643
                  and    kod_ud_lichn in (10, 11, 12, 13, 15, 19)
                 union
                  select 3 ecode,
                         'ГРАЖДАНСТВО неРФ не соответствует УЛ РФ' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    (grazhd <> 643)
                  and    (kod_ud_lichn not in (10, 11, 12, 13, 15, 19, 23))
                 union
                  select 4 ecode,
                         'Тип УЛ запрещенное значение' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    kod_ud_lichn not in (3, 7, 8, 10, 11, 12, 13, 14, 15, 19, 21, 23, 24, 91)
                 union
                  select 6 ecode,
                         'Неправильный шаблон Паспорта РФ' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    kod_ud_lichn = 21
                  and    not
                         regexp_like(ser_nom_doc, '^\d{2}\s\d{2}\s\d{6}$')
                 union
                  select 7 ecode,
                         'Неправильный шаблон Вида на жительство в РФ' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    kod_ud_lichn = 12
                  and    not regexp_like(ser_nom_doc, '^\d{2}\s\d{7}$')
                 union
                  select 91 ecode,
                         'Предупреждение: Налоговый резидент и ГРАЖДАНСТВО или УЛ не РФ' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    status_np = 1
                  and    ((grazhd is null or grazhd <> 643)and
                        kod_ud_lichn in (10, 11, 13, 15, 19))
                 union
                  select 92 ecode,
                         'Предупреждение: Налоговый резидент и вид на жительство РФ' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    status_np = 1
                  and    ((grazhd is null or grazhd <> 643) and
                        kod_ud_lichn = 12)
                 union
                  select 93 ecode,
                         'Предупреждение: Значения ГРАЖДАНСТВО и ШАБЛОН УДОСТОВЕРЕНИЯ соответствуют коду ПАСПОРТА РФ' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    kod_ud_lichn <> 21
                  and    grazhd = 643
                  and    regexp_like(ser_nom_doc, '^\d{2}\s\d{2}\s\d{6}$')
                ) ls
          inner  join f2ndfl_arh_nomspr ns
          on     ns.kod_na = ls.kod_na
          and    ns.god = ls.god
          and    ns.ssylka = ls.ssylka
          and    ns.tip_dox = ls.tip_dox
          and    ns.flag_otmena = 0
          and    ls.nom_korr = 0
          order  by ecode,
                    familiya;
  --!!!!!!!!!!!!
      when 'f2_diff_pers_data' then
        --источник запроса: fxndfl_util.OshibDan_vSpravke
        open l_result for
          select t.fk_contragent,
                 t.ssylka,
                 t.tip_dox,
                 t.inn_fl,
                 t.grazhd,
                 t.familiya,
                 t.imya,
                 t.otchestvo,
                 t.data_rozhd,
                 t.kod_ud_lichn,
                 t.ser_nom_doc,
                 t.status_np,
                 t.einfo
          from   (
            select *
            from   (select 'ФИО_Ф' einfo,
                           count(*) over(partition by ns.fk_contragent, ls.familiya) cfld,
                           ns.ccid,
                           ns.fk_contragent,
                           ls.*
                    from   (select tt.kod_na,
                                   tt.god,
                                   tt.ssylka,
                                   tt.tip_dox,
                                   tt.flag_otmena,
                                   tt.fk_contragent,
                                   tt.ccid
                            from   (select kod_na,
                                           god,
                                           ssylka,
                                           tip_dox,
                                           flag_otmena,
                                           fk_contragent,
                                           count(*) over(partition by fk_contragent) ccid
                                    from   f2ndfl_arh_nomspr
                                    where  kod_na = 1
                                    and    god = p_year
                                    and    tip_dox > 0
                                    and    fk_contragent is not null) tt
                            where  ccid > 1) ns
                    inner  join f2ndfl_load_spravki ls
                    on     ns.kod_na = ls.kod_na
                    and    ns.god = ls.god
                    and    ns.ssylka = ls.ssylka
                    and    ns.tip_dox = ls.tip_dox
                    and    ns.flag_otmena = 0
                    and    ls.nom_korr = 0)
            where  ccid <> cfld
           union
            select *
            from   (select 'ФИО_И' erfld,
                           count(*) over(partition by ns.fk_contragent, ls.imya) cfld,
                           ns.ccid,
                           ns.fk_contragent,
                           ls.*
                    from   (select *
                            from   (select kod_na,
                                           god,
                                           ssylka,
                                           tip_dox,
                                           flag_otmena,
                                           fk_contragent,
                                           count(*) over(partition by fk_contragent) ccid
                                    from   f2ndfl_arh_nomspr
                                    where  kod_na = 1
                                    and    god = p_year
                                    and    tip_dox > 0
                                    and    fk_contragent is not null)
                            where  ccid > 1) ns
                    inner  join f2ndfl_load_spravki ls
                    on     ns.kod_na = ls.kod_na
                    and    ns.god = ls.god
                    and    ns.ssylka = ls.ssylka
                    and    ns.tip_dox = ls.tip_dox
                    and    ns.flag_otmena = 0
                    and    ls.nom_korr = 0)
            where  ccid <> cfld
           union
            select *
            from   (select 'ФИО_О' erfld,
                           count(*) over(partition by ns.fk_contragent, ls.otchestvo) cfld,
                           ns.ccid,
                           ns.fk_contragent,
                           ls.*
                    from   (select *
                            from   (select kod_na,
                                           god,
                                           ssylka,
                                           tip_dox,
                                           flag_otmena,
                                           fk_contragent,
                                           count(*) over(partition by fk_contragent) ccid
                                    from   f2ndfl_arh_nomspr
                                    where  kod_na = 1
                                    and    god = p_year
                                    and    tip_dox > 0
                                    and    fk_contragent is not null)
                            where  ccid > 1) ns
                    inner  join f2ndfl_load_spravki ls
                    on     ns.kod_na = ls.kod_na
                    and    ns.god = ls.god
                    and    ns.ssylka = ls.ssylka
                    and    ns.tip_dox = ls.tip_dox
                    and    ns.flag_otmena = 0
                    and    ls.nom_korr = 0)
            where  ccid <> cfld
           union
            select *
            from   (select 'ДР' erfld,
                           count(*) over(partition by ns.fk_contragent, ls.data_rozhd) cfld,
                           ns.ccid,
                           ns.fk_contragent,
                           ls.*
                    from   (select *
                            from   (select kod_na,
                                           god,
                                           ssylka,
                                           tip_dox,
                                           flag_otmena,
                                           fk_contragent,
                                           count(*) over(partition by fk_contragent) ccid
                                    from   f2ndfl_arh_nomspr
                                    where  kod_na = 1
                                    and    god = p_year
                                    and    tip_dox > 0
                                    and    fk_contragent is not null)
                            where  ccid > 1) ns
                    inner  join f2ndfl_load_spravki ls
                    on     ns.kod_na = ls.kod_na
                    and    ns.god = ls.god
                    and    ns.ssylka = ls.ssylka
                    and    ns.tip_dox = ls.tip_dox
                    and    ns.flag_otmena = 0
                    and    ls.nom_korr = 0)
            where  ccid <> cfld
           union
            select *
            from   (select 'УДЛИЧ' erfld,
                           count(*) over(partition by ns.fk_contragent, ls.ser_nom_doc) cfld,
                           ns.ccid,
                           ns.fk_contragent,
                           ls.*
                    from   (select *
                            from   (select kod_na,
                                           god,
                                           ssylka,
                                           tip_dox,
                                           flag_otmena,
                                           fk_contragent,
                                           count(*) over(partition by fk_contragent) ccid
                                    from   f2ndfl_arh_nomspr
                                    where  kod_na = 1
                                    and    god = p_year
                                    and    tip_dox > 0
                                    and    fk_contragent is not null)
                            where  ccid > 1) ns
                    inner  join f2ndfl_load_spravki ls
                    on     ns.kod_na = ls.kod_na
                    and    ns.god = ls.god
                    and    ns.ssylka = ls.ssylka
                    and    ns.tip_dox = ls.tip_dox
                    and    ns.flag_otmena = 0
                    and    ls.nom_korr = 0)
            where  ccid <> cfld
           union
            select *
            from   (select 'ГРАЖД' erfld,
                           count(*) over(partition by ns.fk_contragent, ls.grazhd) cfld,
                           ns.ccid,
                           ns.fk_contragent,
                           ls.*
                    from   (select *
                            from   (select kod_na,
                                           god,
                                           ssylka,
                                           tip_dox,
                                           flag_otmena,
                                           fk_contragent,
                                           count(*) over(partition by fk_contragent) ccid
                                    from   f2ndfl_arh_nomspr
                                    where  kod_na = 1
                                    and    god = p_year
                                    and    tip_dox > 0
                                    and    fk_contragent is not null)
                            where  ccid > 1) ns
                    inner  join f2ndfl_load_spravki ls
                    on     ns.kod_na = ls.kod_na
                    and    ns.god = ls.god
                    and    ns.ssylka = ls.ssylka
                    and    ns.tip_dox = ls.tip_dox
                    and    ns.flag_otmena = 0
                    and    ls.nom_korr = 0)
            where  ccid <> cfld
           union
            select *
            from   (select 'ИНН' erfld,
                           count(*) over(partition by ns.fk_contragent, ls.inn_fl) cfld,
                           ns.ccid,
                           ns.fk_contragent,
                           ls.*
                    from   (select *
                            from   (select kod_na,
                                           god,
                                           ssylka,
                                           tip_dox,
                                           flag_otmena,
                                           fk_contragent,
                                           count(*) over(partition by fk_contragent) ccid
                                    from   f2ndfl_arh_nomspr
                                    where  kod_na = 1
                                    and    god = p_year
                                    and    tip_dox > 0
                                    and    fk_contragent is not null)
                            where  ccid > 1) ns
                    inner  join f2ndfl_load_spravki ls
                    on     ns.kod_na = ls.kod_na
                    and    ns.god = ls.god
                    and    ns.ssylka = ls.ssylka
                    and    ns.tip_dox = ls.tip_dox
                    and    ns.flag_otmena = 0
                    and    ls.nom_korr = 0)
            where  ccid <> cfld
           union
            select *
            from   (select 'СТАТУС' erfld,
                           count(*) over(partition by ns.fk_contragent, ls.status_np) cfld,
                           ns.ccid,
                           ns.fk_contragent,
                           ls.*
                    from   (select *
                            from   (select kod_na,
                                           god,
                                           ssylka,
                                           tip_dox,
                                           flag_otmena,
                                           fk_contragent,
                                           count(*) over(partition by fk_contragent) ccid
                                    from   f2ndfl_arh_nomspr
                                    where  kod_na = 1
                                    and    god = p_year
                                    and    tip_dox > 0
                                    and    fk_contragent is not null)
                            where  ccid > 1) ns
                    inner  join f2ndfl_load_spravki ls
                    on     ns.kod_na = ls.kod_na
                    and    ns.god = ls.god
                    and    ns.ssylka = ls.ssylka
                    and    ns.tip_dox = ls.tip_dox
                    and    ns.flag_otmena = 0
                    and    ls.nom_korr = 0)
            where  ccid <> cfld
          ) t;
      else
        fix_exception('get_report('||l_report_code || '): Неизвестный код отчета');
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
  
end ndfl2_report_api;
/
