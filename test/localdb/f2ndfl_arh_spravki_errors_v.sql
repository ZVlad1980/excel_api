create or replace view f2ndfl_arh_spravki_errors_v as
  select s.kod_na,
         s.god,
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
         case
           when s.error_list is not null then
             replace(
               replace(
                 replace(
                   s.error_list,
                   ' ',
                   ' _'
                 ),
                 '_ '
               ),
               '_'
             ) 
         end error_list
  from   (select s.kod_na,
                 s.god,
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
                 trim(
                   case
                     when s.grazhd is null                                                          then 1   --ГРАЖДАНСТВО не задано
                   end || ' ' ||
                   case
                     when s.grazhd = '643'
                       and kod_ud_lichn in (10, 11, 12, 13, 15, 19)                                 then 2   --ГРАЖДАНСТВО РФ не соответствует УЛ
                   end || ' ' ||
                   case
                     when s.grazhd <> '643'
                       and kod_ud_lichn not in (10, 11, 12, 13, 15, 19, 23)                         then 3   --ГРАЖДАНСТВО неРФ не соответствует УЛ РФ
                   end || ' ' ||
                   case
                     when kod_ud_lichn not in (3, 7, 8, 10, 11, 12, 13, 14, 15, 19, 21, 23, 24, 91) then 4   --Тип УЛ запрещенное значение
                   end || ' ' ||
                   case
                     when kod_ud_lichn = 21
                       and not regexp_like(ser_nom_doc, '^\d{2}\s\d{2}\s\d{6}$')                    then 5   --Неправильный шаблон Паспорта РФ
                   end || ' ' ||
                   case
                     when kod_ud_lichn = 12
                       and not regexp_like(ser_nom_doc, '^\d{2}\s\d{7}$')                           then 6   --Неправильный шаблон Вида на жительство в РФ
                   end  || ' ' ||
                   case
                     when kod_ud_lichn is null or s.ser_nom_doc is null                             then 7   --Не задано УЛ
                   end  || ' ' ||
                   case
                     when status_np = 1 and coalesce(grazhd, 'NULL') <> '643' 
                       and kod_ud_lichn in (10, 11, 13, 15, 19)                                     then 8   --Налоговый резидент и ГРАЖДАНСТВО или УЛ не РФ
                   end || ' ' ||
                   case
                     when status_np = 1 and coalesce(grazhd, 'NULL') <> '643'
                       and kod_ud_lichn = 12                                                        then 9   --Налоговый резидент и вид на жительство РФ
                   end || ' ' ||
                   case
                     when kod_ud_lichn <> 21 and grazhd = '643'
                       and regexp_like(ser_nom_doc, '^\d{2}\s\d{2}\s\d{6}$')                        then 10  --Значения ГРАЖДАНСТВО и ШАБЛОН УДОСТОВЕРЕНИЯ соответствуют коду ПАСПОРТА РФ
                   end || ' ' ||
                   case
                     when count(distinct case when s.inn_fl is not null then s.ui_person end)
                            over(partition by s.kod_na, s.god, s.inn_fl) > 1                        then 11 --Дублирование ИНН
                   end || ' ' ||
                   case
                     when count(distinct s.ui_person)
                            over(partition by s.kod_na, s.god, s.ser_nom_doc) > 1                   then 12 --Дублирование УЛ
                   end || ' ' ||
                   case
                     when count(distinct s.ui_person) over(partition by s.kod_na, s.god, 
                            s.familiya, s.imya, s.otchestvo, s.data_rozhd) > 1                      then 13 --Дублирование ФИОД
                   end || ' ' ||
                   case
                     when s.inn_fl is null                                                          then 14 --ИНН не заполнен
                   end || ' ' ||
                   case
                     when s.inn_fl is not null and
                       fxndfl_util.Check_INN(s.inn_fl) <> 0                                         then 15 --Некорректный ИНН
                   end || ' ' ||
                   case
                     when fxndfl_util.Check_ResidentTaxRate(s.kod_na, s.god, 
                       s.ui_person, s.status_np) <> 0                                               then 16 --Не соотвутствие ставки и статуса резидента
                   end || ' ' ||
                   case
                     when ip.is_invalid_doc = 'Y'                                                   then 17 --Недействительный паспорт РФ
                   end --*/
                 )       error_list
          from   f2ndfl_arh_spravki s,
                 lateral(
                   select case when ip.series is not null then 'Y' else 'N' end is_invalid_doc 
                   from   v_podft_invalid_passports@gazfond_fondb ip
                   where  1=1
                   and    ip.series = substr(replace(s.ser_nom_doc, ' ', null), 1, 4)
                   and    ip.num = substr(replace(s.ser_nom_doc, ' ', null), 5, 6) --regexp_substr(ar.ser_nom_doc, '\d{6}$')
                   and    s.kod_ud_lichn = 21
                 )(+) ip
        ) s
/
