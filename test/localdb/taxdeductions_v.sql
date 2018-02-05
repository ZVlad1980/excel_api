create or replace view taxdeductions_v as
  select t.nom_vkl,
         t.nom_ips,
         t.shifr_schet,
         t.ssylka_fl,
         t.fk_contragent,
         t.rid_td,
         t.startdate,
         t.enddate,
         t.ssylka_td,
         t.tdid,
         t.benefit_code,
         t.amount,
         t.upper_income,
         t.name,
         t.amount_all
  from   taxdeductions_v@fnd_fondb t
/
drop synonym GNI_KLADR
/
create table GNI_KLADR
(
  nazv   VARCHAR2(40 CHAR),
  socr   VARCHAR2(10 CHAR),
  klcode VARCHAR2(13 CHAR) not null,
  pindex VARCHAR2(6 CHAR),
  gnimb  VARCHAR2(4 CHAR),
  uno    VARCHAR2(4 CHAR),
  ocatd  VARCHAR2(11 CHAR),
  status VARCHAR2(1 CHAR)
)
/
drop synonym GNI_STREET
/
-- Create table
create table GNI_STREET
(
  nazv   VARCHAR2(40 CHAR),
  socr   VARCHAR2(10 CHAR),
  klcode VARCHAR2(17 CHAR) not null,
  pindex VARCHAR2(6 CHAR),
  gnimb  VARCHAR2(4 CHAR),
  uno    VARCHAR2(4 CHAR),
  ocatd  VARCHAR2(11 CHAR)
)
