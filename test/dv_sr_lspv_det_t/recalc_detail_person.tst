PL/SQL Developer Test script 3.0
59
-- Created on 05.03.2018 by V.ZHURAVOV 
declare 
  -- Local variables here
  LC_YEAR        constant int := 2017;
  LC_SSYLKA      constant int := 1659124;
  C_START_MONTH  constant int := 1;
  C_END_MONTH    constant int := 2;
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
             from   dv_sr_lspv_det_v dtt
             where  dtt.year_op = p_year
             and    dtt.nom_vkl = p_nom_vkl
             and    dtt.nom_ips = p_nom_ips
            and    extract(month from dtt.date_op) between C_START_MONTH and nvl(C_END_MONTH, C_START_MONTH)
           );--*/
    --
    update dv_sr_lspv#_v dd
    set    dd.status = 'N'
    where  1=1
    and    extract(month from dd.date_op) between C_START_MONTH and nvl(C_END_MONTH, C_START_MONTH)
    and    dd.nom_vkl = p_nom_vkl
    and    dd.nom_ips = p_nom_ips
    and    dd.year_op = p_year;
    --
    dbms_output.put_line('Prepare recalc: set status: ' || sql%rowcount);
    --
  end prepare_;
begin
  --dbms_session.reset_package; return;
  --
  select sl.nom_vkl, sl.nom_ips
  into   l_nom_vkl, l_nom_ips
  from   sp_lspv sl
  where  sl.ssylka_fl = LC_SSYLKA;
  -- Test statements here
  prepare_(LC_YEAR, l_nom_vkl, l_nom_ips);
  --
  dv_sr_lspv_det_pkg.update_details;
  --
exception
  when others then
    utl_error_api.fix_exception;
    dbms_output.put_line(
      utl_error_api.get_exception_full
    );
    raise;
end;
0
0
