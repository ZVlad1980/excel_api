create or replace package body dv_sr_lspv#_api is
  -- Private type declarations
  GC_PACKAGE_NAME   constant varchar2(32)                       := $$plsql_unit;  
  GС_PRC_NAME       constant dv_sr_lspv_prc_t.process_name%type := 'UPDATE_DV_SR_LSPV#';
  --
  --G_LEGACY       varchar2(1);
  
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
  
  /*function legacy return varchar2 deterministic is begin return nvl(G_LEGACY, 'N'); end legacy;
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
--*/
  /**
   * Процедура create_process создает новый процесс в таблице dv_sr_lspv_prc_t
   */
  function create_process(
    p_year_from    int,
    p_year_to      int
  ) return dv_sr_lspv_prc_t.id%type is
    --
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
    --
    l_process_row.process_name := GС_PRC_NAME;
    l_process_row.start_date   := to_date(p_year_from || '0101', 'yyyymmdd');
    l_process_row.end_date     := to_date(p_year_to   || '1231', 'yyyymmdd');
    --
    dv_sr_lspv_prc_api.create_process(
      p_process_row => l_process_row
    );
    --
    return l_process_row.id;
    --
  exception
    when others then
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
      fix_exception($$plsql_line, 'set_process_state(' || p_process_id || ',' || p_state || ')');
      raise;
  end set_process_state;
  
  /**
   */
  procedure update_dv_sr_lspv#(
    p_process_id      dv_sr_lspv_prc_t.id%type,
    p_year_from    int,
    p_year_to      int
  ) is
  begin
    --
    merge into dv_sr_lspv# d
    using (select d.nom_vkl,
                  d.nom_ips,
                  d.shifr_schet,
                  d.sub_shifr_schet,
                  d.date_op,
                  d.amount,
                  d.ssylka_doc,
                  d.service_doc,
                  case d.det_charge_type
                    when 'RITUAL' then
                      ( select rp.fk_contragent gf_person
                        from   sp_fiz_litz_lspv_v sfl,
                               sp_ritual_pos      rp
                        where  1=1
                        and    rp.ssylka = sfl.ssylka
                        and    sfl.nom_ips = d.nom_ips
                        and    sfl.nom_vkl = d.nom_vkl
                      )
                  end gf_person,
                  case 
                    when d.service_doc < 0 
                        or 
                        (d.service_doc > 0 and
                          exists(
                            select 1 
                            from   dv_sr_lspv_v dd 
                            where  dd.nom_vkl = d.nom_vkl
                            and    dd.nom_ips = d.nom_ips
                            and    dd.shifr_schet = d.shifr_schet
                            and    dd.sub_shifr_schet = d.sub_shifr_schet
                            and    dd.service_doc = d.ssylka_doc
                            and    dd.data_op < d.date_op 
                          )
                        )                  then 'N'
                    when d.service_doc > 0 then 'Y' 
                  end is_parent
           from   dv_sr_lspv_acc_v d
           where  d.year_op between p_year_from and p_year_to
           and    (d.service_doc <> 0 or d.charge_type = 'BENEFIT' or d.det_charge_type = 'RITUAL')
          ) u
    on    (d.nom_vkl         = u.nom_vkl         and
           d.nom_ips         = u.nom_ips         and
           d.date_op         = u.date_op         and
           d.shifr_schet     = u.shifr_schet     and
           d.sub_shifr_schet = u.sub_shifr_schet and
           d.ssylka_doc      = u.ssylka_doc      and
           d.is_parent       = u.is_parent
          )
    when not matched then
      insert (
        nom_vkl,
        nom_ips,
        shifr_schet,
        sub_shifr_schet,
        date_op,
        amount,
        ssylka_doc,
        service_doc,
        gf_person,
        is_parent,
        process_id
      ) values (
        u.nom_vkl,
        u.nom_ips,
        u.shifr_schet,
        u.sub_shifr_schet,
        u.date_op,
        u.amount,
        u.ssylka_doc,
        u.service_doc,
        u.gf_person,
        u.is_parent,
        p_process_id
      );
    --
    -- Обновление статуса записей
    --
    update (select d.is_deleted,
                   d.status
            from   dv_sr_lspv# d
            where  extract(year from d.date_op) between p_year_from and p_year_to
            and    case --проверка существования записи в движении
                     when exists(
                           select 1
                           from   dv_sr_lspv_v dd
                           where  1 = 1
                           and    dd.nom_vkl = d.nom_vkl
                           and    dd.nom_ips = d.nom_ips
                           and    dd.data_op = d.date_op
                           and    dd.shifr_schet = d.shifr_schet
                           and    dd.sub_shifr_schet = d.sub_shifr_schet
                           and    dd.ssylka_doc = d.ssylka_doc
                         ) then 'N'
                      else 'Y'
                    end <> nvl(d.is_deleted, 'N') --если запись помечена как удаленная, но есть в движении или записи нет в движении и она не помечена как удаленная
                    
           ) u
    set    u.is_deleted = case when u.is_deleted is null then 'Y' else null end; --инверсия флага удаления
    --
    update dv_sr_lspv_det_t dt
    set    dt.is_deleted = 'Y'
    where  dt.fk_dv_sr_lspv in (
             select d.id
             from   dv_sr_lspv# d
             where  d.is_deleted = 'Y'
           );
    --
  exception
    when others then
      fix_exception($$plsql_line, 'update_dv_sr_lspv#(' || p_process_id || ', ' || p_year_from || ', ' || p_year_to || ')');
      raise;
  end update_dv_sr_lspv#;
  
  /**
   */
  procedure update_dv_sr_lspv#(
    p_year_from  int,
    p_year_to    int
  ) is
    l_process_id dv_sr_lspv_det_t.process_id%type;
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_process_id := create_process(p_year_from, p_year_to);
    --
    update_dv_sr_lspv#(l_process_id, p_year_from, p_year_to);
    --
    commit;
    --
    set_process_state(
      l_process_id, 
      'SUCCESS'
    );
    --
  exception
    when others then
      rollback;
      fix_exception($$PLSQL_LINE, 'update_dv_sr_lspv#');
      if l_process_id is not null then
        set_process_state(
          l_process_id, 
          'ERROR', 
          p_error_msg => sqlerrm
        );
      end if;
      raise;
  end update_dv_sr_lspv#;
  --
  
  
end dv_sr_lspv#_api;
/
