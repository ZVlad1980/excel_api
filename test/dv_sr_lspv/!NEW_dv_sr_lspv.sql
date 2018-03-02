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
create or replace trigger dv_sr_lspv_bu_trg
  before update of nom_vkl,
                   nom_ips,
                   shifr_schet,
                   data_op,
                   summa,
                   ssylka_doc,
                   sub_shifr_schet,
                   service_doc
  on dv_sr_lspv 
  referencing old as old new as new
  for each row
  when (new.status is null)
begin
  :new.status := 'U';
exception
  when others then
    null;
end dv_sr_lspv_bu_trg;
/
