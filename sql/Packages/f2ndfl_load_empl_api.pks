create or replace package f2ndfl_load_empl_api is

  -- Author  : V.ZHURAVOV
  -- Created : 29.01.2018 13:10:33
  -- Purpose : API загрузки данных по сотрудникам
  
  --
  e_no_xml_found exception;
  
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
   *
   * Если справки нет - поднимает e_no_xml_found, см. выше
   *
   */
  procedure merge_load_xml(
    p_code_na    int,
    p_year       int,
    p_commit     boolean default false
  );

end f2ndfl_load_empl_api;
/
