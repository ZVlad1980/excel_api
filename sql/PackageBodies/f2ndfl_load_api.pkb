create or replace package body f2ndfl_load_api is
  --Тип действия
  C_ACT_TYPE_LOAD  constant varchar2(1) := 'L';
  C_ACT_TYPE_PURGE constant varchar2(1) := 'P';
  
  type g_util_par_type is record (
    KODNA         number        ,
    GOD           number        ,
    TIPDOX        number        ,
    NOMKOR        number        ,
    SPRID         number        ,
    NOMSPR        varchar2(10)  ,
    DATDOK        date          ,
    NOMVKL        number        ,
    NOMIPS        number        ,
    CAID          number        ,
    SRC_SPRID     number        ,
    pCOMMIT       boolean       ,
    NALRES_DEFFER boolean       ,
    ACTUAL_DATE   date          ,
    process_row   dv_sr_lspv_prc_t%rowtype
  );
  
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
   * Процедура set_globals_util_pkg вызывает инициализацию глобальных переменных пакета FXNDFL_UTIL
   *   Инициализация необходима перед вызовом любого метода пакета FXNDFL_UTIL
   */
  procedure set_globals_util_pkg(
    p_globals g_util_par_type
  ) is
  begin
    --
    fxndfl_util.InitGlobals(
        pKODNA  => p_globals.KODNA  ,
        pGOD    => p_globals.GOD    ,
        pTIPDOX => p_globals.TIPDOX ,
        pNOMKOR => p_globals.NOMKOR ,
        pSPRID  => p_globals.SPRID  ,
        pNOMSPR => p_globals.NOMSPR ,
        pDATDOK => p_globals.DATDOK ,
        pNOMVKL => p_globals.NOMVKL ,
        pNOMIPS => p_globals.NOMIPS ,
        pCAID   => p_globals.CAID   ,
        pCOMMIT => nvl(p_globals.pCOMMIT, false),
        pNALRES_DEFFER => p_globals.NALRES_DEFFER,
        pACTUAL_DATE => p_globals.ACTUAL_DATE
      );
    --                               
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end set_globals_util_pkg;
  
  /**
   * Процедура check_legacy_action - проверка допустимости действия
   *   загрузки или очистки
   * !!! Пока только контроль допустимости удаления, НЕТ контроля последовательности создания справок!
   */
  function check_legacy_action(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int,
    p_action_type  varchar2 default C_ACT_TYPE_LOAD --тип действия (L)oad/(P)urge, см. C_ACT_TYPE_
  ) return boolean is
    l_dummy int;
    --
    function check_action_ return boolean is
    begin
      return case
               when p_action_type = 'L' and p_action_code in (
                      C_ACT_LOAD_ALL     ,
                      C_ACT_LOAD_SPRAVKI ,
                      C_ACT_LOAD_TOTAL   ,
                      C_ACT_LOAD_EMPLOYEE,
                      C_ACT_ENUMERATION  ,
                      C_ACT_COPY2ARH     ,
                      C_ACT_INIT_XML     ,
                      C_ACT_DEL_ZERO_REF 
                    ) then true
               when p_action_type = 'P' and p_action_code in (
                      C_PRG_LOAD_ALL    ,
                      C_PRG_LOAD_SPRAVKI,
                      C_PRG_LOAD_TOTAL  ,
                      C_PRG_EMPLOYEES   ,
                      C_PRG_ARH_SPRAVKI ,
                      C_PRG_ARH_TOTAL   ,
                      C_PRG_XML         
                    ) then true
               else false
             end;
    exception
      when no_data_found then
        return false;
    end check_action_;
    --
    function exists_xml_ return boolean is
    begin
      select 1
      into   l_dummy
      from   dual
      where  exists(
               select 1
               from   f_ndfl_arh_xml_files f
               where  f.god = p_year
               and    f.kod_formy = 2
             );
      return true;
    exception
      when no_data_found then
        return false;
    end exists_xml_;
    --
    function exists_load_spravki_ return boolean is
    begin
      select 1
      into   l_dummy
      from   dual
      where exists(
              select 1 
              from   f2ndfl_load_spravki s
              where  s.god = p_year
              and    s.kod_na = p_code_na
            );
      return true;
    exception
      when no_data_found then
        return false;
    end exists_load_spravki_;
    --
    function exists_load_totals_ return boolean is
    begin
      select 1
      into   l_dummy
      from   dual
      where exists(
              select 1 
              from   f2ndfl_load_itogi s
              where  s.god = p_year
              and    s.kod_na = p_code_na
             union all
              select 1 
              from   f2ndfl_load_mes s
              where  s.god = p_year
              and    s.kod_na = p_code_na
             union all
              select 1 
              from   f2ndfl_load_vych s
              where  s.god = p_year
              and    s.kod_na = p_code_na
            );
      return true;
    exception
      when no_data_found then
        return false;
    end exists_load_totals_;
    --
    function exists_arh_spravki_ return boolean is
    begin
      select 1
      into   l_dummy
      from   dual
      where exists(
              select 1
              from   f2ndfl_arh_spravki ss
              where  ss.god = p_year
              and    ss.kod_na = p_code_na
            );
      return true;
    exception
      when no_data_found then
        return false;
    end exists_arh_spravki_;
    --
    function exists_arh_totals_ return boolean is
    begin
      select 1
      into   l_dummy
      from   dual
      where exists(
              select 1
              from   f2ndfl_arh_spravki ss
              where  ss.god = p_year
              and    ss.kod_na = p_code_na
              and    exists  (
                       select s.r_sprid
                       from   f2ndfl_arh_itogi s
                       where  s.r_sprid = ss.id
                      union all
                       select s.r_sprid
                       from   f2ndfl_arh_mes s
                       where  s.r_sprid = ss.id
                      union all
                       select s.r_sprid
                       from   f2ndfl_arh_vych s
                       where  s.r_sprid = ss.id
                     )
            );
      return true;
    exception
      when no_data_found then
        return false;
    end exists_arh_totals_;
    --
    
  begin
    --
    if not check_action_ then
      fix_exception('check_legacy_action(' || p_action_code || '): неизвестный код действия');
      raise e_unknown_action;
    elsif p_action_code in (C_ACT_LOAD_SPRAVKI, C_PRG_LOAD_SPRAVKI) then
      return not exists_load_totals_;
    elsif p_action_code in (C_ACT_LOAD_EMPLOYEE, C_ACT_DEL_ZERO_REF, C_PRG_EMPLOYEES) then
      return not exists_arh_spravki_;
    elsif p_action_code in (C_ACT_LOAD_TOTAL, C_PRG_LOAD_TOTAL, C_ACT_ENUMERATION, C_PRG_ARH_SPRAVKI) then
      return not exists_arh_totals_;
    elsif p_action_code in (C_ACT_INIT_XML) then
      return exists_arh_totals_; --если сформированы ARH_TOTALS
    else
      return not exists_xml_; --запустить purge_loads с флагом force
    end if;
    --
  exception
    when others then
      fix_exception;
      raise;
  end check_legacy_action;
  
  /**
   * Процедура purge_loads - очистка таблиц LOAD и ARH
   *
   * @param p_action_code
   *
   */
  procedure delete_from_loads(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int,
    p_ssylka       int default null,
    p_revenue_type int default null,
    p_nom_corr     int default null
  ) is
  begin
    --
    if ((p_ssylka is not null or p_revenue_type is not null or p_nom_corr is not null) and
         p_action_code <> C_PRG_LOAD_SPRAVKI
       ) and (
         p_revenue_type is not null and p_action_code <> C_PRG_EMPLOYEES
       ) then
      fix_exception('delete_from_loads(' || 
        p_action_code   || ', ' ||
        p_code_na       || ', ' ||
        p_year          || ', ' ||
        p_ssylka        || ', ' ||
        p_revenue_type  || ', ' ||
        p_nom_corr
      || '): запрещенная комбинация параметров очистки!');
      raise e_action_forbidden;
    end if;
    --
    if p_action_code in (C_PRG_XML, C_PRG_ARH_TOTAL) then
      update f2ndfl_arh_spravki s
      set    s.r_xmlid = null
      where  s.r_xmlid is not null
      and    s.kod_na = p_code_na
      and    s.god = p_year;
    end if;
    --
    if p_action_code in (C_PRG_ARH_SPRAVKI, C_PRG_LOAD_TOTAL) then
      update f2ndfl_arh_nomspr t
      set    t.nom_spr = null
      where  t.nom_spr is not null 
      and    t.kod_na = p_code_na
      and    t.god = p_year;
      --
      update f2ndfl_load_spravki t
      set    t.nom_spr = null,
             t.r_sprid = null
      where  t.nom_spr is not null 
      and    t.kod_na = p_code_na
      and    t.god = p_year;
   end if;
   --
   if p_action_code in (C_PRG_ARH_TOTAL, C_PRG_ARH_SPRAVKI, C_PRG_LOAD_TOTAL, C_PRG_LOAD_SPRAVKI, C_PRG_LOAD_ALL) then
      delete from f2ndfl_arh_mes t
      where  t.r_sprid in (
               select s.id
               from   f2ndfl_arh_spravki s
               where  s.kod_na = p_code_na
               and    s.god = p_year
             );
      --
      delete from f2ndfl_arh_vych t
      where  t.r_sprid in (
               select s.id
               from   f2ndfl_arh_spravki s
               where  s.kod_na = p_code_na
               and    s.god = p_year
             );
      --
      delete from f2ndfl_arh_itogi t
      where  t.r_sprid in (
               select s.id
               from   f2ndfl_arh_spravki s
               where  s.kod_na = p_code_na
               and    s.god = p_year
             );
    end if;
    --
    if p_action_code in (C_PRG_ARH_SPRAVKI, C_PRG_LOAD_TOTAL, C_PRG_LOAD_SPRAVKI, C_PRG_LOAD_ALL) then
      update f2ndfl_arh_spravki_err t
      set    t.r_spr_id_prev = null
      where  1=1
      and    t.r_spr_id_prev in (
               select tt.id
               from   f2ndfl_arh_spravki tt
               where  tt.god = p_year
               and    tt.kod_na = p_code_na
             )
      and    t.year > p_year
      and    t.code_na = p_code_na;
      --
      delete from f2ndfl_arh_spravki_err t
      where  t.code_na = p_code_na
      and    t.year = p_year;
      --
      delete from f2ndfl_arh_spravki t
      where  t.kod_na = p_code_na
      and    t.god = p_year;
    end if;
    --
    if p_action_code in (C_PRG_XML, C_PRG_ARH_TOTAL, C_PRG_ARH_SPRAVKI, C_PRG_LOAD_TOTAL, C_PRG_LOAD_SPRAVKI, C_PRG_LOAD_ALL) then
      delete from f_ndfl_arh_xml_files x
      where  x.god = p_year
      and    x.kod_formy = 2;
    end if;
    --
    if p_action_code in (C_PRG_LOAD_TOTAL, C_PRG_EMPLOYEES, C_PRG_LOAD_SPRAVKI, C_PRG_LOAD_ALL) then
      delete from f2ndfl_load_mes t
      where  1=1
      and    t.nom_korr = nvl(p_nom_corr, t.nom_korr)
      and    t.tip_dox = nvl(p_revenue_type, t.tip_dox)
      and    t.ssylka = nvl(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
      --
      delete from f2ndfl_load_vych t
      where  1=1
      and    t.nom_korr = nvl(p_nom_corr, t.nom_korr)
      and    t.tip_dox = nvl(p_revenue_type, t.tip_dox)
      and    t.ssylka = nvl(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
      --
      delete from f2ndfl_load_itogi t
      where  1=1
      and    t.nom_korr = nvl(p_nom_corr, t.nom_korr)
      and    t.tip_dox = nvl(p_revenue_type, t.tip_dox)
      and    t.ssylka = nvl(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
    end if;
    --
    if p_action_code in (C_PRG_LOAD_SPRAVKI, C_PRG_EMPLOYEES, C_PRG_LOAD_ALL) then
      delete from f2ndfl_arh_nomspr t
      where  1=1
      and    nvl(p_nom_corr, 0) = 0
      and    t.tip_dox = nvl(p_revenue_type, t.tip_dox)
      and    t.ssylka = nvl(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
      --
      delete from f2ndfl_load_spravki t
      where  1=1
      and    t.nom_korr = nvl(p_nom_corr, t.nom_korr)
      and    t.tip_dox = nvl(p_revenue_type, t.tip_dox)
      and    t.ssylka = nvl(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
    end if;
    --
  exception
    when others then
      fix_exception;
      raise;
  end delete_from_loads;
  
  /**
   * Процедура purge_loads удаление данных из таблиц LOAD и ARH
   *
   * @param p_action_code - код действия, см. C_PRG_
   * @param p_code_na     - 
   * @param p_year        - 
   * @param p_force       - флаг форсированного режима (без него не будут работать режимы C_PRG_LOAD_ALL, C_PRG_XML)
   * 
   */
  procedure purge_loads(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int,
    p_force        boolean default false
  ) is
    --
    l_process_row  dv_sr_lspv_prc_t%rowtype;
    --
    function check_forbidden_action_ return boolean is
      l_result boolean := false;
    begin
      if not p_force and not check_legacy_action(p_action_code, p_code_na, p_year, C_ACT_TYPE_PURGE) then
          l_result := true;
      end if;
      return l_result;
    end;
    --
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_process_row.process_name := upper(p_action_code);
    l_process_row.start_date   := to_date(p_year || '0101', 'yyyymmdd');
    l_process_row.end_date     := to_date(p_year || '1231', 'yyyymmdd');
    --
    dv_sr_lspv_prc_api.create_process(
      p_process_row => l_process_row
    );
    --
    if check_forbidden_action_ then --not p_force and not check_legacy_action(p_action_code, p_code_na, p_year, C_ACT_TYPE_PURGE) then
      fix_exception('purge_loads(' ||
        p_action_code || ', ' ||
        p_code_na     || ', ' ||
        p_year
      || '): удаление отклонено');
      raise e_action_forbidden;
    end if;
    --
    delete_from_loads(
      p_action_code => p_action_code ,
      p_code_na     => p_code_na     ,
      p_year        => p_year        ,
      p_revenue_type => case p_action_code when C_PRG_EMPLOYEES then 9 else null end
    );
    --
    commit;
    --
    l_process_row.state := 'Success';
    dv_sr_lspv_prc_api.set_process_state(
      p_process_row => l_process_row
    );
    --
  exception
    when others then
      fix_exception;
      rollback;
      if l_process_row.id is not null then
        l_process_row.state := 'ERROR';
        l_process_row.error_msg := sqlerrm;
        dv_sr_lspv_prc_api.set_process_state(
          p_process_row => l_process_row
        );
      end if;
      raise;
  end purge_loads;
  /**
   *
   */
  procedure fill_load_spravki(
    p_globals in out nocopy g_util_par_type
  ) is
  begin
    --
    set_globals_util_pkg(p_globals);
    --
    fxndfl_util.Load_Pensionery_bez_Storno;
    fxndfl_util.Load_Pensionery_so_Storno;
    --
    fxndfl_util.Load_Posobiya_bez_Pravok;
    fxndfl_util.Load_Posobiya_s_Ipravlen;
    --dv_sr_lspv_prc_t
    fxndfl_util.Load_Vykupnye_bez_Pravok;
    fxndfl_util.Load_Vykupnye_s_Ipravlen;
    --
    merge into f2ndfl_load_spravki s
    using (select np.KOD_NA, 
                  np.GOD, 
                  np.Ssylka_Sips, 
                  np.ssylka_tip,
                  np.nalres_status
           from   f_ndfl_load_nalplat np
           where  np.kod_na = p_globals.KODNA
           and    np.god = p_globals.GOD
          ) u
    on    (s.god = u.god and s.kod_na = u.kod_na
           and s.ssylka = u.ssylka_sips
           and case s.tip_dox when 2 then 1 else 0 end = u.ssylka_tip
          )
    when matched then
      update set
        s.status_np = u.nalres_status;
    --Обновление ИНН из CDM.CONTRAGENTS
    merge into f2ndfl_load_spravki s
    using (
            select s.kod_na     ,
                   s.god        ,
                   s.ssylka     ,
                   s.tip_dox    ,
                   s.nom_korr   ,
                   n.ssylka_sips, 
                   n.gf_person,
                   s.inn_fl,
                   c.inn inn_cdm
            from   f_ndfl_load_nalplat n,
                   f2ndfl_load_spravki s,
                   cdm.contragents     c
            where  1=1
            and    coalesce(c.inn, 'NULL') <> coalesce(s.inn_fl, 'NULL')
            and    c.id = n.gf_person
            and    case when s.tip_dox in (1,3) then 0 else 1 end = n.ssylka_tip
            and    s.ssylka = n.ssylka_sips
            and    s.god = n.god
            and    s.kod_na = n.kod_na
            and    n.god = p_globals.GOD
            and    n.kod_na = p_globals.KODNA
          ) u
    on    (s.kod_na   = u.kod_na   and
           s.god      = u.god      and
           s.ssylka   = u.ssylka   and
           s.tip_dox  = u.tip_dox  and
           s.nom_korr = u.nom_korr
          )
    when matched then
      update set
        s.inn_fl_old = u.inn_fl,
        s.inn_fl     = u.inn_cdm;
    --
  exception
    when others then
      fix_exception;
      raise;
  end fill_load_spravki;
  
  /**
   * Процедура загрузки данных по сотрудникам фонда
   *
   *  p_required - флаг обязательности наличия данных, если false и нет данных XML - пропускаем
   *
   */
  procedure load_employee(
    p_globals in out nocopy g_util_par_type,
    p_required boolean
  ) is
    --
  begin
    --
    begin
      f2ndfl_load_empl_api.merge_load_xml(
        p_code_na => p_globals.KODNA,
        p_year    => p_globals.GOD
      );
    exception
      when f2ndfl_load_empl_api.e_no_xml_found then
        if p_required then
          --если загрузка XML обязательна - пропрасываем ошибку дальше
          raise f2ndfl_load_empl_api.e_no_xml_found;
        else
          --иначе - чистим стек ошибок!
          utl_error_api.init_exceptions;
        end if;
    end;
    --
  exception
    when others then
      fix_exception;
      raise;
  end load_employee;
  
  
  /**
   *
   */
  procedure fill_arh_nomspr(
    p_globals in out nocopy g_util_par_type
  ) is
    --
  begin
    --
    set_globals_util_pkg(p_globals);
    --
    fxndfl_util.Load_Numerator;
    --
  exception
    when others then
      fix_exception;
      raise;
  end fill_arh_nomspr;
  
  /**
   * Обновление перс.данных справок (исправление массовых ошибок) - зачем - сам не знаю, видимо так надо
   */
  procedure update_load_spravki(
    p_globals in out nocopy g_util_par_type
  ) is
    --
    procedure update_citizenship_ is
    begin
      merge into f2ndfl_load_spravki s
      using (select s2.kod_na,
                    s2.god,
                    s2.ssylka,
                    s2.tip_dox,
                    s2.nom_korr,
                    gs.ch_kod citizenship
             from   f2ndfl_load_spravki s2,
                    f_ndfl_load_nalplat np,
                    gf_people_v         pe,
                    gf_idcards_v        ic,
                    GNI_STRANY          gs
             where  1 = 1
             and    gs.nb_kod = ic.citizenship
             --
             --and    ic.citizenship is not null
             and    ic.id = pe.fk_idcard
             and    pe.fk_contragent = np.gf_person
             --
             and    np.ssylka_sips = s2.ssylka 
             and    np.ssylka_tip = case when s2.tip_dox in (1,3) then 0 when s2.tip_dox = 2 then 1 else null end
             and    np.god = s2.god
             and    np.kod_na = s2.kod_na
             --
             and    s2.grazhd is null
             and    s2.god = p_globals.GOD
             and    s2.kod_na = p_globals.KODNA
            ) u
      on    (s.kod_na   = u.kod_na   and
             s.god      = u.god      and
             s.ssylka   = u.ssylka   and
             s.tip_dox  = u.tip_dox  and
             s.nom_korr = u.nom_korr
            )
      when matched then
        update set
          s.grazhd = u.citizenship;
    exception
      when others then
        fix_exception;
        raise;
    end update_citizenship_;
    --
    procedure update_idcards_ is
    begin
      merge into f2ndfl_load_spravki s
      using (select s2.kod_na,
                    s2.god,
                    s2.ssylka,
                    s2.tip_dox,
                    s2.nom_korr,
                    --s2.familiya || ' ' || s2.imya || ' ' || s2.otchestvo fio,
                    s2.kod_ud_lichn,
                    s2.ser_nom_doc,
                    ic.fk_idcard_type,
                    ic.series,
                    ic.nbr --,       ic.lastname || ' ' || ic.firstname || ' ' || ic.secondname fio_ic
             from   f2ndfl_load_spravki s2,
                    f_ndfl_load_nalplat np,
                    gf_people_v         pe,
                    gf_idcards_v        ic
             where  1 = 1
                   --
             and    ic.fk_idcard_type(+) <> s2.kod_ud_lichn
             and    ic.id(+) = pe.fk_idcard
             and    pe.fk_contragent(+) = np.gf_person
                   --
             and    np.ssylka_sips = s2.ssylka
             and    np.ssylka_tip = case
                      when s2.tip_dox in (1, 3) then
                       0
                      when s2.tip_dox = 2 then
                       1
                      else
                       null
                    end
             and    np.god = s2.god
             and    np.kod_na = s2.kod_na
                   --
             and    s2.kod_ud_lichn in (1, 2, 4, 22, 26)
             and    s2.god = p_globals.GOD
             and    s2.kod_na = p_globals.KODNA) u
      on (s.kod_na = u.kod_na and s.god = u.god and s.ssylka = u.ssylka and s.tip_dox = u.tip_dox and s.nom_korr = u.nom_korr)
      when matched then
        update
        set    s.kod_ud_lichn = nvl(u.fk_idcard_type, 91),
               s.ser_nom_doc  = case when u.fk_idcard_type is not null then u.series || ' ' || u.nbr else s.ser_nom_doc end;
      --отдельно - т.к. не поддается логике (
      update f2ndfl_load_spravki s
      set    s.kod_ud_lichn = 21,
             s.grazhd = 643
      where  s.god = p_globals.GOD
      and    s.kod_na = p_globals.KODNA
      and    s.tip_dox <> 2
      and    s.ssylka = 491612
      and    s.kod_ud_lichn is null;
      --
    exception
      when others then
        fix_exception;
        raise;
    end update_idcards_;
    --
  begin
    --
    update_citizenship_;
    update_idcards_;
    --
  exception
    when others then
      fix_exception;
      raise;
  end update_load_spravki;
  
  /**
   *
   */
  procedure fill_load_mes(
    p_globals in out nocopy g_util_par_type
  ) is
  begin
    --
    set_globals_util_pkg(p_globals);
    --
    fxndfl_util.Load_MesDoh_Pensia_bezIspr;
    fxndfl_util.Load_MesDoh_Pensia_sIspravl;
    --
    fxndfl_util.Load_MesDoh_Posob_bezIspr;
    fxndfl_util.Load_MesDoh_Posob_sIspravl;
    --
    fxndfl_util.Load_MesDoh_Vykup_bezIspr;
    fxndfl_util.Load_MesDoh_Vykup_sIspravl;
    --
  exception
    when others then
      fix_exception;
      raise;
  end fill_load_mes;
  
  /**
   * Процедура delete_zero_ref - удалит из f2ndfl_load и f2ndfl_arh справки с нулевым доходом
   *   Текущая логика допускает их появление
   *
   *  Если действие запрещено - e_action_forbidden
   *
   */
  procedure delete_zero_ref(
    p_globals  in out nocopy g_util_par_type
  ) is
    cursor l_zero_ref_cur(p_code_na int, p_year int) is
      select li.kod_na,
             li.god,
             li.ssylka,
             li.tip_dox,
             li.nom_korr
      from   f2ndfl_load_itogi li
      where  1=1
      and    coalesce(li.sgd_sum, 0) = 0
      and    li.kod_na = p_code_na 
      and    li.god = p_year
      and    li.tip_dox <> 9; --кроме сотрудников
    type l_refs_tbl_type is table of l_zero_ref_cur%rowtype;
    l_refs_tbl l_refs_tbl_type;
  begin
    --
    if not check_legacy_action(C_ACT_DEL_ZERO_REF, p_globals.KODNA, p_globals.GOD) then
      fix_exception('delete_zero_ref: удаление справок с 0 доходом не доступно, т.к. заполнены таблицы ARH');
      raise e_action_forbidden;
    end if;
    --
    open l_zero_ref_cur(p_globals.KODNA, p_globals.GOD);
    fetch l_zero_ref_cur
      bulk collect into l_refs_tbl;
    close l_zero_ref_cur;
    --
    dbms_output.put_line('Delete zero references');
    for i in 1..l_refs_tbl.count loop
      dbms_output.put('  ' || lpad(to_char(i), 3, ' ') || '. ' || to_char(l_refs_tbl(i).ssylka) || '/' || to_char(l_refs_tbl(i).tip_dox) || '...');
      delete_from_loads(
        p_action_code  => C_PRG_LOAD_SPRAVKI,
        p_code_na      => l_refs_tbl(i).kod_na,
        p_year         => l_refs_tbl(i).god,
        p_ssylka       => l_refs_tbl(i).ssylka,
        p_revenue_type => l_refs_tbl(i).tip_dox,
        p_nom_corr     => l_refs_tbl(i).nom_korr
      );
      dbms_output.put_line('Ok');
    end loop;
    --
  exception
    when others then
      dbms_output.put_line('Error: ' || sqlerrm);
      fix_exception($$PLSQL_LINE);
      raise;
  end delete_zero_ref;
  
  /**
   * Процедура create_load_total расчет итогов F2NDFL_ITOG
   *
   * @param  -
   *
   */
  procedure fill_load_total(
    p_globals  in out nocopy g_util_par_type
  ) is
    l_dummy int;
    procedure init_ is begin set_globals_util_pkg(p_globals); end init_;
    --
  begin
    --
    init_; fxndfl_util.Load_Vychety;
    --
    init_; fxndfl_util.Load_Itogi_Pensia;
    init_; fxndfl_util.Load_Itogi_Posob_bezIspr;
    init_; fxndfl_util.Load_Itogi_Vykup_bezIspr;
    init_; fxndfl_util.Load_Itogi_Vykup_sIspravl;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end fill_load_total;
  
  /**
   * Процедура enum_refs - нумерация справок 2НДФЛ
   *  Вызывается только после полного формирования Loads и NOMSPR
   */
  procedure enum_refs(
    p_globals in out nocopy g_util_par_type
  ) is
  begin
    --
    set_globals_util_pkg(p_globals);
    --
    fxndfl_util.enum_refs(
      p_code_na => p_globals.KODNA,
      p_year    => p_globals.GOD
    );
    --
    f2ndfl_arh_spravki_api.fill_spravki_errors(
      p_code_na => p_globals.KODNA,
      p_year    => p_globals.GOD
    );
  exception
    when others then
      fix_exception;
      raise;
  end enum_refs;
  
  /**
   * Процедура copy_to_arh - копирование load в arh
   */
  procedure copy_to_arh(
    p_globals in out nocopy g_util_par_type
  ) is
  begin
    --
    set_globals_util_pkg(p_globals);
    --
    /*
    TODO: owner="V.Zhuravov" created="02.02.2018"
    text="Добавить защиту от повторного запуска"
    */
    fxndfl_util.KopirSprItog_vArhiv(
      pKodNA  => p_globals.KODNA,
      pGod    => p_globals.GOD
    );
    --
    fxndfl_util.KopirSprMes_vArhiv(
      pKodNA  => p_globals.KODNA,
      pGod    => p_globals.GOD
    );
    --
    fxndfl_util.KopirSprVych_vArhiv(
      pKodNA  => p_globals.KODNA,
      pGod    => p_globals.GOD
    );
    --
    fxndfl_util.update_spravki_finally(
      p_code_na  => p_globals.KODNA,
      p_year     => p_globals.GOD
    );
    --
  exception
    when others then
      fix_exception;
      raise;
  end copy_to_arh;
  
  /**
   * Процедура init_xml - инициализация файлов XML
   */
  procedure init_xml(
    p_globals in out nocopy g_util_par_type
  ) is
  begin
    --
    set_globals_util_pkg(p_globals);
    --
    fxndfl_util.raspredspravki_poxml(
      pKodNA => p_globals.KODNA,
      pGod   => p_globals.GOD,
      pForma => 2
    );
    -- 
  exception
    when others then
      fix_exception;
      raise;
  end init_xml;
  
  /**
   * Процедура create_2ndfl_refs создает справки 2НДФЛ
   * 
   * @ p_action_code - код действия, см. в специи пакета константы C_ACT_
   * @ p_code_na     - 
   * @ p_year        - 
   *
   */
  procedure create_2ndfl_refs(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int,
    p_actual_date  date
  ) is
    l_globals      g_util_par_type;
    l_result       boolean := false;
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_globals.KODNA         := p_code_na;
    l_globals.GOD           := p_year;
    l_globals.NOMKOR        := 0;
    l_globals.NALRES_DEFFER := true;
    l_globals.pCOMMIT       := false;
    l_globals.ACTUAL_DATE   := p_actual_date;
    --
    l_globals.process_row.process_name := upper(p_action_code);
    l_globals.process_row.start_date   := to_date(p_year || '0101', 'yyyymmdd');
    l_globals.process_row.end_date     := to_date(p_year || '1231', 'yyyymmdd');
    --
    dv_sr_lspv_prc_api.create_process(
      p_process_row => l_globals.process_row
    );
    --
    if not check_legacy_action(p_action_code => p_action_code, p_code_na => l_globals.KODNA, p_year => l_globals.GOD) 
      then
      fix_exception('create_2ndfl_refs(' ||
        p_action_code || ', ' ||
        p_code_na     || ', ' ||
        p_year        || '): действие не доступно.');
      raise e_action_forbidden;
    end if;
    
    --Очистка перед выполнением
    delete_from_loads(
      p_action_code  => case p_action_code
                          when C_ACT_LOAD_ALL      then C_PRG_LOAD_ALL    
                          when C_ACT_LOAD_SPRAVKI  then C_PRG_LOAD_SPRAVKI
                          when C_ACT_LOAD_TOTAL    then C_PRG_LOAD_TOTAL  
                          when C_ACT_LOAD_EMPLOYEE then C_PRG_EMPLOYEES    
                          when C_ACT_ENUMERATION   then C_PRG_ARH_SPRAVKI
                          when C_ACT_COPY2ARH      then C_PRG_ARH_TOTAL   
                          when C_ACT_INIT_XML      then C_PRG_XML         
                          else null
                        end,
      p_code_na      => p_code_na    ,
      p_year         => p_year       ,
      p_revenue_type => case p_action_code when C_ACT_LOAD_EMPLOYEE then 9 else null end
    );
    --Отдельно удаляются данные по сотрудникам, т.к. они грузятся только целиком
    if p_action_code = C_ACT_LOAD_TOTAL then
      delete_from_loads(
        p_action_code  => C_PRG_EMPLOYEES ,
        p_code_na      => p_code_na    ,
        p_year         => p_year       ,
        p_revenue_type => 9
      );
    end if;
    --
    if p_action_code in (C_ACT_LOAD_SPRAVKI, C_ACT_LOAD_ALL) then
      fill_load_spravki(
        p_globals => l_globals
      );
      --
      fill_arh_nomspr(
        p_globals => l_globals
      );
      --
      update_load_spravki(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --  
    if p_action_code in (C_ACT_LOAD_TOTAL, C_ACT_LOAD_ALL) then
      --
      fill_load_mes(
        p_globals => l_globals
      );
      --
      fill_load_total(
        p_globals => l_globals
      );
      --
      delete_zero_ref(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --
    if p_action_code in (C_ACT_LOAD_EMPLOYEE, C_ACT_LOAD_SPRAVKI, C_ACT_LOAD_TOTAL, C_ACT_LOAD_ALL) then
      load_employee(
        p_globals  => l_globals,
        p_required => case when p_action_code in (C_ACT_LOAD_SPRAVKI, C_ACT_LOAD_TOTAL) then false else true end
      );
      --
      l_result := true;
    end if;
    --
    if p_action_code in (C_ACT_ENUMERATION, C_ACT_LOAD_ALL) then
      --
      enum_refs(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --
    if p_action_code in (C_ACT_COPY2ARH, C_ACT_LOAD_ALL) then
      --
      copy_to_arh(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --
    if p_action_code in (C_ACT_INIT_XML) then
      --
      init_xml(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --
    if not l_result then
      fix_exception('create_2ndfl_refs('||p_action_code||'): действие не обработано!');
      raise no_data_found;
    end if;
    --
    l_globals.process_row.state := 'Success';
    dv_sr_lspv_prc_api.set_process_state(
      p_process_row => l_globals.process_row
    );
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception;
      if l_globals.process_row.id is not null then
        l_globals.process_row.state := 'ERROR';
        l_globals.process_row.error_msg := sqlerrm;
        dv_sr_lspv_prc_api.set_process_state(
          p_process_row => l_globals.process_row
        );
      end if;
      raise;
  end create_2ndfl_refs;
  
end f2ndfl_load_api;
/
