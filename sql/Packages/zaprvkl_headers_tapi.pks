create or replace package zaprvkl_headers_tapi is

  -- Author  : V.ZHURAVOV
  -- Created : 21.06.2017 17:31:46
  -- Purpose : Table API for table zaprvkl_headers_t
  
  --Статусы процесса обработки 
  G_HDR_STS_CREATED constant varchar2(1) := 'C'; --Created
  G_HDR_STS_READY   constant varchar2(1) := 'R'; --Ready
  G_HDR_STS_PROCESS constant varchar2(1) := 'P'; --Process
  G_HDR_STS_SUCCESS constant varchar2(1) := 'S'; --Success
  G_HDR_STS_ERROR   constant varchar2(1) := 'E'; --Error
  
  /**
   * Функции обвертки для глобальных констант
   */
  function get_hdr_sts_created return varchar2 deterministic;
  function get_hdr_sts_process return varchar2 deterministic;
  function get_hdr_sts_success return varchar2 deterministic;
  function get_hdr_sts_error   return varchar2 deterministic;
  
  -- Public type declarations
  procedure ins(p_row in out nocopy zaprvkl_headers_t%rowtype);
  
  procedure upd(p_row in out nocopy zaprvkl_headers_t%rowtype);
  
  procedure slct(p_row in out nocopy zaprvkl_headers_t%rowtype);
  
end zaprvkl_headers_tapi;
/
