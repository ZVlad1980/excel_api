create or replace view taxdeductions_v as
  select -1 nom_vkl    ,
         -1 nom_ips    ,
         -1 shifr_schet,
         -1 ssylka_fl  ,
         -1 fk_contragent,
         -1 rid_td     ,
         -1 ssylka_td  ,
         -1 tdid       ,
         -1 benefit_code
  from   dual
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
