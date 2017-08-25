create or replace package f_ndfl_load_spisrab_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.07.2017 11:18:03
  -- Purpose : 
  
  procedure load_from_tmp(
    p_load_date date
  );
  

end f_ndfl_load_spisrab_api;
/
