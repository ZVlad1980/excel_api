select fxndfl_out.GetXML_XChFileF2(x.id) xfile,
       x.*
from   f_ndfl_arh_xml_files x
where  x.kod_formy = 2
and    x.god = 2017
and    x.id in (
530,
531,
532,
533,
534,
535,
536


)
/
select x.*
from   f_ndfl_arh_xml_files x
where  x.kod_formy = 2
and    x.god = 2017
