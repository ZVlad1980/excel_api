create table sp_ndfl_errors(
  error_id int constraint sp_ndfl_errors_pk primary key,
  error_msg varchar2(4000),
  error_type varchar2(10) constraint sp_ndfl_errors_chk check (error_type in ('Error', 'Warning')),
  program_name varchar2(150)
)
/
begin
  merge into sp_ndfl_errors se
  using      (select 0 error_id, 'Ошибка программы' error_msg, 'Error' error_type from dual union all
              select 1 , 'ГРАЖДАНСТВО не задано', 'Error' from dual union all
              select 2, 'ГРАЖДАНСТВО РФ не соответствует УЛ', 'Error' from dual union all
              select 3, 'ГРАЖДАНСТВО неРФ не соответствует УЛ РФ', 'Error' from dual union all
              select 4, 'Тип УЛ запрещенное значение', 'Error' from dual union all
              select 5, 'Некорректный номер паспорта РФ', 'Error' from dual union all
              select 6, 'Неправильный шаблон Вида на жительство в РФ', 'Error' from dual union all
              select 7, 'Не задано УЛ', 'Error' from dual union all
              select 8, 'Налоговый резидент и ГРАЖДАНСТВО или УЛ не РФ', 'Warning' from dual union all
              select 9, 'Налоговый резидент и вид на жительство РФ', 'Warning' from dual union all
              select 10, 'Значения ГРАЖДАНСТВО и ШАБЛОН УДОСТОВЕРЕНИЯ соответствуют коду ПАСПОРТА РФ', 'Warning' from dual union all
              select 11, 'Дублирование ИНН', 'Error' from dual union all
              select 12, 'Дублирование УЛ', 'Error' from dual union all
              select 13, 'Дублирование ФИОД', 'Error' from dual union all
              select 14, 'Пустой ИНН', 'Warning' from dual union all
              select 15, 'Некорректный ИНН', 'Error' from dual union all
              select 16, 'Не соотвeтствие ставки и статуса резидента', 'Error' from dual union all
              select 17, 'Недействительный паспорт РФ', 'Warning' from dual union all
              select 18, 'Неправильный шаблон паспорта РФ', 'Error' from dual union all
              select 19, 'В полях ФИО присутствуют два пробела или одно из полей состоит из знаков пунктуации', 'Warning' from dual union all
              select 20, 'Возвраст контрагента < 18 или 100 лет', 'Warning' from dual
             ) u
  on         (se.error_id = u.error_id)
  when matched then
    update set
      se.error_msg = u.error_msg,
      se.error_type = u.error_type
  when not matched then
    insert (error_id, error_msg, error_type) values(u.error_id, u.error_msg, u.error_type);
  dbms_output.put_line(sql%rowcount);
  commit;
end;
/
