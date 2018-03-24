select 'insert into sp_ogr_pv_man_t(nom_vkl, nom_ips, ssylka_fl, shifr_schet, benefit_code, benefit_amount, start_date, end_date, upper_income, regdate)
        values(' || t.nom_vkl || ', ' || t.nom_ips || ', ' || t.ssylka_fl || ', ' || t.shifr_schet || ', ' || 
                    t.benefit_code || ', ' || t.benefit_amount || ', ' ||
                    'to_date(' || to_char(t.start_date, 'yyyymmdd') || ', ''yyyymmdd''), ' || 
                    'to_date(' || to_char(t.end_date, 'yyyymmdd') || ', ''yyyymmdd''), ' || 
                    t.upper_income || ', ' || 
                    'to_date(' || to_char(t.regdate, 'yyyymmdd') || ', ''yyyymmdd''));' cmd,
       t.*,
       t.rowid
from   sp_ogr_pv_man_t t
/
