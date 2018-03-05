create sequence dv_sr_lspv_det_seq cache 10000 order
/
create table dv_sr_lspv_det_t( --детализация движения средств
  id                 int
    default dv_sr_lspv_det_seq.nextval
    constraint dv_sr_lspv_det_pk primary key,
  detail_type        varchar2(8) not null      --тип детализации: BENEFIT, CORRECTION
    constraint dv_sr_lspv_det_type
    check (detail_type in ('BENEFIT', 'CORRECTION')),
  fk_dv_sr_lspv      int         not null, --операция основание записи
  fk_dv_sr_lspv_trg  int                 , --корректируемая операция
  amount             number(10, 2)       , --сумма коррекции/сумма по коду вычета
  addition_code      varchar2(10)        , --дополнительный код операции (код вычета и др.)
  addition_id        int                 , --дополнительный внешний идентификатор, ссылка на внешний справокчник, например, payments.participant_taxdeductions
  process_id         int                 ,
  method             varchar2(1)         , --метод добавления (A)utomate/(M)anual
  is_deleted         varchar2(1)         , --флаг удаления записи
  fk_dv_sr_lspv_det  int                 , --ID операции источника (при перемещении средств с одной расшифровки на другую)
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
    references dv_sr_lspv#(id)      ,
  constraint dv_sr_lspv_det_det_fk
    foreign key (fk_dv_sr_lspv_det)
    references dv_sr_lspv_det_t(id)
)
/
create index dv_sr_lspv_det_prc_ix on dv_sr_lspv_det_t(process_id)
/
create index dv_sr_lspv_det_dv_ix on dv_sr_lspv_det_t(fk_dv_sr_lspv)
/
create index dv_sr_lspv_det_dv_ix2 on dv_sr_lspv_det_t(fk_dv_sr_lspv_trg)
/
create index dv_sr_lspv_det_type_ix on dv_sr_lspv_det_t(detail_type)
/
