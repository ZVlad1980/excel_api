create or replace package dv_sr_lspv_docs_api is

  -- Author  : V.ZHURAVOV
  -- Created : 22.08.2017 14:26:22
  -- Purpose : API for table dv_sr_lspv_docs_t
  
  /**
   * Функции обвертки для представлений
   */
  function get_start_date return date deterministic;
  function get_end_date   return date deterministic;

  /**
   * Процедура установки периода
   */
  procedure set_period(p_year number);
  
  /**
   */
  procedure set_period(p_end_date date);
  
  /**
   */
  procedure set_period(
    p_start_date date,
    p_end_date   date
  );
  /**
   * Процедура synchronize синхронизирует таблицу dv_sr_lspv_docs_t данными из таблицы fnd.dv_sr_lspv
   *  за указанный год (p_year)
   */
  procedure synchronize(p_year in number);

  
  /**
   * Функция определяет является ли операция - возвратом налога по заявлению
   *
   *  На текущий момент, к таковым относятся:
   *    - операции коррекции налога по выкупным суммам
   *    - операции коррекции налога по пенсии, при наличии операции по 83 счету и этому же документу на обратную сумму
   */
  function is_tax_return(
    p_nom_vkl          fnd.dv_sr_lspv.nom_vkl%type,
    p_nom_ips          fnd.dv_sr_lspv.nom_ips%type,
    p_date_op          fnd.dv_sr_lspv.data_op%type,
    p_shifr_schet      fnd.dv_sr_lspv.shifr_schet%type,
    p_sub_shifr_schet  fnd.dv_sr_lspv.sub_shifr_schet%type,
    p_ssylka_doc       fnd.dv_sr_lspv.ssylka_doc%type,
    p_det_charge_type  varchar2,
    p_amount           fnd.dv_sr_lspv.summa%type
  ) return varchar2;
  
end dv_sr_lspv_docs_api;
/
