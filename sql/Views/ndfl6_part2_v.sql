create or replace view ndfl6_part2_v as
  with op_corr as (
    select /*+ MATERIALIZE*/
           dc.data_op, 
           dc.nom_vkl, 
           dc.nom_ips, 
           dc.ssylka_doc,
           dc.shifr_schet, 
           dc.sub_shifr_schet,
           dc.charge_type,
           sum(dc.summa) summa
    from   ndfl_dv_sr_lspv_corr_v dc
    where  1=1 --берем только исходные операции за период
    and    dc.data_op between ndfl_report_api.get_start_date and ndfl_report_api.get_end_date
    and    dc.is_leaf = 1
    group by dc.nom_vkl, 
             dc.nom_ips, 
             dc.data_op, 
             dc.shifr_schet, 
             dc.sub_shifr_schet,
             dc.ssylka_doc,
             dc.charge_type
  ),
  part2 as (
  select d.data_op,
         sum(case when d.charge_type = 'REVENUE' then d.summa + nvl(c.summa, 0) end) revenue,
         sum(
           case 
             when d.charge_type = 'TAX' then 
               case 
                 when abs(d.summa) = abs(c.summa) then 0 --сторно не учитываем
                 else d.summa                            --если корректировка налога - она пишется в поле 90, в раздел2 выводится исходная сумма
               end
           end
         ) tax
  from   ndfl_dv_sr_lspv_v      d,
         op_corr                c
  where  1=1
  --  подтягиваем корректировку
  and    c.nom_vkl         (+) = d.nom_vkl        
  and    c.nom_ips         (+) = d.nom_ips        
  and    c.data_op         (+) = d.data_op        
  and    c.shifr_schet     (+) = d.shifr_schet    
  and    c.sub_shifr_schet (+) = d.sub_shifr_schet
  and    c.ssylka_doc      (+) = d.ssylka_doc     
  and    c.charge_type     (+) = d.charge_type    
  -- берем тока доход и налог
  and    d.charge_type in ('REVENUE', 'TAX')
  -- отсекаем корректирующие операции
  and    d.is_correction    = 'N'
  and    d.service_doc      >= 0
  group by d.data_op
  )
  select p.data_op,
         p.revenue,
         p.tax
  from   part2 p
  where  p.revenue <> 0 or p.tax <> 0
/
