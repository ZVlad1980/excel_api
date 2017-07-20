create or replace package ndfl_report_api is

  -- Author  : V.ZHURAVOV
  -- Created : 03.07.2017 12:34:48
  -- Purpose : 
  
  function get_start_date return date deterministic;
  function get_end_date   return date deterministic;
  
  procedure set_period(
    p_start_date date,
    p_end_date   date default null
  );
  
  /**
   * ��������� get_report ���������� ������ � ������� ������
   * 
   * @param x_result      - ������ � �������
   * @param x_err_msg     - ��������� �� ������
   * @param p_report_code - ��� ������:
   *                            detail_report     - ����������� ����������� 6����
   *                            detail_report_2   - ����������� ����������� 6���� ������� ����� ������ � ������
   *                            correcting_report - 
   *                            error_report      - ����� �� ������� ���������
   * @param p_from_date   - ���� ������ ������� � ������� YYYYMMDD
   * @param p_end_date    - ���� ��������� ������� � ������� YYYYMMDD
   *
   */
  procedure get_report(
    x_result    out sys_refcursor, 
    x_err_msg   out varchar2,
    p_report_code   varchar2,
    p_from_date     varchar2,
    p_end_date      varchar2
  );
  
end ndfl_report_api;
/
