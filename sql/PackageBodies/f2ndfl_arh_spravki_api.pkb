create or replace package body f2ndfl_arh_spravki_api is

  C_PACKAGE_NAME constant varchar2(32) := $$plsql_unit;
  
  type g_util_par_type is record (
    KODNA     number        ,
    GOD       number        ,
    TIPDOX    number        ,
    NOMKOR    number        ,
    SPRID     number        ,
    NOMSPR    varchar2(10)  ,
    DATDOK    date          ,
    NOMVKL    number        ,
    NOMIPS    number        ,
    CAID      number        ,
    SRC_SPRID number
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
        pCOMMIT => false             
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
    p_globals  in out nocopy g_util_par_type
  ) is
    procedure init_ is begin set_globals_util_pkg(p_globals); end init_;
  begin
    --
    case p_rev_type
      when 1 then
        init_; fxndfl_util.Load_Pensionery_bez_Storno;
        init_; fxndfl_util.Load_Pensionery_so_Storno;
        init_; fxndfl_util.Load_MesDoh_Pensia_bezIspr;
        init_; fxndfl_util.Load_MesDoh_Pensia_sIspravl;
      when 2 then
        init_; fxndfl_util.Load_Posobiya_bez_Pravok;
        init_; fxndfl_util.Load_Posobiya_s_Ipravlen;
        init_; fxndfl_util.Load_MesDoh_Posob_bezIspr;
        init_; fxndfl_util.Load_MesDoh_Posob_sIspravl;
      when 3 then
        init_; fxndfl_util.Load_Vykupnye_bez_Pravok;
        init_; fxndfl_util.Load_Vykupnye_s_Ipravlen;
        init_; fxndfl_util.Load_MesDoh_Vykup_bezIspr;
        init_; fxndfl_util.Load_MesDoh_Vykup_sIspravl;
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
    p_globals  in out nocopy g_util_par_type
  ) is
    l_dummy int;
    procedure init_ is begin set_globals_util_pkg(p_globals); end init_;
  begin
    --
    l_dummy := fxndfl_util.ZapolnGRAZHD_poUdLichn(pGod => p_globals.GOD);
    fxndfl_util.copy_load_address(
      p_src_ref_id => p_globals.SRC_SPRID,
      p_nom_corr   => p_globals.NOMKOR
    );
    init_; fxndfl_util.Load_Vychety;
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
    fxndfl_util.calc_benefit_usage(p_spr_id => p_globals.SPRID);
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end create_arh_total; 
  
  /**
   * ��������� calc_reference ������ ����� �������
   *
   * @param p_ref_row    - ������� f2ndfl_arh_spravki%rowtype
   * @param p_src_ref_id - ID ���������� �������
   * @param p_wo_arh     - ��� ��������� ������ � ARH (def: FALSE)
   *
   */
  procedure calc_reference(
    p_ref_row     in out nocopy f2ndfl_arh_spravki%rowtype,
    p_src_ref_id  in f2ndfl_arh_spravki.id%type,
    p_wo_arh      in boolean default false
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
    --
    for r in l_revenue_types_cur loop
      --
      l_globals.TIPDOX := r.rev_type;
      l_globals.NOMVKL := r.nom_vkl;
      l_globals.NOMIPS := r.nom_ips;
      l_globals.CAID   := r.fk_contragent;
      --
      create_load_refs(
        p_rev_type      => r.rev_type,
        p_globals       => l_globals
      );
      --
    end loop;
    --
    l_globals.TIPDOX := null;
    l_globals.NOMVKL := null;
    l_globals.NOMIPS := null;
    l_globals.CAID   := null;
    --
    create_load_total(l_globals);
    --
    if not p_wo_arh then
      create_arh_total(l_globals);
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
    select *
    into   l_result
    from   f2ndfl_arh_spravki s
    where  s.id = p_ref_id;
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
    group by an.nom_spr;
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
   * ������� copy_reference ������� �������������� �������
   *
   * @param p_ref_src - ������ � �������� �������� 
   *
   * @return - f2ndfl_arh_spravki%rowtype ��������� �������
   *
   */
  function copy_reference(
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
    l_result.id := fxndfl_util.copy_ref_2ndfl(
      p_ref_row => l_result
    );
    --
    return l_result;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end copy_reference;
  
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
   * ��������� create_reference_corr �������� �������������� ������� 2����
   *
   * @param p_code_na       - ��� ����������������� (���=1)
   * @param p_year          - ���, �� ������� ���� ������������ �������������
   * @param p_contragent_id - ID �����������, �� �������� ����������� ������� (CDM.CONTRAGENTS.ID)
   *
   */
  procedure create_reference_corr(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_contragent_id  f2ndfl_arh_nomspr.fk_contragent%type
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
    plog('Current spr_id = ' || l_ref_curr.id || ', nom_spr = ' || l_ref_curr.nom_spr || ', nom_korr = ' || l_ref_curr.nom_korr);
    --
    check_synch_load(p_ref_arh => l_ref_curr);
    --
    l_ref_new := copy_reference(
      p_ref_src => l_ref_curr
    );
    --
    plog('New spr_id = ' || l_ref_new.id);
    --
    calc_reference(
      p_ref_row    => l_ref_new,
      p_src_ref_id => l_ref_curr.id
    );
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE);
      raise;
  end create_reference_corr;

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
    p_ref_row f2ndfl_arh_spravki%rowtype
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
    p_ref_id f2ndfl_arh_spravki.id%type
  ) is
  begin
    --
    delete from f2ndfl_arh_adr a
    where  a.r_sprid = p_ref_id;
    --
    plog('  f2ndfl_arh_adr deleted      ' || sql%rowcount || ' row(s)');
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
    delete from f2ndfl_arh_uved a
    where  a.r_sprid = p_ref_id;
    --
    plog('  f2ndfl_arh_uved deleted     ' || sql%rowcount || ' row(s)');
    --
    delete from f2ndfl_arh_spravki a
    where  a.id = p_ref_id;
    --
    plog('  f2ndfl_arh_spravki deleted  ' || sql%rowcount || ' row(s)');
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
   * @param p_ref_id     - ID ��������� �������
   * @param p_commit     - ���� �������� ����������
   *
   */
  procedure delete_reference(
    p_ref_id f2ndfl_arh_spravki.id%type,
    p_commit boolean default false
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
    purge_load_tbl(l_ref_row);
    --
    purge_arh_tbl(l_ref_row.id);
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
        p_wo_arh     => true
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
  --
end f2ndfl_arh_spravki_api;
/
