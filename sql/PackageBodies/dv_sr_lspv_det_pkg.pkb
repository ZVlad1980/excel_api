create or replace package body dv_sr_lspv_det_pkg is

  -- Private type declarations
  GC_PACKAGE_NAME   constant varchar2(32)                       := $$plsql_unit;  
  GС_PRC_UPDATE_DET constant dv_sr_lspv_prc_t.process_name%type := 'UPDATE_DETAIL';
  GC_CHUNK_SIZE     constant int                                := 10000;
  --
  GC_ROW_STS_NEW    constant varchar2(1)                        := 'N';
  GC_ROW_STS_UPDATE constant varchar2(1)                        := 'U';
  GC_ROW_STS_DELETE constant varchar2(1)                        := 'D';
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
    p_process_id dv_sr_lspv_det_t.process_id%type,
    p_list_ids   in out nocopy sys.odciNumberList
  ) return int is
    l_result int;
  begin
    --
    select count(1)
    into   l_result
    from   err$_dv_sr_lspv_det_t e
    where  e.process_id = p_process_id
    and    e.fk_dv_sr_lspv in (
             select t.column_value
             from   table(p_list_ids) t
           );
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
   * @desc Процедура update_benefits_forwards - обработка новых движений по предоставлению вычетов
   */
  procedure insert_benefits_forwards(
    p_process_id dv_sr_lspv_det_t.process_id%type,
    p_list_ids   in out nocopy sys.odciNumberList
  ) is
    --
  begin
    --
    dbms_output.put_line('update_benefits_forwards: receive ' || p_list_ids.count || ' row(s)');
    --
    insert into dv_sr_lspv_det_t(
      fk_dv_sr_lspv,
      amount,
      addition_code,
      addition_id,
      process_id
    )
    select a.id,
           a.benefit_amount,
           coalesce(a.benefit_code, -1 * a.shifr_schet),
           coalesce(a.pt_rid, -1),
           p_process_id
    from   dv_sr_lspv_benefits_v a
    where  1=1
    --
    and    a.benefit_code_cnt = 1
    and    a.id in (
             select t.column_value
             from   table(p_list_ids) t
           )
    log errors into err$_dv_sr_lspv_det_t reject limit unlimited;
    --
    dbms_output.put_line('update_benefits_forwards: insert ' || sql%rowcount || ' row(s)');
    dbms_output.put_line('update_benefits_forwards: errors ' || get_errors_cnt(p_process_id, p_list_ids) || ' row(s)');
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_benefits_forwards');
      raise;
  end insert_benefits_forwards;
  
  /**
   * 
   */
  procedure update_benefits(
    p_process_id dv_sr_lspv_det_t.process_id%type,
    p_date       date
  ) is
    --
    C_BEN_FORWARD constant varchar2(1) := 'F';
    C_BEN_CORR    constant varchar2(1) := 'C';
    C_BEN_ZERO    constant varchar2(1) := 'Z';
    --
    l_list_ids   sys.odciNumberList;
    --
    cursor c_benefits(p_status varchar2, p_action varchar2) is
      select a.id
      from   dv_sr_lspv_acc_v a
      where  1=1
      and    a.status = p_status
      and    case
               when a.amount > 0 then C_BEN_FORWARD --предоставление
               when a.amount < 0 then C_BEN_CORR    --отменя или сторно или возврат
               else                   C_BEN_ZERO
             end = p_action
      and    a.status is not null
      and    a.charge_type = 'BENEFIT'
      and    a.date_op = p_date;
    --
    -- Операции предоставления вычетов
    --
    procedure update_benefits_(
      p_status varchar2,
      p_action varchar2
    ) is
    begin
      open c_benefits(p_status, p_action);
      loop
        fetch c_benefits
          bulk collect into l_list_ids
          limit GC_CHUNK_SIZE;
        exit when l_list_ids.count = 0;
        --
        if p_status = GC_ROW_STS_NEW and p_action = C_BEN_FORWARD then
          insert_benefits_forwards(
            p_process_id => p_process_id,
            p_list_ids   => l_list_ids
          );
        end if;
      end loop;
    end update_benefits_;
    --
  begin
    --новые движения предоставления вычетов
    update_benefits_(GC_ROW_STS_NEW, C_BEN_FORWARD);
    --новые движения предоставления вычетов
    update_benefits_(GC_ROW_STS_NEW, C_BEN_CORR);
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
    cursor c_dv_dates is
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
      from   dv_sr_lspv_acc_v a
      where  a.status is not null
      group by a.date_op
      order by a.date_op;
    --
    --Сброс статусов 
    -- 
    procedure reset_statuses_ is
    begin
      --...не обрабатываемых операций (не возвращаются вьюхой dv_sr_lspv_acc_v)
      update (
               select d.status
               from   dv_sr_lspv d
               where  d.status is not null
               and    not exists (
                        select d.id, d.status
                        from   dv_sr_lspv_acc_v a
                        where  a.id = d.id
                      )
             ) u
      set    u.status = null;
      --... и уже обработанных
      update (select d.status
              from   dv_sr_lspv d
              where  1=1
              and    d.id in (
                       select dt.fk_dv_sr_lspv
                       from   dv_sr_lspv_det_t dt
                       where  dt.process_id = p_process_id
                     ) 
             ) u
      set    u.status = null;
    end reset_statuses_;
    --
  begin
    --
    for d in c_dv_dates loop
      if d.benefit_exists = 'Y' then
        update_benefits(p_process_id, d.date_op);
      end if;
    end loop;
    --
    reset_statuses_;
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
