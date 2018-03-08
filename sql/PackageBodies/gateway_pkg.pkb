create or replace package body gateway_pkg is

  C_DATE_FMT     constant varchar2(20) := 'dd.mm.yyyy';

  
  -- ������ �������� ��� ������
  C_SRC_CHR  constant varchar2(200) := 'AOPEHBCXMK';
  C_DEST_CHR constant varchar2(200) := '����������';
  
  --��� ��� �������� ���������� �������
  type g_parameters_type is table of varchar2(512) index by varchar2(40);
  g_parameters g_parameters_type;
  
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
  
  function to_number$(p_str varchar2) return number is
    l_delim varchar2(1);
  begin
    l_delim := substr(1/2, 1, 1);
    return to_number(prepare_str$(replace(p_str, case l_delim when '.' then ',' else '.' end, l_delim)));
  exception
    when others then
      fix_exception;
      raise;
  end to_number$;
   
  /**
   * ������� get_date ���������� ���� ������ ��� ��������� ��������� ���� � ������
   *
   * @param p_year    - ���
   * @param p_month   - �����
   * @param p_is_end  - ����, ������������ ��� ����: ������ ��� ����� �������
   *
   */
  function get_date(
    p_year   number,
    p_month  number default 12,
    p_is_end boolean default true
  ) return date is
    l_month  varchar2(2);
    l_diff   int;
  begin
    l_month := lpad(case when p_month <1 or p_month > 12 then 12 else p_month end, 2, '0');
    l_diff  := case when p_is_end then 1 else 0 end;
    return add_months(to_date(p_year || l_month || '01', 'yyyymmdd'), l_diff) - l_diff;
  exception
    when others then
      fix_exception;
      raise;
  end get_date;
  
  /**
   * ��������� synhr_dv_sr_lspv_docs ��������� ������������� ������� dv_sr_lspv_docs_t
   *
   * @param p_year        - ��� ������������ ������
   * @param p_month       - ����� ������������ ������
   *
   */
  procedure synhr_dv_sr_lspv_docs(
    x_err_msg    out varchar2,
    p_year            number
  ) is
  begin
    --
    utl_error_api.init_exceptions;
    --
    dv_sr_lspv_docs_api.synchronize(
      p_year => p_year
    );
    --
    dv_sr_lspv#_api.update_dv_sr_lspv#(
      p_year_from => p_year,
      p_year_to   => p_year
    );
    --
    dv_sr_lspv_det_pkg.update_details;
    --
    commit;
    --
  exception
    when others then
      --
      rollback;
      fix_exception;
      x_err_msg :=  utl_error_api.get_error_msg;
      --
  end synhr_dv_sr_lspv_docs;
  
  /**
   * ��������� update_dv_sr_lspv# ��������� ���������� ������� dv_sr_lspv#
   *
   * @param p_year        - ��� ������������ ������
   *
   */
  procedure update_dv_sr_lspv#(
    x_err_msg    out varchar2,
    p_year            number
  ) is
  begin
    --
    utl_error_api.init_exceptions;
    --
    dv_sr_lspv#_api.update_dv_sr_lspv#(
      p_year_from => p_year,
      p_year_to   => p_year
    );
    --
    dv_sr_lspv_det_pkg.update_details;
    --
    commit;
    --
  exception
    when others then
      --
      rollback;
      fix_exception;
      x_err_msg :=  utl_error_api.get_error_msg;
      --
  end update_dv_sr_lspv#;
  
  /**
   * ��������� update_gf_persons ��������� �� ���������� CONTRAGENTS.ID
   */
  procedure update_gf_persons(
    x_err_msg    out varchar2,
    p_year            number
  ) is
  begin
    --
    --
    utl_error_api.init_exceptions;
    --
    dv_sr_lspv_docs_api.update_gf_persons(
      p_year => p_year
    );
    --
    commit;
    --
  exception
    when others then
      --
      rollback;
      fix_exception;
      x_err_msg :=  utl_error_api.get_error_msg;
      --
  end update_gf_persons;
  
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
    /*x_err_msg := 'get_report: ' || p_report_code || ', ' || 
      to_char(get_date(p_year, p_month), 'dd.mm.yyyy') || ', ' || 
      to_char(to_date$(p_report_date), 'dd.mm.yyyy');
    return;--*/
    if lower(substr(p_report_code, 1, 2)) = 'f2' then
      x_result := ndfl2_report_api.get_report(
        p_report_code => p_report_code, 
        p_year        => p_year,
        p_report_date => to_date$(p_report_date)
      );
    else
      x_result := ndfl_report_api.get_report(
        p_report_code => p_report_code, 
        p_end_date    => get_date(p_year, p_month),
        p_report_date => to_date$(p_report_date)
      );
    end if;
    --
  exception
    when others then
      --
      fix_exception;
      x_err_msg := utl_error_api.get_error_msg;
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
      x_err_msg := utl_error_api.get_error_msg;
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
    e_exc  exception;
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_line.last_name   := prepare_str$(p_last_name    ) ;
    l_line.first_name  := prepare_str$(p_first_name   ) ;
    l_line.second_name := prepare_str$(p_second_name  ) ;
    l_line.birth_date  := to_date$(p_birth_date       ) ;
    --
    if not (
        l_line.last_name   is not null and
        l_line.first_name  is not null and
        l_line.second_name is not null and
        l_line.birth_date  is not null
      ) then
      fix_exception('load_employees.' || $$PLSQL_LINE || '. ��� � ���� �������� �.�. ���������!');
      raise e_exc;
    end if;
    
    
    --
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
  end load_employees;
  
  /**
   * ��������� create_ndfl2 ��������� �������� ������� 2����
   */
  procedure create_ndfl2(
    x_err_msg       out varchar2,
    p_code_na       in  varchar2,
    p_year          in  varchar2,
    p_contragent_id in  varchar2
  ) is
  begin
    --
    f2ndfl_arh_spravki_api.create_reference_corr(
      p_code_na       => to_number$(p_code_na),
      p_year          => to_number$(p_year),
      p_contragent_id => to_number$(p_contragent_id)
    );
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception('create_ndfl2(p_code_na => ' || p_code_na ||
        ', p_year => ' || p_year || 
        ', p_contragent_id => ' || p_contragent_id
      );
      x_err_msg := utl_error_api.get_error_msg;
  end create_ndfl2;
  
  /**
   * ��������� ������� ������������ ������� ����������� �������
   */
  procedure build_tax_diff_det_table(
    x_err_msg       out varchar2,
    p_year              number,
    p_month             number
  ) is
  begin
    --
    dv_sr_lspv_docs_api.build_tax_diff(
      p_end_date => get_date(p_year, p_month)
    );
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception('build_tax_diff_det_table(p_year => ' || p_year || ', p_month => ' || p_month || ')');
      x_err_msg := utl_error_api.get_error_msg;
  end build_tax_diff_det_table;
  
  /**
   * ��������� �������� ������ � ������� f_ndfl_load_nalplat
   */
  procedure fill_ndfl_load_nalplat(
    x_err_msg       out varchar2,
    p_code_na           varchar2,    
    p_year              number,
    p_month             number,
    p_actual_date       varchar2
  ) is
  begin
    --
    f_ndfl_load_nalplat_api.fill_ndfl_load_nalplat(
      p_code_na     => p_code_na,
      p_load_date   => get_date(p_year, p_month, false),
      p_actual_date => to_date$(p_actual_date)
    );
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception('fill_ndfl_load_nalplat(p_year => ' || p_year || ', p_month => ' || p_month || ')');
      x_err_msg := utl_error_api.get_error_msg;
  end fill_ndfl_load_nalplat;
  
  /**
   * ��������� �������� ������ � F2NDFL_LOAD_
   */
  procedure f2_ndfl_api(
    x_err_msg       out varchar2,
    p_action_code       varchar2,
    p_code_na           varchar2,    
    p_year              number,
    p_actual_date       varchar2
  ) is
  begin
    --
    f2ndfl_load_api.create_2ndfl_refs(
      p_action_code => p_action_code,
      p_code_na     => p_code_na,
      p_year        => p_year,
      p_actual_date => to_date$(p_actual_date)
    );
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception('f2ndfl_api(p_year => ' || p_year || ', p_action_code => ' || p_action_code || ')');
      x_err_msg := utl_error_api.get_error_msg;
  end f2_ndfl_api;
  
  /**
   * ����� ����� ������������� ����������
   */
  procedure purge_parameters is
  begin
    g_parameters.delete();
  end purge_parameters;
  
  /**
   * ��������� ������� ��� �������� ������������� ������ ����������
   */
  procedure set_parameter(
    p_name  varchar2,
    p_value varchar2
  ) is
  begin
    if p_name is not null and length(p_name) < 20 
        and lengthb(p_value) <= 512
      then
      if g_parameters.exists(p_name) then
        fix_exception('gateway_pkg.set_parameter: parameter ' || p_name || ' is already determined');
        raise DUP_VAL_ON_INDEX;
      end if;
      g_parameters(lower(p_name)) := p_value;
    end if;
  end set_parameter;
  
  /**
   * ��������� ������� ��� �������� ������������� ������ ����������
   */
  function get_parameter(
    p_name  varchar2
  ) return varchar2 deterministic is
  begin
    return g_parameters(p_name);
  end get_parameter;
  
  /**
   * ��������� ������� ��� �������� ������������� ������ ����������
   */
  function get_parameter_num(
    p_name  varchar2
  ) return number deterministic is
  begin
    return to_number(g_parameters(p_name));
  end get_parameter_num;
  
  /**
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
  ) is
    l_req_body   
  begin
    --
    call$(get_execute(p_path => p_path), )
    --
    x_status := 'S';
    --
  exception
    when others then
      fix_exception('request(p_path => "'||p_path||'"): ');
      x_err_msg := utl_error_api.get_error_msg;
      x_status  := 'E';
  end request;
  */
end gateway_pkg;
/
