PL/SQL Developer Test script 3.0
49
-- Created on 05.03.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  LC_YEAR   constant int := 2017;
  LC_SSYLKA constant int := 129844;
  --
  l_nom_vkl int;
  l_nom_ips int;
  --
  procedure prepare_(p_year int, p_nom_vkl int, p_nom_ips int) is
  begin
    --
    update dv_sr_lspv# dd
    set    dd.status = null
    where  dd.status is not null;
    --
    delete from dv_sr_lspv_det_t dt
    where  dt.id in (
             select dtt.id
             from   dv_sr_lspv_det_v d
             where  d.year_op = p_year
             and    d.nom_vkl = p_nom_vkl
             and    d.nom_ips = p_nom_ips
           );
    --
    update dv_sr_lspv#_v dd
    set    dd.status = 'N'
    where  1=1
    and    extract(month from dd.date_op) < 9
    and    dd.nom_vkl = p_nom_vkl
    and    dd.nom_ips = p_nom_ips
    and    dd.year_op = p_year;
    --
  end prepare_;
begin
  select sl.nom_vkl, sl.nom_ips
  into   l_nom_vkl, l_nom_ips
  from   sp_lspv sl
  where  sl.ssylka_fl = LC_SSYLKA;
  -- Test statements here
  prepare_;
  --
  dv_sr_lspv_det_pkg.update_details;
exception
  when others then
    dbms_output.put_line(
      utl_error_api.get_exception_full
    );
end;
0
0
