create sequence dv_sr_lspv_seq cache 10000 order
/
alter table dv_sr_lspv add id int invisible default dv_sr_lspv_seq.nextval 
/
alter table dv_sr_lspv add constraint dv_sr_lspv_uid unique (id)
/
alter table dv_sr_lspv add status varchar2(1) invisible
/
alter table dv_sr_lspv modify (status varchar2(1) default 'N')
/
create index dv_sr_lspv_sts_ix on dv_sr_lspv(status)
/
create index dv_sr_lspv_year_fx on dv_sr_lspv(extract(year from data_op))
/
begin
  dbms_stats.gather_table_stats(user, 'DV_SR_LSPV');
  dbms_stats.gather_index_stats(user, 'DV_SR_LSPV_UID');
  dbms_stats.gather_index_stats(user, 'dv_sr_lspv_year_fx');
end;
/
create table log$_dv_sr_lspv(
  id                    number(*,0), 
  action                varchar2(1),
  nom_vkl               number(10,0),
  nom_ips               number(10,0),
  shifr_schet           number(5,0),
  data_op               date,
  summa                 float(126),
  ssylka_doc            number(10,0),
  kod_oper              number(5,0),
  sub_shifr_schet       number(5,0),
  service_doc           number(10,0),
  status                varchar2(1) default 'N',
  created_at            timestamp default current_timestamp,
  created_by            varchar2(32)
)
/
create index log$_dv_sr_lspv_sts_ix on log$_dv_sr_lspv(status)
/
/*
update dv_sr_lspv_v d
set    d.status = 'N'
where  extract(year from d.data_op) > 2017
*/
