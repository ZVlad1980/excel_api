create or replace package dv_sr_lspv_det_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 23.02.2018 14:10:44
  -- Purpose : 
  
  -- Public type declarations
  function legacy return varchar2 deterministic;
  function get_os_user return varchar2 deterministic;
  
  /**
   * Процедура update_details обновляет данные таблицы 
   *   dv_sr_lspv_det_t данными из dv_sr_lspv, строки в статусе N или U
   *   и сбрасывает их статус в null
   */
  procedure update_details;
  
end dv_sr_lspv_det_pkg;
/
