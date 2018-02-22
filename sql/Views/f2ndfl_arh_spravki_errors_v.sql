create or replace view f2ndfl_arh_spravki_errors_v as
  select s.id r_sprid,
         s.kod_na,
         s.god,
         s.nom_spr,
         s.nom_korr,
         s.ui_person,
         s.inn_fl,
         s.grazhd,
         s.familiya,
         s.imya,
         s.otchestvo,
         s.data_rozhd,
         s.kod_ud_lichn,
         s.ser_nom_doc,
         s.status_np,
         s.is_participant,
         count(distinct case when s.inn_fl is not null then s.ui_person end) over(partition by s.kod_na, s.god, s.inn_fl) inn_dbl ,
         count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.ser_nom_doc)                                    doc_dbl ,
         count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.familiya, s.imya, s.otchestvo, s.data_rozhd)    fiod_dbl ,
         case when ip.series is null then 'N' else 'Y' end is_invalid_doc 
  from   f2ndfl_arh_spravki s
         left join gazfond.v_podft_invalid_passports ip
           on   ip.series = substr(replace(s.ser_nom_doc, ' ', null), 1, 4)
           and  ip.num = substr(replace(s.ser_nom_doc, ' ', null), 5, 6) --regexp_substr(ar.ser_nom_doc, '\d{6}$')
           and  s.kod_ud_lichn = 21
  where  s.priznak_s = 1
/
