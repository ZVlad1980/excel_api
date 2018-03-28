create sequence dv_sr_lspv_prc_seq
/
create table dv_sr_lspv_prc_t (
  id             int default dv_sr_lspv_prc_seq.nextval,
  process_name   varchar2(40),
  start_date     date,
  end_date       date,
  actual_date    date,
  state          varchar2(10),
  deleted_rows   integer,
  error_rows     integer,
  created_by     varchar2(32) default user,
  created_at     timestamp default systimestamp,
  last_udpated_at timestamp default systimestamp,
  error_msg      varchar2(1000)
)
/
alter table dv_sr_lspv_prc_t add
  constraint dv_sr_lspv_prc_pk primary key (id)
/
create sequence dv_sr_lspv_docs_seq cache 100000
/
--rename dv_sr_lspv_docs_t to dv_sr_lspv_docs_t#
create table dv_sr_lspv_docs_t (
  id                 int 
    default dv_sr_lspv_docs_seq.nextval
    primary key , --int generated as identity primary key,
  date_op            date           not null, 
  year_op            as 	          (extract(year from "DATE_OP")),
  month_op           as             (extract(month from "DATE_OP")),
  quarter_op         as             (ceil(extract(month from "DATE_OP")/3)),
  ssylka_doc_op      number         not null, 
  type_op            number,  
  date_doc           date           not null,
  year_doc           as 	          (extract(year from "DATE_DOC")),
  month_doc          as             (extract(month from "DATE_DOC")),
  quarter_doc        as             (ceil(extract(month from "DATE_DOC")/3)),
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
  source_revenue     number, 
  source_benefit     number, 
  source_tax         number,
  process_id         number         not null,
  is_tax_return      varchar2(1),
  is_delete          as             (case when delete_process_id is not null then 'Y' end),
  delete_process_id  number
)
/*
alter  table dv_sr_lspv_docs_t add delete_process_id  number
alter table dv_sr_lspv_docs_t  drop column is_delete
alter table dv_sr_lspv_docs_t  add (is_delete as (case when delete_process_id is not null then 'Y' end))
create index dv_sr_lspv_docs_i7 on dv_sr_lspv_docs_t(is_delete)
*/
/
alter table dv_sr_lspv_docs_t add constraint dv_sr_lspv_docs_chk1 check (not(coalesce(type_op, 0) = -1 and ssylka_doc = ssylka_doc_op))
/
--create unique index dv_sr_lspv_docs_u1 on dv_sr_lspv_docs_t(date_op, ssylka_doc_op, date_doc, ssylka_doc, nom_vkl, nom_ips, gf_person, tax_rate)
drop index dv_sr_lspv_docs_u1
/
create unique index dv_sr_lspv_docs_u1 on dv_sr_lspv_docs_t(date_op, ssylka_doc_op, date_doc, ssylka_doc, nom_vkl, nom_ips, gf_person, tax_rate, delete_process_id)
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
