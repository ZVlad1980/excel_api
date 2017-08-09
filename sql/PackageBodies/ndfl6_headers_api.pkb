create or replace package body ndfl6_headers_api is
  --
  g_exception varchar2(32767);
  --
  procedure fix_exception(p_msg varchar2) is
  begin
    if g_exception is null then
      g_exception := p_msg || chr(10) || dbms_utility.format_error_stack ||
                     chr(10) || dbms_utility.format_error_backtrace ||
                     chr(10) || dbms_utility.format_call_stack;
    end if;
  end fix_exception;
  --
  function get_exception return varchar2 is
  begin
    return g_exception;
  end get_exception;
  --

  /**
  *
  */
  procedure create_header(
    p_header_row in out nocopy ndfl6_headers_t%rowtype
  ) is
  begin
    --
    begin
      select h.*
      into   p_header_row
      from   ndfl6_headers_t h
      where  1 = 1
      and    nvl(h.spr_id, -1) = nvl(p_header_row.spr_id, nvl(h.spr_id, -1))
      and    h.start_date = p_header_row.start_date
      and    h.end_date = p_header_row.end_date;
    exception
      when no_data_found then
        insert into ndfl6_headers_t(
          start_date, 
          end_date, 
          spr_id,
          state
        ) values (
          p_header_row.start_date, 
          p_header_row.end_date, 
          p_header_row.spr_id,
          C_HDR_ST_EMPTY
        )
        returning header_id into p_header_row.header_id;
    end;
    --
  exception
    when others then
      fix_exception('create_header');
      raise;
  end create_header;
  
  /**
  *
  */
  procedure create_header(
    x_header_id  out ndfl6_headers_t.header_id%type,
    p_start_date date,
    p_end_date   date,
    p_spr_id     number default null
  ) is
    l_header_row ndfl6_headers_t%rowtype;
  begin
    l_header_row.start_date := p_start_date;
    l_header_row.end_date   := p_end_date ;
    l_header_row.spr_id     := p_spr_id   ;
    --
    create_header(l_header_row);
    --
    commit;
    --
    if nvl(l_header_row.state, 'NULL') <> C_HDR_ST_SUCCESS then
      fill_lines(
        p_header_row => l_header_row
      );
      --
      commit;
      --
      set_state(p_header_id => l_header_row.header_id, p_state => C_HDR_ST_SUCCESS);
      --
    end if;
    --
    x_header_id := l_header_row.header_id;
    --
  exception
    when others then
      rollback;  
      fix_exception('create_header(' ||
        'p_start_date = ' || p_start_date || ', ' ||
        'p_end_date   = ' || p_end_date || ', ' ||
        'p_spr_id     = ' || p_spr_id || ')'
      );
      raise;
  end create_header;
  
  /**
  *
  */
  procedure set_state(
    p_header_id number,
    p_state     varchar2
  ) is
    pragma autonomous_transaction;
  begin
    --
    update ndfl6_headers_t h
    set    h.state = p_state,
           h.last_updated_at = systimestamp,
           h.last_update_by = user
    where  h.header_id = p_header_id;
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception('set_state. ID = ' || p_header_id);
      raise;
  end set_state;

  /**
  *
  */
  function get_state(
    p_header_id number
  ) return ndfl6_headers_t.state%type is
    l_result ndfl6_headers_t.state%type;
  begin
    --
    select h.state
    into   l_result
    from   ndfl6_headers_t h
    where  h.header_id = p_header_id;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception('get_state. ID = ' || p_header_id);
      raise;
  end get_state;

  /**
  *
  */
  function lock_hdr(
    p_header_id number,
    p_exclusive boolean default false
  ) return boolean is
    l_result boolean := true;
  begin
    --по мере необходимости!
    return l_result;
  exception
    when others then
      fix_exception('lock_hdr. ID = ' || p_header_id || case when
                    p_exclusive then ', exclusive' end);
      raise;
  end lock_hdr;

  /**
  *
  */
  procedure unlock_hdr(
    p_header_id number
  ) is
  begin
    --по мере необходимости!
    null;
  exception
    when others then
      fix_exception('unlock_hdr. ID = ' || p_header_id);
      raise;
  end unlock_hdr;

  /**
  *
  */
  procedure purge_lines(
    p_header_id number
  ) is
  begin
    --
    delete from ndfl6_lines_t lin
    where  lin.header_id = p_header_id;
    --
    set_state(p_header_id => p_header_id, p_state => C_HDR_ST_EMPTY);
    --
  exception
    when others then
      fix_exception('purge_lines. ID = ' || p_header_id);
      raise;
  end purge_lines;

  /**
  *
  */
  procedure fill_lines(
    p_header_row in out nocopy ndfl6_headers_t%rowtype
  ) is
  begin
    --
    ndfl_report_api.set_period(
      p_start_date => p_header_row.start_date,
      p_end_date   => p_header_row.end_date
    );
    --
    set_state(p_header_id => p_header_row.header_id, p_state => C_HDR_ST_PROCESS);
    --
    insert into ndfl6_lines_t(
      header_id,
      tax_rate,
      nom_vkl,
      nom_ips,
      gf_person,
      det_charge_type,
      pen_scheme,
      revenue_amount,
      benefit,
      tax_retained,
      tax_calc,
      tax_returned_prev,
      tax_returned_curr,
      tax_corr_83,
      rev_source_q1,
      rev_source_q2,
      rev_source_q3,
      rev_source_q4,
      rev_source,
      rev_corr_prev,
      rev_corr_q1,
      rev_corr_q2,
      rev_corr_q3,
      rev_corr_q4
    ) with lines as (
        select /*+ materialize */lin.tax_rate,
               lin.nom_vkl,
               lin.nom_ips,
               lin.gf_person,
               lin.det_charge_type,
               lin.pen_scheme,
               lin.revenue_amount,
               lin.benefit,
               lin.tax_retained,
               lin.tax_calc,
               lin.tax_returned_prev,
               lin.tax_returned_curr,
               lin.tax_corr_83,
               lin.rev_source_q1,
               lin.rev_source_q2,
               lin.rev_source_q3,
               lin.rev_source_q4,
               lin.rev_source,
               lin.rev_corr_prev,
               lin.rev_corr_q1,
               lin.rev_corr_q2,
               lin.rev_corr_q3,
               lin.rev_corr_q4
        from   ndfl6_lines_v lin
      ) select p_header_row.header_id, lines.* from lines;
    --











  exception
    when others then
      fix_exception('fill_lines. ID = ' || p_header_row.header_id);
      set_state(p_header_id => p_header_row.header_id, p_state => C_HDR_ST_ERROR);
      raise;
  end fill_lines;
  --
end ndfl6_headers_api;
/
