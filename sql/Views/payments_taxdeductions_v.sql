create or replace view payments_taxdeductions_v as
  select pt.rid,
         pt.tdappid,
         a.ssylka_fl,
         pt.startdate                    start_date,
         pt.enddate                      end_date,
         extract(year from pt.startdate) start_year,
         extract(year from pt.enddate)   end_year,
         pt.status,
         pt.state,
         t.code                          benefit_code,
         t.name,
         t.amount,
         t.upper_income,
         t.frequency,
         t.type,
         t.payrestrictionid
  from   payments.participant_taxdeductions pt,
         payments.tdapplications            a,
         payments.taxdeductions             t
  where  1=1
  and    t.rid = pt.tdid
  and    a.rid = pt.tdappid
/
