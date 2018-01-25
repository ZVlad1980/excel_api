create or replace package f2ndfl_load_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.01.2018 16:27:46
  -- Purpose : 
  
  /**
   *
   */
  procedure create_2ndfl_refs(
    p_code_na int,
    p_year    int
  );

end f2ndfl_load_api;
/
