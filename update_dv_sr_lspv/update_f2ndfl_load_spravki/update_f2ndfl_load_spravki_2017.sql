/*--Мартыновский (2935325)
update f2ndfl_load_spravki s
set    s.ser_nom_doc = '45 09 005840'
where  s.ssylka = 217788
and    s.kod_na = 1
and    s.god = 2017
and    s.tip_dox = 1
and    s.nom_korr = 0
/
update f2ndfl_load_spravki s
set    s.ser_nom_doc = '14 01 490479'
where  s.ssylka = 1646910
and    s.kod_na = 1
and    s.god = 2017
and    s.tip_dox = 1
and    s.nom_korr = 0
/
begin
  merge into f2ndfl_load_spravki ss
  using (
          select p.fk_contragent,
                 s.ssylka,
                 s.familiya,
                 s.imya,
                 s.otchestvo,
                 s.data_rozhd,
                 s.grazhd_2017,
                 s.grazhd_2016,
                 ic.citizenship
          from   (
                   select sp.ssylka,
                          sp.familiya,
                          sp.imya,
                          sp.otchestvo,
                          sp.data_rozhd,
                          max(case sp.god when 2016 then sp.grazhd end) grazhd_2016,
                          max(case sp.god when 2017 then sp.grazhd end) grazhd_2017,
                          max(case sp.god when 2017 then 1 end)         is_2017
                   from   f2ndfl_load_spravki sp
                   where  1=1
                   and sp.kod_na = 1
                   and sp.god in (2016, 2017)
                   and sp.nom_korr = 0
                   and sp.tip_dox = 1
                   group by sp.ssylka,
                            sp.familiya,
                            sp.imya,
                            sp.otchestvo,
                            sp.data_rozhd
                 ) s,
                 sp_fiz_lits  sfl,
                 gf_people_v  p,
                 gf_idcards_v ic
          where  sfl.ssylka = s.ssylka
          and    ic.id = p.fk_idcard
          and    p.fk_contragent = sfl.gf_person
          and    s.grazhd_2017 is null
          and    s.is_2017 = 1
       ) u
  on   (ss.kod_na = 1 and ss.god = 2017 and ss.ssylka = u.ssylka and ss.tip_dox = 1 and ss.nom_korr = 0)
  when matched then
    update set
      ss.grazhd = u.grazhd_2016;
  --
  dbms_output.put_line(sql%rowcount);
end;
*/
select p.fk_contragent,
       s.ssylka,
       s.familiya,
       s.imya,
       s.otchestvo,
       s.data_rozhd,
       s.kod_ud_2017,
       s.nom_doc_2017,
       s.grazhd_2017,
       s.kod_ud_2016,
       s.nom_doc_2016,
       s.grazhd_2016,
       ic.citizenship,
       ic.series,
       ic.nbr
from   (
         select sp.ssylka,
                sp.familiya,
                sp.imya,
                sp.otchestvo,
                sp.data_rozhd,
                max(case sp.god when 2016 then sp.grazhd end) grazhd_2016,
                max(case sp.god when 2016 then sp.kod_ud_lichn end) kod_ud_2016,
                max(case sp.god when 2016 then sp.ser_nom_doc end) nom_doc_2016,
                max(case sp.god when 2017 then sp.grazhd end) grazhd_2017,
                max(case sp.god when 2017 then sp.kod_ud_lichn end) kod_ud_2017,
                max(case sp.god when 2017 then sp.ser_nom_doc end)  nom_doc_2017,
                max(case sp.god when 2017 then 1 end)         is_2017
         from   f2ndfl_load_spravki sp
         where  1=1
         and    sp.kod_na = 1
         and    sp.god in (2016, 2017)
         and    sp.nom_korr = 0
         and    sp.tip_dox = 1
         group by sp.ssylka,
                  sp.familiya,
                  sp.imya,
                  sp.otchestvo,
                  sp.data_rozhd
       ) s,
       sp_fiz_lits  sfl,
       gf_people_v  p,
       gf_idcards_v ic
where  sfl.ssylka = s.ssylka
and    ic.id = p.fk_idcard
and    p.fk_contragent = sfl.gf_person
and    s.kod_ud_2017 in (10, 12)
and    s.grazhd_2017 = 643
and    s.is_2017 = 1
