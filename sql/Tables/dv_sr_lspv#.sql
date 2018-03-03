create sequence dv_sr_lspv#_seq cache 10000 order
/
create table dv_sr_lspv#( --детализация движения средств
  id                 int
    default dv_sr_lspv#_seq.nextval
    constraint dv_sr_lspv#_pk primary key   ,
  nom_vkl            number(10)              ,
  nom_ips            number(10)              ,
  shifr_schet        number(5)               ,
  sub_shifr_schet    number(5)               ,
  date_op            date                    ,
  amount             number(15,2)            ,
  ssylka_doc         number(10)              ,
  service_doc        number(10)              ,
  process_id         int                     ,
  status             varchar2(1) default 'N' ,
  is_deleted         varchar2(1)             ,
  constraint dv_sr_lspv#_prc_fk
    foreign key (process_id)
    references dv_sr_lspv_prc_t(id)
)
/
create index dv_sr_lspv#_prc_ix on dv_sr_lspv#(process_id)
/
create index dv_sr_lspv#_year_ix on dv_sr_lspv#(extract(year from date_op))
/
create index dv_sr_lspv#_date_ix on dv_sr_lspv#(date_op)
/
create index dv_sr_lspv#_date_ix2 on dv_sr_lspv#(status)
/
create unique index dv_sr_lspv#_ux on dv_sr_lspv#(nom_vkl, nom_ips, date_op, shifr_schet, sub_shifr_schet, ssylka_doc)
/
