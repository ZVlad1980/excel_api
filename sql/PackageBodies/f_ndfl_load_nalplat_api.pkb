create or replace package body f_ndfl_load_nalplat_api is

  -- Private type declarations
  
  
  /**
   * Обвертки обработки ошибок
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
    p_code_na     int,
    p_year        int
  ) is
  begin
    dv_sr_lspv_docs_api.update_gf_persons(
      p_year => p_year
    );
  end update_gf_person;
  
  /**
   * Процедура fill_ndfl_load_nalplat - заполнение таблицы
   *  f_ndfl_load_nalplat, с отметкой НА с нулевым доходом
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
    l_end_date    := add_months(l_from_date, l_quarter_row.month_end); --т.к. в пакете используются условия строго меньше - дата следующая за конечной!
    l_term_year   := add_months(l_from_date, 12);
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
    update_gf_person(
      p_code_na => p_code_na,
      p_year    => l_year
    );
  exception
    when others then
      fix_exception;
      raise;
  end fill_ndfl_load_nalplat;
  
  
end f_ndfl_load_nalplat_api;
/
