create or replace package gateway_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 25.08.2017 12:18:49
  -- Purpose : API Gateway
  
  /**
   * Процедура запускает синхронизацию таблицу dv_sr_lspv_docs_t
   */
  procedure synhr_dv_sr_lspv_docs(
    x_err_msg    out varchar2,
    p_end_date   in  varchar2
  );
  
  /**
   * Процедура get_report возвращает курсор с данными отчета
   * 
   * @param x_result      - курсор с данными
   * @param x_err_msg     - сообщение об ошибке
   * @param p_report_code - код отчета
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
   * Процедура load_employees запускает загрузки сотрудников в f_ndfl_load_spisrab
   *   (из tmp таблицы, см. процедуру add_line)
   */
  procedure load_employees(
    x_err_msg   out varchar2,
    p_load_date varchar2
  );
  
  /**
   * Процедура load_employees добавляет персональные данные в tmp таблицу
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
  procedure load_employees(
    p_last_name    varchar2,
    p_first_name   varchar2,
    p_second_name  varchar2,
    p_birth_date   varchar2,
    p_snils        varchar2,
    p_inn          varchar2
  );
  
  /**
   * Процедура create_ndfl2 запускает создание справки 2НДФЛ
   */
  procedure create_ndfl2(
    x_err_msg       out varchar2,
    p_code_na       in  varchar2,
    p_year          in  varchar2,
    p_contragent_id in  varchar2
  );
  
end gateway_pkg;
/
