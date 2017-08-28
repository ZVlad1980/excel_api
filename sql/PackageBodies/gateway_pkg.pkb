create or replace package body gateway_pkg is

  C_DATE_FMT     constant varchar2(20) := 'dd.mm.yyyy';

  
  -- ������ �������� ��� ������
  C_SRC_CHR  constant varchar2(200) := 'AOPEHBCXMK';
  C_DEST_CHR constant varchar2(200) := '����������';
  
  -- Private type declarations
   /**
   * �������� ��������� ������
   */
  procedure fix_exception(p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => p_msg
    );
  end;
  
  /**
   * ������� ��������������� ������ � ���� (���������� null � ������ ������)
   *  ���� ��������� � ������� ��������
   */
  function to_date$(p_date_str varchar2) return date is
  begin
    return to_date(p_date_str, C_DATE_FMT);
  exception
    when others then
      return null;
  end to_date$;
  
  /**
   * ������� ���������� ������ ����� (���) ��� ���������
   *  ��������������:
   *    - �������� ���������, ��������� � ������� �������� ��������
   *    - ������� �������
   *    - ���������� �������� � 0
   *    - �������� ����� �������� ����� ���������
   */
   function prepare_str$(p_str varchar2) return varchar2 is
   begin
     return 
       translate(
           trim(
             regexp_replace(
               p_str, '  +', ' '
             )
           ),
         C_SRC_CHR,
         C_DEST_CHR
       );
   end prepare_str$;
   
   /**
   * ��������� ��������� ������������� ������� dv_sr_lspv_docs_t
   */
  procedure synhr_dv_sr_lspv_docs(
    x_err_msg    out varchar2,
    p_end_date   in  varchar2
  ) is
  begin
    --
    --
    utl_error_api.init_exceptions;
    --
    dv_sr_lspv_docs_api.synchronize(
      p_year => to_number(
                  extract(year from to_date(p_end_date, C_DATE_FMT))
                )
    );
    --
  exception
    when others then
      --
      fix_exception;
      x_err_msg :=  utl_error_api.get_exception;
      --
  end synhr_dv_sr_lspv_docs;
  
  /**
   * ��������� get_report ���������� ������ � ������� ������
   * 
   * @param x_result      - ������ � �������
   * @param x_err_msg     - ��������� �� ������
   * @param p_report_code - ��� ������
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
  ) is
  begin
    --
    x_result := ndfl_report_api.get_report(
      p_report_code => p_report_code, 
      p_end_date    => to_date(p_end_date, C_DATE_FMT)
    );
    --
  exception
    when others then
      --
      fix_exception;
      x_err_msg := utl_error_api.get_exception;
      --
  end get_report;
  
  /**
   * ��������� load_employees ��������� �������� ����������� � f_ndfl_load_spisrab
   *   (�� tmp �������, ��. ��������� add_line)
   */
  procedure load_employees(
    x_err_msg   out varchar2,
    p_load_date varchar2
  ) is
  begin
    --
    utl_error_api.init_exceptions;
    --
    f_ndfl_load_spisrab_api.load_from_tmp(
      p_load_date => to_date(p_load_date, C_DATE_FMT)
    );
    --
  exception
    when others then
      fix_exception('load_employees(p_load_date => ' || p_load_date);
      x_err_msg := utl_error_api.get_exception;
  end load_employees;
  
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
  ) is
    l_line zaprvkl_lines_tmp%rowtype;
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_line.last_name   := prepare_str$(p_last_name    ) ;
    l_line.first_name  := prepare_str$(p_first_name   ) ;
    l_line.second_name := prepare_str$(p_second_name  ) ;
    l_line.birth_date  := to_date$(p_birth_date       ) ;
    l_line.snils       := prepare_str$(p_snils        ) ;
    l_line.inn         := prepare_str$(p_inn          ) ;
    --
    zaprvkl_lines_tmp_api.add_line(
      p_line => l_line
    );
    --
  exception
    when others then
      fix_exception('load_employees(p_last_name => ' || p_last_name);
      --x_err_msg := utl_error_api.get_exception;
  end load_employees;
  
end gateway_pkg;
/