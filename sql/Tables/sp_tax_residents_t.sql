create sequence sp_tax_residents_seq order
/
--alter table sp_tax_residents_t add is_disable         varchar2(1) default null
create table sp_tax_residents_t (
  id                 int 
    default    sp_tax_residents_seq.nextval
    constraint sp_tax_residents_pk primary key,
  fk_contragent      int not null,
  resident           varchar2(1) default 'N',
  start_date         date not null,
  end_date           date,
  process_id         number         not null,
  is_disable         varchar2(1) default null
)
/
create index sp_tax_residents_ux on sp_tax_residents_t(fk_contragent, resident, start_date, end_date)
/
