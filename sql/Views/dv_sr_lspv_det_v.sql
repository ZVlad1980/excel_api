create or replace view dv_sr_lspv_det_v as
  select d.date_op,
         d.date_op + 1 transfer_date,
         d.type_op,
         d.date_doc date_corr,
         d.det_charge_type,
         d.pen_scheme_code,
         sum(nvl(d.revenue, 0))                                            revenue,
         sum(d.benefit)                                                    benefit,
         sum(nvl(d.tax,     0))                                            tax,
         sum(case d.tax_rate_op when 13 then nvl(d.revenue, 0) else 0 end) revenue13,
         sum(nvl(d.benefit, 0))                                            benefit13,
         sum(case d.tax_rate_op when 13 then nvl(d.tax,     0) else 0 end) tax13,
         sum(case d.tax_rate_op when 30 then nvl(d.revenue, 0) else 0 end) revenue30,
         sum(case d.tax_rate_op when 30 then nvl(d.benefit, 0) else 0 end) benefit30,
         sum(case d.tax_rate_op when 30 then nvl(d.tax,     0) else 0 end) tax30
  from   dv_sr_lspv_docs_v d
  where  1=1
  group by d.date_op, d.type_op, d.det_charge_type, d.pen_scheme_code, d.date_doc
  having sum(nvl(abs(d.revenue), 0) + nvl(abs(d.benefit), 0) + nvl(abs(d.tax), 0)) <> 0
/
