create or replace package body dv_sr_lspv_docs_api is

  -- Private type declarations
  C_PACKAGE_NAME constant varchar2(32) := $$plsql_unit;
  
  --
  G_START_DATE date;
  G_END_DATE   date;
  
  /**
   * Обвертки обработки ошибок
   */
  procedure fix_exception(p_line number, p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => C_PACKAGE_NAME || '(' || p_line || '): ' || ' ' || p_msg
    );
  end;
  
  /**
   * Функции обвертки для представлений
   */
  function get_start_date return date deterministic is begin return G_START_DATE; end;
  function get_end_date   return date deterministic is begin return G_END_DATE; end;
  
  procedure set_period(
    p_start_date date,
    p_end_date   date
  ) is
  begin
    G_START_DATE := p_start_date;
    G_END_DATE   := trunc(p_end_date) + 1 - .00001; --на конец суток
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
   * Процедура установки периода
   */
  procedure set_period(p_year number) is
  begin
    if not p_year between 1995 and 2030 then
      fix_exception($$plsql_line, 'Year no correct: ' || p_year);
      raise utl_error_api.G_EXCEPTION;
    end if;
    --
    set_period(
      p_start_date => to_date(p_year || '0101', 'yyyymmdd'),
      p_end_date   => to_date(p_year || '1231', 'yyyymmdd')
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
   */
  function create_process return dv_sr_lspv_prc_t.id%type is
    pragma autonomous_transaction;
    --
    l_result dv_sr_lspv_prc_t.id%type;
  begin
    --
    --dbms_lock!!!
    insert into dv_sr_lspv_prc_t(
      start_date,
      end_date,
      state
    ) values (
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
           p.deleted_rows  = p_deleted_rows,
           last_udpated_at = default,
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
  procedure update_dv_sr_lspv_docs_t(p_process_id dv_sr_lspv_prc_t.id%type) is
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
    set_process_state(
      p_process_id, 
      'SUCCESS', 
      p_deleted_rows => sql%rowcount,
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
   * Процедура synchronize синхронизирует таблицу dv_sr_lspv_docs_t данными из таблицы fnd.dv_sr_lspv
   *  за указанный год (p_year)
   */
  procedure synchronize(p_year in number) is
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
  begin
    --
    set_period(p_year);
    --
    update_dv_sr_lspv_docs_t(create_process);
    --
    stats_;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'synchronize(' || p_year || ')');
      raise;
  end synchronize;
  
  /**
   * Функция определяет является ли операция - возвратом налога по заявлению
   *
   *  На текущий момент, к таковым относятся:
   *    - операции коррекции налога по выкупным суммам
   *    - операции коррекции налога по пенсии, при наличии операции по 83 счету и этому же документу на обратную сумму
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

begin
  set_period(p_year => extract(year from sysdate));
end dv_sr_lspv_docs_api;
/
