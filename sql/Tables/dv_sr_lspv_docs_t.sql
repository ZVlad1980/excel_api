create sequence dv_sr_lspv_prc_seq
/
create table dv_sr_lspv_prc_t (
  id             int default dv_sr_lspv_prc_seq.nextval,
  process_name   varchar2(40),
  start_date     date,
  end_date       date,
  state          varchar2(10),
  deleted_rows   integer,
  error_rows     integer,
  created_by     varchar2(32) default user,
  created_at     timestamp default systimestamp,
  last_udpated_at timestamp default systimestamp,
  error_msg      varchar2(1000)
)
/
create sequence dv_sr_lspv_docs_seq cache 100000
/
create table dv_sr_lspv_docs_t (
  id                 int 
    default dv_sr_lspv_docs_seq.nextval
    primary key , --int generated as identity primary key,
  date_op            date           not null, 
  ssylka_doc_op      number         not null, 
  type_op            number,  
  date_doc           date           not null,
  ssylka_doc         number(10,0)   not null, 
  nom_vkl            number(10,0)   not null, 
  nom_ips            number(10,0)   not null, 
  ssylka_fl          number(10,0), 
  gf_person          number         not null, 
  pen_scheme_code    number(5,0)    not null, 
  tax_rate           number         not null, 
  det_charge_type    varchar2(20), 
  revenue            number, 
  benefit            number, 
  tax                number, 
  tax_83             number, 
  source_revenue     number, 
  source_benefit     number, 
  source_tax         number,
  process_id         number         not null,
  is_tax_return      varchar2(1),
  is_delete          varchar2(1)   --флаг удаления записи из fnd.dv_sr_lspv
)
/
alter table dv_sr_lspv_docs_t add constraint dv_sr_lspv_docs_chk1 check (not(coalesce(type_op, 0) = -1 and ssylka_doc = ssylka_doc_op))
/
begin
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name => 'dv_sr_lspv_docs_t');
end;
/
create index err$_dv_sr_lspv_docs_i1 on err$_dv_sr_lspv_docs_t(process_id)
/
create unique index dv_sr_lspv_docs_u1 on dv_sr_lspv_docs_t(date_op, ssylka_doc_op, date_doc, ssylka_doc, nom_vkl, nom_ips, gf_person, tax_rate)
/
create index dv_sr_lspv_docs_i1 on dv_sr_lspv_docs_t(gf_person, tax_rate, date_op)
/
create index dv_sr_lspv_docs_i2 on dv_sr_lspv_docs_t(pen_scheme_code, det_charge_type, date_op)
/
create index dv_sr_lspv_docs_i3 on dv_sr_lspv_docs_t(type_op, date_op)
/
create index dv_sr_lspv_docs_i4 on dv_sr_lspv_docs_t(ssylka_doc, date_op)
/
create index dv_sr_lspv_docs_i5 on dv_sr_lspv_docs_t(date_op, gf_person)
/
create index dv_sr_lspv_docs_i6 on dv_sr_lspv_docs_t(process_id)
/
create index dv_sr_lspv_docs_i7 on dv_sr_lspv_docs_t(is_delete)
/
create index dv_sr_lspv_docs_i8 on dv_sr_lspv_docs_t(ssylka_doc, nom_vkl, nom_ips)
/
