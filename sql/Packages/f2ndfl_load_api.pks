create or replace package f2ndfl_load_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.01.2018 16:27:46
  -- Purpose : 
  
  /**
   * Процедура purge_loads - очистка таблиц f2ndfl_load_ и f2ndfl_arh_nomspr
   */
  procedure purge_loads(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int
  );
  
  /**
   *
   */
  procedure create_2ndfl_refs(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int
  );

end f2ndfl_load_api;
/
