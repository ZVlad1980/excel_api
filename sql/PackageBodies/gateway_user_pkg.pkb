create or replace package body gateway_user_pkg is

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
  ) is
  begin
    --
    gateway_pkg.get_report(
      x_result      => x_result      ,
      x_err_msg     => x_err_msg     ,
      p_report_code => p_report_code ,
      p_year        => p_year        ,
      p_month       => p_month       ,
      p_report_date => p_report_date
    );
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
    gateway_pkg.load_employees(
      x_err_msg   => x_err_msg  ,
      p_load_date => p_load_date
    );
    --
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
  begin
    --
    gateway_pkg.load_employees(
      p_last_name   => p_last_name  ,
      p_first_name  => p_first_name ,
      p_second_name => p_second_name,
      p_birth_date  => p_birth_date ,
      p_snils       => p_snils      ,
      p_inn         => p_inn        
    );
    --
  end load_employees;
  
end gateway_user_pkg;
/
