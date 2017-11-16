create or replace package dv_sr_lspv_docs_api is

  -- Author  : V.ZHURAVOV
  -- Created : 22.08.2017 14:26:22
  -- Purpose : API for table dv_sr_lspv_docs_t
  
  /**
   * Функции обвертки для представлений
   */
  function get_start_date      return date deterministic;
  function get_end_date        return date deterministic;
  function get_is_buff         return varchar2 deterministic;
  function get_start_date_buf  return date deterministic;
  function get_end_date_buf    return date deterministic;
    
  /**
   * Процедура установки периода
   */
  procedure set_period(p_year number);
  
  /**
   * Процедуры set_is_buff и unset_is_buff - включают и выключают учет буфера расчетов VYPLACH... в представлениях
   */
  procedure set_is_buff;
  procedure unset_is_buff;
  
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
   */
  function  get_last_update_date(p_year in number) return timestamp;
    
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
  
  /**
   * Процедура build_tax_diff формирует данные по расхождению удержанного и исчисленного налога
   *   Данные пишутся в таблицу dv_sr_lspv_tax_diff_buf, таблица перед формированием очищается!
   *   Для корректного вывода данных, использовать сортировку: 
   *     order by d.gf_person, d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips
   *
   * @param p_end_date - дата окончания периода выборки (по умолчанию - дата окончания предыдущего месяца от текущей даты)
   *
   */
  procedure build_tax_diff(
    p_end_date date default null
  );
  
end dv_sr_lspv_docs_api;
/
