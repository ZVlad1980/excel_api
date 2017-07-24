create table ndfl6_headers_t(
  header_id       int generated as identity primary key,
  spr_id        number,
  start_date      date,
  end_date        date,
  created_at      timestamp default systimestamp,
  create_by       varchar2(32) default user,
  last_updated_at timestamp default systimestamp,
  last_update_by  varchar2(32) default user,
  state           varchar2(20) default 'New'
)
/
