create or replace view contragent_merge_log_v as
  select m.id,
         level lvl,
         m.transaction_group,
         m.fk_person_removed,
         connect_by_root(m.fk_person_removed) fk_person_removed_root,
         m.fk_person_united,
         m.table_name,
         m.column_name,
         m.op_date,
         m.op_type,
         m.undo_date,
         m.info
  from   gazfond.contragent_merge_log m
  where  m.table_name = 'PEOPLE'
  connect by prior m.fk_person_united = m.fk_person_removed
  and        prior m.table_name = m.table_name
/
