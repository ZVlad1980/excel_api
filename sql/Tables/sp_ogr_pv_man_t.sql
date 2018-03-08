create sequence sp_ogr_pv_man_seq cache 10 order
/
create table sp_ogr_pv_man_t( --детализация движения средств
  id                 int
    default sp_ogr_pv_man_seq.nextval
    constraint sp_ogr_pv_man_pk    primary key,
  nom_vkl            number(10)    not null   ,
  nom_ips            number(10)    not null   ,
  ssylka_fl          number(10)    not null   ,
  shifr_schet        number(5)     not null   ,
  benefit_code       number(5)     not null   ,
  benefit_amount     number(10, 2) not null   ,
  start_date         date          not null   ,
  end_date           date          not null   ,
  upper_income       number(10, 2)            ,
  regdate            date          not null   ,
  enabled            varchar2(1)   default 'Y'
)
/
create index sp_ogr_pv_man_ix on sp_ogr_pv_man_t(nom_vkl, nom_ips)
/
create index sp_ogr_pv_man_ix2 on sp_ogr_pv_man_t(ssylka_fl)
/
