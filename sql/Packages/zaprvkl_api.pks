create or replace package zaprvkl_api is

  -- Author  : V.ZHURAVOV
  -- Created : 21.06.2017 16:41:41
  -- Purpose : API ���������� �������� ���� ���������
  
  -- ������� �������������� ������
  --(F)ull identification, (P)art identification, (N)on identification, (D)ouble source, (M)ultiple identification, 'E'rror
  G_LN_STS_CREATED      constant varchar2(1) := 'C';
  G_LN_STS_IDENTIFICATE constant varchar2(1) := 'I';
  G_LN_STS_FULL_IDENT   constant varchar2(1) := 'F';
  G_LN_STS_PART_IDENT   constant varchar2(1) := 'P';
  G_LN_STS_NONE_IDENT   constant varchar2(1) := 'N';
  G_LN_STS_DOUBLE_IDENT constant varchar2(1) := 'D';
  G_LN_STS_MULTY_IDENT  constant varchar2(1) := 'M';
  G_LN_STS_ERROR_IDENT  constant varchar2(1) := 'E';
  
  G_FMT_DATE constant varchar2(20) := 'dd.mm.yyyy';
  
  /**
   * ������� �������� ��� ���������� ��������
   */
  function get_ln_sts_created      return varchar2 deterministic;
  function get_ln_sts_full_ident   return varchar2 deterministic;
  function get_ln_sts_part_ident   return varchar2 deterministic;
  function get_ln_sts_none_ident   return varchar2 deterministic;
  function get_ln_sts_double_ident return varchar2 deterministic;
  function get_ln_sts_multy_ident  return varchar2 deterministic;
  function get_ln_sts_error_ident  return varchar2 deterministic;
  --
  function get_fmt_date            return varchar2 deterministic;
  
  
  /**
   * ������� create_header - ������� ��������� ���������
   *
   * @param x_err_msg     - ��������� �� ������ (���� ����)
   * @param p_investor_id - ����� ��������� (��. fnd.sp_fiz_lits.nom_vkl).
   *                          ���� �� ����� - �� ����� ���������� ������ �������������� ��������� � ���������
   *
   */
  function create_header(
    x_err_msg       out varchar2,
    p_investor_id   fnd.sp_ur_lits.ssylka%type default null
  ) return zaprvkl_headers_t.id%type;
  
  /**
   * ��������� add_line_tmp ��������� ������������ ������ � tmp �������
   *  ���������� ������������ ����� ���������� ����� g_lines_tmp,
   *  ����� ����� ����� 1000 ����� (��. ��������� purge_lines_tmp)
   *  ��������� ���������� �� Excel
   *
   * @param p_last_name   - �������
   * @param p_first_name  - ���
   * @param p_second_name - ��������
   * @param p_birth_date  - ���� �������� � ������� ��.��.����
   * @param p_employee_id - ��������� �����
   * @param p_snils       - �����
   * @param p_inn         - ���
   *
   */
  procedure add_line_tmp(
    p_excel_id     number,
    p_last_name    varchar2,
    p_first_name   varchar2,
    p_second_name  varchar2,
    p_birth_date   varchar2,
    p_employee_id  varchar2,
    p_snils        varchar2,
    p_inn          varchar2
  );
  
  /**
   * ��������� start_process ��������� ������� ��������� ������
   *   ��������� � ����������� �� �������� ������� ���������
   * 
   * @param x_err_msg    - ��������� ��� ������ (������� ���������� -1)
   * @param p_header_id  - ID ��������� ��������
   * 
   */
  procedure start_process(
    x_err_msg     out varchar2,
    p_header_id   zaprvkl_headers_t.id%type
  );
  
  /**
   * ��������� get_results - ���������� ����� ����������� � ������������ ���������
   *
   * @param x_result      - �������������� ������
   * @param x_err_msg     - ��������� �� ������
   * @param p_header_id   - ID ��������� ���������
   * @param p_result_code - ��� ������������� ������:
   *                          participants            - ���������
   *                          not_found               - �����������
   *                          possible_participants   - ��������� ���������
   *                          errors                  - ������
   *
   */
  procedure get_results(
    x_result      out sys_refcursor,
    x_err_msg     out varchar2,
    p_header_id   integer,
    p_result_name varchar2
  );
  
  
  /**
   * ������� edit_distance ��������� ��������� ���� ���� �� ��������� ������������������
   */
  function edit_distance
  (
    plname in varchar2,
    prname in varchar2
  ) return number;

  /**
   * ������� edit_distance ��������� ��������� ���� ��� �� ��������� ������������������
   *   ��� ��������� ��������� �������������� ���� � ������ � ������ yyyymmdd
   */
  function edit_distance
  (
    plname in date,
    prname in date
  ) return number;
  
  /**
   * ��������������� �������
   */
  
  /**
   * ������� prepare_str$ ���������� ������ ����� (���) ��� ���������
   *  ��������������:
   *    - �������� ���������, ��������� � ������� �������� ��������
   *    - ������� �������
   *    - ���������� �������� � 0
   *    - �������� ����� �������� ����� ���������
   */
   function prepare_str$(p_str varchar2) return varchar2;
  
  /**
   * ������� to_date$ ��������������� ������ � ���� (���������� null � ������ ������)
   *  ���� ��������� � ������� G_FMT_DATE
   */
   function to_date$(p_date_str varchar2) return date;
   
end zaprvkl_api;
/
