create or replace view ndfl6_quarters_v as
  with quarters(code, quarter, month_start, month_end) as (
    select 21, 1,  1,  3 from dual union all
    select 31, 2,  4,  6 from dual union all
    select 33, 3,  7,  9 from dual union all
    select 34, 4, 10, 12 from dual
  )
  select q.code,
         q.quarter,
         q.month_start,
         q.month_end
  from   quarters q
/
