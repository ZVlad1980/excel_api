select p.*
--delete
from   dv_sr_lspv_prc_t p
where  1 = 1 --p.process_name = 'UPDATE_GF_PERSONS'
--and    p.id = 1083
order  by p.created_at desc
          --fetch first rows only
           fetch next 10 rows only
