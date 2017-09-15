create or replace package zaprvkl_api is

  -- Author  : V.ZHURAVOV
  -- Created : 21.06.2017 16:41:41
  -- Purpose : API построения обратной базы участника
  
  -- Статусы результирующей строки
  --(F)ull identification, (P)art identification, (N)on identification, (D)ouble source, (M)ultiple identification, 'E'rror
  G_LN_STS_CREATED      constant varchar2(1) := 'C';
  G_LN_STS_IDENTIFICATE constant varchar2(1) := 'I';
  G_LN_STS_FULL_IDENT   constant varchar2(1) := 'F';
  G_LN_STS_PART_IDENT   constant varchar2(1) := 'P';
  G_LN_STS_NONE_IDENT   constant varchar2(1) := 'N';
  G_LN_STS_DOUBLE_IDENT constant varchar2(1) := 'D';
  G_LN_STS_MULTY_IDENT  constant varchar2(1) := 'M';
  G_LN_STS_ERROR_IDENT  constant varchar2(1) := 'E';
  
  G_FMT_DATE constant varchar2(20) := 'dd.mm.yyyy';
  
  /**
   * Функции обвертки для глобальных констант
   */
  function get_ln_sts_created      return varchar2 deterministic;
  function get_ln_sts_full_ident   return varchar2 deterministic;
  function get_ln_sts_part_ident   return varchar2 deterministic;
  function get_ln_sts_none_ident   return varchar2 deterministic;
  function get_ln_sts_double_ident return varchar2 deterministic;
  function get_ln_sts_multy_ident  return varchar2 deterministic;
  function get_ln_sts_error_ident  return varchar2 deterministic;
  --
  function get_fmt_date            return varchar2 deterministic;
  
  
  /**
   * Функция create_header - создает заголовок обработки
   *
   * @param x_err_msg     - сообщение об ошибке (если есть)
   * @param p_investor_id - номер вкладчика (см. fnd.sp_fiz_lits.nom_vkl).
   *                          Если не задан - не будет выполнятся анализ принадлежности участника к вкладчику
   *
   */
  function create_header(
    x_err_msg       out varchar2,
    p_investor_id   fnd.sp_ur_lits.ssylka%type default null
  ) return zaprvkl_headers_t.id%type;
  
  /**
   * Процедура add_line_tmp добавляет персональные данные в tmp таблицу
   *  Добавление производится через глобальный буфер g_lines_tmp,
   *  Сброс через кажду 1000 строк (см. процедуру purge_lines_tmp)
   *  Процедура вызывается из Excel
   *
   * @param p_last_name   - фамилия
   * @param p_first_name  - имя
   * @param p_second_name - отчество
   * @param p_birth_date  - дата рождения в формате ДД.ММ.ГГГГ
   * @param p_employee_id - табельный номер
   * @param p_snils       - СНИЛС
   * @param p_inn         - ИНН
   *
   */
  procedure add_line_tmp(
    p_excel_id     number,
    p_last_name    varchar2,
    p_first_name   varchar2,
    p_second_name  varchar2,
    p_birth_date   varchar2,
    p_employee_id  varchar2,
    p_snils        varchar2,
    p_inn          varchar2
  );
  
  /**
   * Процедура start_process запускает процесс обработки данных
   *   Обработка в зависимости от текущего статуса заголовка
   * 
   * @param x_err_msg    - сообщение обо ошибке (функция возвратила -1)
   * @param p_header_id  - ID заголовка процесса
   * 
   */
  procedure start_process(
    x_err_msg     out varchar2,
    p_header_id   zaprvkl_headers_t.id%type
  );
  
  /**
   * Процедура get_results - возвращает набор рекордсетов с результатами обработки
   *
   * @param x_result      - результирующий курсор
   * @param x_err_msg     - сообщение об ошибке
   * @param p_header_id   - ID заголовка обработки
   * @param p_result_code - код запрашиваемых данных:
   *                          participants            - участники
   *                          not_found               - неучастники
   *                          possible_participants   - возможные участники
   *                          errors                  - ошибки
   *
   */
  procedure get_results(
    x_result      out sys_refcursor,
    x_err_msg     out varchar2,
    p_header_id   integer,
    p_result_name varchar2
  );
  
  
  /**
   * Функция edit_distance выполняет сравнение двух имен по рассоянию Дамерау–Левенштейна
   */
  function edit_distance
  (
    plname in varchar2,
    prname in varchar2
  ) return number;

  /**
   * Функция edit_distance выполняет сравнение двух дат по рассоянию Дамерау–Левенштейна
   *   Для сравнения выполняет преобразование даты в строку в формат yyyymmdd
   */
  function edit_distance
  (
    plname in date,
    prname in date
  ) return number;
  
  /**
   * Вспомогательные функции
   */
  
  /**
   * Функция prepare_str$ подготовки строки имени (ФИО) для обработки
   *  Преобразования:
   *    - удаление начальных, хвостовых и двойных пробелов пробелов
   *    - верхний регистр
   *    - трансляция латиницы и 0
   *    - удаление любых символов кроме кириллицы
   */
   function prepare_str$(p_str varchar2) return varchar2;
  
  /**
   * Функция to_date$ конвертирования строки в дату (возвращает null в случае ошибки)
   *  Дата ожидается в формате G_FMT_DATE
   */
   function to_date$(p_date_str varchar2) return date;
   
end zaprvkl_api;
/
