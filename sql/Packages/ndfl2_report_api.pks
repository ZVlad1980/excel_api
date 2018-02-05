create or replace package ndfl2_report_api is

  -- Author  : V.ZHURAVOV
  -- Created : 24.01.2018 14:47:58
  -- Purpose : 
  
  /**
   * Функция get_report возвращает курсор с данными отчета
   * 
   * @param p_report_code - код отчета
   * @param p_year        - год, за который строится отчет
   * @param p_report_date - дата, на которую формируется отчет
   *
   */
  function get_report(
    p_report_code   varchar2,
    p_year          int,
    p_report_date   date default null
  ) return sys_refcursor;

end ndfl2_report_api;
/
