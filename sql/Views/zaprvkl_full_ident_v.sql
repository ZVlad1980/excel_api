create or replace view zaprvkl_full_ident_v as
  select s.header_id,
         s.line_id,
         p.pen_scheme,
         p.person_id,
         p.investor_id
  from   zaprvkl_lines_v   s,
         zaprvkl_persons_v p
  where  1=1
  and    p.birth_date = s.birth_date
  and    p.second_name = s.second_name
  and    p.first_name = s.first_name
  and    p.last_name = s.last_name
  --
  and    s.status    = zaprvkl_api.get_ln_sts_created
/
