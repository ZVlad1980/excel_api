--create table test_tbl(msg varchar2(20), created_at timestamp default systimestamp);
--
create global temporary table zaprvkl_lines_tmp(
  excel_id       integer,
  last_name      varchar2(255), 
  first_name     varchar2(255), 
  second_name    varchar2(255), 
  birth_date_str varchar2(20), 
  birth_date     date, 
  employee_id    varchar2(25), 
  snils          varchar2(14), 
  inn            varchar2(15)
) on commit preserve rows;
--
create sequence zaprvkl_headers_seq start with 1000 cache 50;
--
create table zaprvkl_headers_t(
  id               int default zaprvkl_headers_seq.nextval, --generated as identity    primary key,
  investor_id      number(10),
  status           varchar2(1)    default 'L',        --(C)reated, (P)rocess, (S)uccess, (E)rror
  create_at        timestamp      default systimestamp,
  created_by       varchar2(32)   default user,
  last_update_at   timestamp      default systimestamp,
  fl_force_stop    varchar2(1),                    -- Флаг форсированной остановки
  err_msg          varchar2(2000),                  --сообщение об ошибке
  constraint  zaprvkl_headers_pk primary key (id)
);
--
create sequence zaprvkl_lines_seq start with 150000 cache 50;
--
create table zaprvkl_lines_t(
  id          int default zaprvkl_lines_seq.nextval, -- generated as identity primary key,
  header_id   int,
  excel_id    integer,
  status      varchar2(1), --(C)reate, (I)dentification, (N)on identification, (D)ouble source, (M)ultiple identification, (E)rror
  last_name   varchar2(255),
  first_name  varchar2(255),
  second_name varchar2(255),
  birth_date  date,
  employee_id varchar2(255),
  snils       varchar2(255),
  inn         varchar2(255),
  double_id   int,
  err_msg     varchar2(255), --сообщение об ошибке
  constraint  zaprvkl_lines_pk primary key (id)
);
--
alter table zaprvkl_lines_t add constraint zaprvkl_lines_hdr_fk foreign key (header_id) references zaprvkl_headers_t(id) on delete cascade;
--
create index zaprvkl_lines_hdr_idx on zaprvkl_lines_t(header_id, status);
--
create table zaprvkl_cross_t(
  header_id int,
  line_id   int,
  person_id number(10),
  status    varchar2(1), --(F)ull identification, (P)art identification
  diff_name varchar2(20)
);
--
alter table zaprvkl_cross_t add constraint zaprvkl_cross_line_fk foreign key (line_id) references zaprvkl_lines_t(id) on delete cascade;
--
create index zaprvkl_cross_hdr_idx on zaprvkl_cross_t(header_id, line_id, status)
--alter table zaprvkl_cross_t add constraint zaprvkl_cross_person_fk foreign key (line_id) references fnd.sp_fiz_lits(ssylka)
/
