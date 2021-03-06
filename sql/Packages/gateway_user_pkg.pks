create or replace package gateway_user_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 18.10.2017 12:18:49
  -- Purpose : API Gateway User. ���� ��� ������������� �����.
  
  /**
   * ��������� get_report ���������� ������ � ������� ������
   * 
   * @param x_result      - ������ � �������
   * @param x_err_msg     - ��������� �� ������
   * @param p_report_code - ��� ������
   * @param p_year        - ��� ������������ ������
   * @param p_month       - ����� ������������ ������
   * @param p_report_date - ����, �� ������� ����������� �����
   *
   */
  procedure get_report(
    x_result      out sys_refcursor, 
    x_err_msg     out varchar2,
    p_report_code     varchar2,
    p_year            number,
    p_month           number,
    p_report_date     varchar2
  );
  
  /**
   * ��������� load_employees ��������� �������� ����������� � f_ndfl_load_spisrab
   *   (�� tmp �������, ��. ��������� add_line)
   */
  procedure load_employees(
    x_err_msg   out varchar2,
    p_load_date varchar2
  );
  
  /**
   * ��������� load_employees ��������� ������������ ������ � tmp �������
   *   �������� API 
   *
   * @param p_last_name   - �������
   * @param p_first_name  - ���
   * @param p_second_name - ��������
   * @param p_birth_date  - ���� �������� � ������� ��.��.����
   * @param p_snils       - �����
   * @param p_inn         - ���
   *
   */
  procedure load_employees(
    p_last_name    varchar2,
    p_first_name   varchar2,
    p_second_name  varchar2,
    p_birth_date   varchar2,
    p_snils        varchar2,
    p_inn          varchar2
  );
  
end gateway_user_pkg;
/
