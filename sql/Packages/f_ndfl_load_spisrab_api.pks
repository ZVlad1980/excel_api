create or replace package f_ndfl_load_spisrab_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.07.2017 11:18:03
  -- Purpose : 
  
  procedure load_from_tmp(
    p_load_date date,
    p_header_id ndfl6_headers_t.header_id%type
  );
  

end f_ndfl_load_spisrab_api;
/
