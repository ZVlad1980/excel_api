create or replace package f2ndfl_load_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.01.2018 16:27:46
  -- Purpose : 
  
  --Коды действий процедуры create_2ndfl_refs
  C_ACT_LOAD_ALL      constant varchar2(30) := 'f2_load_all';           --Полный цикл создания справок 2НДФЛ
  C_ACT_LOAD_SPRAVKI  constant varchar2(30) := 'f2_load_spravki';       --Загрузка F2NDFL_LOAD_SPRAVKI и F2NDFL_ARH_NOMSPR
  C_ACT_LOAD_TOTAL    constant varchar2(30) := 'f2_load_total';         --Загрузка F2NDFL_LOAD_MES, F2NDFL_LOAD_VYCH, F2NDFL_LOAD_ITOGI + удаление справок с 0 доходом (пока еще могут быть)
  C_ACT_LOAD_EMPLOYEE constant varchar2(30) := 'f2_load_employee';      --Загрузка данных по сотрудникам фонда (данные д.б. в таблице f_ndfl_load_employees_xml
  C_ACT_ENUMERATION   constant varchar2(30) := 'f2_enumeration';        --Нумерация справок, заполнение F2NDFL_ARH_SPRAVKI + связка с F2NDFL_LOAD
  C_ACT_COPY2ARH      constant varchar2(30) := 'f2_copy2arh';           --Копирование суммовых показателей из F2NDFL_LOAD в F2NDFL_ARH
  C_ACT_INIT_XML      constant varchar2(30) := 'f2_arh_init_xml';       --Ининциализация файлов для передачи в ГНИ + разбивка справок по этим файлам
  --
  C_ACT_DEL_ZERO_REF  constant varchar2(30) := 'f2_del_zero_ref';       --Удаление справок с нулевым доходом (кривая операция, таких справок не должно быть!)
  
  --Коды действий процедуры purge_loads
  C_PRG_LOAD_ALL      constant varchar2(30) := 'f2_purge_all';          --Удаление всей информации из LOAD и ARH
  C_PRG_LOAD_SPRAVKI  constant varchar2(30) := 'f2_purge_load_spravki'; --Удаление F2NDFL_ARH_NOMSPR и F2NDFL_LOAD_SPRAVKI
  C_PRG_LOAD_TOTAL    constant varchar2(30) := 'f2_purge_load_total';   --Удаление суммовых показателей из F2NDFL_LOAD_
  C_PRG_EMPLOYEES     constant varchar2(30) := 'f2_purge_employees';    --Удаление данных по сотрудникам
  C_PRG_ARH_SPRAVKI   constant varchar2(30) := 'f2_purge_arh_spravki';  --Удаление ARH_SPRAVKI, очистка нумерации
  C_PRG_ARH_TOTAL     constant varchar2(30) := 'f2_purge_arh_total';    --Удаление суммовых показателей из F2NDFL_ARH_
  C_PRG_XML           constant varchar2(30) := 'f2_purge_xml';          --Удаление файлов XML, с предварительной отвязкой справок от них
  
  --
  e_action_forbidden exception; --Действие запрещено!
  e_unknown_action   exception; --Неизвестный код действия!
  
  /**
   * Процедура purge_loads удаление данных из таблиц LOAD и ARH
   *
   * @param p_action_code - код действия, см. C_PRG_
   * @param p_code_na     - 
   * @param p_year        - 
   * @param p_force       - флаг форсированного режима (без него не будут работать режимы C_PRG_LOAD_ALL, C_PRG_XML)
   * 
   * Если действие запрещено - e_action_forbidden
   *
   */
  procedure purge_loads(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int,
    p_force        boolean default false
  );
  
  /**
   * Процедура create_2ndfl_refs создает справки 2НДФЛ
   * 
   * @ p_action_code - код действия, см. в специи пакета константы C_ACT_
   * @ p_code_na     - 
   * @ p_year        - 
   * @ p_actual_date - дата, на которую формируются данные (до которой учитываются корректировки)
   * 
   * Если действие запрещено - e_action_forbidden
   *
   */
  procedure create_2ndfl_refs(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int,
    p_actual_date  date
  );

end f2ndfl_load_api;
/
