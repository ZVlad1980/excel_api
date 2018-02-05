create or replace package ndfl2_report_api is

  -- Author  : V.ZHURAVOV
  -- Created : 24.01.2018 14:47:58
  -- Purpose : 
  
  /**
   * ������� get_report ���������� ������ � ������� ������
   * 
   * @param p_report_code - ��� ������
   * @param p_year        - ���, �� ������� �������� �����
   * @param p_report_date - ����, �� ������� ����������� �����
   *
   */
  function get_report(
    p_report_code   varchar2,
    p_year          int,
    p_report_date   date default null
  ) return sys_refcursor;

end ndfl2_report_api;
/
