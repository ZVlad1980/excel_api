create or replace view participant_taxdeductions_v as
  select t.ssylka_fl,
         t.rid,
         t.tdappid,
         t.start_date,
         t.end_date,
         t.start_year,
         t.end_year,
         t.status,
         t.state,
         t.code,
         t.name,
         t.amount,
         t.upper_income,
         t.frequency,
         t.type,
         t.payrestrictionid
  from   participant_taxdeductions_v@fnd_fondb t
/
