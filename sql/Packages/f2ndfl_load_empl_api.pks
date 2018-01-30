create or replace package f2ndfl_load_empl_api is

  -- Author  : V.ZHURAVOV
  -- Created : 29.01.2018 13:10:33
  -- Purpose : API загрузки данных по сотрудникам
  
  /**
   * Процедура загрузки XML данных
   */
  procedure load_xml(
    p_code_na    int,
    p_year       int,
    p_xml        xmltype
  );
  
  /**
   * Процедура загрузки данных в таблицы load
   */
  procedure merge_load_xml(
    p_code_na    int,
    p_year       int
  );

end f2ndfl_load_empl_api;
/
