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
    p_contragent_id  f2ndfl_arh_nomspr.fk_contragent%type
  );

  /**
   * Процедура delete_reference удаляет данные справки из таблиц F2NDFL_, кроме F2NDFL_ARH_NOMSPR
   *  Если данные справки включены в XML для ГНИ - удаление отменяется.
   * Внимание: для исходных справок (корр.номер=0) данные по сотрудникам фонда не удаляются, также не удаляются данные по 9 типу дохода (зп)
   *   Т.е. если справка относится к сотруднику фонда, не являющемуся контрагентом - она не будет удалена, 
   *        если сотрудник является контрагентом - будут удалены данные по всем типам дохода, кроме 9 (зп)
   *
   * @param p_ref_id - ID удаляемой справки
   * @param p_commit - флаг фиксации транзакции
   *
   */
  procedure delete_reference(
    p_ref_id f2ndfl_arh_spravki.id%type,
    p_commit boolean default false
  );

end f2ndfl_arh_spravki_api;
/
