begin
  dv_sr_lspv_docs_api.set_period(
    p_start_date  => to_date(20160101,'yyyymmdd'),
    p_end_date    => to_date(20161231,'yyyymmdd'),
    p_report_date => null
  );
end;
/
select dv_sr_lspv_docs_api.get_start_date,
       dv_sr_lspv_docs_api.get_end_date,
       dv_sr_lspv_docs_api.get_year,
       dv_sr_lspv_docs_api.get_report_date,
       dv_sr_lspv_docs_api.get_resident_date
from   dual
