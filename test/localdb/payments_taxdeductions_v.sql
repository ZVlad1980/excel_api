create or replace view payments_taxdeductions_v as
  select t.rid,
         t.tdappid,
         t.ssylka_fl,
         t.start_date,
         t.end_date,
         t.start_year,
         t.end_year,
         t.status,
         t.state,
         t.benefit_code,
         t.name,
         t.amount,
         t.upper_income,
         t.frequency,
         t.type,
         t.payrestrictionid,
         t.regdate
  from   payments_taxdeductions_v@fnd_fondb t
/
