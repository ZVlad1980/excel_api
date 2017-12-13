create or replace package body gateway_pkg is

  C_DATE_FMT     constant varchar2(20) := 'dd.mm.yyyy';

  
  -- Строки символов для замены
  C_SRC_CHR  constant varchar2(200) := 'AOPEHBCXMK';
  C_DEST_CHR constant varchar2(200) := 'АОРЕНВСХМК';
  
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
   * Функция конвертирования строки в дату (возвращает null в случае ошибки)
   *  Дата ожидается в формате ГГГГММДД
   */
  function to_date$(p_date_str varchar2) return date is
  begin
    return to_date(p_date_str, C_DATE_FMT);
  exception
    when others then
      return null;
  end to_date$;
  
  /**
   * Функция подготовки строки имени (ФИО) для обработки
   *  Преобразования:
   *    - удаление начальных, хвостовых и двойных пробелов пробелов
   *    - верхний регистр
   *    - трансляция латиницы и 0
   *    - удаление любых символов кроме кириллицы
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
   * Процедура запускает синхронизацию таблицу dv_sr_lspv_docs_t
   */
  procedure synhr_dv_sr_lspv_docs(
    x_err_msg    out varchar2,
    p_end_date   in  varchar2
  ) is
  begin
    --
    utl_error_api.init_exceptions;
    --
    dv_sr_lspv_docs_api.synchronize(
      p_year => to_number(
                  extract(year from to_date(p_end_date, C_DATE_FMT))
                )
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
  end synhr_dv_sr_lspv_docs;
  
  /**
   * Процедура update_gf_persons обновляет не актуальные CONTRAGENTS.ID
   */
  procedure update_gf_persons(
    x_err_msg    out varchar2,
    p_end_date   in  varchar2
  ) is
  begin
    --
    --
    utl_error_api.init_exceptions;
    --
    dv_sr_lspv_docs_api.update_gf_persons(
      p_year => to_number(
                  extract(year from to_date(p_end_date, C_DATE_FMT))
                )
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
   * Процедура get_report возвращает курсор с данными отчета
   * 
   * @param x_result      - курсор с данными
   * @param x_err_msg     - сообщение об ошибке
   * @param p_report_code - код отчета
   * @param p_from_date   - дата начала выборки в формате YYYYMMDD
   * @param p_end_date    - дата окончания выборки в формате YYYYMMDD
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
      x_err_msg := utl_error_api.get_error_msg;
      --
  end get_report;
  
  /**
   * Процедура load_employees запускает загрузки сотрудников в f_ndfl_load_spisrab
   *   (из tmp таблицы, см. процедуру add_line)
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
   * Процедура load_employees добавляет персональные данные в tmp таблицу
   *   Вызывает API 
   *
   * @param p_last_name   - фамилия
   * @param p_first_name  - имя
   * @param p_second_name - отчество
   * @param p_birth_date  - дата рождения в формате ДД.ММ.ГГГГ
   * @param p_snils       - СНИЛС
   * @param p_inn         - ИНН
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
      fix_exception('load_employees.' || $$PLSQL_LINE || '. ФИО и дата рождения д.б. заполнены!');
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
   * Процедура create_ndfl2 запускает создание справки 2НДФЛ
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
   * Процедура запуска формирования таблицы расхождения налогов
   */
  procedure build_tax_diff_det_table(
    x_err_msg       out varchar2,
    p_end_date      in  varchar2
  ) is
  begin
    --
    dv_sr_lspv_docs_api.build_tax_diff(
      p_end_date => to_date$(p_end_date)
    );
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception('build_tax_diff_det_table(p_end_date => ' || p_end_date || ')');
      x_err_msg := utl_error_api.get_error_msg;
  end build_tax_diff_det_table;
  
end gateway_pkg;
/
