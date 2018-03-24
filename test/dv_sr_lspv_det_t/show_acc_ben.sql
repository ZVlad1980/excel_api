/*
select a.date_op,
             max(case when a.shifr_schet > 1000 then 'Y' end)    benefit_exists,
             max(case when a.shifr_schet = 62 then 'Y' end)      ritual_exists,
             max(
               case 
                 when a.service_doc <> 0 or 
                   (a.shifr_schet <> 85 and
                    a.amount < 0
                   ) 
                   then 'Y' 
               end
             )                                                      corr_exists
      from   dv_sr_lspv#_v a
      where  a.status = 'N'
      group by a.date_op
      order by a.date_op;
*/
begin
  dv_sr_lspv_docs_api.set_period(
    p_start_date  => to_date(20170101,'yyyymmdd'),
    p_end_date    => to_date(20170609,'yyyymmdd'),
    p_report_date => to_date(20170609,'yyyymmdd')
  );
end;
/
select 'BENEFIT',
               b.fk_dv_sr_lspv,
               b.benefit_amount,
               b.benefit_code,
               b.pt_rid,
               b.fk_dv_sr_lspv_trg,
               b.fk_dv_sr_lspv_det,
               null--p_process_id*/
        from   dv_sr_lspv_acc_ben_v b
/*
select b.start_date,
                  b.end_date,
                  b.benefit_code,
                  b.benefit_amount,
                  b.upper_income,
                  b.pt_rid,
                  b.regdate,
                  b.start_month,
                  b.end_month
           from   sp_ogr_benefits_v b
           where  b.nom_vkl = 140
           and    b.nom_ips = 3635
           and    b.shifr_schet in (1021, 1031)
           and    trunc(b.regdate) <= to_date(20180209, 'yyyymmdd')
           and    to_date(20180209, 'yyyymmdd') between b.start_date and b.end_date 
--*/
