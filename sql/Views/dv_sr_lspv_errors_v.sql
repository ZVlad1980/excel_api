create or replace view dv_sr_lspv_errors_v as
  /*with corrections as (
    select c.date_op, 
           c.ssylka_doc_op, 
           c.date_doc, 
           c.ssylka_doc, 
           c.nom_vkl, 
           c.nom_ips, 
           c.charge_type, 
           c.det_charge_type, 
           c.shifr_schet, 
           c.sub_shifr_schet, 
           c.sub_shifr_grp, 
           c.tax_rate, 
           c.service_doc, 
           c.amount, 
           c.source_op_amount,
           c.type_op, 
           c.corr_op_amount
    from   dv_sr_lspv_corr_v c
    where  c.type_op = -1
  )
  --нет ссылок на корректирующую операцию
  select dc.date_op,
         dc.ssylka_doc_op ssylka_doc,
         dc.nom_vkl,
         dc.nom_ips,
         dc.shifr_schet,
         dc.SUB_SHIFR_SCHET,
         dc.amount,
         null source_amount,
         null ssylka_fl,
         cast(null as varchar2(200)) fio,
         1 error_code,
         null error_sub_code,
         null gf_person
  from   corrections dc
  where  dc.type_op = -1
  and    dc.ssylka_doc_op = dc.ssylka_doc
 union all
  --сумма коррекции не соответствует сумме исходных операций (для двойных цепочек)
  select dc.date_op,
         dc.ssylka_doc_op ssylka_doc,
         dc.nom_vkl,
         dc.nom_ips,
         dc.shifr_schet,
         dc.SUB_SHIFR_SCHET,
         max(dc.corr_op_amount)    amount,
         sum(dc.source_op_amount)  source_amount,
         null ssylka_fl,
         null fio,
         2 error_code,
         null error_sub_code,
         null gf_person
  from   corrections dc
  where  dc.charge_type <> 'BENEFIT' --отключил проверку по вычетам, т.к. они не всегда кратны
  and    dc.type_op = -1
  group by dc.date_op, dc.ssylka_doc_op, dc.nom_vkl, dc.nom_ips, dc.shifr_schet, dc.sub_shifr_schet
  having count(1) > 1 and abs(sum(dc.source_op_amount)) <> abs(max(dc.corr_op_amount))
 */
  select dd.date_op                                                    date_op,
         dd.ssylka_doc                                                 ssylka_doc,
         dd.nom_vkl,
         dd.nom_ips,
         dd.shifr_schet                                                shifr_schet, 
         dd.sub_shifr_schet                                            sub_shifr_schet,
         dd.amount                                                      amount, 
         null                                                          source_amount,
         fl.ssylka                                                     ssylka_fl,
         fl.last_name || ' ' || fl.first_name || ' ' || fl.second_name fio,
         2                                                             error_code,
         null                                                          error_sub_code,
         null                                                          gf_person
  from   dv_sr_lspv_acc_v dd,
         lateral(
           select sfl.ssylka,
                  sfl.last_name,
                  sfl.first_name,
                  sfl.second_name
           from   sp_fiz_litz_lspv_v sfl
           where  sfl.nom_vkl = dd.nom_vkl
           and    sfl.nom_ips = dd.nom_ips
         ) fl
  where  1=1
  and    dd.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_report_date
  and    (
           (--коррекция без привязки к исходной операции
              dd.shifr_schet in (55, 60, 62) and
              dd.service_doc = -1            and
              not exists (
                select 1 
                from   dv_sr_lspv ddd
                where  ddd.nom_vkl = dd.nom_vkl
                and    ddd.nom_ips = dd.nom_ips
                and    ddd.service_doc = dd.ssylka_doc
                and    ddd.shifr_schet = dd.shifr_schet
                and    ddd.sub_shifr_schet = dd.sub_shifr_schet
              )
          ) 
          or
          (--отрицательная сумма по прямой операции!
             dd.shifr_schet in (55, 60) and
             dd.service_doc = 0 and
             dd.amount < 0
          )
          or
          (--возврат налога по выкупной без коррекции дохода!
             dd.shifr_schet = 85           and
             dd.sub_shifr_schet in (2, 3)  and
             dd.service_doc = -1           and
             not exists (
               select 1 
               from   dv_sr_lspv ddd
               where  ddd.summa <> 0
               and    ddd.nom_vkl = dd.nom_vkl
               and    ddd.nom_ips = dd.nom_ips
               and    ddd.ssylka_doc = dd.ssylka_doc
               and    ddd.shifr_schet = 55
               and    ddd.sub_shifr_schet = 0
             )
          ) 
        )
 union all
 /*
 TODO: owner="V.Zhuravov" created="12.12.2017"
 text="Перевести следующие два запроса на таблицу DV_SR_GF_PERSONS_T"
 */ -- не идентифицированные участники
  select null                                                          date_op,
         null                                                          ssylka_doc,
         fl.nom_vkl,
         fl.nom_ips,
         null                                                          shifr_schet, 
         null                                                          sub_shifr_schet,
         null                                                          amount, 
         null                                                          source_amount,
         fl.ssylka                                                     ssylka_fl,
         fl.familiya || ' ' || fl.imya || ' ' || fl.otchestvo          fio,
         3                                                             error_code,
         null                                                          error_sub_code,
         null                                                          gf_person
  from   sp_fiz_lits_non_ident_v fl
 union all
  -- не идентифицированные получатели пособий
  select null date_op,
         vp.ssylka_doc,
         vp.nom_vkl,
         vp.nom_ips,
         null,
         null,
         null,
         null,
         vp.ssylka ssylka_fl,
         vp.fio,
         4 error_code,
         null error_sub_code,
         null gf_person
  from   vyplach_posob_non_ident_v vp
 union all
  -- вторые получатели пособий
  select rr.data_vypl,
         rr.ssylka_doc,
         rr.nom_vkl,
         rr.nom_ips,
         null,
         null,
         null,
         null,
         rr.ssylka_fl ssylka_fl,
         rr.fio,
         5 error_code,
         null error_sub_code,
         null gf_person
  from   vyplach_posob_receivers_v rr
  where  1 = 1
  and    rr.nom_vipl > 1
 union all
  --контрагенты с разными ФИО, ДР, ИНН, резидентсво с одинаковым GF_PERSON
  select null data_vypl,
         null ssylka_doc,
         d.nom_vkl,
         d.nom_ips,
         null,
         null,
         null,
         null,
         d.ssylka_fl ssylka_fl,
         cast(d.fio || ' (' || to_char(d.birth_date, 'dd.mm.yyyy') || '), ИНН: ' ||
           d.inn || ', ' || case d.resident when 1 then 'резидент' when 2 then 'не резидент' else 'не определен: ' || d.resident end
          as varchar2(200)) fio,
         6 error_code,
         d.diff_sum error_sub_code,
         d.gf_person
  from   sp_fiz_lits_diff_v d
 union all
  select da.date_op,
         da.ssylka_doc,
         da.nom_vkl,
         da.nom_ips,
         da.shifr_schet,
         da.SUB_SHIFR_SCHET,
         da.amount,
         null source_amount,
         null ssylka_fl,
         cast(null as varchar2(200)) fio,
         7 error_code,
         null error_sub_code,
         null gf_person
  from   dv_sr_lspv_acc_v da
  where  1=1
  and    da.service_doc = 0
  and    da.charge_type = 'REVENUE'
  and    da.det_charge_type in ('PENSION', 'RITUAL')
  and    da.amount < 0
  and    da.date_op between dv_sr_lspv_docs_api.get_start_date and dv_sr_lspv_docs_api.get_end_date
 union all
  -- Ошибки программы UPDATE_GF_PERSONS (последний запуск)
  select null date_op,
         null ssylka_doc,
         gp.nom_vkl,
         gp.nom_ips,
         null,
         null,
         null,
         null,
         gp.ssylka ssylka_fl,
         null fio,
         8 error_code,
         null error_sub_code,
         gp.gf_person_old gf_person
  from   dv_sr_gf_persons_t gp
  where  1=1
  and    gp.gf_person_new is null
  and    gp.process_id = (
           select p.id
           from   dv_sr_lspv_prc_t p
           where  p.process_name = 'UPDATE_GF_PERSONS'
           order by p.created_at desc
           fetch first rows only
         )
/
