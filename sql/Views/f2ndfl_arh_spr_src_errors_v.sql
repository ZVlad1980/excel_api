create or replace view f2ndfl_arh_spr_src_errors_v as
  select s.kod_na,
         s.god,
         null nom_spr,
         null nom_korr,
         s.ui_person,
         s.inn inn_fl,
         s.citizenship grazhd,
         s.lastname familiya,
         s.firstname imya,
         s.secondname otchestvo,
         s.birthdate data_rozhd,
         s.fk_idcard_type kod_ud_lichn,
         s.ser_nom_doc,
         s.status_np,
         s.is_participant,
         count(distinct case when s.inn  is not null then s.ui_person end) over(partition by s.kod_na, s.god, s.inn ) inn_dbl ,
         count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.ser_nom_doc)                                    doc_dbl ,
         count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.lastname , s.firstname , s.secondname , s.birthdate)    fiod_dbl ,
         ip.is_invalid_doc 
  from   f2ndfl_arh_spravki_src_v s,
         lateral(
           select case when ip.series is not null then 'Y' else 'N' end is_invalid_doc 
           from   gazfond.v_podft_invalid_passports ip
           where  1=1
           and    ip.series = substr(replace(s.ser_nom_doc, ' ', null), 1, 4)
           and    ip.num = substr(replace(s.ser_nom_doc, ' ', null), 5, 6) --regexp_substr(ar.ser_nom_doc, '\d{6}$')
           and    s.fk_idcard_type  = 21
         )(+) ip
/
