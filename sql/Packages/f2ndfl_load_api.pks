create or replace package f2ndfl_load_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.01.2018 16:27:46
  -- Purpose : 
  
  --���� �������� ��������� create_2ndfl_refs
  C_ACT_LOAD_ALL      constant varchar2(30) := 'f2_load_all';           --������ ���� �������� ������� 2����
  C_ACT_LOAD_SPRAVKI  constant varchar2(30) := 'f2_load_spravki';       --�������� F2NDFL_LOAD_SPRAVKI � F2NDFL_ARH_NOMSPR
  C_ACT_LOAD_TOTAL    constant varchar2(30) := 'f2_load_total';         --�������� F2NDFL_LOAD_MES, F2NDFL_LOAD_VYCH, F2NDFL_LOAD_ITOGI + �������� ������� � 0 ������� (���� ��� ����� ����)
  C_ACT_LOAD_EMPLOYEE constant varchar2(30) := 'f2_load_employee';      --�������� ������ �� ����������� ����� (������ �.�. � ������� f_ndfl_load_employees_xml
  C_ACT_ENUMERATION   constant varchar2(30) := 'f2_enumeration';        --��������� �������, ���������� F2NDFL_ARH_SPRAVKI + ������ � F2NDFL_LOAD
  C_ACT_COPY2ARH      constant varchar2(30) := 'f2_copy2arh';           --����������� �������� ����������� �� F2NDFL_LOAD � F2NDFL_ARH
  C_ACT_INIT_XML      constant varchar2(30) := 'f2_arh_init_xml';       --�������������� ������ ��� �������� � ��� + �������� ������� �� ���� ������
  --
  C_ACT_DEL_ZERO_REF  constant varchar2(30) := 'f2_del_zero_ref';       --�������� ������� � ������� ������� (������ ��������, ����� ������� �� ������ ����!)
  
  --���� �������� ��������� purge_loads
  C_PRG_LOAD_ALL      constant varchar2(30) := 'f2_purge_all';          --�������� ���� ���������� �� LOAD � ARH
  C_PRG_LOAD_SPRAVKI  constant varchar2(30) := 'f2_purge_load_spravki'; --�������� F2NDFL_ARH_NOMSPR � F2NDFL_LOAD_SPRAVKI
  C_PRG_LOAD_TOTAL    constant varchar2(30) := 'f2_purge_load_total';   --�������� �������� ����������� �� F2NDFL_LOAD_
  C_PRG_EMPLOYEES     constant varchar2(30) := 'f2_purge_employees';    --�������� ������ �� �����������
  C_PRG_ARH_SPRAVKI   constant varchar2(30) := 'f2_purge_arh_spravki';  --�������� ARH_SPRAVKI, ������� ���������
  C_PRG_ARH_TOTAL     constant varchar2(30) := 'f2_purge_arh_total';    --�������� �������� ����������� �� F2NDFL_ARH_
  C_PRG_XML           constant varchar2(30) := 'f2_purge_xml';          --�������� ������ XML, � ��������������� �������� ������� �� ���
  
  --
  e_action_forbidden exception; --�������� ���������!
  e_unknown_action   exception; --����������� ��� ��������!
  
  /**
   * ��������� purge_loads �������� ������ �� ������ LOAD � ARH
   *
   * @param p_action_code - ��� ��������, ��. C_PRG_
   * @param p_code_na     - 
   * @param p_year        - 
   * @param p_force       - ���� �������������� ������ (��� ���� �� ����� �������� ������ C_PRG_LOAD_ALL, C_PRG_XML)
   * 
   * ���� �������� ��������� - e_action_forbidden
   *
   */
  procedure purge_loads(
    p_action_code  varchar2,
    p_code_na      int,
    p_year         int,
    p_force        boolean default false
  );
  
  /**
   * ��������� create_2ndfl_refs ������� ������� 2����
   * 
   * @ p_action_code - ��� ��������, ��. � ������ ������ ��������� C_ACT_
   * @ p_code_na     - 
   * @ p_year        - 
   * @ p_actual_date - ����, �� ������� ����������� ������ (�� ������� ����������� �������������)
   * 
   * ���� �������� ��������� - e_action_forbidden
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
