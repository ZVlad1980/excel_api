create or replace package body zaprvkl_headers_tapi is

  procedure ins(p_row in out nocopy zaprvkl_headers_t%rowtype) is
  begin
    insert into zaprvkl_headers_t(
      investor_id,
      status
    ) values (
      p_row.investor_id,
      p_row.status
    ) returning id into p_row.id;
  end ins;
  
  procedure upd(p_row in out nocopy zaprvkl_headers_t%rowtype) is
  begin
    --
    update zaprvkl_headers_t h
    set    h.status = p_row.status,
           h.err_msg = p_row.err_msg,
           h.last_update_at = systimestamp
    where  h.id = p_row.id;
    --
  end upd;
  
  procedure slct(p_row in out nocopy zaprvkl_headers_t%rowtype) is
  begin
    select *
    into   p_row
    from   zaprvkl_headers_t h
    where  h.id = p_row.id;
  exception
    when no_data_found then
      null;
  end slct;
  
  /**
   * Функции обвертки для глобальных констант
   */
  function get_hdr_sts_created return varchar2 is begin return G_HDR_STS_CREATED; end get_hdr_sts_created;
  function get_hdr_sts_process return varchar2 is begin return G_HDR_STS_PROCESS; end get_hdr_sts_process;
  function get_hdr_sts_success return varchar2 is begin return G_HDR_STS_SUCCESS; end get_hdr_sts_success;
  function get_hdr_sts_error   return varchar2 is begin return G_HDR_STS_ERROR  ; end get_hdr_sts_error  ;
  
end zaprvkl_headers_tapi;
/
