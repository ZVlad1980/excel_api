create or replace package body f_ndfl_load_nalplat_api is

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
   */
  procedure update_gf_person(
    p_year        int
  ) is
  begin
    dv_sr_lspv_docs_api.update_gf_persons(
      p_year => p_year
    );
  end update_gf_person;
  
  /**
   *
   */
  procedure update_resident_status(
    p_code_na     int,
    p_year        int
  ) is
  begin
    --
    update (select na2.kod_na,
                   na2.god,
                   na2.ssylka_tip,
                   na2.nom_vkl,
                   na2.nom_ips,
                   na2.nalres_status,
                   coalesce(nn.resident, 1) resident
            from   f_ndfl_load_nalplat na2,
                   lateral (
                     select case nn.resident
                              when 'N' then 2
                              else          1
                            end resident
                     from   sp_tax_residents_v nn
                     where  nn.fk_contragent = na2.gf_person
                   )(+)                nn
            where  1 = 1
            and    na2.nalres_status <> coalesce(nn.resident, 1)
            and    na2.god = p_year
            and    na2.kod_na = p_code_na) u
    set    u.nalres_status = u.resident;
    --
  exception
    when others then
      fix_exception;
      raise;
  end update_resident_status;
  
  /**
   * ��������� ��������� ���� ���������� ������ ���� �� ���� �������� (��� ������...)
   */
  procedure set_zero_nalplat(
    p_code_na     int
  ) is
  begin
    --
    update (select n.sgd_isprvnol
            from   f_ndfl_load_nalplat n
            where  1=1
            and    not exists (
                     select 1
                     from   dv_sr_lspv_acc_v a
                     where  a.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
                     and    a.nom_vkl = n.nom_vkl
                     and    a.nom_ips = n.nom_ips
                   )
            and    n.kod_na = p_code_na
            and    n.god = dv_sr_lspv_docs_api.get_year
            and    n.sgd_isprvnol = 0
           ) u
    set    u.sgd_isprvnol = 1;
    --
  exception
    when others then
      fix_exception;
      raise;
  end set_zero_nalplat;
  
  
  
  /**
   * ��������� fill_ndfl_load_nalplat - ���������� �������
   *  f_ndfl_load_nalplat, � �������� �� � ������� �������
   */
  procedure fill_ndfl_load_nalplat(
    p_code_na     int,
    p_load_date   date
  ) is
    l_quarter_row sp_quarters_v%rowtype;
    
    l_year      int;
    l_from_date date;
    l_end_date  date;
    l_term_year date;
  begin
    
    l_quarter_row := fxndfl_util.get_quarter_row(
      p_date => p_load_date
    );
    l_year        := extract(year from p_load_date);
    l_from_date   := trunc(p_load_date, 'Y');
    l_end_date    := add_months(l_from_date, l_quarter_row.month_end); --�.�. � ������ ������������ ������� ������ ������ - ���� ��������� �� ��������!
    l_term_year   := add_months(l_from_date, 12);
    --
    dv_sr_lspv_docs_api.set_period(
      p_year        => l_year,
      p_report_date => l_end_date
    );
    --
    fxndfl_util.fill_ndfl_load_nalplat(
      p_code_na   => p_code_na,
      p_year      => l_year,
      p_from_date => l_from_date,
      p_end_date  => l_end_date,
      p_term_year => l_term_year,
      p_period    => l_quarter_row.code
    );
    --
    fxndfl_util.set_zero_nalplat(
      p_code_na   => p_code_na,
      p_year      => l_year,
      p_from_date => l_from_date,
      p_end_date  => l_end_date,
      p_term_year => l_term_year
    );
    --
    set_zero_nalplat(
      p_code_na => p_code_na
    );
    --
    update_gf_person(
      p_year    => l_year
    );
    --���� ���. ��� �������� �� ������������ �� dv_sr_lspv_docs_t - ������!
    update_resident_status(
      p_code_na => p_code_na,
      p_year    => l_year
    );
    --
  exception
    when others then
      fix_exception;
      raise;
  end fill_ndfl_load_nalplat;
  
  
end f_ndfl_load_nalplat_api;
/
