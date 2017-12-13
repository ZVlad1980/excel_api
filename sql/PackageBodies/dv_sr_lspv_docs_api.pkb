create or replace package body dv_sr_lspv_docs_api is

  -- Private type declarations
  C_PACKAGE_NAME constant varchar2(32) := $$plsql_unit;
  
  --����� ��������� 
  �_PRC_SYNCHRONIZE       constant varchar2(40) := 'SYNCHRONIZE';
  C_PRC_UPDATE_GF_PERSONS constant varchar2(40) := 'UPDATE_GF_PERSONS';
  
  --
  G_START_DATE     date;
  G_END_DATE       date;
  G_IS_BUF         varchar2(1) := 'N';
  G_START_DATE_BUF date;
  G_END_DATE_BUF   date;
  /**
   * �������� ��������� ������
   */
  procedure fix_exception(p_line number, p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => C_PACKAGE_NAME || '(' || p_line || '): ' || ' ' || p_msg
    );
  end;
  
  /**
   * ������� �������� ��� �������������
   */
  function get_start_date return date deterministic is begin return G_START_DATE; end;
  function get_end_date   return date deterministic is begin return G_END_DATE; end;
  function get_is_buff    return varchar2 deterministic is begin return G_IS_BUF; end;
  function get_start_date_buf  return date deterministic is begin return G_START_DATE_BUF; end;
  function get_end_date_buf    return date deterministic is begin return G_END_DATE_BUF; end;
  /**
   * ��������� set_is_buff � unset_is_buff - �������� � ��������� ���� ������ �������� VYPLACH... � ��������������
   */
  procedure set_is_buff is
  begin 
    G_IS_BUF         := 'Y';
    if extract(month from trunc(G_END_DATE)) = 12 then
      unset_is_buff;
    else
      G_START_DATE_BUF := trunc(G_END_DATE) + 1;
      G_END_DATE_BUF   := add_months(trunc(G_START_DATE_BUF, 'MM'), 1) - 1;
    end if;
  end set_is_buff;
  
  procedure unset_is_buff is 
  begin 
    G_IS_BUF := 'N'; 
    G_START_DATE_BUF := null;
    G_END_DATE_BUF := null;
  end unset_is_buff;
  
  procedure set_period(
    p_start_date date,
    p_end_date   date
  ) is
  begin
    G_START_DATE := p_start_date;
    G_END_DATE   := trunc(p_end_date) + 1 - .00001; --�� ����� �����
    if get_is_buff = 'Y' then
      set_is_buff; --�������� �������, ���� ������� ���� ������ VYPLACH
    else
      unset_is_buff;
    end if;
  end set_period;
  
  procedure set_period(
    p_end_date date
  ) is
  begin
    set_period(
      p_start_date => trunc(p_end_date, 'Y'),
      p_end_date   => p_end_date
    );
  end set_period; 
  
  /**
   * ��������� ��������� �������
   */
  procedure set_period(p_year number) is
    l_end_date date;
  begin
    if not p_year between 1995 and 2030 then
      fix_exception($$plsql_line, 'Year no correct: ' || p_year);
      raise utl_error_api.G_EXCEPTION;
    end if;
    --
    if p_year = extract(year from sysdate) then
      l_end_date := trunc(sysdate, 'MM') - .00001; --���� ���������� - ���������� �����
    else
      l_end_date := to_date(p_year || '1231', 'yyyymmdd');
    end if;
    --
    set_period(
      p_start_date => to_date(p_year || '0101', 'yyyymmdd'),
      p_end_date   => l_end_date
    );
    --
  exception
    when others then
      fix_exception($$plsql_line, 'set_period(' || p_year || ')');
      raise;
  end set_period;
  
  /**
   *
   */
  function  get_last_update_date(p_year in number) return timestamp is
    l_result timestamp;
  begin
    --
    select max(p.created_at) last_update --to_char(max(p.created_at), 'dd.mm.yyyy hh24:mi:ss') last_update
    into   l_result
    from   DV_SR_LSPV_PRC_T p
    where  extract(year from p.end_date) = p_year;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'get_last_update_date(' || p_year || ')');
      raise;
  end get_last_update_date;
  
  /**
   * ��������� create_process ������� ����� ������� � ������� dv_sr_lspv_prc_t
   */
  function create_process(
    p_process_name varchar2 default �_PRC_SYNCHRONIZE
  ) return dv_sr_lspv_prc_t.id%type is
    pragma autonomous_transaction;
    --
    l_result dv_sr_lspv_prc_t.id%type;
  begin
    --
    --dbms_lock!!!
    insert into dv_sr_lspv_prc_t(
      process_name,
      start_date,
      end_date,
      state
    ) values (
      p_process_name,
      G_START_DATE,
      G_END_DATE  ,
      'CREATED'
    ) returning id into l_result;
    --
    commit;
    --
    return l_result;
    --
  exception
    when others then
      rollback;
      fix_exception($$plsql_line, 'create_process');
      raise;
  end create_process;
  
  /**
   */
  procedure set_process_state(
    p_process_id      dv_sr_lspv_prc_t.id%type,
    p_state           dv_sr_lspv_prc_t.state%type,
    p_error_msg       dv_sr_lspv_prc_t.error_msg%type    default null,
    p_deleted_rows    dv_sr_lspv_prc_t.deleted_rows%type default null,
    p_error_rows      dv_sr_lspv_prc_t.error_rows%type   default null
  ) is
    pragma autonomous_transaction;
  begin
    --
    update dv_sr_lspv_prc_t p
    set    p.state         = p_state,
           p.error_msg     = p_error_msg,
           last_udpated_at = default,
           p.deleted_rows  = p_deleted_rows,
           error_rows      = p_error_rows
    where  p.id = p_process_id;
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception($$plsql_line, 'set_process_state(' || p_process_id || ',' || p_state || ')');
      raise;
  end set_process_state;
  
  /**
   */
  function get_error_rows_cnt(
    p_process_id dv_sr_lspv_prc_t.id%type
  ) return dv_sr_lspv_prc_t.error_rows%type is
    l_result dv_sr_lspv_prc_t.error_rows%type;
  begin
    --
    select count(1)
    into   l_result
    from   err$_dv_sr_lspv_docs_t ed
    where  ed.process_id = p_process_id;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'get_error_rows_cnt(' || p_process_id || ')');
      raise;
  end get_error_rows_cnt;
  /**
   */
  procedure update_dv_sr_lspv_docs_t(
    p_process_id dv_sr_lspv_prc_t.id%type
  ) is
    l_del_rows number;
  begin
    --
    set_process_state(
      p_process_id, 
      'PROCESSED'
    );
    --
    merge into dv_sr_lspv_docs_t d
    using (select dc.date_op, 
                  dc.ssylka_doc_op, 
                  dc.type_op, 
                  dc.date_doc, 
                  dc.ssylka_doc, 
                  dc.nom_vkl, 
                  dc.nom_ips, 
                  dc.ssylka_fl, 
                  dc.gf_person, 
                  dc.pen_scheme_code,
                  dc.tax_rate, 
                  dc.det_charge_type,
                  dc.revenue, 
                  dc.benefit, 
                  dc.tax, 
                  dc.tax_83, 
                  dc.source_revenue, 
                  dc.source_benefit, 
                  dc.source_tax,
                  dc.is_tax_return
           from   dv_sr_lspv_docs_src_v  dc
         ) u
    on   (d.date_op       = u.date_op         and 
          d.ssylka_doc_op = u.ssylka_doc_op   and 
          d.date_doc      = u.date_doc        and 
          d.ssylka_doc    = u.ssylka_doc      and 
          d.nom_vkl       = u.nom_vkl         and 
          d.nom_ips       = u.nom_ips         and 
          d.gf_person     = u.gf_person       and 
          d.tax_rate      = u.tax_rate     
         )--DATE_OP, SSYLKA_DOC_OP, DATE_DOC, SSYLKA_DOC, NOM_VKL, NOM_IPS, GF_PERSON, TAX_RATE
    when matched then
      update set
        d.det_charge_type = u.det_charge_type,
        d.revenue         = u.revenue, 
        d.benefit         = u.benefit, 
        d.tax             = u.tax, 
        d.tax_83          = u.tax_83, 
        d.source_revenue  = u.source_revenue,
        d.source_benefit  = u.source_benefit,
        d.source_tax      = u.source_tax,
        d.is_tax_return   = u.is_tax_return,
        d.process_id      = p_process_id
    when not matched then
      insert (
        id,
        date_op, 
        ssylka_doc_op, 
        type_op, 
        date_doc, 
        ssylka_doc, 
        nom_vkl, 
        nom_ips, 
        ssylka_fl, 
        gf_person, 
        pen_scheme_code, 
        tax_rate, 
        det_charge_type, 
        revenue, 
        benefit, 
        tax, 
        tax_83, 
        source_revenue,
        source_benefit,
        source_tax,
        is_tax_return,
        process_id
      ) values (
        dv_sr_lspv_docs_seq.nextval,
        u.date_op, 
        u.ssylka_doc_op, 
        u.type_op,
        u.date_doc, 
        u.ssylka_doc, 
        u.nom_vkl, 
        u.nom_ips, 
        u.ssylka_fl, 
        u.gf_person, 
        u.pen_scheme_code,
        u.tax_rate, 
        u.det_charge_type,
        u.revenue, 
        u.benefit, 
        u.tax, 
        u.tax_83, 
        u.source_revenue, 
        u.source_benefit, 
        u.source_tax,
        u.is_tax_return,
        p_process_id
      )
      log errors into err$_dv_sr_lspv_docs_t reject limit unlimited;
    --
    update dv_sr_lspv_docs_t d
    set    d.is_delete = 'Y',
           d.process_id = p_process_id
    where  d.process_id <> p_process_id;
    --
    l_del_rows := sql%rowcount;
    --
    set_process_state(
      p_process_id, 
      'SUCCESS', 
      p_deleted_rows => l_del_rows,
      p_error_rows   => get_error_rows_cnt(p_process_id)
    );
    --
  exception
    when others then
      fix_exception($$plsql_line, 'update_dv_sr_lspv_docs_t');
      set_process_state(
        p_process_id, 
        'ERROR', 
        p_error_msg => sqlerrm
      );
      raise;
  end update_dv_sr_lspv_docs_t;

  /**
   * ��������� synchronize �������������� ������� dv_sr_lspv_docs_t ������� �� ������� fnd.dv_sr_lspv
   *  �� ��������� ��� (p_year)
   */
  procedure synchronize(p_year in number) is
    --
    function check_update_gf_persons_ return boolean is
      l_last_start date;
    begin
      select max(p.created_by)
      into   l_last_start
      from   dv_sr_lspv_prc_t p
      where  p.process_name = 'UPDATE_GF_PERSONS';
      --
      return trunc(sysdate) - trunc(l_last_start) >= 1;
    exception
      when no_data_found then
        return true;
      when others then
        fix_exception($$plsql_line, 'check_update_gf_persons_');
        raise;
    end check_update_gf_persons_;
    --
    --
    procedure stats_ is
    begin
      dbms_stats.gather_table_stats('FND', upper('dv_sr_lspv_docs_t'));
      return;
      dbms_stats.gather_index_stats('FND', upper('dv_sr_lspv_docs_i1'));
      dbms_stats.gather_index_stats('FND', upper('dv_sr_lspv_docs_i2'));
      dbms_stats.gather_index_stats('FND', upper('dv_sr_lspv_docs_i3'));
      dbms_stats.gather_index_stats('FND', upper('dv_sr_lspv_docs_i4'));
      dbms_stats.gather_index_stats('FND', upper('dv_sr_lspv_docs_i5'));
      dbms_stats.gather_index_stats('FND', upper('dv_sr_lspv_docs_i6'));
      dbms_stats.gather_index_stats('FND', upper('dv_sr_lspv_docs_i7'));
      dbms_stats.gather_index_stats('FND', upper('dv_sr_lspv_docs_u1'));
    end;
    --
  begin
    --���������� GF_PERSONS ��������� � �������� �������� ������, ����� ������ ��� ���������
    if check_update_gf_persons_ then
      update_gf_persons(p_year);
    end if;
    --
    set_period(p_year);
    --
    update_dv_sr_lspv_docs_t(
      p_process_id => create_process
    );
    --
    stats_;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'synchronize(' || p_year || ')');
      raise;
  end synchronize;
  
  /**
   * ��������� build_list_gf_persons ������ ������ ������������ / ������������� GF_PERSON
   *  � ������� DV_SR_LSPV_UID_PERS_T
   */
  procedure build_list_gf_persons(
    p_process_id int
  ) is
    --
    procedure insert_gf_persons_ is
    begin
      insert into dv_sr_gf_persons_t(
        contragent_type,
        nom_vkl,
        nom_ips,
        ssylka,
        gf_person_old,
        gf_person_new,
        process_id
      ) select gp.contragent_type,
               gp.nom_vkl,
               gp.nom_ips,
               gp.ssylka,
               case gp.gf_person when -1 then null else gp.gf_person end,
               (select max(m.fk_person_united)keep(dense_rank last order by m.lvl) 
                from   contragent_merge_log_v m
                where  1=1
                and    m.fk_person_removed_root = gp.gf_person
               ) fk_person_united,
               p_process_id
        from   sp_gf_persons_v        gp
        where  1=1
        and    gp.gf_person not in (
                 select p.fk_contragent
                 from   gf_people_v p
               );
    exception
      when others then
        fix_exception($$plsql_line, 'insert_gf_persons_(' || p_process_id || ')');
        raise;
    end insert_gf_persons_;
    --
    -- ����������� GF_PERSON �� ��� (������� �� ���������� ����������)
    --
    procedure update_gf_person_inn_ is
    begin
      update dv_sr_gf_persons_t  gp
      set    gp.gf_person_new = (
               select c.id
               from   sp_inn_fiz_lits     inn,
                      gazfond.contragents c
               where  1=1
               and    c.inn = inn.inn
               and    inn.ssylka = gp.ssylka
             )
      where  gp.gf_person_new is null
      and    gp.contragent_type = 'PENSIONER'
      and    gp.process_id = p_process_id;
    exception
      when others then
        fix_exception($$plsql_line, 'update_gf_person_inn_(' || p_process_id || ')');
        raise;
    end update_gf_person_inn_;
    --
    -- ����������� GF_PERSON �� ��� + ��
    --
    procedure update_gf_person_fio_ is
    begin
      update dv_sr_gf_persons_t  gp
      set    gp.gf_person_new = (
               select p.fk_contragent
               from   (
                       select p.fk_contragent,
                              count(1)over(partition by p.fk_contragent) cnt
                       from   sp_fiz_lits         fl,
                              gf_people_v         p
                       where  1=1
                       --
                       and    p.birthdate = fl.data_rogd
                       and    nvl(upper(p.secondname), '$NULL$') = nvl(upper(fl.otchestvo), '$NULL$')
                       and    upper(p.firstname) = upper(fl.imya)
                       and    upper(p.lastname) = upper(fl.familiya)
                       --
                       and    fl.ssylka = gp.ssylka
                      ) p
               where  p.cnt = 1
             )
      where  gp.gf_person_new is null
      and    gp.contragent_type = 'PENSIONER'
      and    gp.process_id = p_process_id;
      --
      update dv_sr_gf_persons_t  gp
      set    gp.gf_person_new = (
               select p.fk_contragent
               from   (
                       select p.fk_contragent,
                              count(1)over(partition by p.fk_contragent) cnt
                       from   sp_ritual_pos_v     fl,
                              gf_people_v         p
                       where  1=1
                       --
                       and    p.birthdate = fl.birth_date 
                       and    nvl(upper(p.secondname), '$NULL$') = nvl(upper(fl.second_name ), '$NULL$')
                       and    upper(p.firstname) = upper(fl.first_name )
                       and    upper(p.lastname) = upper(fl.last_name )
                       --
                       and    fl.ssylka = gp.ssylka
                      ) p
               where  p.cnt = 1
             )
      where  gp.gf_person_new is null
      and    gp.contragent_type = 'SUCCESSOR'
      and    gp.process_id = p_process_id;
    exception
      when others then
        fix_exception($$plsql_line, 'update_gf_person_inn_(' || p_process_id || ')');
        raise;
    end update_gf_person_fio_;
    --
  begin
    --
    insert_gf_persons_;
    update_gf_person_inn_;
    update_gf_person_fio_;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'build_list_gf_persons(' || p_process_id || ')');
      raise;
  end build_list_gf_persons;
  
  /**
   * ��������� update_gf_persons ��������� GF_PERSONS
   *  � �������� SP_FIZ_LITS.GF_PERSON, POLUCH_POSOB.GF_PERSON, SP_RITUAL_POS.FK_CONTRAGENT, DV_SR_LSPV_DOCS_T.GF_PEROSN
   *  �� ������� DV_SR_LSPV_UID_PERS_T
   */
  procedure update_gf_persons(
    p_process_id int
  ) is
    --
    -- ���������� GF_PERSON � sp_fiz_lits
    --
    procedure update_pensioners_ is
    begin
      update (select fl.ssylka,
                     fl.gf_person,
                     gp.gf_person_new
              from   dv_sr_gf_persons_t gp,
                     sp_fiz_lits        fl
              where  1=1
              and    fl.gf_person <> gp.gf_person_new
              and    fl.ssylka = gp.ssylka
              and    gp.contragent_type = 'PENSIONER'
              and    gp.process_id = p_process_id
             ) u
      set u.gf_person = u.gf_person_new;
    exception
      when others then
        fix_exception($$plsql_line, 'update_pensioners_(' || p_process_id || ')');
        raise;
    end update_pensioners_;
    --
    -- ���������� GF_PERSON � sp_ritual_pos
    --
    procedure update_successors_ is
    begin
      update (select fl.ssylka,
                     fl.fk_contragent,
                     gp.gf_person_new
              from   dv_sr_gf_persons_t gp,
                     sp_ritual_pos      fl
              where  1=1
              and    fl.fk_contragent <> gp.gf_person_new
              and    fl.ssylka = gp.ssylka
              and    gp.contragent_type = 'PENSIONER'
              and    gp.process_id = p_process_id
             ) u
      set u.fk_contragent = u.gf_person_new;
      --
      /*
      update (select fl.ssylka,
                     fl.fk_contragent,
                     gp.gf_person_new
              from   dv_sr_gf_persons_t gp,
                     vyplach_posob      fl
              where  1=1
              and    fl.ssylka = gp.ssylka
              and    gp.contragent_type = 'PENSIONER'
              and    gp.process_id = p_process_id
             ) u
      set u.fk_contragent = u.gf_person_new;
      --*/
    exception
      when others then
        fix_exception($$plsql_line, 'update_successors_(' || p_process_id || ')');
        raise;
    end update_successors_;
    --
    -- ���������� GF_PERSON � dv_sr_lspv_docs_t
    --
    procedure update_docs_t_ is
    begin
      merge into dv_sr_lspv_docs_t d
      using (select dd.id,
                    gp.gf_person_new
             from   dv_sr_gf_persons_t gp,
                    dv_sr_lspv_docs_t  dd
             where  1 = 1
             and    dd.gf_person = gp.gf_person_old
             and    gp.gf_person_old is not null
             and    gp.process_id = p_process_id
            ) u
      on    (d.id = u.id)
      when matched then
        update set
        d.gf_person = u.gf_person_new;
    exception
      when others then
        fix_exception($$plsql_line, 'update_docs_t_(' || p_process_id || ')');
        raise;
    end update_docs_t_;
    --
  begin
    --
    update_pensioners_;
    update_successors_;
    update_docs_t_;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'update_gf_persons(' || p_process_id || ')');
      raise;
  end update_gf_persons;
  
  /**
   * ��������� ���������� GF_PERSON �� DV_SR_LSPV �� �������� ���
   *  ��������� ������� SP_FIZ_LITS.GF_PERSON, POLUCH_POSOB.GF_PERSON, SP_RITUAL_POS.FK_CONTRAGENT, DV_SR_LSPV_DOCS_T.GF_PEROSN
   *  �������� ������ � dv_sr_gf_persons_t
   */
  procedure update_gf_persons(
    p_year  in number
  ) is
    --
    l_process_id int;
    --
  begin
    --
    set_period(p_year);
    --
    l_process_id := create_process(
      p_process_name => C_PRC_UPDATE_GF_PERSONS
    );
    --
    build_list_gf_persons(
      p_process_id => l_process_id
    );
    --
    update_gf_persons(
      p_process_id => l_process_id
    );
    --
    set_process_state(
      l_process_id, 
      'SUCCESS'
    );
    --
  exception
    when others then
      fix_exception($$plsql_line, 'update_gf_persons(' || p_year || ')');
      if l_process_id is not null then
        set_process_state(
          l_process_id, 
          'ERROR', 
          p_error_msg => sqlerrm
        );
      end if;
      raise;
  end update_gf_persons;
  
  
  /**
   * ������� ���������� �������� �� �������� - ��������� ������ �� ���������
   *
   *  �� ������� ������, � ������� ���������:
   *    - �������� ��������� ������ �� �������� ������
   *    - �������� ��������� ������ �� ������, ��� ������� �������� �� 83 ����� � ����� �� ��������� �� �������� �����
   */
  function is_tax_return(
    p_nom_vkl          fnd.dv_sr_lspv.nom_vkl%type,
    p_nom_ips          fnd.dv_sr_lspv.nom_ips%type,
    p_date_op          fnd.dv_sr_lspv.data_op%type,
    p_shifr_schet      fnd.dv_sr_lspv.shifr_schet%type,
    p_sub_shifr_schet  fnd.dv_sr_lspv.sub_shifr_schet%type,
    p_ssylka_doc       fnd.dv_sr_lspv.ssylka_doc%type,
    p_det_charge_type  varchar2,
    p_amount           fnd.dv_sr_lspv.summa%type
  ) return varchar2 is
    --
    l_result varchar2(1) := 'N';
    --
    cursor l_ret_tax_cur is
      select a.amount
      from   dv_sr_lspv_acc_v a
      where  1=1
      and    a.date_op         < p_date_op        
      and    a.shifr_schet     = 83
      and    a.ssylka_doc      = p_ssylka_doc
      and    a.nom_vkl         = p_nom_vkl        
      and    a.nom_ips         = p_nom_ips        ;
    --
  begin
    --
    if p_det_charge_type = 'PENSION' then
      for i in l_ret_tax_cur loop
        l_result := case abs(p_amount) when abs(i.amount) then 'Y' else 'N' end;
        exit;
      end loop;
    end if;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception('is_tax_return ' || p_nom_vkl || '/'
        || p_nom_ips         || '/'
        || p_date_op         || '/'
        || p_shifr_schet     || '/'
        || p_sub_shifr_schet || '/'
        || p_ssylka_doc      || '/'
        || p_det_charge_type || '/'
        || p_amount
      );
      return null;
  end is_tax_return;
  
  /**
   * ��������� build_tax_diff ��������� ������ �� ����������� ����������� � ������������ ������
   *   ������ ������� � ������� dv_sr_lspv_tax_diff_buf, ������� ����� ������������� ���������!
   *
   * @param p_end_date - ���� ��������� ������� ������� (�� ��������� - ���� ��������� ����������� ������ �� ������� ����)
   *
   */
  procedure build_tax_diff(
    p_end_date date default null
  ) is
  begin
    --
    set_period(
      p_end_date => nvl(p_end_date, trunc(sysdate, 'MM') - 1)
    );
    set_is_buff;
    --
    execute immediate 'truncate table dv_sr_lspv_tax_diff_buf';
    --
    insert into dv_sr_lspv_tax_diff_buf(
      gf_person,
      lastname,
      firstname,
      secondname,
      ssylka_fl,
      nom_vkl,
      nom_ips,
      pen_scheme,
      revenue_shifr_schet,
      tax_shifr_schet,
      revenue,
      benefit,
      tax,
      tax_retained,
      tax_calc,
      tax_diff
    ) select d.gf_person,
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
      from   dv_sr_lspv_tax_diff_det_v d;
    --
  exception
    when others then
      fix_exception($$plsql_line);
      dbms_output.put_line(utl_error_api.get_exception_full);
      raise;
  end build_tax_diff;

begin
  set_period(p_end_date => trunc(sysdate, 'MM') - 1);
end dv_sr_lspv_docs_api;
/
