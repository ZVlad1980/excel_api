create or replace package body ndfl_report_api is
  
  C_DATE_FMT     constant varchar2(20) := 'dd.mm.yyyy';
  C_DATE_OUT_FMT constant varchar2(20) := 'dd.mm.yyyy';

  g_start_date date;
  g_end_date   date;

  function get_start_date return date deterministic is begin return g_start_date; end;
  function get_end_date   return date deterministic is begin return g_end_date; end;
  
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
   * Процедура get_report возвращает курсор с данными отчета
   * 
   * @param x_result      - курсор с данными
   * @param x_err_msg     - сообщение об ошибке
   * @param p_report_code - код отчета:
   *                            detail_report   - ежемесячная расшифровка для 6НДФЛ
   *                            detail_report_2 - ежемесячная расшифровка для 6НДФЛ c детализацией по статьям доходов и ставкам налога  
   *                            error_report    - отчет об ошибках коррекций
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
    set_period(to_date(p_from_date, C_DATE_FMT), to_date(p_end_date, C_DATE_FMT));
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
      else
        x_err_msg := 'Неизвестный код отчета: ' || p_report_code;
    end case;
    --
  exception
    when others then
      x_err_msg := nvl(x_err_msg, dbms_utility.format_error_stack || chr(10) || dbms_utility.format_error_backtrace);
      --
  end get_report;
  
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
