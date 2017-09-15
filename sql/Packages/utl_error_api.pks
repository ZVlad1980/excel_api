create or replace package utl_error_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.07.2017 10:26:58
  -- Purpose : API обработки ошибок
  G_EXCEPTION exception;
  
  procedure init_exceptions;
  
  procedure fix_exception(
    p_err_msg varchar2 default null
  );
  
  function get_exception(
    p_ind integer default 1
  ) return varchar2;
  
  procedure fix_exception(
    p_routine varchar2,
    p_params  sys.odcivarchar2list,
    p_err_msg varchar2 default null
  );
  
  function get_exception_full return varchar2;

  
  /**
   *
   */
  function get_error_msg return varchar2;
  
end utl_error_api;
/
