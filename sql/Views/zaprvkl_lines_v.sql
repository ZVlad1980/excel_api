create or replace view zaprvkl_lines_v as 
  select lin.excel_id,
         lin.id         line_id,
         lin.header_id,
         lin.status,
         lin.last_name,
         lin.first_name,
         lin.second_name,
         lin.birth_date,
         lin.employee_id,
         lin.snils,
         lin.inn,
         lin.err_msg,
         lin.double_id
  from   zaprvkl_lines_t lin
/
