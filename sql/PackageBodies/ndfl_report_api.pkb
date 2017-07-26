create or replace package body ndfl_report_api is
  
  C_DATE_FMT     constant varchar2(20) := 'dd.mm.yyyy';
  C_DATE_OUT_FMT constant varchar2(20) := 'dd.mm.yyyy';
  
  -- Строки символов для замены
  C_SRC_CHR  constant varchar2(200) := 'AOPEHBCXMK';
  C_DEST_CHR constant varchar2(200) := 'АОРЕНВСХМК';
  
  g_start_date date;
  g_end_date   date;
  
  function get_start_date return date deterministic is begin return g_start_date; end;
  function get_end_date   return date deterministic is begin return g_end_date; end;
  
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
   * Процедура set_period устанавливает период выборки для представления ndfl_dv_sr_lspv_v
   *
   * @param p_start_date - дата начала выборки (усекается до начала суток)
   * @param p_end_date   - дата окончания выборки
   *             Если дата окончания не задана - устанавливается по p_start_date на конец суток
   *
   */
  procedure set_period(
    p_start_date date,
    p_end_date   date default null
  ) is
  begin 
    g_start_date := trunc(p_start_date);
    g_end_date   := trunc(nvl(p_end_date, p_start_date)) + 1/24/60/60*86399;
  end set_period;
  
  /**
   *
   */
  procedure create_header(
    x_header_id  in out nocopy ndfl6_headers_t.header_id%type,
    x_start_date in out nocopy date,
    x_end_date   in out nocopy date
  ) is
  begin
    --
    x_end_date   := add_months(trunc(x_end_date, 'MM'), 1) - 1;
    x_start_date := trunc(x_end_date, 'Y'); --для 6НДФЛ всегда с начала года до конца заданного месяца
    --
    ndfl6_headers_api.create_header(
      x_header_id  => x_header_id,
      p_start_date => x_start_date,
      p_end_date   => x_end_date
    );
    --
    commit;
    --
  exception
    when others then
      fix_exception;
      raise;
  end;
  /**
   * Процедура get_report возвращает курсор с данными отчета
   * 
   * @param x_result      - курсор с данными
   * @param x_err_msg     - сообщение об ошибке
   * @param p_report_code - код отчета:
   *                            detail_report   - ежемесячная расшифровка для 6НДФЛ
   *                            detail_report_2 - ежемесячная расшифровка для 6НДФЛ c детализацией по статьям доходов и ставкам налога  
   *                            error_report    - отчет об ошибках коррекций
   *                            ndfl6_part1       - обобщенные показатели раздела 1 формы 6НДФЛ (поля 060, 070, 080, 090)
   *                            ndfl6_part1_rates - обобщенные показатели раздела 1 формы 6НДФЛ по ставкам (поля 010, 020, 030, 040)
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
    l_header_id  ndfl6_headers_t.header_id%type;
    l_start_date date;
    l_end_date   date;
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_start_date := to_date(p_from_date, C_DATE_FMT);
    l_end_date := to_date(p_end_date, C_DATE_FMT);
    --
    if substr(p_report_code, 1, 5) = 'ndfl6' then
      create_header(
        x_header_id  => l_header_id,
        x_start_date => l_start_date,
        x_end_date   => l_end_date
      );
    end if;
    --
    set_period(l_start_date, l_end_date);
    --
    case p_report_code
      when 'detail_report' then
        open x_result for
          select case when r.block_row_num = 1 then to_char(r.operation_date, C_DATE_OUT_FMT) end  operation_date      ,
                 case when r.block_row_num = 1 then to_char(r.transfer_date, C_DATE_OUT_FMT)  end  transfer_date       ,
                 case when r.block_row_num = 1 then r.revenue                                 end  revenue             ,
                 case when r.block_row_num = 1 then r.benefit                                 end  benefit             ,
                 case when r.block_row_num = 1 then r.tax                                     end  tax                 ,
                 to_char(r.correction_date, C_DATE_OUT_FMT)                                        correction_date     ,
                 to_char(r.corrected_date,  C_DATE_OUT_FMT)                                        corrected_date      ,
                 r.corr_revenue,
                 r.corr_benefit,
                 r.corr_tax
          from   ndfl_report_detail_v r
          order  by r.operation_date, r.corrected_date;
      when 'detail_report_2' then
        open x_result for
          select case when block_row_num = 1 then to_char(r.operation_date, C_DATE_OUT_FMT) end operation_date  ,
                 case when block_row_num = 1 then to_char(r.transfer_date, C_DATE_OUT_FMT)  end transfer_date   ,
                 case when block_row_num = 1 then r.charge_type                             end charge_type     ,
                 case when block_row_num = 1 then r.pen_scheme                              end pen_scheme      ,
                 case when block_row_num = 1 then r.revenue_13                              end revenue_13      ,
                 case when block_row_num = 1 then r.benefit_13                              end benefit_13      ,
                 case when block_row_num = 1 then r.tax_13                                  end tax_13          ,
                 case when block_row_num = 1 then r.revenue_30                              end revenue_30      ,
                 case when block_row_num = 1 then r.tax_30                                  end tax_30          ,
                 to_char(r.correction_date, C_DATE_OUT_FMT)                                     correction_date ,
                 to_char(r.corrected_date, C_DATE_OUT_FMT)                                      corrected_date  ,
                 r.corr_revenue_13                                                                              ,
                 r.corr_benefit_13                                                                              ,
                 r.corr_tax_13                                                                                  ,
                 r.corr_revenue_30                                                                              ,
                 r.corr_tax_30
          from   ndfl_report_detail_2_v r
          order  by r.operation_date  ,
                    r.block_num       ,
                    --r.charge_code     ,
                    r.pen_scheme      ,
                    r.corrected_date; --*/
      when 'correcting_report' then
        open x_result for
          select c.corr_quartal,
                 c.corr_mouth,
                 c.corr_data_op,
                 c.corr_ssylka_doc,
                 c.src_year,
                 c.src_quartal,
                 c.src_data_op,
                 c.src_ssylka_doc,
                 c.src_summa,
                 c.correction_sum,
                 c.nom_vkl,
                 c.nom_ips,
                 c.shifr_schet,
                 c.sub_shifr_schet,
                 c.ssylka_fl,
                 c.last_name,
                 c.first_name,
                 c.second_name
          from   ndfl_report_correcting_v c
          order by c.corr_data_op, c.gf_person, c.nom_vkl, c.nom_ips, c.src_data_op, c.shifr_schet, c.sub_shifr_schet;
      when 'error_report' then
        open x_result for
          select r.data_op,
                 r.ssylka_doc,
                 r.nom_vkl,
                 r.nom_ips,
                 r.shifr_schet,
                 r.suB_SHifr_schet,
                 r.correcting_summa,
                 r.corrected_docs,
                 case r.error_code
                   when 1 then
                     'Отсутствует ссылка на корректирующую операцию'
                   when 2 then
                     'Сумма корректирующей операции (' || r.correcting_summa || ') не полностью закрывает сумму корректируемых операций (' || r.corrected_summa || ')'
                 end err_description
          from   ndfl_report_errors_v r
          order by r.nom_vkl, r.nom_ips, r.shifr_schet, r.SUB_SHIFR_SCHET, r.ssylka_doc;
      when 'ndfl6_part1' then
        open x_result for
          select max(c.total_persons)               total_persons,
                 sum(
                   nvl(c.tax_retained, 0) 
                     - nvl(c.tax_returned_prev, 0) 
                     - nvl(c.tax_returned_curr, 0)
                 )                                  tax_retained,
                 null                               tax_not_retained,
                 abs(sum(
                   nvl(c.tax_returned_prev, 0) 
                     + nvl(c.tax_returned_curr, 0)
                 ))                                 tax_returned
          from   ndfl6_calcs_v c
          where  c.header_id = l_header_id;
      when 'ndfl6_part1_rates' then
        open x_result for
          select c.tax_rate          ,
                 c.revenue_amount    ,
                 null                revenue_div_amount,
                 c.benefit           ,
                 c.tax_calc          ,
                 null                tax_calc_div      ,
                 null                advance_amount    
          from   ndfl6_calcs_v c
          where  c.header_id = l_header_id
          order by 
            c.tax_rate;
      when 'employees_report' then
        open x_result for
          with emp_with_revenue as (
            select lin.gf_person,
                   listagg(lin.pen_scheme, ', ') within group (order by lin.pen_scheme) pen_schemes,
                   listagg(
                     case lin.det_charge_type
                       when 'PENSION' then 'Пенсия'
                       when 'BUYBACK' then 'Выкупная сумма'
                       when 'RITUAL'  then 'Ритуальное пособие'
                     end,
                     ', '
                   ) within group (order by lin.det_charge_type) revenue_types,
                   sum(lin.revenue_amount) revenue_amount
            from   ndfl6_lines_t       lin
            where  1=1
            and    lin.header_id = 1
            group by lin.gf_person
          )
          select emp.familiya,
                 emp.imya,
                 emp.otchestvo,
                 emp.data_rozhd,
                 case
                   when emp.gf_person is null then 'Неучастник'
                   else                            'Участник'
                 end participant,
                 case
                   when rev.revenue_amount > 0 then 'Да'
                   else                             'Нет'
                 end is_revenue,
                 rev.pen_schemes,
                 rev.revenue_types
          from   f_ndfl_load_spisrab emp,
                 emp_with_revenue    rev
          where  1=1
          and    rev.gf_person(+) = emp.gf_person
          and    emp.god = 2017
          order by emp.familiya,
                   emp.imya,
                   emp.otchestvo,
                   emp.data_rozhd;
      else
        x_err_msg := 'Неизвестный код отчета: ' || p_report_code;
    end case;
    --
  exception
    when others then
      --
      x_err_msg := nvl(x_err_msg, dbms_utility.format_error_stack || chr(10) || dbms_utility.format_error_backtrace);
      --
  end get_report;
  
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
  
  /**
   * Процедура add_line_tmp добавляет персональные данные в tmp таблицу
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
  procedure add_line(
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
  end add_line;
  
  /**
   *
   * Процедура load_employees запускает загрузку сотрудников из tmp таблицы
   *  в f_ndfl_load_spisrab
   */
  procedure load_employees(
    x_err_msg   out varchar2,
    p_load_date date
  ) is
    l_header_id  ndfl6_headers_t.header_id%type;
    l_start_date date;
    l_end_date   date;
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_end_date := p_load_date;
    create_header(
      x_header_id  => l_header_id ,
      x_start_date => l_start_date,
      x_end_date   => l_end_date  
    );
    --
    zaprvkl_lines_tmp_api.flush_to_table;
    --
    f_ndfl_load_spisrab_api.load_from_tmp(
      p_load_date => p_load_date,
      p_header_id => l_header_id
    );
    --
  exception
    when others then
      fix_exception('load_employees(p_load_date => ' || to_char(p_load_date, 'dd.mm.yyyy'));
      x_err_msg := utl_error_api.get_exception;
  end load_employees;
  
  --
begin
  --
  set_period(
    p_start_date => add_months(trunc(sysdate, 'MM'), -2), ---18),
    p_end_date   => add_months(trunc(sysdate, 'MM'), -1) - 1
  );
  --
  
end ndfl_report_api;
/
