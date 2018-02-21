create or replace package f2ndfl_arh_spravki_api is

  -- Author  : V.ZHURAVOV
  -- Created : 02.11.2017 15:54:23
  -- Purpose : API формирование справок 2НДФЛ

  /**
   * Функция get_reference_last возвращает номер 2НДФЛ справки по году и контрагенту
   *
   * @param p_kod_na        - код НА
   * @param p_year          - год
   * @param p_contragent_id - ID контрагента
   *
   * @return - f2ndfl_arh_nomspr.nom_spr%type
   *
   */
  function get_reference_num(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_contragent_id  f2ndfl_arh_nomspr.fk_contragent%type
  ) return f2ndfl_arh_nomspr.nom_spr%type;
  
  /**
   * Функция get_reference_last_id возвращает ID справки по году и номеру
   *  Если справок несколько - возвращает ID последней корректировки
   *
   * @param p_code_na - код НА
   * @param p_year    - год
   * @param p_ref_num - номер справки 2НДФЛ
   *
   * @return - f2ndfl_arh_spravki.id%type
   *
   */
  function get_reference_last_id(
    p_code_na   f2ndfl_arh_spravki.kod_na%type,
    p_year      f2ndfl_arh_spravki.god%type,
    p_ref_num   f2ndfl_arh_spravki.nom_spr%type,
    p_load_exists varchar2 default 'Y'
  ) return f2ndfl_arh_spravki.id%type;
  
  /**
   * Процедура create_reference_corr созданет справку 2НДФЛ
   *   Если справка уже есть в f2ndfl_arh_spravki - создание корректирующей справки
   *   Если справки еще нет - создание новой справки, с 0 коррекцией
   *
   * @param p_code_na       - код налогоплательщика (НПФ=1)
   * @param p_year          - год, за который надо сформировать корректировку
   * @p_actual_date         - дата, на которую формируются данные (учет корректировок!)
   * @param p_contragent_id - ID контрагента, по которому формируется справка (CDM.CONTRAGENTS.ID)
   * @param p_ref_num       - номер справки (необязательный)
   *
   */
  procedure create_reference(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_actual_date    date,
    p_contragent_id  f2ndfl_arh_spravki.ui_person%type,
    p_ref_num        f2ndfl_arh_spravki.nom_spr%type default null
  );
  
  /**
   * Процедура create_reference_corr создания корректирующей справки 2НДФЛ
   *
   * @param p_code_na       - код налогоплательщика (НПФ=1)
   * @param p_year          - год, за который надо сформировать корректировку
   * @param p_contragent_id - ID контрагента, по которому формируется справка (CDM.CONTRAGENTS.ID)
   *
   */
  procedure create_reference_corr(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_contragent_id  f2ndfl_arh_nomspr.fk_contragent%type,
    p_actual_date    date default sysdate
  );
  
  /**
   * Процедура recalc_reference - пересчет суммовых показателей справки
   *   По заданному контрагенту удаляются суммовые показатели (F2NDFL_LOAD_MES, F2NDFL_LOAD_VYCH, F2NDFL_LOAD_ITOGI, 
   *     F2NDFL_ARH_MES, F2NDFL_ARH_VYCH, F2NDFL_ARH_ITOGI) по всем типам дохода, кроме ЗП (9),
   *     и выполняется повторный расчет
   *
   * @param p_ref_id       - F2NDFL_ARH_SPRAVKI.ID
   *
   */
  procedure recalc_reference(
    p_ref_id        f2ndfl_arh_spravki.id%type,
    p_actual_date   date,
    p_commit        boolean default false
  );

  /**
   * Процедура delete_reference удаляет данные справки из таблиц F2NDFL_, кроме F2NDFL_ARH_NOMSPR
   *  Если данные справки включены в XML для ГНИ - удаление отменяется.
   * Внимание: для исходных справок (корр.номер=0) данные по сотрудникам фонда не удаляются, также не удаляются данные по 9 типу дохода (зп)
   *   Т.е. если справка относится к сотруднику фонда, не являющемуся контрагентом - она не будет удалена, 
   *        если сотрудник является контрагентом - будут удалены данные по всем типам дохода, кроме 9 (зп)
   *
   * @param p_ref_id      - ID удаляемой справки
   * @param p_commit      - флаг фиксации транзакции
   * @param p_only_amount - флаг удаления только суммовых показателей
   *
   */
  procedure delete_reference(
    p_ref_id        f2ndfl_arh_spravki.id%type,
    p_commit        boolean default false,
    p_only_amount   boolean default false
  );
  
  /*
   * Синхронизация таблиц load с arh (за 16 год - рассинхронизированы!)
   *  
   * @param p_code_na  - код НА
   * @param p_year     - год
   * @param p_ref_id   - optional, f2ndfl_arh_spravki.id
   *
   */
  procedure synhonize_load(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_ref_id         f2ndfl_arh_spravki.id%type default null
  );
  
  /**
   * Функция validate_pers_info - проверяет перс.данные
   *
   * @param p_code_na       - 
   * @param p_year          -
   * @param p_fk_contragent - 
   * @param p_last_name     - 
   * @param p_first_name    - 
   * @param p_middle_name   - 
   * @param p_birth_date    - 
   * @param p_doc_code      - код УЛ
   * @param p_doc_num       - серия и номер УЛ
   * @param p_inn           - ИНН
   * @param p_citizenship   - гражданство (код страны)
   * @param p_resident      - резидент (1/2 - да/нет)
   * @param p_inn_dbl       - количество записей с одинаковым ИНН  count(distinct case when s.inn_fl is not null then s.ui_person end) over(partition by s.kod_na, s.god, s.inn_fl)
   * @param p_fiod_dbl      - количество записей с одинаковым ФИОД count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.ser_nom_doc)
   * @param p_doc_dbl       - количество записей с одинаковым УЛ   count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.familiya, s.imya, s.otchestvo, s.data_rozhd)
   * @param p_invalid_doc   - признак недействительного паспорта (Y/N)
   *
   * @return varchar2- строка со списком ошибок ч/з пробел (см. спр. sp_ndfl_errors)
   *
   */
  function validate_pers_info(
    p_code_na        int,  
    p_year           int,
    p_nom_spr        varchar2,
    p_fk_contragent  int,
    p_lastname       varchar2,
    p_firstname      varchar2,
    p_secondname     varchar2,
    p_birth_date     date,
    p_doc_code       int,
    p_doc_num        varchar2,
    p_inn            varchar2,
    p_citizenship    varchar2,
    p_resident       int,
    p_inn_dbl        int,
    p_fiod_dbl       int,
    p_doc_dbl        int,
    p_invalid_doc    varchar2
  ) return varchar2;
  
  /**
   * Процедура fill_spravki_errors заполняет таблицу ошибок перс.данных - f2ndfl_arh_srpavki_err
   */
  procedure fill_spravki_errors(
    p_code_na int,
    p_year    int
  );
  
  /**
   * Процедура fix_citizenship - заполняет гражданства в F2NDFL_ARH_SPRAVKI по адресу контрагента
   * !!! Ручной вызов, по необходимости.
   */
  procedure fix_cityzenship(
    p_code_na int,
    p_year    int,
    p_ref_id  f2ndfl_arh_spravki.id%type default null
  );
  
end f2ndfl_arh_spravki_api;
/
