with prc as (
  select p.*
  from   dv_sr_lspv_prc_t p
  where  1=1--p.process_name = 'UPDATE_GF_PERSONS'
  order  by p.created_at desc
  --fetch first rows only
  offset 5 rows fetch next 10 rows only
)
select pt.*
from   prc p,
       dv_sr_gf_persons_t pt
where  pt.process_id = p.id
/
/* -- Check is null
select *
from   dv_sr_gf_persons_t pt
where  pt.gf_person_new is null
*/
select p.*
  from   dv_sr_lspv_prc_t p
  where  1=1--p.process_name = 'UPDATE_GF_PERSONS'
  order  by p.created_at desc
  --fetch first rows only
  fetch next 10 rows only
