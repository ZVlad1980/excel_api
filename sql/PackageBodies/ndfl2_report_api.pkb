create or replace package body ndfl2_report_api is

  -- Private type declarations
  /**
   * �������� ��������� ������
   */
  procedure fix_exception(p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => p_msg
    );
  end;
  
  /**
   * ������� get_report ���������� ������ � ������� ������
   * 
   * @param p_report_code - ��� ������
   * @param p_end_date    - �������� ���� ������
   * @param p_report_date - ����, �� ������� ����������� �����
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
      when 'f2_arh_batch_xml' then
        open l_result for
          select x.id, 
                 x.filename, 
                 count(distinct s.id) cnt_spr,
                 min(s.familiya)      from_familiya,
                 max(s.familiya)      to_familiya,
                 min(s.nom_spr)       from_nom_spr,
                 max(s.nom_spr)       to_nom_spr,
                 max(s.priznak_s)     priznak_s
          from   f_ndfl_arh_xml_files x,
                 f2ndfl_arh_spravki   s
          where  1=1
          and    s.r_xmlid = x.id
          and    s.god = x.god
          and    s.kod_na = 1
          and    x.god = p_year
          and    x.kod_formy = 2
          group by x.id, x.filename, x.god
          order by id;
      when 'f2_priznak2' then
        open l_result for
          select s.nom_spr,
                 s.familiya || ' ' || s.imya || ' ' || s.otchestvo || ' (' || to_char(s.data_rozhd, 'dd.mm.yyyy') || ')' fio,
                 s.ui_person,
                 case s.status_np
                   when 1 then '��'
                   when 2 then '���'
                   else '�� ����������'
                 end       is_resident,
                 s.grazhd,
                 (select sum(ai.vzysk_ifns)
                  from   f2ndfl_arh_itogi ai
                  where  ai.r_sprid = s.id
                 ) debt_amount,
                 s.nom_korr
          from   f2ndfl_arh_spravki   s
          where  1=1
          and    s.priznak_s = 2
          and    s.kod_na = 1
          and    s.god = p_year
          order by s.nom_spr, s.nom_korr;
      when 'f2_arh_spravki_errors' then
        open l_result for
          with w_errors as (
            select /*+ materialized*/
                   e.kod_na, 
                   e.god, 
                   e.ui_person, 
                   e.inn_fl, 
                   e.grazhd, 
                   e.familiya, 
                   e.imya, 
                   e.otchestvo, 
                   e.data_rozhd, 
                   e.kod_ud_lichn, 
                   e.ser_nom_doc, 
                   e.status_np, 
                   e.is_participant,         
                   e.error_list
            from   f2ndfl_arh_spravki_errors_v e
            where  1=1
            and    e.error_list is not null
            and    e.god = p_year
            and    e.kod_na = 1
          )
          select coalesce(ed.error_type, 'ErrorUnknown') error_type, 
                 coalesce(ed.error_msg, to_char(p.error_id)) error_msg, 
                 e.ui_person, 
                 e.familiya, 
                 e.imya, 
                 e.otchestvo, 
                 to_char(e.data_rozhd, 'dd.mm.yyyy') data_rozhd,
                 e.inn_fl, 
                 e.grazhd, 
                 case e.status_np
                   when 1 then 'Y'
                   when 2 then 'N'
                 end status_np, 
                 e.kod_ud_lichn, 
                 e.ser_nom_doc,
                 s_prev.inn_fl          prev_inn_fl         ,
                 s_prev.grazhd          prev_grazhd         ,
                 s_prev.status_np       prev_status_np      ,
                 s_prev.kod_ud_lichn    prev_kod_ud_lichn   ,
                 s_prev.ser_nom_doc     prev_ser_nom_doc
          from   w_errors e,
                 lateral(
                   select level lvl,
                          to_number(regexp_substr(e.error_list, '[^ ]+', 1, level)) error_id
                   from   dual
                   connect by level <= regexp_count(e.error_list, ' +?') + 1
                 ) p,
                 lateral(
                   select ed.error_msg,
                          ed.error_type,
                          case ed.error_id
                            when 11 then e.inn_fl
                            when 12 then e.ser_nom_doc
                          end || '#' || e.familiya || '#' || e.imya || '#' || e.otchestvo || '#' || e.data_rozhd || '#' || e.ui_person
                            ord_value
                   from   sp_ndfl_errors ed
                   where  ed.error_id = p.error_id
                 )(+) ed,
                 f2ndfl_arh_spravki s_prev
          where  1=1
          and    s_prev.nom_korr(+) = 0 --���� �� ���
          and    s_prev.ui_person(+) = e.ui_person
          and    s_prev.god(+) = e.god - 1
          and    s_prev.kod_na(+) = e.kod_na
          order by ed.error_id, ed.ord_value;
      when 'f2_full_namesake' then
        --�������� �������: fxndfl_util.SovpDan_Kontragentov
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
                   when 1 then '���'
                   when 2 then '���'
                   when 3 then '���+���'
                   when 4 then '����'
                   when 5 then '����+���'
                   when 6 then '����+���'
                   when 7 then '��'
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
                      when 1 then '���'
                      when 2 then '���'
                      when 3 then '���+���'
                      when 4 then '����'
                      when 5 then '����+���'
                      when 6 then '����+���'
                      when 7 then '��'
                      else null
                    end,
                    ls.grazhd,
                    ls.familiya,
                    ls.imya,
                    ls.otchestvo,
                    ls.data_rozhd;
      when 'f2_error_report' then
        --�������� �������: fxndfl_util.OshibDan_vSpravke
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
                         '����������� �� ������' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    grazhd is null
                 union
                  select 2 ecode,
                         '����������� �� �� ������������� ��' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    grazhd = 643
                  and    kod_ud_lichn in (10, 11, 12, 13, 15, 19)
                 union
                  select 3 ecode,
                         '����������� ���� �� ������������� �� ��' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    (grazhd <> 643)
                  and    (kod_ud_lichn not in (10, 11, 12, 13, 15, 19, 23))
                 union
                  select 4 ecode,
                         '��� �� ����������� ��������' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    kod_ud_lichn not in (3, 7, 8, 10, 11, 12, 13, 14, 15, 19, 21, 23, 24, 91)
                 union
                  select 6 ecode,
                         '������������ ������ �������� ��' einfo,
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
                         '������������ ������ ���� �� ���������� � ��' einfo,
                         x.*
                  from   f2ndfl_load_spravki x
                  where  kod_na = 1
                  and    god = p_year
                  and    tip_dox > 0
                  and    kod_ud_lichn = 12
                  and    not regexp_like(ser_nom_doc, '^\d{2}\s\d{7}$')
                 union
                  select 91 ecode,
                         '��������������: ��������� �������� � ����������� ��� �� �� ��' einfo,
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
                         '��������������: ��������� �������� � ��� �� ���������� ��' einfo,
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
                         '��������������: �������� ����������� � ������ ������������� ������������� ���� �������� ��' einfo,
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
      when 'f2_diff_pers_data' then
        --�������� �������: fxndfl_util.OshibDan_vSpravke
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
            from   (select '���_�' einfo,
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
            from   (select '���_�' erfld,
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
            from   (select '���_�' erfld,
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
            from   (select '��' erfld,
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
            from   (select '�����' erfld,
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
            from   (select '�����' erfld,
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
            from   (select '���' erfld,
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
            from   (select '������' erfld,
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
      when 'f2_ndfl_nalplat_pers' then
        --�������� �������: fxndfl_util.SovpDan_Kontragentov
        open l_result for
          with nalplat as (
            select n.nom_vkl,
                   n.nom_ips,
                   n.ssylka_sips,
                   n.gf_person,
                   case n.ssylka_tip
                     when 0 then
                       'PENSIONER'
                     else 'SUCCESSOR'
                   end person_type,
                   case n.sgd_isprvnol
                     when 1 then
                      'N'
                     else
                      'Y'
                   end exists_revenue,
                   case n.nalres_status
                     when 1 then 'Y'
                     when 2 then 'N'
                     else        'Unknown'
                   end is_resident
            from   f_ndfl_load_nalplat n
            where  n.god = dv_sr_lspv_docs_api.get_year
            and    n.kod_na = 1
          ),
          lspv_s as (
            select d.nom_vkl, 
                   d.nom_ips,
                   d.ssylka_fl,
                   d.gf_person,
                   case max(case d.det_charge_type  when 'RITUAL' then 1 else 0 end)
                     when 0 then
                       'PENSIONER'
                     else 'SUCCESSOR'
                   end person_type,
                   case 
                     when sum(d.revenue_curr_year) > 0 then
                       'Y'
                     else 'N'
                   end exists_revenue,
                   case max(d.tax_rate)
                     when 30 then 'N'
                     else         'Y'
                   end is_resident
            from   dv_sr_lspv_docs_v d
            group by d.nom_vkl, 
                   d.nom_ips,
                   d.ssylka_fl,
                   d.gf_person
          ),
          nalplat_pers_v as (
            select n.nom_vkl        nom_vkl_np,
                   n.nom_ips        nom_ips_np,
                   n.gf_person      gf_person_np,
                   n.ssylka_sips    ssylka_np,      
                   n.person_type    person_type_np,
                   n.exists_revenue exists_revenue_np,
                   n.is_resident	  is_resident_np,
                   p.nom_vkl       ,
                   p.nom_ips       ,
                   p.gf_person     ,
                   p.ssylka_fl     ssylka,
                   p.person_type   ,
                   p.exists_revenue,
                   p.is_resident
            from   nalplat n
              full   outer join lspv_s p
              on     p.nom_vkl = n.nom_vkl 
              and    p.nom_ips = n.nom_ips
              and    p.person_type = n.person_type
            where  1=1
            and    (
                     (coalesce(n.gf_person, -1) <> coalesce(p.gf_person, -2))
                    or
                     (n.is_resident <> p.is_resident)
                   )
          )
          select p.nom_vkl_np,
                 p.nom_ips_np,
                 p.gf_person_np,
                 p.ssylka_np,
                 p.person_type_np,
                 p.exists_revenue_np,
                 pnp.fullname,
                 p.is_resident_np,
                 p.nom_vkl,
                 p.nom_ips,
                 p.gf_person,
                 p.ssylka,
                 p.person_type,
                 p.exists_revenue,
                 pp.fullname,
                 p.is_resident
          from   nalplat_pers_v p,
                 gf_people_v    pnp,
                 gf_people_v    pp
          where  1 = 1
          and    pp.fk_contragent(+) = p.gf_person
          and    pnp.fk_contragent(+) = p.gf_person_np;
      else
        fix_exception('get_report('||l_report_code || '): ����������� ��� ������');
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
