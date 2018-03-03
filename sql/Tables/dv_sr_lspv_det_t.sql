create sequence dv_sr_lspv_det_seq cache 10000 order
/
create table dv_sr_lspv_det_t( --детализация движения средств
  id                 int
    default dv_sr_lspv_det_seq.nextval
    constraint dv_sr_lspv_det_pk primary key,
  charge_type        varchar2(8) not null, --тип операции: BENEFIT, REVENUE, TAX
  fk_dv_sr_lspv      int         not null, --операция основание записи
  fk_dv_sr_lspv_trg  int                 , --корректируемая операция
  amount             number(10, 2)       , --сумма коррекции/сумма по коду вычета
  addition_code      varchar2(10)        , --дополнительный код операции (код вычета и др.)
  addition_id        int                 , --дополнительный внешний идентификатор, ссылка на внешний справокчник, например, payments.participant_taxdeductions
  gf_person          int                 , --ID контрагента для пособий (остальные определяются динамически!)
  process_id         int                 ,
  method             varchar2(1)         , --метод добавления (A)utomate/(M)anual
  is_deleted         varchar2(1)         , --флаг удаления из движения + set is_disabled = 'Y'
  is_disabled        varchar2(1)         , --флаг деактивации строки - строка не видна из dv_sr_lspv_det_v
  created_by         varchar2(32)        , --заполняется при ручной коррекции
  created_at         date                , --заполняется при ручной коррекции
  last_updated_by    varchar2(32)        , --заполняется при ручной коррекции
  last_updated_at    date                , --заполняется при ручной коррекции
  constraint dv_sr_lspv_det_prc_fk
    foreign key (process_id)
    references dv_sr_lspv_prc_t(id)      ,
  constraint dv_sr_lspv_det_dv_fk
    foreign key (fk_dv_sr_lspv)
    references dv_sr_lspv#(id)      ,
  constraint dv_sr_lspv_det_dv_trg_fk
    foreign key (fk_dv_sr_lspv_trg)
    references dv_sr_lspv#(id)
)
/
create index dv_sr_lspv_det_prc_ix on dv_sr_lspv_det_t(process_id)
/
create index dv_sr_lspv_det_dv_ix on dv_sr_lspv_det_t(fk_dv_sr_lspv)
/
create index dv_sr_lspv_det_dv_ix2 on dv_sr_lspv_det_t(fk_dv_sr_lspv_trg)
/
/*alter table dv_sr_lspv_det_t add
  constraint dv_sr_lspv_det_dv_fk 
  foreign key (fk_dv_sr_lspv) 
  references dv_sr_lspv(id)
  on delete cascade
--
create table log$_dv_sr_lspv_det_t( --логирование ручных изменений!
  id                 int,
  action             varchar2(1),
  action_date        date default current_date,
  action_by          varchar2(32),
  fk_dv_sr_lspv      int, --операция основание записи
  fk_dv_sr_lspv_trg  int,                  --корректируемая операция
  amount             number(10, 2),        --сумма коррекции/сумма по коду вычета
  addition_code      varchar2(10),         --дополнительный код операции (код вычета и др.)
  addition_id        int,
  gf_person          int                 , --ID контрагента для пособий (остальные определяются динамически!)
  process_id         int,
  method             varchar2(1),          --метод добавления (A)utomate/(M)anual
  created_by         varchar2(32),         --заполняется при ручной коррекции
  created_at         date,
  is_deleted         varchar2(1),
  is_disabled        varchar2(1),
  last_updated_by    varchar2(32),         --заполняется при ручной коррекции
  last_updated_at    date
)
*/
