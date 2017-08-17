create or replace package body ndfl_report_api is
  
  C_DATE_FMT     constant varchar2(20) := 'dd.mm.yyyy';
  C_DATE_OUT_FMT constant varchar2(20) := 'dd.mm.yyyy';
  
  -- ������ �������� ��� ������
  C_SRC_CHR  constant varchar2(200) := 'AOPEHBCXMK';
  C_DEST_CHR constant varchar2(200) := '����������';
  
  g_start_date date;
  g_end_date   date;
  
  function get_start_date return date deterministic is begin return g_start_date; end;
  function get_end_date   return date deterministic is begin return g_end_date; end;
  
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
   * ��������� set_period ������������� ������ ������� ��� ������������� ndfl_dv_sr_lspv_v
   *
   * @param p_start_date - ���� ������ ������� (��������� �� ������ �����)
   * @param p_end_date   - ���� ��������� �������
   *             ���� ���� ��������� �� ������ - ��������������� �� p_start_date �� ����� �����
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
    x_end_date   in out nocopy date,
    p_is_force   in boolean default false
  ) is
  begin
    --
    x_end_date   := add_months(trunc(x_end_date, 'MM'), 1) - 1;
    x_start_date := trunc(x_end_date, 'Y'); --��� 6���� ������ � ������ ���� �� ����� ��������� ������
    --
    ndfl6_headers_api.create_header(
      x_header_id  => x_header_id,
      p_start_date => x_start_date,
      p_end_date   => x_end_date,
      p_is_force   => p_is_force
    );
    --
    commit;
    --
  exception
    when others then
      fix_exception;
      raise;
  end create_header;
  
  /**
   *
   */
  procedure ndfl_prepare_data(
    x_err_msg    out varchar2,
    p_end_date   in  varchar2
  ) is
    l_header_id   ndfl6_headers_t.header_id%type;
    l_start_date  date;
    l_end_date    date;
  begin
    l_end_date := to_date(p_end_date, C_DATE_FMT);
    create_header(
      x_header_id  => l_header_id,
      x_start_date => l_start_date,
      x_end_date   => l_end_date,
      p_is_force   => true
    );
    --
  exception
    when others then
      --
      fix_exception;
      x_err_msg := nvl(x_err_msg, dbms_utility.format_error_stack || chr(10) || dbms_utility.format_error_backtrace);
      --
  end ndfl_prepare_data;
  
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
                 to_char(r.corrected_date,  C_DATE_OUT_FMT)                                        corrected_date      ,
                 to_char(r.correction_date, C_DATE_OUT_FMT)                                        correction_date     ,
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
                 to_char(r.corrected_date, C_DATE_OUT_FMT)                                      corrected_date  ,
                 to_char(r.correction_date, C_DATE_OUT_FMT)                                     correction_date ,
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
                     '����������� ������ �� �������������� ��������'
                   when 2 then
                     '����� �������������� �������� (' || r.correcting_summa || ') �� ��������� ��������� ����� �������������� �������� (' || r.corrected_summa || ')'
                 end err_description
          from   ndfl_report_errors_v r
          order by r.nom_vkl, r.nom_ips, r.shifr_schet, r.SUB_SHIFR_SCHET, r.ssylka_doc;
      when 'ndfl6_part1_general_data' then
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
      when 'ndfl6_part1_rates_data' then
        open x_result for
          select c.tax_rate,
                 sum(c.revenue_amount) revenue_amount     ,
                 null                  revenue_div_amount ,
                 sum(c.benefit)        benefit            ,
                 sum(c.tax_calc)       tax_calc           ,
                 null                  tax_calc_div       ,
                 null                  advance_amount
          from   ndfl6_calcs_v c
          where  c.header_id = l_header_id
          group  by c.tax_rate
          order  by c.tax_rate;
      when 'ndfl6_part1_rates_13_wo_bb' then
        open x_result for
          select case t.det_charge_type
                   when 'PENSION' then
                     '������'
                   else
                     '��������'
                 end det_charge_type,
                 t.pen_scheme,
                 sum(t.revenue_amount) revenue,
                 sum(nvl(t.rev_corr_q1, 0) + nvl(t.rev_corr_q2, 0) + nvl(t.rev_corr_q3, 0) + nvl(t.rev_corr_q4, 0)) year,
                 nvl(sum(t.rev_corr_q1), 0)    q1,
                 nvl(sum(t.rev_corr_q2), 0)    q2,
                 nvl(sum(t.rev_corr_q3), 0)    q3,
                 nvl(sum(t.rev_corr_q4), 0)    q4
          from   ndfl6_lines_t t
          where  1=1
          and    t.det_charge_type in ('PENSION', 'RITUAL')
          and    t.tax_rate = 13
          and    t.header_id = l_header_id
          group by t.det_charge_type, t.pen_scheme
          order by t.det_charge_type, t.pen_scheme;
      when 'ndfl6_part1_rates_13_bb' then
        open x_result for
          select case rn
                   when 1 then
                     case c.det_charge_type 
                       when 'BUYBACK' then
                         '�������� �����'
                     end
                 end                              det_charge_type,
                 c.pen_scheme     ,
                 nvl(c.revenue, 0)                revenue,
                 nvl(c.revenue, 0) - 
                   nvl(c.rev_corr_curr_year, 0)   source_summa,
                 nvl(c.rev_source, 0)             rev_source,
                 nvl(c.rev_corr_curr_year, 0)     rev_corr_curr_year,
                 nvl(c.rev_source, 0) + 
                   nvl(c.rev_corr_curr_year, 0)   diff,
                 nvl(c.rev_corr_prev, 0)          rev_corr_prev
          from   (
                    select row_number()over(partition by t.det_charge_type order by t.det_charge_type) rn,
                           t.det_charge_type,
                           t.pen_scheme,
                           sum(t.revenue_amount) revenue,
                           null                  empty,
                           sum(rev_source)       rev_source,
                           sum(nvl(t.rev_corr_q1, 0) + nvl(t.rev_corr_q2, 0) + nvl(t.rev_corr_q3, 0) + nvl(t.rev_corr_q4, 0)) rev_corr_curr_year,
                           sum(rev_corr_prev) rev_corr_prev
                    from   ndfl6_lines_t t
                    where  1=1
                    and    t.det_charge_type in ('BUYBACK')
                    and    t.tax_rate = 13
                    and    t.header_id = l_header_id
                    group by t.det_charge_type, t.pen_scheme
                 ) c
          order by c.det_charge_type, c.pen_scheme;
      when 'ndfl6_part1_rates_30' then
        open x_result for
          select case rn
                   when 1 then
                     case c.det_charge_type 
                       when 'PENSION' then
                         '������'
                       when 'RITUAL' then
                         '��������'
                       when 'BUYBACK' then
                         '�������� �����'
                     end
                 end det_charge_type,
                 c.pen_scheme     ,
                 c.revenue ,
                 c.tax_calc,
                 case
                   when c.tax_calc - c.tax_retained <> 0 then
                     case 
                       when c.tax_calc - c.tax_retained > 1 then
                         '���������'
                       when c.tax_calc - c.tax_retained < -1 then
                         '���������'
                     end || ': ' || to_char(c.tax_calc - c.tax_retained) || ' ���., ��. ����'
                 end diff_descr
          from   (
                    select row_number()over(partition by t.det_charge_type order by t.det_charge_type) rn,
                           t.det_charge_type,
                           t.pen_scheme,
                           sum(t.revenue_amount) revenue,
                           sum(t.tax_calc)       tax_calc,
                           sum(t.tax_retained)   tax_retained
                    from   ndfl6_lines_t t
                    where  1=1
                    and    t.header_id = l_header_id
                    and    t.tax_rate = 30
                    group by t.det_charge_type, t.pen_scheme
                 ) c
          order by c.det_charge_type, c.pen_scheme;
      when 'ndfl6_part1_rates_persn' then
        open x_result for
          select --gp.fk_contragent gf_person,
                 gp.lastname,
                 gp.firstname,
                 gp.secondname,
                 p.tax_calc,
                 p.tax_retained,
                 p.tax_calc - p.tax_retained tax_diff
          from   (select p.gf_person,
                         sum(p.tax_retained) tax_retained,
                         sum(p.tax_calc) tax_calc
                  from   ndfl6_persons_v p
                  where  header_id = l_header_id
                  and    p.tax_rate = 30
                  group  by p.gf_person) p,
                 gazfond.people          gp
          where  1 = 1
          and    gp.fk_contragent = p.gf_person
          and    p.tax_calc <> p.tax_retained
          order  by gp.lastname, gp.firstname, gp.secondname;
      when 'ndfl6_part2_data' then
        open x_result for
          select p.data_op,
                 p.revenue,
                 p.tax
          from   ndfl6_part2_v p
          order by p.data_op;
      when 'ndfl6_employees_report' then
        open x_result for
          with emp_with_revenue as (
            select lin.gf_person,
                   listagg(
                     case lin.det_charge_type
                       when 'PENSION' then '������'
                       when 'BUYBACK' then '�������� �����'
                       when 'RITUAL'  then '���������� �������'
                     end,
                     ', '
                   ) within group (order by lin.det_charge_type) revenue_types,
                   sum(lin.revenue_amount) revenue_amount
            from   ndfl6_lines_t       lin
            where  1=1
            and    lin.header_id = l_header_id
            group by lin.gf_person
          )
          select emp.familiya,
                 emp.imya,
                 emp.otchestvo,
                 emp.data_rozhd,
                 emp.inn_fl,
                 case
                   when emp.gf_person is not null and
                         exists(select 1 from fnd.sp_fiz_lits sfl where upper(sfl.familiya) = upper(emp.familiya) and sfl.gf_person = emp.gf_person)
                     then
                       '��������'
                   else '����������'
                 end participant,
                 case
                   when rev.revenue_amount > 0 then '��'
                   else                             '���'
                 end is_revenue,
                 (select listagg(ps.pen_scheme, ', ') within group (order by ps.pen_scheme)
                  from   (select fl.gf_person,
                                 fl.pen_scheme
                          from   sp_fiz_litz_lspv_v fl
                          where  fl.gf_person = emp.gf_person
                          and    upper(fl.last_name) = upper(emp.familiya)
                          and    fl.pen_scheme_code <> 7
                          group by fl.gf_person, fl.pen_scheme) ps
                 ) pen_schemes,
                 rev.revenue_types
          from   f_ndfl_load_spisrab emp,
                 emp_with_revenue    rev
          where  1=1
          and    rev.gf_person(+) = emp.gf_person
          and    emp.god = extract(year from l_end_date)
          order by emp.familiya,
                   emp.imya,
                   emp.otchestvo,
                   emp.data_rozhd;
      when 'ndfl6_recalc_curr_year' then
        open x_result for
          with lines as (
            select lin.det_charge_type, lin.pen_scheme,
                   sum(lin.tax_returned_curr) tax_returned_curr
            from   ndfl6_lines_t lin
            where  lin.header_id = l_header_id
            group by lin.det_charge_type, lin.pen_scheme
          )
          select case lin.det_charge_type
                   when 'PENSION' then '������ '
                   when 'BUYBACK' then '���.���.'
                   when 'RITUAL' then  '���.����.'
                   else lin.det_charge_type
                 end || '��.' || lin.pen_scheme,
                 abs(lin.tax_returned_curr) tax_returned_curr
          from   lines lin
          where  lin.tax_returned_curr is not null
          order by lin.det_charge_type, lin.pen_scheme;
      when 'ndfl6_recalc_prev_year' then
        open x_result for
          with lines as (
            select lin.det_charge_type, lin.pen_scheme,
                   sum(lin.tax_returned_prev) tax_returned_prev
            from   ndfl6_lines_t lin
            where  lin.header_id = l_header_id
            group by lin.det_charge_type, lin.pen_scheme
          )
          select case lin.det_charge_type
                   when 'PENSION' then '������ '
                   when 'BUYBACK' then '���.���.'
                   when 'RITUAL' then  '���.����.'
                   else lin.det_charge_type
                 end || '��.' || lin.pen_scheme,
                 abs(lin.tax_returned_prev) tax_returned_prev
          from   lines lin
          where  lin.tax_returned_prev is not null
          order by lin.det_charge_type, lin.pen_scheme;
      else
        x_err_msg := /*
          ndfl_report2_api.request(
            x_result        => x_result     ,
            p_report_code   => p_report_code,
            p_from_date     => p_from_date  ,
            p_end_date      => p_end_date   
          ); --*/'����������� ��� ������: ' || p_report_code;
    end case;
    --
  exception
    when others then
      --
      fix_exception;
      x_err_msg := nvl(x_err_msg, dbms_utility.format_error_stack || chr(10) || dbms_utility.format_error_backtrace);
      --
  end get_report;
  
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
   * ��������� add_line_tmp ��������� ������������ ������ � tmp �������
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
   * ��������� load_employees ��������� �������� ����������� �� tmp �������
   *  � f_ndfl_load_spisrab
   */
  procedure load_employees(
    x_err_msg   out varchar2,
    p_load_date varchar2
  ) is
    l_header_id  ndfl6_headers_t.header_id%type;
    l_start_date date;
    l_end_date   date;
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_end_date := to_date(p_load_date, C_DATE_FMT);
    --
    create_header(
      x_header_id  => l_header_id ,
      x_start_date => l_start_date,
      x_end_date   => l_end_date  
    );
    --
    zaprvkl_lines_tmp_api.flush_to_table;
    --
    f_ndfl_load_spisrab_api.load_from_tmp(
      p_load_date => l_end_date,
      p_header_id => l_header_id
    );
    --
  exception
    when others then
      fix_exception('load_employees(p_load_date => ' || p_load_date);
      x_err_msg := utl_error_api.get_exception;
  end load_employees;
  
  --
begin
  --
  set_period(
    p_start_date => to_date(20170101, 'yyyymmdd'),
    p_end_date   => to_date(20170630, 'yyyymmdd')
  );
  --
  
end ndfl_report_api;
/
