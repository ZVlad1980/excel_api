create or replace view sp_ritual_pos_v as
  select rp.ssylka,
         rp.fio_vlad,
          substr(rp.fio_vlad, 1, instr(rp.fio_vlad, ' ') - 1)    last_name,
         substr(rp.fio_vlad, 
           instr(rp.fio_vlad, ' ') + 1, 
           instr(rp.fio_vlad, ' ', 1, 2) 
           - instr(rp.fio_vlad, ' ') - 1
         )                                                       first_name,
         substr(rp.fio_vlad, instr(rp.fio_vlad, ' ', 1, 2) + 1)  second_name,
         rp.rogd_vlad                                            birth_date,
         rp.fk_contragent                                        gf_person
  from   fnd.sp_ritual_pos   rp
/
