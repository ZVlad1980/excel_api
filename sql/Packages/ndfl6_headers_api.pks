create or replace package ndfl6_headers_api is

  -- Author  : V.ZHURAVOV
  -- Created : 21.07.2017 12:53:00
  -- Purpose : API подготовки данных для справок 6НДФЛ
  
  C_HDR_ST_EMPTY   constant varchar2(20) := 'EMPTY';
  C_HDR_ST_PROCESS constant varchar2(20) := 'PROCESS';
  C_HDR_ST_SUCCESS constant varchar2(20) := 'SUCCESS';
  C_HDR_ST_ERROR   constant varchar2(20) := 'ERROR';  
    
  procedure create_header(
    p_header_row in out nocopy ndfl6_headers_t%rowtype
  );  
    
  procedure create_header(
    x_header_id  out ndfl6_headers_t.header_id%type,
    p_start_date date,
    p_end_date   date,
    p_spr_id     number default null
  );
  
  procedure set_state(
    p_header_id number,
    p_state     varchar2
  );
  
  function get_state(
    p_header_id number
  ) return ndfl6_headers_t.state%type;
  
  function lock_hdr(
    p_header_id number,
    p_exclusive boolean default false
  ) return boolean;
  
  procedure unlock_hdr(
    p_header_id number
  );
  
  procedure purge_lines(
    p_header_id number
  );
  
  procedure fill_lines(
    p_header_row in out nocopy ndfl6_headers_t%rowtype
  );
  
end ndfl6_headers_api;
/
