create or replace package gateway_pkg is

  -- Author  : V.ZHURAVOV
  -- Created : 25.08.2017 12:18:49
  -- Purpose : API Gateway
  
  /**
   * ��������� synhr_dv_sr_lspv_docs ��������� ������������� ������� dv_sr_lspv_docs_t
   *
   * @param p_year        - ��� ������������ ������
   *
   */
  procedure synhr_dv_sr_lspv_docs(
    x_err_msg    out varchar2,
    p_year            number
  );
  
  /**
   * ��������� update_gf_persons ��������� �� ���������� CONTRAGENTS.ID
   */
  procedure update_gf_persons(
    x_err_msg    out varchar2,
    p_year            number
  );
  
  /**
   * ��������� update_dv_sr_lspv# ��������� ���������� ������� dv_sr_lspv#
   *
   * @param p_year        - ��� ������������ ������
   *
   */
  procedure update_dv_sr_lspv#(
    x_err_msg    out varchar2,
    p_year            number
  );
  
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
  
  /**
   * ��������� create_ndfl2 ��������� �������� ������� 2����
   */
  procedure create_ndfl2(
    x_err_msg       out varchar2,
    p_code_na       in  varchar2,
    p_year          in  varchar2,
    p_contragent_id in  varchar2
  );
  
  /**
   * ��������� ������� ������������ ������� ����������� �������
   */
  procedure build_tax_diff_det_table(
    x_err_msg       out varchar2,
    p_year              number,
    p_month             number
  );
  
  /**
   * ��������� �������� ������ � ������� f_ndfl_load_nalplat
   */
  procedure fill_ndfl_load_nalplat(
    x_err_msg       out varchar2,
    p_code_na           varchar2,    
    p_year              number,
    p_month             number,
    p_actual_date       varchar2
  );
  
  /**
   * ��������� �������� ������ � F2NDFL_LOAD_
   */
  procedure f2_ndfl_api(
    x_err_msg       out varchar2,
    p_action_code       varchar2,
    p_code_na           varchar2,    
    p_year              number,
    p_actual_date       varchar2
  );
  
  /**
   * ����� ����� ������������� ����������
   */
  procedure purge_parameters;
  
  /**
   * ��������� ������� ��� �������� ������������� ������ ����������
   */
  procedure set_parameter(
    p_name  varchar2,
    p_value varchar2
  );
  
  /**
   * ��������� ������� ��� �������� ������������� ������ ����������
   */
  function get_parameter(
    p_name  varchar2
  ) return varchar2 deterministic;
  
  /**
   * ��������� ������� ��� �������� ������������� ������ ����������
   */
  function get_parameter_num(
    p_name  varchar2
  ) return number deterministic;
  
  /** JSON �� ������������� � 12.1.0.1!!! ����� ���� ����������!
   * ��������� request - ������ ����� �����
   *
   * @param x_result_set - �������������� ����� ������ (������)
   * @param x_status     - ������ ����������: (S)uccess/(E)rror/(M)an
   * @param x_err_code   - ��� ������ (������ HTTP status)
   * @param x_err_msg    - ��������� �� ������
   * @param p_path       - ���� �������������� ������� (���� ������ �������������)
   * @param p_req_json   - ��������� ������� � ������� JSON
   *
   /
  procedure request(
    x_result_set out sys_refcursor,
    x_status     out varchar2,
    x_err_msg    out varchar2,
    p_path       in  varchar2,
    p_req_json   in  varchar2
  );
  */
end gateway_pkg;
/
