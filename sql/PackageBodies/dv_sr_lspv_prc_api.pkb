create or replace package body dv_sr_lspv_prc_api is

  -- Private type declarations
  
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
   * 
   */
  procedure create_process(
    p_process_row in out nocopy dv_sr_lspv_prc_t%rowtype
  ) is
    pragma autonomous_transaction;
  begin
    --
    insert into dv_sr_lspv_prc_t(
      process_name,
      start_date,
      end_date,
      state
    ) values (
      p_process_row.process_name,
      p_process_row.start_date,
      p_process_row.end_date  ,
      'CREATED'
    ) returning id, state into p_process_row.id, p_process_row.state;
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception;
      raise;
  end create_process;
  
  /**
   *
   */
  procedure set_process_state(
    p_process_row in out nocopy dv_sr_lspv_prc_t%rowtype
  ) is
    pragma autonomous_transaction;
  begin
    --
    update dv_sr_lspv_prc_t p
    set    p.state           = p_process_row.state          ,
           p.error_msg       = p_process_row.error_msg      ,
           p.last_udpated_at = systimestamp,
           p.deleted_rows    = nvl(p_process_row.deleted_rows, p.deleted_rows)   ,
           p.error_rows      = nvl(p_process_row.error_rows,   p.error_rows)
    where  p.id = p_process_row.id;
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception;
      raise;
  end set_process_state;
  
end dv_sr_lspv_prc_api;
/
