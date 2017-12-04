create or replace package body ndfl_report_api is
  
  --C_DATE_OUT_FMT constant varchar2(20) := 'dd.mm.yyyy';
  
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
   * ������� get_report ���������� ������ � ������� ������
   * 
   * @param p_report_code - ��� ������
   * @param p_from_date   - ���� ������ ������� � ������� YYYYMMDD
   * @param p_end_date    - ���� ��������� ������� � ������� YYYYMMDD
   *
   */
  function get_report(
    p_report_code   varchar2,
    p_end_date      date
  ) return sys_refcursor is
    --
    l_result      sys_refcursor;
    l_report_code varchar2(100);
    --
  begin
    --
    l_report_code := p_report_code;
    dv_sr_lspv_docs_api.set_period(p_end_date);
    if p_report_code = 'tax_diff_det_report' then
      dv_sr_lspv_docs_api.set_is_buff;
    else
      dv_sr_lspv_docs_api.unset_is_buff;
      if l_report_code = 'tax_diff_det_report2' then
        l_report_code := 'tax_diff_det_report';
      end if;
    end if;
    --
    case l_report_code
      when 'synch_error_report' then
        open l_result for
          select case when e.type_op = -1 then '���������' end type_op,
                 substr(e.date_op, 1, 10) date_op,
                 e.ssylka_doc_op,
                 substr(e.date_doc, 1, 10) date_doc,
                 e.ssylka_doc,
                 e.ssylka_fl,
                 e.nom_vkl,
                 e.nom_ips,
                 e.gf_person,
                 e.det_charge_type,
                 e.ora_err_mesg$,
                 e.process_id
          from   err$_dv_sr_lspv_docs_t e
          where  e.process_id in (
            select p.id
            from   dv_sr_lspv_prc_t p
            order by p.created_at desc
            fetch first rows only
          );
      when 'ndfl2_tax_corr' then
        open l_result for
          select case 
                   when coalesce(c.spr_revenue_corr, 0) - coalesce(c.revenue_corr, 0) > .01  or
                        coalesce(c.spr_tax_corr, 0) - coalesce(c.tax_corr, 0) > .01 then '��������� �������������� �������'
                   when c.exists_xml = 'N' then '��������� ������� �� ����������'
                 end state,
                 c.kod_na,
                 c.year_doc,
                 c.gf_person,
                 c.year_doc,
                 c.gf_person, 
                 c.fio, 
                 c.spr_nom, 
                 c.spr_corr_num, 
                 c.spr_date, 
                 c.spr_revenue, 
                 c.spr_tax, 
                 c.spr_revenue_corr,
                 c.spr_tax_corr, 
                 c.revenue_corr, 
                 c.tax_corr
          from   ndfl2_corr_spr_rep_v c
          order by c.fio, c.year_doc;
      when 'tax_retained_report' then
        open l_result for
          select dc.describe || ', ����� ' || ps.name payment_descr,
                 d.tax_retained_13,
                 d.tax_retained_30,
                 null                                 dummy_col,
                 d.tax_wo_corr_13,
                 d.tax_corr_13,
                 d.tax_wo_corr_30,
                 d.tax_corr_30
          from   ndfl_report_tax_retained_v d,
                 sp_det_charge_types_v      dc,
                 sp_pen_schemes_v           ps
          where  1=1
          and    ps.code(+) = d.pen_scheme_code
          and    dc.det_charge_type = d.det_charge_type
          order by 
            case d.det_charge_type when 'PENSION' then 1 when 'RITUAL' then 2 else 3 end,
            d.pen_scheme_code;
      when 'tax_retained_report2' then
        open l_result for
          select 'TAX_RETAINED_DATE' key, (select sum(d.tax_retained) from ndfl6_part2_v d)     value from dual union all
          select 'TAX_NOT_RETAINED'  key, (select sum(d.tax_diff) from dv_sr_lspv_tax_diff_v d) value from dual union all
          select 'TAX_RETURN'        key, (select d.tax_return from ndfl6_part1_general_v d)    value from dual union all
          select 'TAX_RETURN_83'     key, (select sum(d.amount) from dv_sr_lspv_83_v d)           value from dual;
      when 'detail_report' then
        open l_result for
          select r.date_op,
                 case when r.first_row = 'Y' and r.revenue > 0 then r.date_op + 1 end transfer_date,
                 case r.first_row when 'Y' then r.revenue       end revenue      ,
                 case r.first_row when 'Y' then r.benefit       end benefit      ,
                 case r.first_row when 'Y' then r.tax           end tax          ,
                 r.date_op                                          date_op_corr ,
                 r.date_corr,
                 r.revenue_corr,
                 r.benefit_corr,
                 r.tax_corr
          from   ndfl6_report_detail_v r
          where  1 = 1
          order by r.date_op,
                   r.date_corr;
      when 'detail_report_2' then
        open l_result for
          select r.date_op,
                 case when r.first_row = 'Y' and coalesce(tax13, 0) + coalesce(tax30, 0) <> 0 then r.date_op + 1     end date_transfer,
                 r.det_charge_describe,
                 r.pen_scheme,
                 case r.first_row when 'Y' then r.revenue13       end revenue13      ,
                 case r.first_row when 'Y' then r.benefit13       end benefit13      ,
                 case r.first_row when 'Y' then r.tax13           end tax13          ,
                 case r.first_row when 'Y' then r.revenue30       end revenue30      ,
                 case r.first_row when 'Y' then r.tax30           end tax30          ,
                 r.date_op                                            date_op_corr   ,
                 r.date_corr,
                 r.revenue13_corr,
                 r.benefit13_corr,
                 r.tax13_corr,
                 r.revenue30_corr,
                 r.tax30_corr
          from   ndfl6_report_detail2_v r
          order by r.date_op,
                   r.det_charge_ord_num, 
                   r.pen_scheme, 
                   r.date_corr;
      when 'correcting_report' then
        open l_result for
          select c.quarter_op,
                 c.month_op,
                 c.date_op,
                 c.ssylka_doc_op,
                 c.year_doc,
                 c.quarter_doc,
                 c.date_doc,
                 c.ssylka_doc,
                 c.source_amount,
                 c.amount,
                 c.nom_vkl,
                 c.nom_ips,
                 c.shifr_schet,
                 c.sub_shifr_schet,
                 c.ssylka,
                 c.last_name,
                 c.first_name,
                 c.second_name
          from   ndfl6_report_correcting_v c
          where  coalesce(c.amount, 0) <> 0
          order by c.date_op, c.last_name, c.first_name, c.second_name, c.nom_vkl, c.nom_ips, c.date_doc, c.shifr_schet, c.sub_shifr_schet;
      when 'error_report' then
        open l_result for
          select r.date_op,
                 r.ssylka_doc,
                 r.nom_vkl,
                 r.nom_ips,
                 r.shifr_schet,
                 r.sub_shifr_schet,
                 r.amount,
                 case r.error_code
                   when 1 then
                     '����������� ������ �� �������������� ��������'
                   when 2 then
                     '����� �������������� �������� (' || r.amount || ') �� ��������� ��������� ����� �������������� �������� (' || r.source_amount || ')'
                   when 3 then
                     '�� ��������� GF_PERSON ��������� (��. sp_fiz_lits_non_ident_v)'
                   when 4 then
                     '�� ��������� GF_PERSON ���������� ������� (��. vyplach_posob_non_ident_v)'
                   when 5 then
                     '������ ��� ����� ������� ������� �� ������ �����������'
                   when 6 then
                     '������������ ������: ' ||
                     case
                       when bitand(power(2, 0), r.error_sub_code) > 0 then '���'
                     end || ', ' ||
                     case
                       when bitand(power(2, 1), r.error_sub_code) > 0 then '��'
                     end || ', ' ||
                     case
                       when bitand(power(2, 2), r.error_sub_code) > 0 then '���'
                     end || ', ' ||
                     case
                       when bitand(power(2, 3), r.error_sub_code) > 0 then '������ ���������'
                     end
                 end err_description,
                 r.fio
          from   dv_sr_lspv_errors_v r
          order by r.error_code, r.gf_person, r.nom_vkl, r.nom_ips, r.shifr_schet, r.SUB_SHIFR_SCHET, r.ssylka_doc;
      when 'tax_diff_report' then
        open l_result for
          select d.gf_person,
                 p.lastname, 
                 p.firstname, 
                 p.secondname, 
                 d.tax_rate,
                 d.accounts_cnt,
                 d.tax_calc,
                 d.tax_retained
          from   dv_sr_lspv_tax_diff_v d,
                 gf_people_v       p
          where  1=1
          and    p.fk_contragent = d.gf_person
          order by d.tax_diff;
      when 'tax_diff_det_report' then
        open l_result for
          select d.gf_person,
                 d.lastname, 
                 d.firstname, 
                 d.secondname,
                 d.ssylka_fl,
                 d.nom_vkl,
                 d.nom_ips, 
                 d.pen_scheme,
                 d.revenue_shifr_schet,
                 d.tax_shifr_schet,
                 d.revenue, 
                 d.benefit, 
                 d.tax,
                 case row_number()over(partition by d.gf_person order by d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips)
                   when 1 then d.tax_retained
                 end tax_retained,
                 case row_number()over(partition by d.gf_person order by d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips)
                   when 1 then d.tax_calc
                 end tax_calc, 
                 case row_number()over(partition by d.gf_person order by d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips)
                   when 1 then d.tax_diff
                 end tax_diff
          from   dv_sr_lspv_tax_diff_det_v d
          order by d.gf_person, d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips;
      when 'tax_diff_from_buf' then
        open l_result for
          select d.gf_person,
                 d.lastname, 
                 d.firstname, 
                 d.secondname,
                 d.ssylka_fl,
                 d.nom_vkl,
                 d.nom_ips, 
                 d.pen_scheme,
                 d.revenue_shifr_schet,
                 d.tax_shifr_schet,
                 d.revenue, 
                 d.benefit, 
                 d.tax,
                 d.tax_retained,
                 d.tax_calc, 
                 d.tax_diff
          from   DV_SR_LSPV_TAX_DIFF_BUF d
          order by d.gf_person, d.pen_scheme, d.nom_vkl, d.nom_ips;
      when 'ndfl6_part1_general_data' then
        open l_result for
          select d.total_persons,
                 d.tax_retained,
                 null tax_not_retained,
                 d.tax_return
          from   ndfl6_part1_general_v d;
      when 'ndfl6_recalc_curr_year' then
        open l_result for
          select t.det_charge_describe || ' ��. ' || t.pen_scheme describe,
                 abs(t.tax_returned) tax_returned
          from   ndfl6_tax_returns_v t
          where  t.current_year = 'Y'
          order  by t.det_charge_ord_num, t.pen_scheme;
      when 'ndfl6_recalc_prev_year' then
        open l_result for
          select t.det_charge_describe || ' ��. ' || t.pen_scheme describe,
                 abs(t.tax_returned) tax_returned
          from   ndfl6_tax_returns_v t
          where  t.current_year = 'N'
          order  by t.det_charge_ord_num, t.pen_scheme;
      when 'ndfl6_part1_rates_data' then
        /*
        TODO: owner="V.Zhuravov" category="Optimize" priority="1 - High" created="28.08.2017"
        text="���������� ������"
        */
        open l_result for
          select d.tax_rate,
                 sum(d.revenue)  revenue       ,
                 null            revenue_div   ,
                 sum(d.benefit)  benefit       ,
                 sum(d.tax_calc) tax_calc      ,
                 null            tax_calc_div  ,
                 null            advance_amount
          from   dv_sr_lspv_pers_v d
          group by d.tax_rate
          order by d.tax_rate;
      when 'ndfl6_part1_rates_13_wo_bb' then
        open l_result for
          select t.det_charge_describe,
                 t.pen_scheme,
                 t.revenue,
                 nvl(t.storno_total, 0) storno_total ,
                 nvl(t.storno_q1,    0) storno_q1    ,
                 nvl(t.storno_q2,    0) storno_q2    ,
                 nvl(t.storno_q3,    0) storno_q3    ,
                 nvl(t.storno_q4,    0) storno_q4
          from   ndfl6_part1_rates_13_wo_bb_v t
          order by t.det_charge_ord_num, t.pen_scheme_code;
      when 'ndfl6_part1_rates_13_bb' then
        open l_result for
          select case when row_number()over(order by d.pen_scheme_code) = 1 then d.det_charge_describe end det_charge_describe,
                 d.pen_scheme,
                 d.revenue,
                 d.fix_revenue,
                 nvl(d.source_revenue, 0)   source_revenue,
                 nvl(d.corr_revenue,   0)   corr_revenue,
                 nvl(d.source_revenue, 0) + 
                   nvl(d.corr_revenue, 0) 
                                            diff_revenue,
                 nvl(d.revenue_prev_year,0) revenue_prev_year
          from   ndfl6_part1_rates_13_bb_v d
          order by d.pen_scheme_code;
      when 'ndfl6_part1_rates_30' then
        open l_result for
          select d.det_charge_describe,
                 d.pen_scheme,
                 d.revenue,
                 d.tax_calc,
                 case
                   when d.tax_diff <> 0 then
                     case 
                       when d.tax_diff < 1 then
                         '���������'
                       when d.tax_diff > -1 then
                         '���������'
                     end || ': ' || to_char(abs(d.tax_diff)) || ' ���., ��. ����'
                 end diff_descr
          from   ndfl6_part1_rates_30_v d
          order by d.det_charge_ord_num, d.pen_scheme_code;
      when 'ndfl6_part1_rates_persn' then
        open l_result for
          select gp.lastname,
                 gp.firstname,
                 gp.secondname,
                 gp.tax_calc,
                 gp.tax_retained,
                 gp.tax_diff
          from   ndfl6_part1_rates_30_persns_v gp
          order by gp.lastname,
                   gp.firstname,
                   gp.secondname;
      when 'ndfl6_part2_data' then
        open l_result for
          select d.date_doc,
                 d.revenue,
                 d.tax_retained
          from   ndfl6_part2_v d
          where  coalesce(d.revenue, 0) > 0 or + coalesce(d.tax_retained, 0) > 0
          order by d.date_doc;
      when 'ndfl6_employees_report' then
        open l_result for
          with emp_with_revenue as (
            select p.gf_person,
                   listagg(dc.describe, ', ') within group(order by dc.order_num) revenue_types,
                   sum(p.revenue) revenue
            from   dv_sr_lspv_docs_pers_v p,
                   sp_det_charge_types_v  dc
            where  dc.det_charge_type(+) = p.det_charge_type
            group  by p.gf_person
            having sum(p.revenue) <> 0
          )
          select emp.familiya,
                 emp.imya,
                 emp.otchestvo,
                 emp.data_rozhd,
                 emp.inn_fl,
                 case
                    when emp.gf_person is not null and exists
                           (select 1
                            from   fnd.sp_fiz_lits sfl
                            where  upper(sfl.familiya) = upper(emp.familiya)
                            and    sfl.gf_person = emp.gf_person
                           ) then
                     '��������'
                    else
                     '����������'
                  end participant,
                 case
                    when rev.revenue > 0 then
                     '��'
                    else
                     '���'
                  end is_revenue,
                 (select listagg(ps.pen_scheme, ', ') within group(order by ps.pen_scheme)
                  from   (select fl.gf_person, fl.pen_scheme
                          from   sp_fiz_litz_lspv_v fl
                          where  fl.gf_person = emp.gf_person
                          and    upper(fl.last_name) = upper(emp.familiya)
                          and    fl.pen_scheme_code <> 7
                          group  by fl.gf_person, fl.pen_scheme) ps) pen_schemes,
                 rev.revenue_types
          from   f_ndfl_load_spisrab emp, 
                 emp_with_revenue    rev
          where  1 = 1
          and    rev.gf_person(+) = emp.gf_person
          and    emp.god = extract(year from p_end_date)
          order  by emp.familiya, emp.imya, emp.otchestvo, emp.data_rozhd;
      else
        fix_exception('get_report('||l_report_code || '): ����������� ��� ������');
        raise utl_error_api.G_EXCEPTION;
    end case;
    --
    return l_result;
    --
  exception
    when others then
      --
      fix_exception;
      raise;
      --x_err_msg := nvl(x_err_msg, dbms_utility.format_error_stack || chr(10) || dbms_utility.format_error_backtrace);
  end get_report;
  
end ndfl_report_api;
/
