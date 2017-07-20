create or replace package ndfl_report_api is

  -- Author  : V.ZHURAVOV
  -- Created : 03.07.2017 12:34:48
  -- Purpose : 
  
  function get_start_date return date deterministic;
  function get_end_date   return date deterministic;
  
  procedure set_period(
    p_start_date date,
    p_end_date   date default null
  );
  
  /**
   * Процедура get_report возвращает курсор с данными отчета
   * 
   * @param x_result      - курсор с данными
   * @param x_err_msg     - сообщение об ошибке
   * @param p_report_code - код отчета:
   *                            detail_report     - ежемесячная расшифровка 6НДФЛ
   *                            detail_report_2   - ежемесячная расшифровка 6НДФЛ разрезе типов дохода и ставок
   *                            correcting_report - 
   *                            error_report      - отчет об ошибках коррекций
   * @param p_from_date   - дата начала выборки в формате YYYYMMDD
   * @param p_end_date    - дата окончания выборки в формате YYYYMMDD
   *
   */
  procedure get_report(
    x_result    out sys_refcursor, 
    x_err_msg   out varchar2,
    p_report_code   varchar2,
    p_from_date     varchar2,
    p_end_date      varchar2
  );
  
end ndfl_report_api;
/
