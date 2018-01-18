begin
  dv_sr_lspv_docs_api.set_period(p_year => 2016);
end;
/
select *
from   dv_sr_lspv_docs_src_v d
order by d.date_op
