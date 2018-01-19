PL/SQL Developer Test script 3.0
72
-- Created on 04.11.2017 by V.ZHURAVOV 
declare
  -- Local variables here
  l_ref_row f2ndfl_arh_spravki%rowtype;
  cursor l_load_itog_cur is
    select t.dolg_na,
           t.vzusk_ifns,
           t.tax_83,
           t.kod_na, 
           t.god, 
           t.ssylka, 
           t.tip_dox, 
           t.nom_korr, 
           t.tax_rate
    from   (select count(t.tip_dox) over(partition by t.ssylka, t.gf_person) cnt_tip_dox,
                   case sign(d.tax)
                     when -1 then abs(d.tax)
                   end dolg_na,
                   case sign(d.tax)
                     when 1 then abs(d.tax)
                   end vzusk_ifns,
                   -d.tax tax_83,
                   t.kod_na, t.god, t.ssylka, t.tip_dox, t.nom_korr, t.tax_rate
            from   dv_sr_lspv_docs_t        d,
                   f2ndfl_load_totals_det_v t
            where  1 = 1
            and    t.is_last_spr(+) = 'Y'
            and    t.gf_person(+) = d.gf_person
            and    t.ssylka(+) = d.ssylka_fl
            and    d.gf_person in (1431857,
                                   1345314,
                                   2955699,
                                   1659708,
                                   2954167,
                                   1383586,
                                   3071456,
                                   1259143,
                                   3018286,
                                   3029940,
                                   2889788,
                                   2927892,
                                   2911865,
                                   1584791
                                   )
            and    d.date_op = to_date(20161231, 'yyyymmdd')
            and    d.type_op = -2) t
    where  ((cnt_tip_dox > 1 and tip_dox = 1) or cnt_tip_dox = 1);
    
begin
  --dbms_session.reset_package; return;
  --
  -- dbms_output.put_line(utl_error_api.get_exception_full); return;
  -- Test statements here
  --
  dv_sr_lspv_docs_api.set_period(
    p_end_date    => to_date(20161231, 'yyyymmdd'),
    p_report_date => sysdate
  );
  dv_sr_lspv_docs_api.set_employees(p_flag => true);
  for i in l_load_itog_cur loop
    update f2ndfl_load_itogi li
    set    li.sum_obl_nu = li.sum_obl_nu + i.tax_83
    where  1=1
    and    li.kod_stavki = i.tax_rate
    and    li.nom_korr = i.nom_korr
    and    li.tip_dox = i.tip_dox
    and    li.ssylka = i.ssylka
    and    li.god = i.god
    and    li.kod_na = i.kod_na;
  end loop;
end;
--358536*/
0
4
gl_SPRID
gl_CAID
l_result.nom_spr
p_src_ref_id
