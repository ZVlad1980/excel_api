alter table sp_ogr_pv add status varchar2(1) invisible
/
alter table sp_ogr_pv add created_at date invisible 
/
alter table sp_ogr_pv modify (created_at date default current_date)
/
create index sp_ogr_pv_sts_ix on sp_ogr_pv(status)
/
update sp_ogr_pv o
set    o.status = 'N',
       o.created_at = to_date(20180101, 'yyyymmdd')
where  o.kod_ogr_pv > 1000
/
create table log$_sp_ogr_pv (
  id           number(10,0),
  action       varchar2(1),
  nom_vkl      number(10,0), 
  nom_ips      number(10,0), 
  kod_ogr_pv   number(5,0), 
  nach_deistv  date, 
  okon_deistv  date, 
  primech      varchar2(255), 
  ssylka_fl    number(10,0), 
  kod_insz     number(10,0), 
  ssylka_td    number(10,0), 
  rid_td       number(10,0),
  status       varchar2(1) default 'N',
  inserted_at  date,
  created_at   timestamp default current_timestamp,
  created_by   varchar2(32)
)
/
create index log$_sp_ogr_pv_sts_ix on log$_sp_ogr_pv(status)
/

