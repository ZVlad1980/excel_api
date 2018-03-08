create or replace package dv_sr_lspv_det_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 23.02.2018 14:10:44
  -- Purpose : 
  
  -- Public type declarations
  function legacy return varchar2 deterministic;
  function get_os_user return varchar2 deterministic;
  
  /**
   * ��������� update_details ��������� ������ ������� 
   *   dv_sr_lspv_det_t ������� �� dv_sr_lspv, ������ � ������� N ��� U
   *   � ���������� �� ������ � null
   */
  procedure update_details(
    p_commit  boolean default false
  );
  
  /**
   * ��������� recalc_pers_details ������������� ����������� 
   *  �� ��������� ����������� � ����
   */
  procedure recalc_pers_details(
    p_commit    boolean default false,
    p_year      int,
    p_ssylka_fl int
  );
  
  /**
   *
   */
  function get_remains_shifr_schet(
    p_year         int,
    p_nom_vkl      int,
    p_nom_ips      int,
    p_shifr_schet  int
  ) return number;
  
end dv_sr_lspv_det_pkg;
/
