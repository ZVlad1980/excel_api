create or replace view zaprvkl_part_ident_v as
  select 'none' diff_name,
         s.header_id,
         s.line_id,
         p.pen_scheme,
         p.person_id,
         s.status,
         0 edit_distance,
         p.investor_id
  from   zaprvkl_persons_translate_v p,
         zaprvkl_lines_translate_v   s
  where  (
          p.birth_date  = s.birth_date   and
          p.second_name = s.second_name and
          p.first_name  = s.first_name   and
          p.last_name   = s.last_name
         )
  union all
  select 'birth_date' diff_name,
         s.header_id,
         s.line_id,
         p.pen_scheme,
         p.person_id,
         s.status,
         zaprvkl_api.edit_distance(p.birth_date, s.birth_date) edit_distance,
         p.investor_id
  from   zaprvkl_persons_translate_v p,
         zaprvkl_lines_translate_v   s
  where  (
          p.birth_date  <> s.birth_date   and    
          p.second_name = s.second_name and    
          p.first_name  = s.first_name   and    
          p.last_name   = s.last_name
         )
  union all
  select 'second_name' diff_name,
         s.header_id,
         s.line_id,
         p.pen_scheme,
         p.person_id,
         s.status,
         zaprvkl_api.edit_distance(p.second_name, s.second_name) edit_distance,
         p.investor_id
  from   zaprvkl_persons_translate_v p,
         zaprvkl_lines_translate_v   s
  where  (
          p.birth_date  = s.birth_date   and    
          p.second_name <> s.second_name and    
          p.first_name  = s.first_name   and    
          p.last_name   = s.last_name
         )
  union all
  select 'first_name' diff_name,
         s.header_id,
         s.line_id,
         p.pen_scheme,
         p.person_id,
         s.status,
         zaprvkl_api.edit_distance(p.first_name, s.first_name) edit_distance,
         p.investor_id
  from   zaprvkl_persons_translate_v p,
         zaprvkl_lines_translate_v   s
  where  (
          p.birth_date = s.birth_date   and    
          p.second_name = s.second_name and    
          p.first_name <> s.first_name   and    
          p.last_name = s.last_name
         )
  union all
  select 'last_name' diff_name,
         s.header_id,
         s.line_id,
         p.pen_scheme,
         p.person_id,
         s.status,
         zaprvkl_api.edit_distance(p.last_name, s.last_name) edit_distance,
         p.investor_id
  from   zaprvkl_persons_translate_v p,
         zaprvkl_lines_translate_v   s
  where  (
          p.birth_date = s.birth_date   and    
          p.second_name = s.second_name and    
          p.first_name = s.first_name   and    
          p.last_name <> s.last_name
         )
/
