create or replace package gateway_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 25.08.2017 12:18:49
  -- Purpose : API Gateway
  
  /**
   * Процедура synhr_dv_sr_lspv_docs запускает синхронизацию таблицу dv_sr_lspv_docs_t
   *
   * @param p_year        - год формирования данных
   *
   */
  procedure synhr_dv_sr_lspv_docs(
    x_err_msg    out varchar2,
    p_year            number
  );
  
  /**
   * Процедура update_gf_persons обновляет не актуальные CONTRAGENTS.ID
   */
  procedure update_gf_persons(
    x_err_msg    out varchar2,
    p_year            number
  );
  
  /**
   * Процедура update_dv_sr_lspv# запускает обновление таблицы dv_sr_lspv#
   *
   * @param p_year        - год формирования данных
   *
   */
  procedure update_dv_sr_lspv#(
    x_err_msg    out varchar2,
    p_year            number
  );
  
  /**
   * Процедура get_report возвращает курсор с данными отчета
   * 
   * @param x_result      - курсор с данными
   * @param x_err_msg     - сообщение об ошибке
   * @param p_report_code - код отчета
   * @param p_year        - год формирования отчета
   * @param p_month       - месяц формирования отчета
   * @param p_report_date - дата, на которую формируется отчет
   *
   */
  procedure get_report(
    x_result      out sys_refcursor, 
    x_err_msg     out varchar2,
    p_report_code     varchar2,
    p_year            number,
    p_month           number,
    p_report_date     varchar2
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
  
  /**
   * Процедура запуска формирования таблицы расхождения налогов
   */
  procedure build_tax_diff_det_table(
    x_err_msg       out varchar2,
    p_year              number,
    p_month             number
  );
  
  /**
   * Процедура загрузки данных в таблицу f_ndfl_load_nalplat
   */
  procedure fill_ndfl_load_nalplat(
    x_err_msg       out varchar2,
    p_code_na           varchar2,    
    p_year              number,
    p_month             number,
    p_actual_date       varchar2
  );
  
  /**
   * Процедура загрузки данных в F2NDFL_LOAD_
   */
  procedure f2_ndfl_api(
    x_err_msg       out varchar2,
    p_action_code       varchar2,
    p_code_na           varchar2,    
    p_year              number,
    p_actual_date       varchar2
  );
  
  /**
   * Сброс ранее установленных параметров
   */
  procedure purge_parameters;
  
  /**
   * Временное решение для передачи произвольного набора параметров
   */
  procedure set_parameter(
    p_name  varchar2,
    p_value varchar2
  );
  
  /**
   * Временное решение для передачи произвольного набора параметров
   */
  function get_parameter(
    p_name  varchar2
  ) return varchar2 deterministic;
  
  /**
   * Временное решение для передачи произвольного набора параметров
   */
  function get_parameter_num(
    p_name  varchar2
  ) return number deterministic;
  
  /** JSON не поддержвается в 12.1.0.1!!! Нужна своя реализация!
   * Процедура request - единая точка входа
   *
   * @param x_result_set - результирующий набор данных (курсор)
   * @param x_status     - статус завершения: (S)uccess/(E)rror/(M)an
   * @param x_err_code   - код ошибки (аналог HTTP status)
   * @param x_err_msg    - сообщение об ошибке
   * @param p_path       - путь запрашиваемого сервиса (пока только одноуровневый)
   * @param p_req_json   - параметры запроса в формате JSON
   *
   /
  procedure request(
    x_result_set out sys_refcursor,
    x_status     out varchar2,
    x_err_msg    out varchar2,
    p_path       in  varchar2,
    p_req_json   in  varchar2
  );
  */
end gateway_pkg;
/
