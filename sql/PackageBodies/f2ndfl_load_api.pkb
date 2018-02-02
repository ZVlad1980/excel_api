create or replace package body f2ndfl_load_api is
  
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
        pNALRES_DEFFER => p_globals.NALRES_DEFFER
      );
    --                               
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end set_globals_util_pkg;
  
  /**
   * Процедура purge_loads - очистка таблиц f2ndfl_load_ и f2ndfl_arh_nomspr
   *    KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR
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
    if p_action_code in ('f2_purge_amount', 'f2_purge_total', 'f2_purge_all') then
      delete from f2ndfl_load_itogi t
      where  1=1
      and    t.nom_korr = coalesce(p_nom_corr, t.nom_korr)
      and    t.tip_dox = coalesce(p_revenue_type, t.tip_dox)
      and    t.ssylka = coalesce(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
      --
      delete from f2ndfl_load_vych t
      where  1=1
      and    t.nom_korr = coalesce(p_nom_corr, t.nom_korr)
      and    t.tip_dox = coalesce(p_revenue_type, t.tip_dox)
      and    t.ssylka = coalesce(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
    end if;
    --
    if p_action_code in ('f2_purge_amount', 'f2_purge_mes', 'f2_purge_total', 'f2_purge_all') then
      delete from f2ndfl_load_mes t
      where  1=1
      and    t.nom_korr = coalesce(p_nom_corr, t.nom_korr)
      and    t.tip_dox = coalesce(p_revenue_type, t.tip_dox)
      and    t.ssylka = coalesce(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
    end if;
    --
    if p_action_code in ('f2_purge_pers', 'f2_purge_nomspr', 'f2_purge_all') then
      delete from f2ndfl_arh_nomspr t
      where  1=1
      and    t.tip_dox = coalesce(p_revenue_type, t.tip_dox)
      and    t.ssylka = coalesce(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
    end if;
    --
    if p_action_code in ('f2_purge_pers', 'f2_purge_spravki', 'f2_purge_nomspr', 'f2_purge_all') then
      delete from f2ndfl_load_spravki t
      where  1=1
      and    t.nom_korr = coalesce(p_nom_corr, t.nom_korr)
      and    t.tip_dox = coalesce(p_revenue_type, t.tip_dox)
      and    t.ssylka = coalesce(p_ssylka, t.ssylka)
      and    t.kod_na = p_code_na
      and    t.god = p_year;
      --
    end if;
    --
  exception
    when others then
      fix_exception;
      raise;
  end delete_from_loads;
  
  /**
   * Процедура purge_loads - очистка таблиц f2ndfl_load_ и f2ndfl_arh_nomspr
   */
  procedure purge_loads(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int
  ) is
    --
    l_process_row  dv_sr_lspv_prc_t%rowtype;
    --
    function exists_arh_ return boolean is
      l_dummy int;
    begin
      select 1
      into   l_dummy
      from   f2ndfl_arh_spravki s
      where  rownum = 1
      and    s.kod_na = p_code_na
      and    s.god = p_year;
      --
      return true;
      --
    exception
      when no_data_found then
        return false;
    end exists_arh_;
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_process_row.process_name := upper('p_action_code');
    l_process_row.start_date   := to_date(p_year || '0101', 'yyyymmdd');
    l_process_row.end_date     := to_date(p_year || '1231', 'yyyymmdd');
    --
    dv_sr_lspv_prc_api.create_process(
      p_process_row => l_process_row
    );
    --
    if exists_arh_ then
      fix_exception('Справки за ' || p_year || ' скопированы в arh! Очистка load невозможна!');
      raise no_data_found;
    end if;
    --
    delete_from_loads(
      p_action_code => p_action_code ,
      p_code_na     => p_code_na     ,
      p_year        => p_year        
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
    function exists_load_spravki_(p_code_na int, p_year int) return boolean is
      l_dummy int;
    begin
      select 1
      into   l_dummy
      from   f2ndfl_load_spravki s
      where  rownum = 1
      and    s.kod_na = p_code_na
      and    s.god = p_year;
      --
      return true;
      --
    exception
      when no_data_found then
        return false;
    end exists_load_spravki_;
  begin
    --если в заданном периоде есть хоть одна справка - пропускаем формирование! (пока так)
    if exists_load_spravki_(p_globals.KODNA, p_globals.GOD) then
      return; --pass
    end if;
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
            and    n.god = 2017
            and    n.kod_na = 1
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
    function exists_load_mes_(p_code_na int, p_year int) return boolean is
      l_dummy int;
    begin
      select 1
      into   l_dummy
      from   f2ndfl_load_mes s
      where  rownum = 1
      and    s.kod_na = p_code_na
      and    s.god = p_year;
      --
      return true;
      --
    exception
      when no_data_found then
        return false;
    end exists_load_mes_;
  begin
    --если в заданном периоде есть хоть одна справка - пропускаем формирование! (пока так)
    if exists_load_mes_(p_globals.KODNA, p_globals.GOD) then
      return; --pass
    end if;
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
    open l_zero_ref_cur(p_globals.KODNA, p_globals.GOD);
    fetch l_zero_ref_cur
      bulk collect into l_refs_tbl;
    close l_zero_ref_cur;
    --
    dbms_output.put_line('Delete zero references');
    for i in 1..l_refs_tbl.count loop
      dbms_output.put('  ' || lpad(to_char(i), 3, ' ') || '. ' || to_char(l_refs_tbl(i).ssylka) || '/' || to_char(l_refs_tbl(i).tip_dox) || '...');
      delete_from_loads(
        p_action_code  => 'f2_purge_all',
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
    function not_exists_load_vych_(p_code_na int, p_year int) return boolean is
      l_dummy int;
    begin
      select 1
      into   l_dummy
      from   f2ndfl_load_vych s
      where  rownum = 1
      and    s.kod_na = p_code_na
      and    s.god = p_year;
      --
      return true;
    exception
      when no_data_found then
        return false;
    end not_exists_load_vych_;
    --
    function not_exists_load_itogi_(p_code_na int, p_year int) return boolean is
      l_dummy int;
    begin
      select 1
      into   l_dummy
      from   f2ndfl_load_itogi s
      where  rownum = 1
      and    s.kod_na = p_code_na
      and    s.god = p_year;
      --
      return true;
    exception
      when no_data_found then
        return false;
    end not_exists_load_itogi_;
    --
  begin
    --если в заданном периоде есть хоть одна справка - пропускаем формирование! (пока так)
    if not_exists_load_vych_(p_globals.KODNA, p_globals.GOD) then
      init_; fxndfl_util.Load_Vychety;
    end if;
    --
    if not_exists_load_itogi_(p_globals.KODNA, p_globals.GOD) then
      init_; fxndfl_util.Load_Itogi_Pensia;
      init_; fxndfl_util.Load_Itogi_Posob_bezIspr;
      init_; fxndfl_util.Load_Itogi_Vykup_bezIspr;
      init_; fxndfl_util.Load_Itogi_Vykup_sIspravl;
    end if;
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
  exception
    when others then
      fix_exception;
      raise;
  end copy_to_arh;
  
  /**
   * Процедура enum_refs - нумерация справок 2НДФЛ
   *  Вызывается только после полного формирования Loads и NOMSPR
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
   *
   */
  procedure create_2ndfl_refs(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int
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
    --
    
    l_globals.process_row.process_name := upper(p_action_code);
    l_globals.process_row.start_date   := to_date(p_year || '0101', 'yyyymmdd');
    l_globals.process_row.end_date     := to_date(p_year || '1231', 'yyyymmdd');
    --
    dv_sr_lspv_prc_api.create_process(
      p_process_row => l_globals.process_row
    );
    --
    if p_action_code in ('f2_load_spravki', 'f2_load_all') then
      fill_load_spravki(
        p_globals => l_globals
      );
    end if;
    --  
    if p_action_code in ('f2_load_spravki', 'f2_arh_nomspr', 'f2_load_all') then
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
    if p_action_code in ('f2_load_mes', 'f2_load_total', 'f2_load_all') then
      --
      fill_load_mes(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --  
    if p_action_code in ('f2_load_itogi', 'f2_load_total', 'f2_load_all') then
      --
      fill_load_total(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --
    if p_action_code in ('f2_delete_zero_ref', 'f2_load_itogi', 'f2_load_total', 'f2_load_all') then
      --
      delete_zero_ref(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --
    if p_action_code in ('f2_enumeration', 'f2_load_all') then
      --
      enum_refs(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --
    if p_action_code in ('f2_copy2arh', 'f2_load_all') then
      --
      copy_to_arh(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --
    if p_action_code in ('f2_init_xml', 'f2_load_all') then
      --
      init_xml(
        p_globals => l_globals
      );
      --
      l_result := true;
    end if;
    --
    if not l_result then
      fix_exception('create_2ndfl_refs('||p_action_code||'): unknown action.');
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
