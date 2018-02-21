create or replace package body f2ndfl_arh_spravki_api is

  C_PACKAGE_NAME constant varchar2(32) := $$plsql_unit;
  
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
    ACTUAL_DATE   date
  );
  --
  
  /**
   * �������� ��������� ������
   */
  procedure fix_exception(p_line number, p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_routine => C_PACKAGE_NAME || '(' || p_line || ')' ,
      p_params  => null                                   ,
      p_err_msg => p_msg
    );
  end;
  
  procedure init_exceptions is begin utl_error_api.init_exceptions; end init_exceptions;

  /**
   * ���������� plog - �������� dbms_output
   */
  procedure plog(p_msg varchar2, p_eof boolean default true) is
  begin
    if p_eof then
      dbms_output.put_line(p_msg);
    else
      dbms_output.put(p_msg);
    end if;
  end plog;
  
  /**
   * ��������� set_globals_util_pkg �������� ������������� ���������� ���������� ������ FXNDFL_UTIL
   *   ������������� ���������� ����� ������� ������ ������ ������ FXNDFL_UTIL
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
        pCOMMIT => false            ,
        pACTUAL_DATE => p_globals.ACTUAL_DATE
      );
    --                               
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end set_globals_util_pkg;
  /**
   * ��������� create_load_refs ��������� ������� � �������� F2NDFL_LOAD: SPRAVKI, MES
   *
   * @param  -
   *
   */
  procedure create_load_refs(
    p_rev_type f2ndfl_arh_nomspr.tip_dox%type,
    p_globals  in out nocopy g_util_par_type,
    p_only_amount in boolean
  ) is
    procedure init_ is begin set_globals_util_pkg(p_globals); end init_;
  begin
    --
    case p_rev_type
      when 1 then
        if not p_only_amount then
          init_; fxndfl_util.Load_Pensionery_bez_Storno;
          init_; fxndfl_util.Load_Pensionery_so_Storno;
        end if;
        init_; fxndfl_util.Load_MesDoh_Pensia_bezIspr;
        init_; fxndfl_util.Load_MesDoh_Pensia_sIspravl;
        init_; fxndfl_util.Load_Vychety;
      when 2 then
        if not p_only_amount then
          init_; fxndfl_util.Load_Posobiya_bez_Pravok;
          init_; fxndfl_util.Load_Posobiya_s_Ipravlen;
        end if;
        init_; fxndfl_util.Load_MesDoh_Posob_bezIspr;
        init_; fxndfl_util.Load_MesDoh_Posob_sIspravl;
        init_; fxndfl_util.Load_Vychety;
      when 3 then
        if not p_only_amount then
          init_; fxndfl_util.Load_Vykupnye_bez_Pravok;
          init_; fxndfl_util.Load_Vykupnye_s_Ipravlen;
        end if;
        init_; fxndfl_util.Load_MesDoh_Vykup_bezIspr;
        init_; fxndfl_util.Load_MesDoh_Vykup_sIspravl;
        init_; fxndfl_util.Load_Vychety;
      when 9 then
        fxndfl_util.copy_load_employees(
          p_src_ref_id  => p_globals.SRC_SPRID,
          p_corr_ref_id => p_globals.SPRID,
          p_nom_corr    => p_globals.NOMKOR
        );
      else
        plog('���������������� ��� ������: ' || p_rev_type);
        --������ ��� - ������ �������
    end case;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end create_load_refs;
  
  /**
   * ��������� create_load_total ������ ������ F2NDFL_ITOG
   *
   * @param  -
   *
   */
  procedure create_load_total(
    p_globals  in out nocopy g_util_par_type,
    p_only_amount in boolean
  ) is
    l_dummy int;
    procedure init_ is begin set_globals_util_pkg(p_globals); end init_;
  begin
    --
    --��������, �.�. � 17 ���� ������ ������� �� GAZFOND --l_dummy := fxndfl_util.ZapolnGRAZHD_poUdLichn(pGod => p_globals.GOD);
    --
    if not p_only_amount then
      fxndfl_util.copy_load_address(
        p_src_ref_id => p_globals.SRC_SPRID,
        p_nom_corr   => p_globals.NOMKOR
      );
    end if;
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
  end create_load_total;
  
  /**
   * ��������� calc_total_ref ��������� F2NDFL_ARH � ������� �� �������
   *
   * @param p_ref_id    - ID ����������� ������� f2ndfl_arh_spravki.id%type
   *
   */
  procedure create_arh_total(
    p_globals g_util_par_type
  ) is
    procedure init_ is begin set_globals_util_pkg(p_globals); end init_;
  begin
    --
    init_; fxndfl_util.KopirSprItog_vArhiv(pKodNA => p_globals.KODNA, pGod => p_globals.GOD);
    init_; fxndfl_util.KopirSprMes_vArhiv(pKodNA => p_globals.KODNA, pGod => p_globals.GOD);
    init_; fxndfl_util.KopirSprVych_vArhiv(pKodNA => p_globals.KODNA, pGod => p_globals.GOD);
    fxndfl_util.calc_benefit_usage(
      p_code_na => p_globals.KODNA,
      p_year    => p_globals.GOD,
      p_spr_id  => p_globals.SPRID
    );
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end create_arh_total; 
  
  /**
   * ��������� calc_reference ������ ����� �������
   *
   * @param p_ref_row     - ������� f2ndfl_arh_spravki%rowtype
   * @param p_src_ref_id  - ID ���������� �������
   * @param p_actual_date - ����, �� ������� ����������� ������ (�������������)
   * @param p_wo_arh      - ��� ��������� ������ � ARH (def: FALSE)
   * @param p_only_amount - ���� ���������� ������ �������� ����������� ������� (���������� �� recalc_reference)
   *                      !!! ��� ������������� ����� - �� �������������� ������ �� �� (9)
   *
   */
  procedure calc_reference(
    p_ref_row     in out nocopy f2ndfl_arh_spravki%rowtype,
    p_src_ref_id  in f2ndfl_arh_spravki.id%type,
    p_actual_date in date       ,
    p_wo_arh      in boolean default false,
    p_only_amount in boolean default false
  ) is
  cursor l_revenue_types_cur is
      select an.tip_dox       rev_type      ,
             an.fk_contragent fk_contragent ,
             an.ssylka        ssylka_fl     ,
             ls.nom_vkl                     ,
             ls.nom_ips
      from   f2ndfl_arh_nomspr an,
             sp_lspv           ls
      where  1=1
      --
      and    ls.ssylka_fl(+) = an.ssylka
      --
      and    an.nom_spr = p_ref_row.nom_spr
      and    an.god     = p_ref_row.god
      and    an.kod_na  = p_ref_row.kod_na  ;
    --
    l_globals g_util_par_type;
    --
  begin
    --
    l_globals.KODNA      := p_ref_row.kod_na;
    l_globals.GOD        := p_ref_row.god;
    l_globals.NOMKOR     := p_ref_row.nom_korr;
    l_globals.SPRID      := p_ref_row.id;
    l_globals.NOMSPR     := p_ref_row.nom_spr;
    l_globals.DATDOK     := p_ref_row.data_dok;
    l_globals.SRC_SPRID  := p_src_ref_id;
    l_globals.ACTUAL_DATE := p_actual_date;
    --
    for r in l_revenue_types_cur loop
      --
      continue when p_only_amount and r.rev_type = 9;
      --
      l_globals.TIPDOX := r.rev_type;
      l_globals.NOMVKL := r.nom_vkl;
      l_globals.NOMIPS := r.nom_ips;
      l_globals.CAID   := r.fk_contragent;
      --
      create_load_refs(
        p_rev_type      => r.rev_type,
        p_globals       => l_globals,
        p_only_amount   => p_only_amount
      );
      --
    end loop;
    --
    l_globals.TIPDOX := null;
    l_globals.NOMVKL := null;
    l_globals.NOMIPS := null;
    l_globals.CAID   := null;
    --
    create_load_total(
      p_globals       => l_globals,
      p_only_amount   => p_only_amount
    );
    --
    if not p_wo_arh then
      create_arh_total(
        p_globals       => l_globals
      );
    end if;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end calc_reference;  

  /**
   * ������� get_reference_row ���������� ������ F2NDFL_ARH_SPRAVKI �� ID
   *
   * @return - 2ndfl_arh_spravka%rowtype
   *
   */
  function get_reference_row(
    p_ref_id         f2ndfl_arh_spravki.id%type
  ) return f2ndfl_arh_spravki%rowtype is
    l_result f2ndfl_arh_spravki%rowtype;
  begin
    --
    if p_ref_id is not null then
      select *
      into   l_result
      from   f2ndfl_arh_spravki s
      where  s.id = p_ref_id;
    end if;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end get_reference_row;

  /**
   * ������� get_reference_last ���������� ����� 2���� ������� �� ���� � �����������
   *
   * @param p_kod_na        - ��� ��
   * @param p_year          - ���
   * @param p_contragent_id - ID �����������
   *
   * @return - f2ndfl_arh_nomspr.nom_spr%type
   *
   */
  function get_reference_num(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_contragent_id  f2ndfl_arh_nomspr.fk_contragent%type
  ) return f2ndfl_arh_nomspr.nom_spr%type is
    l_result f2ndfl_arh_nomspr.nom_spr%type;
  begin
    --
    select max(an.nom_spr)
    into   l_result
    from   f2ndfl_arh_nomspr an
    where  1=1
    and    an.fk_contragent = p_contragent_id
    and    an.god           = p_year
    and    an.kod_na        = p_code_na       
    --group by an.nom_spr
    ;
    --
    return l_result;
    --
  exception
    when no_data_found then
      fix_exception(
        $$PLSQL_LINE,
        '�� ������� ������� �� ' || p_year || ' ��� ��� ����������� ' || p_contragent_id || ' (��: ' || p_code_na || ')'
      );
      raise;
    when others then
      fix_exception(
        $$PLSQL_LINE,
        'get_reference_num('||p_code_na||', '||p_year||', '||p_contragent_id||')'
      );
      raise;
  end get_reference_num;
  
  /**
   * ������� get_reference_last_id ���������� ID ������� �� ���� � ������
   *  ���� ������� ��������� - ���������� ID ��������� �������������
   *
   * @param p_code_na - ��� ��
   * @param p_year    - ���
   * @param p_ref_num - ����� ������� 2����
   *
   * @return - f2ndfl_arh_spravki.id%type
   *
   */
  function get_reference_last_id(
    p_code_na   f2ndfl_arh_spravki.kod_na%type,
    p_year      f2ndfl_arh_spravki.god%type,
    p_ref_num   f2ndfl_arh_spravki.nom_spr%type,
    p_load_exists varchar2 default 'Y'
  ) return f2ndfl_arh_spravki.id%type is
    l_result f2ndfl_arh_spravki.id%type;
  begin
    --
    if p_ref_num is null then
      return null;
    end if;
    --
    select max(sp.id)keep(dense_rank last order by sp.nom_korr)
    into   l_result
    from   f2ndfl_arh_spravki sp
    where  1=1
         -- ����������� ��������� ������� ������� �� ����� �������,
         -- �.�. ������� ARH ����� ���� ������� � ��� ������� �� �������
    and    case 
             when p_load_exists = 'Y' and 
                  not exists(select 1 from f2ndfl_load_spravki ls where ls.r_sprid = sp.id) then
               0
             else
               1
           end  = 1
    and    sp.nom_spr = p_ref_num
    and    sp.god     = p_year
    and    sp.kod_na  = p_code_na;
    --
    if l_result is null then
      raise no_data_found;
    end if;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception(
        $$PLSQL_LINE,
        'get_reference_last_id('||p_code_na||', '||p_year||', '||p_ref_num||')'
      );
      raise;
  end get_reference_last_id;

  /**
   * ������� get_reference_last - ���������� ��������� ������� 2���� �� ��� �� �����������
   *
   * @param p_kod_na        - ��� ��
   * @param p_year          - ���
   * @param p_contragent_id - ID �����������
   *
   * @return - 2ndfl_arh_spravka%rowtype
   *
   */
  function get_reference_last(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_contragent_id  f2ndfl_arh_nomspr.fk_contragent%type
  ) return f2ndfl_arh_spravki%rowtype is
    l_ref_id f2ndfl_arh_spravki.id%type;
  begin
    --
    l_ref_id := get_reference_last_id(
      p_code_na       => p_code_na       ,
      p_year          => p_year          ,
      p_ref_num       => get_reference_num(
                           p_code_na       => p_code_na       ,
                           p_year          => p_year          ,
                           p_contragent_id => p_contragent_id 
                         )
    );
    --
    return get_reference_row(l_ref_id);
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end get_reference_last;
  
  /**
   * ������� create_reference ������� �������������� �������
   *
   * @param p_ref_src - ������ � �������� �������� 
   *
   * @return - f2ndfl_arh_spravki%rowtype ��������� �������
   *
   */
  function create_reference(
    p_ref_src in out nocopy f2ndfl_arh_spravki%rowtype
  ) return f2ndfl_arh_spravki%rowtype is
    --
    l_result f2ndfl_arh_spravki%rowtype;
    --
  begin
    --
    l_result          := p_ref_src;
    l_result.nom_korr := p_ref_src.nom_korr + 1;
    l_result.data_dok := trunc(sysdate);
    --
    fxndfl_util.create_f2ndfl_arh_spravki(
      p_code_na       => p_ref_src.kod_na,
      p_year          => p_ref_src.god,
      p_contragent_id => p_ref_src.ui_person,
      p_nom_spr       => p_ref_src.nom_spr,
      p_nom_korr      => p_ref_src.nom_korr
    );
    --
    l_result.id := get_reference_last_id(
      p_code_na     => p_ref_src.kod_na,
      p_year        => p_ref_src.god,
      p_ref_num     => p_ref_src.nom_spr,
      p_load_exists => 'N'
    );
    --
    if p_ref_src.id is not null then
      fix_cityzenship(
        p_code_na => p_ref_src.kod_na,
        p_year    => p_ref_src.god,
        p_ref_id  => l_result.id
      );
      fxndfl_util.copy_adr(
        p_src_ref_id => p_ref_src.id,
        p_trg_ref_id => l_result.id
      );
    end if;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end create_reference;
  
  /**
   * ��������� check_synchr_load ��������� ������������� ������ � �������� F2NDFL_LOAD � F2NDFL_ARH
   *  ���� ������ �� ��������� - ����������� ����������
   */
  procedure check_synch_load(
    p_ref_arh in out nocopy f2ndfl_arh_spravki%rowtype
  ) is
    l_num_corr_load f2ndfl_load_spravki.nom_korr%type;
  begin
    --���� ������ ������� �������
    begin
      select max(s.nom_korr)
      into   l_num_corr_load
      from   f2ndfl_load_spravki s
      where  1 = 1
      and    s.nom_spr = p_ref_arh.nom_spr
      and    s.god = p_ref_arh.god
      and    s.kod_na = p_ref_arh.kod_na;
    exception
      when no_data_found then
        fix_exception($$PLSQL_LINE, '��� ������� ' || p_ref_arh.nom_spr || '/' || p_ref_arh.nom_korr || ' ('||p_ref_arh.id||') ��� ������ � ������� F2NDFL_LOAD_SPRAVKI');
        raise;
    end;
    --
    if l_num_corr_load <> p_ref_arh.nom_korr then
      fix_exception($$PLSQL_LINE, '��� ������� ' || p_ref_arh.nom_spr || '/' || p_ref_arh.nom_korr || ' ('||p_ref_arh.id||') ����� ��������� ������������� �� ��������� � F2NDFL_LOAD_SPRAVKI: ' || l_num_corr_load);
      raise no_data_found;
    end if;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end check_synch_load;
  
  /**
   * ��������� create_reference_corr �������� ������� 2����
   *   ���� ������� ��� ���� � f2ndfl_arh_spravki - �������� �������������� �������
   *   ���� ������� ��� ��� - �������� ����� �������, � 0 ����������
   *
   * @param p_code_na       - ��� ����������������� (���=1)
   * @param p_year          - ���, �� ������� ���� ������������ �������������
   * @p_actual_date         - ����, �� ������� ����������� ������ (���� �������������!)
   * @param p_contragent_id - ID �����������, �� �������� ����������� ������� (CDM.CONTRAGENTS.ID)
   * @param p_ref_num       - ����� ������� (��������������)
   *
   */
  procedure create_reference(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_actual_date    date,
    p_contragent_id  f2ndfl_arh_spravki.ui_person%type,
    p_ref_num        f2ndfl_arh_spravki.nom_spr%type default null
  ) is
    l_ref_curr f2ndfl_arh_spravki%rowtype;
    l_ref_new  f2ndfl_arh_spravki%rowtype;
    e_int      exception;
  begin
    --
    init_exceptions;
    --
    if p_year < 2015 or p_year > (extract(year from sysdate) - 1) then
      fix_exception($$PLSQL_LINE, '���������� ������� �������������� ������� �� ' || p_year || '. �������������� ������� 2���� ��������� ������ ������� � 2015 ����.');
      raise e_int;
    end if;
    --
    if p_code_na <> 1 then
      fix_exception($$PLSQL_LINE, '����������� ��� ���������� ������: ' || p_code_na);
      raise e_int;
    end if;
    --
    l_ref_curr := get_reference_last(
      p_code_na       => p_code_na       ,
      p_year          => p_year          ,
      p_contragent_id => p_contragent_id 
    );
    --
    if l_ref_curr.id is null then
      --
      if p_ref_num is null then
        fix_exception(
          $$PLSQL_LINE, 
          'f2ndfl_arh_spravki_api.create_reference(' ||
            p_code_na       || ', ' ||
            p_year          || ', ' ||
            p_contragent_id || ', ' ||
            p_ref_num       || '): �� ����������� ��� �������� ������� � �� ����� ����� ����� �������!'
        );
        raise no_data_found;
      end if;
      --
      l_ref_curr.kod_na  := p_code_na;
      l_ref_curr.god     := p_year   ;
      l_ref_curr.nom_spr := p_ref_num;
    else
      plog('Current spr_id = ' || l_ref_curr.id || ', nom_spr = ' || l_ref_curr.nom_spr || ', nom_korr = ' || l_ref_curr.nom_korr);
      check_synch_load(p_ref_arh => l_ref_curr);
    end if;
    --
    l_ref_curr.ui_person := p_contragent_id;
    --
    l_ref_new := create_reference(
      p_ref_src => l_ref_curr
    );
    --
    plog('New spr_id = ' || l_ref_new.id);
    --
    calc_reference(
      p_ref_row    => l_ref_new,
      p_src_ref_id => l_ref_curr.id,
      p_actual_date => p_actual_date
    );
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end create_reference;
  
  /**
   * ��������� create_reference_corr �������� �������������� ������� 2����
   *  !!!�������� ��� �������������
   *
   * @param p_code_na       - ��� ����������������� (���=1)
   * @param p_year          - ���, �� ������� ���� ������������ �������������
   * @param p_contragent_id - ID �����������, �� �������� ����������� ������� (CDM.CONTRAGENTS.ID)
   *
   */
  procedure create_reference_corr(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_contragent_id  f2ndfl_arh_nomspr.fk_contragent%type,
    p_actual_date    date default sysdate
  ) is
  begin
    --
    create_reference(
      p_code_na       => p_code_na      ,
      p_year          => p_year         ,
      p_contragent_id => p_contragent_id,
      p_actual_date   => p_actual_date
    );
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end create_reference_corr;
  
  /**
   * ��������� recalc_reference - �������� �������� ����������� �������
   *   �� ��������� ����������� ��������� �������� ���������� (F2NDFL_LOAD_MES, F2NDFL_LOAD_VYCH, F2NDFL_LOAD_ITOGI, 
   *     F2NDFL_ARH_MES, F2NDFL_ARH_VYCH, F2NDFL_ARH_ITOGI) �� ���� ����� ������, ����� �� (9),
   *     � ����������� ��������� ������
   *
   * @param p_ref_id       - F2NDFL_ARH_SPRAVKI.ID
   *
   */
  procedure recalc_reference(
    p_ref_id        f2ndfl_arh_spravki.id%type,
    p_actual_date   date,
    p_commit        boolean default false
  ) is
    l_ref_row f2ndfl_arh_spravki%rowtype;
  begin
    --
    delete_reference(
      p_ref_id      => p_ref_id,
      p_commit      => p_commit,
      p_only_amount => true
    );
    --
    l_ref_row := get_reference_row(p_ref_id);
    --
    calc_reference(
      p_ref_row     => l_ref_row,
      p_src_ref_id  => null,
      p_wo_arh      => false,
      p_only_amount => true,
      p_actual_date => p_actual_date
    );
    --
    if p_commit then
      commit;
    end if;
    --
  exception
    when others then
      if p_commit then
        rollback;
      end if;
      fix_exception($$PLSQL_LINE);
      raise;
  end recalc_reference;

  /**
   * ������� is_employee_ref �������� �������������� ������� ���������� �����, 
   *   �� ����������� ������������ �����
   *
   * @param p_ref_id - ID �������
   *
   * @return - boolean
   *
   */
  function is_employee_ref(
    p_ref_id f2ndfl_arh_spravki.id%type
  ) return boolean is
    l_result int;
  begin
    --
    begin
      select count(1)
      into   l_result
      from   f2ndfl_arh_nomspr an
      where  1=1
      and    an.tip_dox <> FXNDFL_UTIL.C_REVTYP_EMPL
      and    (an.kod_na, an.god, an.nom_spr) in (
               select s.kod_na, s.god, s.nom_spr
               from   f2ndfl_arh_spravki s
               where  s.id = p_ref_id
             )
      group by 1;
    exception
      when no_data_found then
        l_result := 0;
    end;
    --
    return l_result = 0;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end is_employee_ref;
  
  /**
   * ��������� purge_load_tbl ������� ������ � �������� ������� 2���� �� ������ F2NDFL_LOAD_
   *
   * @param p_ref_row - ������ ������� F2NDFL_ARH_SPRAVKI
   *
   */
  procedure purge_load_tbl(
    p_ref_row f2ndfl_arh_spravki%rowtype,
    p_only_amount   boolean default false
  ) is
    cursor l_revenue_types_cur is
      select an.tip_dox       rev_type      ,
             an.fk_contragent fk_contragent ,
             an.ssylka        ssylka_fl
      from   f2ndfl_arh_nomspr an
      where  1=1
      and    an.tip_dox <> fxndfl_util.C_REVTYP_EMPL
      and    an.nom_spr = p_ref_row.nom_spr
      and    an.god     = p_ref_row.god
      and    an.kod_na  = p_ref_row.kod_na  ;
    --
    procedure purge_load_tbl_(
      p_row l_revenue_types_cur%rowtype
    ) is
    begin
      --
      delete from f2ndfl_load_itogi t
      where  1 = 1
      and    t.nom_korr = p_ref_row.nom_korr
      and    t.tip_dox = p_row.rev_type
      and    t.ssylka = p_row.ssylka_fl
      and    t.god = p_ref_row.god
      and    t.kod_na = p_ref_row.kod_na;
      --
      plog('  f2ndfl_load_itogi deleted   ' || sql%rowcount || ' row(s)');
      --
      delete from f2ndfl_load_mes t
      where  1 = 1
      and    t.nom_korr = p_ref_row.nom_korr
      and    t.tip_dox = p_row.rev_type
      and    t.ssylka = p_row.ssylka_fl
      and    t.god = p_ref_row.god
      and    t.kod_na = p_ref_row.kod_na;
      --
      plog('  f2ndfl_load_mes deleted     ' || sql%rowcount || ' row(s)');
      --
      delete from f2ndfl_load_vych t
      where  1 = 1
      and    t.nom_korr = p_ref_row.nom_korr
      and    t.tip_dox = p_row.rev_type
      and    t.ssylka = p_row.ssylka_fl
      and    t.god = p_ref_row.god
      and    t.kod_na = p_ref_row.kod_na;
      --
      plog('  f2ndfl_load_vych deleted    ' || sql%rowcount || ' row(s)');
      --
      if not p_only_amount then
        delete from f2ndfl_load_adr t
        where  1 = 1
        and    t.nom_korr = p_ref_row.nom_korr
        and    t.tip_dox = p_row.rev_type
        and    t.ssylka = p_row.ssylka_fl
        and    t.god = p_ref_row.god
        and    t.kod_na = p_ref_row.kod_na;
        --
        plog('  f2ndfl_load_adr deleted     ' || sql%rowcount || ' row(s)');
        --
        delete from f2ndfl_load_uved t
        where  1 = 1
        and    t.nom_korr = p_ref_row.nom_korr
        and    t.tip_dox = p_row.rev_type
        and    t.ssylka = p_row.ssylka_fl
        and    t.god = p_ref_row.god
        and    t.kod_na = p_ref_row.kod_na;
        --
        plog('  f2ndfl_load_uved deleted    ' || sql%rowcount || ' row(s)');
        --
        delete from f2ndfl_load_spravki t
        where  1 = 1
        and    t.nom_korr = p_ref_row.nom_korr
        and    t.tip_dox = p_row.rev_type
        and    t.ssylka = p_row.ssylka_fl
        and    t.god = p_ref_row.god
        and    t.kod_na = p_ref_row.kod_na;
        --
        plog('  f2ndfl_load_spravki deleted ' || sql%rowcount || ' row(s)');
        --
      end if;
    end purge_load_tbl_;
    --
  begin
    --
    for rt in l_revenue_types_cur loop
      purge_load_tbl_(rt);
    end loop;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end purge_load_tbl;
  
  /**
   * ��������� purge_arh_tbl ������� ������ � �������� ������� 2���� �� ������ F2NDFL_ARH (����� F2NDFL_ARH_NOMSPR)
   *
   * @param p_ref_id - ID ��������� �������
   *
   */
  procedure purge_arh_tbl(
    p_ref_id f2ndfl_arh_spravki.id%type,
    p_only_amount   boolean default false
  ) is
  begin
    --
    delete from f2ndfl_arh_mes a
    where  a.r_sprid = p_ref_id;
    --
    plog('  f2ndfl_arh_mes deleted      ' || sql%rowcount || ' row(s)');
    --
    delete from f2ndfl_arh_vych a
    where  a.r_sprid = p_ref_id;
    --
    plog('  f2ndfl_arh_vych deleted     ' || sql%rowcount || ' row(s)');
    --
    delete from f2ndfl_arh_itogi a
    where  a.r_sprid = p_ref_id;
    --
    plog('  f2ndfl_arh_itogi deleted    ' || sql%rowcount || ' row(s)');
    --
    if not p_only_amount then
      delete from f2ndfl_arh_adr a
      where  a.r_sprid = p_ref_id;
      --
      plog('  f2ndfl_arh_adr deleted      ' || sql%rowcount || ' row(s)');
      --
      delete from f2ndfl_arh_uved a
      where  a.r_sprid = p_ref_id;
      --
      plog('  f2ndfl_arh_uved deleted     ' || sql%rowcount || ' row(s)');
      --
      delete from f2ndfl_arh_spravki a
      where  a.id = p_ref_id;
      --
      plog('  f2ndfl_arh_spravki deleted  ' || sql%rowcount || ' row(s)');
    end if;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end purge_arh_tbl;

  /**
   * ��������� delete_reference ������� ������ ������� �� ������ F2NDFL_, ����� F2NDFL_ARH_NOMSPR
   *  ���� ������ ������� �������� � XML ��� ��� - �������� ����������.
   * ��������: ��� �������� ������� (����.�����=0) ������ �� ����������� ����� �� ���������, ����� �� ��������� ������ �� 9 ���� ������ (��)
   *   �.�. ���� ������� ��������� � ���������� �����, �� ����������� ������������ - ��� �� ����� �������, 
   *        ���� ��������� �������� ������������ - ����� ������� ������ �� ���� ����� ������, ����� 9 (��)
   *
   * @param p_ref_id      - ID ��������� �������
   * @param p_commit      - ���� �������� ����������
   * @param p_only_amount - ���� �������� ������ �������� �����������
   *
   */
  procedure delete_reference(
    p_ref_id        f2ndfl_arh_spravki.id%type,
    p_commit        boolean default false,
    p_only_amount   boolean default false
  ) is
    l_ref_row f2ndfl_arh_spravki%rowtype;
  begin
    --
    init_exceptions;
    --
    if is_employee_ref(p_ref_id) then
      fix_exception($$PLSQL_LINE, '�������� ������� (' || p_ref_id || ') ���������. ������� �� ���������� �����, �� ���������� ������������ �����.');
      raise utl_error_api.G_EXCEPTION;
    end if;
    --
    l_ref_row := get_reference_row(p_ref_id);
    --
    if l_ref_row.r_xmlid is not null then
      fix_exception($$PLSQL_LINE, '�������� (' || p_ref_id || ') ���������. ������ ������� �������� � ���� ��� �������� � ���.');
      raise utl_error_api.G_EXCEPTION;
    end if;
    --
    plog(
      '�������� ������� �' || l_ref_row.nom_spr || ' (����. ' || l_ref_row.nom_korr || ') �� ' || l_ref_row.god || ' �� ' || 
      l_ref_row.familiya || ' ' || l_ref_row.imya || ' ' || l_ref_row.otchestvo
    );
    --
    purge_load_tbl(l_ref_row, p_only_amount);
    --
    purge_arh_tbl(l_ref_row.id, p_only_amount);
    --
    if p_commit then 
      commit;
    else
      plog('���������� �� �������������');
    end if;
    --
    plog('�������� ���������');
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      dbms_output.put_line(utl_error_api.get_exception_full);
      if p_commit then rollback; end if;
      raise;
  end delete_reference;
  
  /*
   * ������������� ������� load �� arh (�� 16 ��� - �������������������!)
   *  
   * @param p_code_na       - ��� ��
   * @param p_year          - ���
   * @param p_contragent_id - optional
   *
   */
  procedure synhonize_load(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_ref_id         f2ndfl_arh_spravki.id%type default null
  ) is
    --
    e_int      exception;
    --
    cursor l_refs_cur is
      select ls.nom_spr, 
             sa.id spr_id, 
             sa2.id prev_sprid
      from   (
              select sa.kod_na,
                     sa.god,
                     sa.nom_spr,
                     max(sa.nom_korr) nom_korr,
                     max(sa.id) keep(dense_rank last order by sa.nom_korr) id
              from   f2ndfl_arh_spravki sa
              where  sa.id = nvl(p_ref_id, sa.id)
              group by sa.kod_na,
                       sa.god,
                       sa.nom_spr
             ) sa,
             (
              select ls.kod_na,
                     ls.god,
                     ls.nom_spr,
                     max(ls.nom_korr) nom_korr
              from   f2ndfl_load_spravki ls
              where  ls.tip_dox <> 9
              group by ls.kod_na,
                       ls.god,
                       ls.nom_spr
             ) ls,
             f2ndfl_arh_spravki sa2
      where  1=1
      --
      and    sa2.nom_korr = sa.nom_korr - 1
      and    sa2.nom_spr = sa.nom_spr
      and    sa2.god = sa.god
      and    sa2.kod_na = sa.kod_na
      --
      and    ls.nom_korr < sa.nom_korr
      and    ls.nom_spr = sa.nom_spr
      and    ls.god = sa.god
      and    ls.kod_na = sa.kod_na
      --
      and    sa.god = p_year
      and    sa.kod_na = p_code_na;
    --
    procedure create_reference_corr_(
      p_ref_rec in out nocopy l_refs_cur%rowtype
    ) is
      l_ref_curr f2ndfl_arh_spravki%rowtype;
    begin
      l_ref_curr := get_reference_row(p_ref_rec.spr_id);
      --
      plog('Prev  spr_id = ' || p_ref_rec.prev_sprid || ', source spr_id = ' || l_ref_curr.id || ', nom_spr = ' || l_ref_curr.nom_spr || ', nom_korr = ' || l_ref_curr.nom_korr);
      calc_reference(
        p_ref_row    => l_ref_curr,
        p_src_ref_id => p_ref_rec.prev_sprid, --(��� ����������� ������ �� ���������� �����)
        p_wo_arh     => true,
        p_actual_date => sysdate
      );
      --
    end create_reference_corr_;
    --
  begin
    --
    init_exceptions;
    --
    if p_year < 2015 or p_year > (extract(year from sysdate) - 1) then
      fix_exception($$PLSQL_LINE, '���������� ������� �������������� ������� �� ' || p_year || '. �������������� ������� 2���� ��������� ������ ������� � 2015 ����.');
      raise e_int;
    end if;
    --
    if p_code_na <> 1 then
      fix_exception($$PLSQL_LINE, '����������� ��� ���������� ������: ' || p_code_na);
      raise e_int;
    end if;
    --
    for r in l_refs_cur loop
      create_reference_corr_(r);
    end loop;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end synhonize_load;
  
  /**
   * ������� validate_pers_info - ��������� ����.������
   *
   * @param p_fk_contragent - 
   * @param p_last_name     - 
   * @param p_first_name    - 
   * @param p_middle_name   - 
   * @param p_birth_date    - 
   * @param p_doc_code      - ��� ��
   * @param p_doc_num       - ����� � ����� ��
   * @param p_inn           - ���
   * @param p_citizenship   - ����������� (��� ������)
   * @param p_resident      - �������� (1/2 - ��/���)
   * @param p_inn_dbl       - ���������� ������� � ���������� ���  count(distinct case when s.inn_fl is not null then s.ui_person end) over(partition by s.kod_na, s.god, s.inn_fl)
   * @param p_fiod_dbl      - ���������� ������� � ���������� ���� count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.ser_nom_doc)
   * @param p_doc_dbl       - ���������� ������� � ���������� ��   count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.familiya, s.imya, s.otchestvo, s.data_rozhd)
   *
   * @return varchar2- ������ �� ������� ������ �/� ������ (��. ���. sp_ndfl_errors)
   *
   */
  function validate_pers_info(
    p_code_na        int,  
    p_year           int,
    p_nom_spr        varchar2,
    p_fk_contragent  int,
    p_doc_code       int,
    p_doc_num        varchar2,
    p_inn            varchar2,
    p_citizenship    varchar2,
    p_resident       int,
    p_inn_dbl        int,
    p_fiod_dbl       int,
    p_doc_dbl        int,
    p_invalid_doc    varchar2
  ) return varchar2 is
    l_result varchar2(4000);
    procedure append_code_(p_error_code int) is
    begin
      l_result := l_result || case when l_result is not null then ' ' end || to_char(p_error_code);
    end append_code_;
  begin
    --
    if p_citizenship is null                                           then append_code_(1); end if;   --����������� �� ������
    --
    if p_citizenship = 643 and p_doc_code 
      in (10, 11, 12, 13, 15, 19)                                      then append_code_(2); end if;   --����������� �� �� ������������� ��
    --
    if p_citizenship = '643' and p_doc_code 
      in (10, 11, 12, 13, 15, 19)                                      then append_code_(3); end if;   --����������� ���� �� ������������� �� ��
    --
    if p_doc_code not in (3, 7, 8, 10, 11, 12, 
      13, 14, 15, 19, 21, 23, 24, 91)                                  then append_code_(4); end if;   --��� �� ����������� ��������
    --
    if p_doc_code = 21 and not 
        regexp_like(p_doc_num, '^\d{2}\s\d{2}\s\d{6}$') then 
      if length(regexp_replace(p_doc_num, '[^[[:digit:]]]*')) = 10     then append_code_(18);          --������������ ������ �������� ��
      else                                                                  append_code_(5);           --������������ ����� �������� ��
      end if;
    end if;
    --
    if p_doc_code = 12 and not 
      regexp_like(p_doc_num, '^\d{2}\s\d{7}$')                         then append_code_(6);  end if;  --������������ ������ ���� �� ���������� � ��
    --
    if p_doc_code is null or p_doc_num is null                         then append_code_(7);  end if;  --�� ������ ��
    --
    if p_resident = 1 and coalesce(p_citizenship, 'NULL') <> '643' 
      and p_doc_code in (10, 11, 13, 15, 19)                           then append_code_(8);  end if;  --��������� �������� � ����������� ��� �� �� ��
    --
    if p_resident = 1 and coalesce(p_citizenship, 'NULL') <> '643'
      and p_doc_code = 12                                              then append_code_(9);  end if;  --��������� �������� � ��� �� ���������� ��
    --
    if p_doc_code <> 21 and p_citizenship = '643'
      and regexp_like(p_doc_num, '^\d{2}\s\d{2}\s\d{6}$')              then append_code_(10); end if; --�������� ����������� � ������ ������������� ������������� ���� �������� ��
    --
    if p_inn_dbl  > 1                                                  then append_code_(11); end if; --������������ ���
    if p_doc_dbl  > 1                                                  then append_code_(12); end if; --������������ ��
    if p_fiod_dbl > 1                                                  then append_code_(13); end if; --������������ ����
    --
    if p_inn is null                                                then append_code_(14); end if; --��� �� ��������
    --
    if p_inn is not null and
      fxndfl_util.Check_INN(p_inn) <> 0                             then append_code_(15); end if; --������������ ���
    --
    if p_nom_spr is not null and fxndfl_util.Check_ResidentTaxRate(
         p_code_na, 
         p_year, 
         p_nom_spr, 
         p_resident) <> 0                                           then append_code_(16); end if; --�� �����e������ ������ � ������� ���������
    --
    if p_invalid_doc = 'Y'                                          then append_code_(17); end if; --���������������� ������� ��
    --
    return l_result;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      return '0';
  end validate_pers_info;
  
  /**
   * 
   */
  procedure fill_spravki_errors(
    p_code_na int,
    p_year    int
  ) is
  begin
    --
    merge into f2ndfl_arh_spravki_err ase
    using (with w_errors as (
             select  e.kod_na, 
                     e.god,
                     e.r_sprid,
                     e.ui_person,
                     f2ndfl_arh_spravki_api.validate_pers_info(
                       e.kod_na          ,
                       e.god             ,
                       e.nom_spr         ,
                       e.ui_person       ,
                       e.kod_ud_lichn    ,
                       e.ser_nom_doc     ,
                       e.inn_fl          ,
                       e.grazhd          ,
                       e.status_np       ,
                       e.inn_dbl         ,
                       e.fiod_dbl        ,
                       e.doc_dbl         ,
                       e.is_invalid_doc
                     )                            error_list
             from   f2ndfl_arh_spravki_errors_v e
             where  1=1
             and    e.god = p_year
             and    e.kod_na = p_code_na
           )
           select e.kod_na code_na,
                  e.god year,
                  e.r_sprid,
                  s_prev.id r_sprid_prev,
                  p.error_id
           from   w_errors e,
                  lateral(
                    select level lvl,
                           to_number(regexp_substr(e.error_list, '[^ ]+', 1, level)) error_id
                    from   dual
                    connect by level <= regexp_count(e.error_list, ' +?') + 1
                  ) p,
                  lateral(
                    select 1
                    from   sp_ndfl_errors     se
                    where  se.error_type <> 'Warning'
                    and    se.error_id = p.error_id
                  ) se,
                  lateral(
                    select max(s_prev.id) keep(dense_rank last order by s_prev.nom_korr) id
                    from   f2ndfl_arh_spravki s_prev
                    where  s_prev.ui_person(+) = e.ui_person
                    and    s_prev.god(+) = e.god - 1
                    and    s_prev.kod_na(+) = e.kod_na
                  ) s_prev
           where  1=1
           and    e.error_list is not null
          ) u
    on    (ase.code_na = u.code_na and ase.year = u.year and ase.r_sprid = u.r_sprid)
    when not matched then
      insert (code_na, year, r_sprid, r_spr_id_prev, error_id)
        values (u.code_na, u.year, u.r_sprid, u.r_sprid_prev, u.error_id);
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end fill_spravki_errors;
  
  /**
   * ��������� fix_citizenship - ��������� ����������� � F2NDFL_ARH_SPRAVKI �� ������ �����������
   * !!! ������ �����, �� �������������.
   */
  procedure fix_cityzenship(
    p_code_na int,
    p_year    int,
    p_ref_id  f2ndfl_arh_spravki.id%type
  ) is
  begin
    merge into f2ndfl_arh_spravki sa
    using ( select t.id,
                   t.status,
                   s.id r_sprid,
                   max(a.fk_country_code)keep(dense_rank first order by a.fk_address_type) fk_country_code
            from   F2NDFL_ARH_SPRAVKI_ERR t,
                   f2ndfl_arh_spravki     s,
                   gazfond.addresses      a
            where  1=1
            and    a.fk_contragent = s.ui_person
            and    s.is_participant = 'Y'
            and    s.id = t.r_sprid
            and    t.status = 'New'
            and    t.error_id = 1
            and    t.r_sprid = nvl(p_ref_id, t.r_sprid)
            and    t.year = p_year
            and    t.code_na = p_code_na
            group by t.id,
                   t.status,
                   s.id
            having max(a.fk_country_code)keep(dense_rank first order by a.fk_address_type) is not null
          ) u
    on    (sa.id = u.r_sprid)
    when matched then
      update set
        sa.grazhd = u.fk_country_code;
    --
    update (select t.status
            from   F2NDFL_ARH_SPRAVKI_ERR t
            where  1=1
            and    exists(
                     select 1
                     from   f2ndfl_arh_spravki s
                     where  s.id = t.r_sprid
                     and    s.grazhd is not null
                   )
            and    t.status = 'New'
            and    t.error_id = 1
            and    t.r_sprid = nvl(p_ref_id, t.r_sprid)
            and    t.year = p_year
            and    t.code_na = p_code_na
           ) u
    set    u.status = 'Fix';
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end fix_cityzenship;
  --
end f2ndfl_arh_spravki_api;
/
