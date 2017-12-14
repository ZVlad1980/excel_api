create or replace package ndfl_report_api is

  -- Author  : V.ZHURAVOV
  -- Created : 03.07.2017 12:34:48
  -- Purpose : 
  
  /**
   * ������� get_report ���������� ������ � ������� ������
   * 
   * @param p_report_code - ��� ������
   * @param p_end_date    - �������� ���� ������
   * @param p_report_date - ����, �� ������� ����������� �����
   *
   */
  function get_report(
    p_report_code   varchar2,
    p_end_date      date,
    p_report_date   date default null
  ) return sys_refcursor;
  
end ndfl_report_api;
/
