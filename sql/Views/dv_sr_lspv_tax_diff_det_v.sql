create or replace view dv_sr_lspv_tax_diff_det_v as
  select d.gf_person,
         vkl.nom_vkl,
         vkl.nom_ips,
         vkl.pen_scheme_code,
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
         d.tax_diff
  from   dv_sr_lspv_tax_diff_v d,
         gf_people_v           p,
         lateral(
           select dd.gf_person,
                  dd.nom_vkl,
                  dd.nom_ips,
                  dd.pen_scheme_code,
                  sum(dd.benefit) benefit,
                  sum(dd.revenue) revenue,
                  sum(dd.tax)     tax
           from   dv_sr_lspv_docs_t dd
           where  dd.gf_person = d.gf_person
           group by dd.gf_person,
                    dd.nom_vkl,
                    dd.nom_ips,
                    dd.pen_scheme_code
         ) vkl
  where  1 = 1
  and    vkl.gf_person = d.gf_person
  and    p.fk_contragent = d.gf_person
/
