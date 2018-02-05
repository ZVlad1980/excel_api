/*
select s.kod_na,
       s.god,
       s.ssylka,
       s.nom_korr,
       sd.tax_rate,
       s.tip_dox,
       r.month,
       r.rev_code,
       r.rev_amount,
       p.last_name
from   f_ndfl_load_employees_xml t,
       xmltable('/Файл/Документ' passing(t.xml_data) 
         columns 
           doc_num varchar2(10) path '@НомСпр',
           rev_data xmltype path 'СведДох',
           receivers xmltype path 'ПолучДох'
       ) d,
       xmltable('/ПолучДох/ФИО' passing(d.receivers)
         columns
           last_name   varchar2(100) path '@Фамилия',
           first_name  varchar2(100) path '@Имя',
           second_name varchar2(100) path '@Отчество'
       ) p,
       xmltable('/СведДох' passing(d.rev_data) 
         columns
           tax_rate number path '@Ставка',
           rev_ben  xmltype path 'ДохВыч'
       ) sd,
       xmltable('/ДохВыч/СвСумДох' passing(sd.rev_ben) 
         columns
           month varchar2(2) path '@Месяц',
           rev_code varchar2(5) path '@КодДоход',
           rev_amount varchar2(10) path '@СумДоход',
           ben_code varchar2(5) path 'СвСумВыч/@КодВычет',
           ben_amount varchar2(10) path 'СвСумВыч/@СумВычет'
       ) r,
       F2ndfl_Load_Spravki s,
       f2ndfl_load_mes     m
where  1 = 1 
and    m.doh_kod_gni = r.rev_code
and    m.tip_dox = 9
and    m.mes = r.month
and    m.nom_korr = s.nom_korr
and    m.tip_dox = s.tip_dox
and    m.ssylka = s.ssylka
and    m.god = s.god
and    m.kod_na = s.kod_na
and    s.tip_dox(+) = 9
and    nvl(s.otchestvo(+), 'NULL') = nvl(p.second_name, 'NULL')
and    s.imya(+) = p.first_name
and    s.familiya(+) = p.last_name
and    s.god(+) = t.year
and    s.kod_na(+) = t.code_na
and    t.id = 41
*/
begin
merge into f2ndfl_load_mes     m
using (select s.kod_na,
              s.god,
              s.ssylka,
              s.nom_korr,
              sd.tax_rate,
              s.tip_dox,
              r.month,
              r.rev_code,
              r.rev_amount,
              p.last_name
       from   f_ndfl_load_employees_xml t,
              xmltable('/Файл/Документ' passing(t.xml_data) 
                columns 
                  doc_num varchar2(10) path '@НомСпр',
                  rev_data xmltype path 'СведДох',
                  receivers xmltype path 'ПолучДох'
              ) d,
              xmltable('/ПолучДох/ФИО' passing(d.receivers)
                columns
                  last_name   varchar2(100) path '@Фамилия',
                  first_name  varchar2(100) path '@Имя',
                  second_name varchar2(100) path '@Отчество'
              ) p,
              xmltable('/СведДох' passing(d.rev_data) 
                columns
                  tax_rate number path '@Ставка',
                  rev_ben  xmltype path 'ДохВыч'
              ) sd,
              xmltable('/ДохВыч/СвСумДох' passing(sd.rev_ben) 
                columns
                  month varchar2(2) path '@Месяц',
                  rev_code varchar2(5) path '@КодДоход',
                  rev_amount varchar2(10) path '@СумДоход',
                  ben_code varchar2(5) path 'СвСумВыч/@КодВычет',
                  ben_amount varchar2(10) path 'СвСумВыч/@СумВычет'
              ) r,
              F2ndfl_Load_Spravki s
       where  1 = 1 
       and    s.tip_dox(+) = 9
       and    nvl(s.otchestvo(+), 'NULL') = nvl(p.second_name, 'NULL')
       and    s.imya(+) = p.first_name
       and    s.familiya(+) = p.last_name
       and    s.god(+) = t.year
       and    s.kod_na(+) = t.code_na
       and    t.id = 41
      ) u
on    (m.doh_kod_gni = u.rev_code
       and    m.tip_dox = 9
       and    m.mes = u.month
       and    m.nom_korr = u.nom_korr
       and    m.tip_dox = u.tip_dox
       and    m.ssylka = u.ssylka
       and    m.god = u.god
       and    m.kod_na = u.kod_na)
when matched then
  update set
    m.kod_stavki = u.tax_rate;
    dbms_output.put_line(sql%rowcount);
end;
