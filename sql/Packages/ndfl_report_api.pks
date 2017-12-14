create or replace package ndfl_report_api is

  -- Author  : V.ZHURAVOV
  -- Created : 03.07.2017 12:34:48
  -- Purpose : 
  
  /**
   * Функция get_report возвращает курсор с данными отчета
   * 
   * @param p_report_code - код отчета
   * @param p_end_date    - конечная дата отчета
   * @param p_report_date - дата, на которую формируется отчет
   *
   */
  function get_report(
    p_report_code   varchar2,
    p_end_date      date,
    p_report_date   date default null
  ) return sys_refcursor;
  
end ndfl_report_api;
/
