create or replace view zaprvkl_persons_translate_v as
  select p.person_id,
         translate(p.last_name,   '�', '�') last_name, 
         translate(p.first_name,  '�', '�') first_name,
         translate(p.second_name, '�', '�') second_name,
         p.birth_date,
         p.pen_scheme,
         p.sex,
         p.investor_id
  from   zaprvkl_persons_v p
/
