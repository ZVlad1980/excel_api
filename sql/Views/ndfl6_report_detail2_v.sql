create or replace view ndfl6_report_detail2_v as 
  with r as (
    select nvl(d.date_op, dc.date_op)                 date_op,
           nvl(d.det_charge_type, dc.det_charge_type) det_charge_type,
           nvl(d.pen_scheme_code, dc.pen_scheme_code) pen_scheme_code,
           d.revenue13,
           d.benefit13,
           d.tax13,
           d.revenue30,
           d.tax30,
           dc.date_corr,
           dc.revenue13                               revenue13_corr,
           dc.benefit13                               benefit13_corr,
           dc.tax13                                   tax13_corr,
           dc.revenue30                               revenue30_corr,
           dc.tax30                                   tax30_corr
    from (
    select d.*
    from   dv_sr_lspv_det_v d
    where  d.type_op is null
    ) d
    full outer join (
    select *
    from   dv_sr_lspv_det_v d
    where  d.type_op  = -1
    ) dc
    on  d.date_op = dc.date_op
    and d.det_charge_type = dc.det_charge_type
    and d.pen_scheme_code = dc.pen_scheme_code
  )
    select case row_number() over(
                  partition by 
                    r.date_op, 
                    dc.order_num,
                    ps.name
                    order by r.date_corr
                ) 
             when 1 then 'Y' 
             else 'N' 
           end                  first_row,
           dc.describe          det_charge_describe,
           dc.order_num         det_charge_ord_num,
           ps.name              pen_scheme,
           r.date_op,
           r.det_charge_type,
           r.revenue13,
           r.benefit13,
           r.tax13    ,
           r.revenue30,
           r.tax30    ,
           r.date_op            date_op_corr   ,
           r.date_corr,
           r.revenue13_corr,
           r.benefit13_corr,
           r.tax13_corr,
           r.revenue30_corr,
           r.tax30_corr
    from   r,
           sp_pen_schemes_v      ps,
           sp_det_charge_types_v dc
    where  1 = 1
    and    dc.det_charge_type(+) = r.det_charge_type
    and    ps.code(+) = r.pen_scheme_code
/
