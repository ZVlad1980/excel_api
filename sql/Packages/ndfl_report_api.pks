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
   *                            ndfl6_part1       - обобщенные показатели раздела 1 формы 6НДФЛ (поля 060, 070, 080, 090)
   *                            ndfl6_part1_rates - обобщенные показатели раздела 1 формы 6НДФЛ по ставкам (поля 010, 020, 030, 040)
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
  
  /**
   * Процедура add_line_tmp добавляет персональные данные в tmp таблицу
   *   Вызывает API 
   *
   * @param p_last_name   - фамилия
   * @param p_first_name  - имя
   * @param p_second_name - отчество
   * @param p_birth_date  - дата рождения в формате ДД.ММ.ГГГГ
   * @param p_snils       - СНИЛС
   * @param p_inn         - ИНН
   *
   */
  procedure add_line(
    p_last_name    varchar2,
    p_first_name   varchar2,
    p_second_name  varchar2,
    p_birth_date   varchar2,
    p_snils        varchar2,
    p_inn          varchar2
  );
  
  /**
   *
   * Процедура load_employees запускает загрузку сотрудников из tmp таблицы
   *  в f_ndfl_load_spisrab
   */
  procedure load_employees(
    x_err_msg   out varchar2,
    p_load_date date
  );
  
end ndfl_report_api;
/
