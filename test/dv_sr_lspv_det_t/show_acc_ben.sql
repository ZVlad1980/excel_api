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
