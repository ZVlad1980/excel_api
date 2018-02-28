create sequence dv_sr_lspv_det_seq cache 10000 order
/
create table dv_sr_lspv_det_t( --детализация движения средств
  id                 int
    default dv_sr_lspv_det_seq.nextval
    constraint dv_sr_lspv_det_pk primary key,
  charge_type        varchar2(8) not null, --тип операции (Revenue, Benefit, Tax)
  fk_dv_sr_lspv      int         not null, --операция основание записи
  fk_dv_sr_lspv_trg  int                 , --корректируемая операция
  amount             number(10, 2)       , --сумма коррекции/сумма по коду вычета
  addition_code      varchar2(10)        , --дополнительный код операции (код вычета и др.)
  process_id         int                 ,
  method             varchar2(1)         , --метод добавления (A)utomate/(M)anual
  created_by         varchar2(32)        , --заполняется при ручной коррекции
  created_at         date                , --заполняется при ручной коррекции
  is_deleted         varchar2(1)         , --флаг удаления из движения + set is_disabled = 'Y'
  is_disabled        varchar2(1)         , --флаг деактивации строки - строка не видна из dv_sr_lspv_det_v
  last_updated_by    varchar2(32)        , --заполняется при ручной коррекции
  last_updated_at    date
    default current_date                 ,
  constraint dv_sr_lspv_det_prc_fk
    foreign key (process_id)
    references dv_sr_lspv_prc_t(id)
)
/
create table log$_dv_sr_lspv_det_t( --логирование ручных изменений!
  id                 int,
  action             varchar2(1),
  action_date        date default current_date,
  action_by          varchar2(32),
  charge_type        varchar2(8), --тип операции (Revenue, Benefit, Tax)
  fk_dv_sr_lspv      int, --операция основание записи
  fk_dv_sr_lspv_trg  int,                  --корректируемая операция
  amount             number(10, 2),        --сумма коррекции/сумма по коду вычета
  addition_code      varchar2(10),         --дополнительный код операции (код вычета и др.)
  process_id         int,
  method             varchar2(1),          --метод добавления (A)utomate/(M)anual
  created_by         varchar2(32),         --заполняется при ручной коррекции
  created_at         date,
  is_deleted         varchar2(1),
  is_disabled        varchar2(1),
  last_updated_by    varchar2(32),         --заполняется при ручной коррекции
  last_updated_at    date
)
/
