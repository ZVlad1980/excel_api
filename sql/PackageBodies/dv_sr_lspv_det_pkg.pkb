create or replace package body dv_sr_lspv_det_pkg is

  -- Private type declarations
  GC_PACKAGE_NAME   constant varchar2(32)                       := $$plsql_unit;  
  GС_PRC_UPDATE_DET constant dv_sr_lspv_prc_t.process_name%type := 'UPDATE_DETAIL';
  --GC_CHUNK_SIZE     constant int                                := 10000;
  --
  GC_ROW_STS_NEW    constant varchar2(1)                        := 'N';
  --GC_ROW_STS_UPDATE constant varchar2(1)                        := 'U';
  --GC_ROW_STS_DELETE constant varchar2(1)                        := 'D';
  --
  G_LEGACY       varchar2(1);
  
  /**
   * Обвертки обработки ошибок
   */
  procedure fix_exception(p_line number, p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => GC_PACKAGE_NAME || '(' || p_line || '): ' || ' ' || p_msg
    );
  end fix_exception;
  --
  
  function legacy return varchar2 deterministic is begin return nvl(G_LEGACY, 'N'); end legacy;
  --
  
  function get_os_user return varchar2 deterministic is
    l_result log$_dv_sr_lspv.created_by%type;
  begin
    select substrb(sys_context( 'userenv', 'os_user'), 1,32)
    into   l_result
    from dual;
    --
    return l_result;
  exception
    when others then
      return null;
  end get_os_user;

  /**
   * Процедура create_process создает новый процесс в таблице dv_sr_lspv_prc_t
   */
  function create_process(
    p_process_name varchar2 default GС_PRC_UPDATE_DET
  ) return dv_sr_lspv_prc_t.id%type is
    --
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
    --
    l_process_row.process_name := p_process_name;
    --
    dv_sr_lspv_prc_api.create_process(
      p_process_row => l_process_row
    );
    --
    return l_process_row.id;
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
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
    --
    l_process_row.id              := p_process_id  ;
    l_process_row.state           := p_state       ;
    l_process_row.error_msg       := p_error_msg   ;
    l_process_row.deleted_rows    := p_deleted_rows;
    l_process_row.error_rows      := p_error_rows  ;
    --
    dv_sr_lspv_prc_api.set_process_state(
      p_process_row => l_process_row
    );
    --
  exception
    when others then
      rollback;
      fix_exception($$plsql_line, 'set_process_state(' || p_process_id || ',' || p_state || ')');
      raise;
  end set_process_state;
  
  /**
   *
   */
  function get_errors_cnt(
    p_process_id dv_sr_lspv_det_t.process_id%type
  ) return int is
    l_result int;
  begin
    --
    select count(1)
    into   l_result
    from   err$_dv_sr_lspv_det_t e
    where  e.process_id = p_process_id;
    --
    return l_result;
    --
  exception
    when others then
      rollback;
      fix_exception($$plsql_line, 'get_errors_cnt(' || p_process_id || ')');
      raise;
  end;
  
  /**
   * 
   */
  procedure update_benefits(
    p_process_id dv_sr_lspv_det_t.process_id%type,
    p_date       date
  ) is
    --
    procedure update_benefits_new_ is
    begin
      --
      insert into dv_sr_lspv_det_t(
        charge_type,
        fk_dv_sr_lspv,
        amount,
        addition_code,
        addition_id,
        process_id
      ) select 'BENEFIT',
               a.fk_dv_sr_lspv#,
               case
                 when a.benefit_code_cnt = 0 then
                   a.amount
                 when a.benefit_code_cnt = 1 then
                  a.benefit_amount
                 when a.benefit_code_cnt > 0 then
                  case
                    when a.start_month > coalesce(a.last_month, a.month_op) then
                     0
                    else
                     (least(a.end_month, coalesce(a.last_month, a.month_op)) - a.start_month + 1) *
                        a.benefit_amount
                  end - a.total_benefits
               end benefit_amount,
               coalesce(a.benefit_code, -1 * a.shifr_schet),
               coalesce(a.pt_rid, -1),
               p_process_id
        from   dv_sr_lspv_acc_ben_v a
        where  1=1
        and    (
                 (a.benefit_code_cnt > 0 and a.amount > 0) 
                or
                 (a.benefit_code_cnt = 0 and a.amount <> 0)
               )
        and    nvl(a.regdate, a.date_op) <= a.date_op --!ТОЛЬКО АКТУАЛЬНЫЕ НА МОМЕНТ РАСЧЕТА, ЛИБО УДАЛЕННЫЕ
        and    a.date_op = p_date
        and    a.status = GC_ROW_STS_NEW
      log errors into err$_dv_sr_lspv_det_t reject limit unlimited;
      --
      dbms_output.put_line('update_benefits_new_: insert ' || sql%rowcount || ' row(s)');
      --
    end update_benefits_new_;
    --
  begin
    --
    
    --
    update_benefits_new_;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_details');
      raise;
  end update_benefits;
  
  /**
   * 
   */
  procedure update_details(
    p_process_id dv_sr_lspv_det_t.process_id%type
  ) is
    --
    type lt_date_rec is record(
      date_op date,
      benefit_exists varchar2(1),
      ritual_exists varchar2(1),
      corr_exists varchar2(1)
    );
    type lt_dates_tbl is table of lt_date_rec;
    l_dates_tbl lt_dates_tbl;
    --
    procedure build_dates_list_ is
    begin
      with w_dv as (
        select /*+ materialize*/
               d.year_op, d.nom_vkl, d.nom_ips, d.date_op, d.shifr_schet, d.sub_shifr_schet, d.ssylka_doc
        from   dv_sr_lspv#_v d
        where  d.status = GC_ROW_STS_NEW --only is new records
      )
      select a.date_op,
             max(case a.charge_type when 'BENEFIT' then 'Y' end)    benefit_exists,
             max(case a.det_charge_type when 'RITUAL' then 'Y' end) ritual_exists,
             max(
               case 
                 when a.service_doc <> 0 or 
                   (a.charge_type in ('REVENUE', 'BENEFIT') and
                    a.amount < 0
                   ) 
                   then 'Y' 
               end
             )                                                      corr_exists
      bulk collect into l_dates_tbl
      from   dv_sr_lspv_acc_v a
      where  (a.nom_vkl, a.nom_ips, a.date_op)
             in (select d.nom_vkl, d.nom_ips, d.date_op--, d.shifr_schet, d.sub_shifr_schet, d.ssylka_doc
                 from   w_dv d
                )
      and       a.year_op >= (select min(d.year_op) from w_dv d)
      group by a.date_op
      order by a.date_op;
      --
    end build_dates_list_;
    --
    --Сброс статусов 
    -- 
    procedure reset_statuses_ is
    begin
      --... обработанных
      update (select d.status
              from   dv_sr_lspv#_v d
              where  1=1
              and    d.id in (
                       select dt.fk_dv_sr_lspv
                       from   dv_sr_lspv_det_v dt
                       where  dt.process_id = p_process_id
                     ) 
              and    d.status = GC_ROW_STS_NEW
             ) u
      set    u.status = null;
    end reset_statuses_;
    --
  begin
    --
    build_dates_list_;
    --
    for i in 1..l_dates_tbl.count loop
      dv_sr_lspv_docs_api.set_period(
        p_start_date  => trunc(l_dates_tbl(i).date_op, 'Y'),
        p_end_date    => l_dates_tbl(i).date_op,
        p_report_date => l_dates_tbl(i).date_op
      );
      if l_dates_tbl(i).benefit_exists = 'Y' then
        update_benefits(p_process_id, l_dates_tbl(i).date_op);
      end if;
    end loop;
    --
    reset_statuses_;
    --
    dbms_output.put_line('update_benefits_forwards: errors ' || get_errors_cnt(p_process_id) || ' row(s)');
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_details');
      raise;
  end update_details;
  
  /**
   * Процедура update_details обновляет данные таблицы 
   *   dv_sr_lspv_det_t данными из dv_sr_lspv, строки в статусе N или U
   *   и сбрасывает их статус в null
   */
  procedure update_details is
    l_process_id dv_sr_lspv_det_t.process_id%type;
  begin
    --
    l_process_id := create_process;
    --
    G_LEGACY := 'Y';
    --
    update_details(l_process_id);
    --
    set_process_state(
      l_process_id, 
      'SUCCESS'
    );
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_details');
      if l_process_id is not null then
        set_process_state(
          l_process_id, 
          'ERROR', 
          p_error_msg => sqlerrm
        );
      end if;
      raise;
  end update_details;
  
end dv_sr_lspv_det_pkg;
/
