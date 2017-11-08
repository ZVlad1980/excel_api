create or replace package f2ndfl_arh_spravki_api is

  -- Author  : V.ZHURAVOV
  -- Created : 02.11.2017 15:54:23
  -- Purpose : API формирование справок 2НДФЛ
  
  /** ТОКА ДЛЯ ОТЛАДКИ
   * Процедура calc_reference расчет новой справки
   *
   * @param p_ref_row    - справка f2ndfl_arh_spravki%rowtype
   * @param p_src_ref_id - ID предыдущей справки
   *
   /
  procedure calc_reference(
    p_ref_row     in out nocopy f2ndfl_arh_spravki%rowtype
  );
  --*/
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

end f2ndfl_arh_spravki_api;
/
