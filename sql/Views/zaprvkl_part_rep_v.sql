create or replace view zaprvkl_part_rep_v as
with cross_lines as (
  select c.header_id,
         c.line_id,
         c.person_id,
         c.diff_name
  from   zaprvkl_cross_t c
  where  c.status = 'P'
)
select lin.header_id, 
       lin.id line_id, 
       lin.excel_id,
       cast(null as integer) ips_num, 
       lin.last_name, 
       lin.first_name, 
       lin.second_name, 
       lin.birth_date, 
       lin.employee_id,
       lin.snils,
       cast(null as date)          accession_date,
       cast(null as number)        pen_schem_num,
       cast(null as varchar2(255)) investor,
       cast(null as date)          pay_start_date,
       cast(null as date)          supposed_pay_start_date,
       cast(null as number)        rasch_pen,
       cast(null as number)        delta_lv,
       cast(null as number)        dop_pen,
       cast(null as varchar2(1))   is_disabled,
       cast(null as varchar2(40))  person_type
from   zaprvkl_lines_t lin
where  lin.id in (select c.line_id from cross_lines c where c.header_id = lin.header_id)
 union all
select c.header_id, 
       c.line_id, 
       null excel_id,
       p.ips_num, 
       upper(p.last_name) last_name,  
       upper(p.first_name) first_name, 
       upper(p.second_name) second_name, 
       p.birth_date, 
       p.employee_id,
       p.snils,             
       p.accession_date,
       p.pen_schem_num,
       p.investor,
       p.pay_start_date,
       p.supposed_pay_start_date,
       p.rasch_pen,
       p.delta_lv,
       p.dop_pen,
       p.is_disabled,
       case
         when p.is_disabled = 'Y' then
           'Инвалид'
         when p.rasch_pen is not null then
           'Пенсионер'
         else
           'Участник'
       end person_type
from   cross_lines            c,
       zaprvkl_persons_rep_v p
where  p.person_id = c.person_id
/
