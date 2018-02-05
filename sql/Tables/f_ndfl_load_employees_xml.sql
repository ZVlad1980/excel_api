create sequence f_ndfl_load_employees_seq order
/
create table f_ndfl_load_employees_xml(
  id               int 
    default        f_ndfl_load_employees_seq.nextval
    constraint     f_ndfl_load_employees_pk primary key,
  code_na          int,
  year             int,
  xml_data         xmltype,
  created_at       timestamp
    default        systimestamp,
  created_by       varchar2(30)
    default        user
)
/
/*
select t.*, t.rowid
from   f_ndfl_load_employees_xml t
*/
