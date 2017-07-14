PL/SQL Developer Test script 3.0
13
-- Created on 12.07.2017 by V.ZHURAVOV 
declare 
  -- Local variables here
  i integer;
begin
  -- Test statements here
  f6ndfl_xml_parse(
    p_xml     => @@buh_dat.xml
  );
  --
  commit;
  --
end;
0
0
