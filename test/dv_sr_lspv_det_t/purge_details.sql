/*
declare
  l sys.odcinumberlist;
begin
  select dt.id
  bulk   collect
  into   l
  --delete
  from   dv_sr_lspv_det_t dt
  where  dt.fk_dv_sr_lspv in (select d.id
                              from   dv_sr_lspv#_v d
                              where  d.year_op = 2018);
  forall i in 1..l.count
    delete from dv_sr_lspv_det_t dt
    where  dt.id = l(i);
end;
*/
delete from dv_sr_lspv#_v d where  d.year_op = 2018
