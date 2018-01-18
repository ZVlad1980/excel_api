begin
  dv_sr_lspv_docs_api.set_period(
    p_end_date    => to_date(20161231, 'yyyymmdd'),
    p_report_date => to_date(20171231, 'yyyymmdd')
  );
end;
/
select d.gf_person,
                 p.lastname, 
                 p.firstname, 
                 p.secondname, 
                 d.tax_rate,
                 d.accounts_cnt,
                 d.tax_calc,
                 d.tax_retained
          from   dv_sr_lspv_tax_diff_v d,
                 gf_people_v       p
          where  1=1
          --and    d.gf_person = 3052332

          and    p.fk_contragent = d.gf_person
          order by d.tax_diff, p.lastname, p.firstname, p.secondname;
