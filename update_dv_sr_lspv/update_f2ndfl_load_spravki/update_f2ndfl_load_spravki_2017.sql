--Мартыновский (2935325)
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

/*select *
from   f2ndfl_load_spravki s
/
--Ошибка определения ИНН у получателей пособий - исправлена, при повторном формировании - не должно повториться
update f2ndfl_load_spravki s
set    s.inn_fl = case s.ssylka when 235899 then '331201413906' else null end
where  1=1
and    s.inn_fl = '673100836003'
and    s.kod_na = 1
and    s.god = 2017
and    s.tip_dox = 2
and    s.nom_korr = 0
and    s.ssylka in (
1000973,
229680,
96616,
109131,
242070,
304012,
91733,
33561,
235899,
104796,
46357,
11649,
84792,
24769,
229424,
71718,
56591,
34828,
105575,
5320,
98809,
49437,
6694,
14030,
222403,
7349
)
*/
