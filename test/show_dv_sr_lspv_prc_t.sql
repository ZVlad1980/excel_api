select *--max(p.created_by)
    --  into   l_last_start
      from   dv_sr_lspv_prc_t p
      order by p.created_at
      where  p.process_name = 'UPDATE_GF_PERSONS'
