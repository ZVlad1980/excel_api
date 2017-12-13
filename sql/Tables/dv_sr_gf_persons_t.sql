create sequence dv_sr_gf_persons_seq cache 100000
/
create table dv_sr_gf_persons_t(
  id               int 
    default        dv_sr_gf_persons_seq.nextval
    constraint     dv_sr_gf_persons_pk primary key,
  contragent_type  varchar2(40),
  nom_vkl          int not null,
  nom_ips          int not null,
  ssylka           int not null,
  gf_person_old    int,
  gf_person_new    int,
  process_id       int,
  too_many         varchar2(1),
  constraint dv_sr_gf_persons_uc unique (process_id, contragent_type, ssylka)
) 
/
create index dv_sr_gf_persons_ix on dv_sr_gf_persons_t(process_id)
/
