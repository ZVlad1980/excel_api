create or replace package dv_sr_lspv_prc_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.01.2018 16:56:20
  -- Purpose : 
  
  /**
   * 
   */
  procedure create_process(
    p_process_row in out nocopy dv_sr_lspv_prc_t%rowtype
  );
  
  /**
   *
   */
  procedure set_process_state(
    p_process_row in out nocopy dv_sr_lspv_prc_t%rowtype
  );

end dv_sr_lspv_prc_api;
/
