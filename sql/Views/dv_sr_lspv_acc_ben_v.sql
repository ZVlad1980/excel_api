create or replace view dv_sr_lspv_acc_ben_v as
  with w_dv_sr_lspv as (
    select case
             when d.amount = 0 then 0 --метка изменения выета в прошлых периодах
             when d.service_doc <> 0 and d.is_parent = 'N' then 3 --сторно!
             when d.amount < 0 
               and exists(
                 select 1
                 from   sp_fiz_litz_lspv_v sfl,
                        sp_tax_residents_v r
                 where  1=1
                 and    r.resident = 'N'
                 and    r.fk_contragent = sfl.gf_person
                 and    sfl.nom_ips = d.nom_ips
                 and    sfl.nom_vkl = d.nom_vkl
               )                                                     then 2 --это смена статуса резидента!
             else                                                         1 --это обычная операция
           end type_op,
           d.id, 
           d.charge_type, 
           d.det_charge_type,
           d.year_op, 
           d.gf_person, 
           d.nom_vkl, 
           d.nom_ips, 
           d.shifr_schet, 
           d.sub_shifr_schet,
           d.date_op, 
           extract(month from d.date_op) month_op,
           d.amount, 
           d.ssylka_doc, 
           d.service_doc, 
           d.process_id, 
           d.status
    from   dv_sr_lspv#_acc_v d
    where  1=1
    and    d.status = 'N'
    and    d.charge_type = 'BENEFIT'
    and    d.date_op = trunc(dv_sr_lspv_docs_api.get_end_date)
    and    d.year_op >= dv_sr_lspv_docs_api.get_year
  )
  select d.type_op,
         d.id                                          fk_dv_sr_lspv,
         case count(distinct b.pt_rid)
                over(partition by d.date_op, 
                                  d.nom_vkl, 
                                  d.nom_ips, 
                                  d.shifr_schet
              )
           when 0 then
             d.amount
           else
            case
              when b.start_month > b.end_month then
               0
              else
               (
                 (least(b.end_month, d.month_op) - b.start_month + 1) *
                  b.benefit_amount - (
                    select coalesce(sum(dt.amount), 0)
                    from   dv_sr_lspv_det_v dt
                    where  dt.year_op = d.year_op
                    and    dt.date_op < d.date_op
                    and    dt.addition_id = b.pt_rid
                    and    dt.detail_type = 'BENEFIT'
                  )
               ) * 
               case 
                 when d.service_doc <> 0 then
                   sign(d.amount)
                 else 1
               end
            end
         end                                           benefit_amount,
         coalesce(b.benefit_code, d.shifr_schet)       benefit_code,
         coalesce(b.pt_rid, -1)                        pt_rid,
         null                                          fk_dv_sr_lspv_trg,
         null                                          fk_dv_sr_lspv_det
  from   w_dv_sr_lspv d,
         lateral (
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
           where  b.nom_vkl = d.nom_vkl
           and    b.nom_ips = d.nom_ips
           and    b.shifr_schet = d.shifr_schet
           and    trunc(b.regdate) <= d.date_op
           and    d.date_op between b.start_date and b.end_date
         ) b
  where  d.type_op = 1 --резиденты, обычная операция
union all
  select d.type_op,
         d.id                        fk_dv_sr_lspv,
         d.amount / 
           sum(dt.amount)
             over(partition by d.id) 
           * dt.amount               benefit_amount,
         to_number(dt.addition_code) benefit_code,
         dt.addition_id              pt_rid,
         dt.fk_dv_sr_lspv            fk_dv_sr_lspv_trg,
         dt.id                       fk_dv_sr_lspv_det
  from   w_dv_sr_lspv      d,
         dv_sr_lspv_det_v  dt
  where  1=1
  --
  and    dt.sub_shifr_schet = d.sub_shifr_schet
  and    dt.shifr_schet = d.shifr_schet
  and    dt.src_service_doc = d.ssylka_doc
  and    dt.nom_ips = d.nom_ips
  and    dt.nom_vkl = d.nom_vkl
  and    dt.detail_type = 'BENEFIT'
  --
  and    d.type_op = 3
union all
  select d.type_op,
         d.id                        fk_dv_sr_lspv,
         -1 * dt.amount              benefit_amount,
         to_number(dt.addition_code) benefit_code,
         dt.addition_id              pt_rid,
         dt.fk_dv_sr_lspv            fk_dv_sr_lspv_trg,
         dt.id                       fk_dv_sr_lspv_det
  from   w_dv_sr_lspv                d,
         lateral(
           select dt.amount,
                  dt.addition_code,
                  dt.addition_id,
                  dt.fk_dv_sr_lspv,
                  dt.id
           from   dv_sr_lspv_det_v  dt
           where  1=1
           and    dt.date_op < d.date_op
           and    dt.sub_shifr_schet = d.sub_shifr_schet
           and    dt.shifr_schet = d.shifr_schet
           and    dt.nom_ips = d.nom_ips
           and    dt.nom_vkl = d.nom_vkl
           and    dt.detail_type = 'BENEFIT'
         )                          dt
  where  d.type_op = 2
/