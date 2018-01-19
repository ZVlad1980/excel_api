create or replace view f2ndfl_arh_spravki_v as
  select sa.id,
         sa.kod_na, 
         sa.god,
         ns.fk_contragent gf_person,
         ns.is_employee,
         ns.is_participant,
         sa.data_dok, 
         sa.nom_spr,  
         sa.nom_korr, 
         sa.kvartal, 
         sa.priznak_s, 
         sa.inn_fl, 
         sa.inn_ino, 
         sa.status_np, 
         sa.grazhd, 
         sa.familiya, 
         sa.imya, 
         sa.otchestvo, 
         sa.data_rozhd, 
         sa.kod_ud_lichn,
         sa.ser_nom_doc,
         case max(sa.nom_korr)over(partition by ns.fk_contragent)
           when sa.nom_korr then 'Y'
           else 'N'
         end is_last_spr,
         sa.r_xmlid
  from   f2ndfl_arh_spravki sa,
         lateral (
           select ns.kod_na, ns.god, ns.nom_spr, ns.fk_contragent,
                  max(case when ns.tip_dox = 9 then 'Y' else 'N' end)          is_employee,
                  max(case when ns.tip_dox in (1, 2, 3) then 'Y' else 'N' end) is_participant
           from   f2ndfl_arh_nomspr  ns
           where  ns.nom_spr = sa.nom_spr
           and    ns.god = sa.god
           and    ns.kod_na = sa.kod_na
           group by ns.kod_na, ns.god, ns.nom_spr, ns.fk_contragent
         ) ns
  where  1 = 1
  and    sa.god = dv_sr_lspv_docs_api.get_year
  and    sa.kod_na = 1
/
