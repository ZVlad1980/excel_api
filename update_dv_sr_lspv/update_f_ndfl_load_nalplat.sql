begin

  merge into f_ndfl_load_nalplat ns
  --KOD_NA, GOD, SSYLKA_TIP, NOM_VKL, NOM_IPS
  using (select ns.kod_na,
                ns.god,
                ns.ssylka_tip,
                ns.nom_vkl,
                ns.nom_ips,
                gp.gf_person_new
         from   dv_sr_gf_persons_t  gp,
                f_ndfl_load_nalplat ns
         where  1 = 1
         and    ns.gf_person = gp.gf_person_old
         and    gp.gf_person_old is not null) u
  on (ns.kod_na = u.kod_na and ns.god = u.god and ns.ssylka_tip = u.ssylka_tip and ns.nom_vkl = u.nom_vkl and ns.nom_ips = u.nom_ips)
  when matched then
    update
    set    ns.gf_person = u.gf_person_new;
  dbms_output.put_line('Updated: ' || sql%rowcount || ' row(s)');
end;
