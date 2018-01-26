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
   *
   */
  procedure fill_load_spravki(
    p_globals in out nocopy g_util_par_type,
    p_force   boolean
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
      if p_force then
        delete from f2ndfl_load_spravki s
        where  s.kod_na = p_code_na
        and    s.god = p_year;
        raise no_data_found;
      end if;
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
    p_globals in out nocopy g_util_par_type,
    p_force   boolean
  ) is
    --
  begin
    --
    if p_force then
      delete from f2ndfl_arh_nomspr ns
      where  ns.kod_na = p_globals.KODNA
      and    ns.god = p_globals.GOD;
    end if;
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
   *
   */
  procedure create_2ndfl_refs(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int,
    p_force        boolean default false
  ) is
    l_globals g_util_par_type;
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
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
        p_globals => l_globals,
        p_force   => p_force
      );
    elsif p_action_code in ('f2_arh_nomspr', 'f2_load_all') then
      fill_arh_nomspr(
        p_globals => l_globals,
        p_force   => p_force
      );
    else
      fix_exception('create_2ndfl_refs: неизвествный код действия: ' || p_action_code);
      raise no_data_found;
    end if;
    --
    l_globals.process_row.state := 'Success';
    dv_sr_lspv_prc_api.set_process_state(
      p_process_row => l_globals.process_row
    );
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception;
      if l_globals.process_row.id is not null then
        l_process_row.state := 'ERROR';
        l_process_row.error_msg := sqlerrm;
        dv_sr_lspv_prc_api.set_process_state(
          p_process_row => l_globals.process_row
        );
      end if;
      raise;
  end create_2ndfl_refs;
  
end f2ndfl_load_api;
/
