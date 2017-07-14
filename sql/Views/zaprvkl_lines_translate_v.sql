create or replace view zaprvkl_lines_translate_v as
  select s.line_id,
         s.header_id,
         s.status,
         translate(s.last_name,   '¨', 'Å') last_name, 
         translate(s.first_name,  '¨', 'Å') first_name,
         translate(s.second_name, '¨', 'Å') second_name,
         s.birth_date
  from   zaprvkl_lines_v s
  where  s.status = zaprvkl_api.get_ln_sts_created
/
