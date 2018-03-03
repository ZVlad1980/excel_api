create or replace package dv_sr_lspv#_api is

  -- Author  : V.ZHURAVOV
  -- Created : 02.03.2018 14:01:17
  -- Purpose : 
  
  procedure update_dv_sr_lspv#(
    p_year_from  int,
    p_year_to    int
  );

end dv_sr_lspv#_api;
/
