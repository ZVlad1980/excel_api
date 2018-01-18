create or replace package f_ndfl_load_spisrab_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.07.2017 11:18:03
  -- Purpose : 
  
  procedure load_from_tmp(
    p_load_date date
  );
  
  /**
   * Процедура идентификации сотрудников фонда по базе участников фонда
   */
  procedure identify_employees(
    p_year       integer
  );

end f_ndfl_load_spisrab_api;
/
