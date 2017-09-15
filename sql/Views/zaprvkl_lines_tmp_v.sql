create or replace view zaprvkl_lines_tmp_v as
select tt.excel_id,
       tt.last_name  ,
       tt.first_name ,
       tt.second_name,
       tt.birth_date,
       tt.birth_date_str,
       row_number() over (
           partition by
             translate(tt.last_name, 'Ё', 'Е'),
             translate(tt.first_name, 'Ё', 'Е'),
             translate(tt.second_name, 'Ё-', 'Е '),
             tt.birth_date
           order by tt.last_name
         )                      double_row_num,
       first_value(tt.excel_id) over (
           partition by
             translate(tt.last_name, 'Ё', 'Е'),
             translate(tt.first_name, 'Ё', 'Е'),
             translate(tt.second_name, 'Ё-', 'Е '),
             tt.birth_date
           order by tt.last_name
         )                      double_id,
       tt.employee_id,
       tt.snils,
       tt.inn
from   zaprvkl_lines_tmp  tt
/
