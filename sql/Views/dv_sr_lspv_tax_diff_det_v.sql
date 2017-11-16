create or replace view dv_sr_lspv_tax_diff_det_v as
  select d.gf_person,
         vkl.nom_vkl,
         vkl.nom_ips,
         vkl.ssylka_fl,
         vkl.pen_scheme,
         vkl.det_charge_type,
         vkl.tax_rate tax_rate_op,
         p.lastname,
         p.firstname,
         p.secondname,
         d.tax_rate,
         d.accounts_cnt,
         vkl.benefit,
         vkl.revenue,
         vkl.tax,
         d.revenue revenue_total,
         d.benefit benefit_total,
         d.tax_calc,
         d.tax_retained,
         d.tax_diff,
         case vkl.det_charge_type
           when 'PENSION' then 60
           when 'BUYBACK' then 55
           when 'RITUAL'  then 62
         end                        revenue_shifr_schet,
         case vkl.det_charge_type
           when 'PENSION' then 85
           when 'BUYBACK' then 85
           when 'RITUAL'  then 86
         end || '/' ||
         (case vkl.det_charge_type
           when 'PENSION' then 0
           when 'BUYBACK' then 2
           when 'RITUAL'  then 0
          end + 
          case vkl.tax_rate
            when 13 then 0
            when 30 then 1
          end
         )                          tax_shifr_schet
  from   dv_sr_lspv_tax_diff_v d,
         gf_people_v           p,
         lateral(
           select dd.gf_person,
                  dd.nom_vkl,
                  dd.nom_ips,
                  dd.ssylka_fl,
                  dd.det_charge_type,
                  ps.name pen_scheme, --dd.pen_scheme_code,
                  dd.tax_rate,
                  sum(dd.benefit) benefit,
                  sum(dd.revenue) revenue,
                  sum(dd.tax)     tax
           from   dv_sr_lspv_docs_t dd,
                  sp_pen_schemes_v  ps
           where  dd.gf_person = d.gf_person
           and    ps.code = dd.pen_scheme_code
           group by dd.gf_person,
                    dd.nom_vkl,
                    dd.nom_ips,
                    dd.ssylka_fl,
                    dd.det_charge_type,
                    ps.name,
                    dd.tax_rate
         ) vkl
  where  1 = 1
  and    vkl.gf_person = d.gf_person
  and    p.fk_contragent = d.gf_person
/
