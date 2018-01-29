create or replace package body dv_sr_lspv_docs_api is

  -- Private type declarations
  C_PACKAGE_NAME constant varchar2(32) := $$plsql_unit;
  
  --Имена процессов 
  С_PRC_SYNCHRONIZE       constant varchar2(40) := 'SYNCHRONIZE';
  C_PRC_UPDATE_GF_PERSONS constant varchar2(40) := 'UPDATE_GF_PERSONS';
  
  --
  G_START_DATE      date;
  G_END_DATE        date;
  G_IS_BUF          varchar2(1) := 'N';
  G_START_DATE_BUF  date;
  G_END_DATE_BUF    date;
  G_REPORT_DATE     date; --дата, на которую формируется отчет (от этой даты зависит подхват корректировок)
  G_RESIDENT_DATE   date; --дата, на которую определяется статус резиденства контрагентов
  G_WO_EMPLOYEES    varchar2(1) := 'N'; --флаг учета данных сотрудников в отчетах (актуально для 2NDFL)
  G_2NDFL_LAST_ONLY varchar2(1) := 'Y'; --флаг учета данных только последней справки!
  
  /**
   * Обвертки обработки ошибок
   */
  procedure fix_exception(p_line number, p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => C_PACKAGE_NAME || '(' || p_line || '): ' || ' ' || p_msg
    );
  end;
  
  /**
   * Функции обвертки для представлений
   */
  function get_start_date return date deterministic is begin return G_START_DATE; end;
  function get_end_date   return date deterministic is begin return G_END_DATE; end;
  function get_year       return int deterministic is begin return extract(year from G_END_DATE); end;
  function get_is_buff    return varchar2 deterministic is begin return G_IS_BUF; end;
  function get_start_date_buf  return date deterministic is begin return G_START_DATE_BUF; end;
  function get_end_date_buf    return date deterministic is begin return G_END_DATE_BUF; end;
  function get_report_date     return date deterministic is begin return G_REPORT_DATE; end;
  function get_resident_date   return date deterministic is begin return G_RESIDENT_DATE; end;
  function get_employees  return varchar2 deterministic is begin return G_WO_EMPLOYEES; end;
  procedure set_employees(p_flag boolean) is begin G_WO_EMPLOYEES := case when p_flag then 'Y' else 'N' end; end set_employees;
  function get_last_only  return varchar2 deterministic is begin return G_2NDFL_LAST_ONLY; end;
  procedure set_last_only(p_flag boolean) is begin G_2NDFL_LAST_ONLY := case when p_flag then 'Y' else 'N' end; end set_last_only;
  
  /**
   * Процедуры set_is_buff и unset_is_buff - включают и выключают учет буфера расчетов VYPLACH... в представлениях
   */
  procedure set_is_buff is
  begin 
    G_IS_BUF         := 'Y';
    if extract(month from trunc(G_END_DATE)) = 12 then
      unset_is_buff;
    else
      G_START_DATE_BUF := trunc(G_END_DATE) + 1;
      G_END_DATE_BUF   := add_months(trunc(G_START_DATE_BUF, 'MM'), 1) - 1;
    end if;
  end set_is_buff;
  
  procedure unset_is_buff is 
  begin 
    G_IS_BUF := 'N'; 
    G_START_DATE_BUF := null;
    G_END_DATE_BUF := null;
  end unset_is_buff;
  
  /**
   * Процедура set_period устанавливает глобальные переменные для ограничений в представлениях
   */
  procedure set_period(
    p_start_date  date,
    p_end_date    date,
    p_report_date date default null
  ) is
  begin
    --
    G_START_DATE      := p_start_date;
    G_END_DATE        := trunc(p_end_date) + 1 - .00001; --на конец суток
    G_WO_EMPLOYEES    := 'N'; --по умолчанию - сброс, т.к. для выверки не актуально!
    G_2NDFL_LAST_ONLY := 'Y';
    --
    G_REPORT_DATE   := greatest(
                         nvl(p_report_date, 
                           case 
                             when extract(year from G_END_DATE) < extract(year from sysdate) then 
                               (trunc(sysdate) + .99999) 
                             else G_END_DATE 
                           end
                         ),
                         G_END_DATE
                       );
    G_RESIDENT_DATE := trunc(least(G_REPORT_DATE, to_date((extract(year from G_END_DATE)) || '1231', 'yyyymmdd')));
    --
    if get_is_buff = 'Y' then
      set_is_buff; --пересчет периода, если включен учет буфера VYPLACH
    else
      unset_is_buff;
    end if;
  end set_period;
  
  procedure set_period(
    p_end_date date,
    p_report_date date default null
  ) is
  begin
    set_period(
      p_start_date  => trunc(p_end_date, 'Y'),
      p_end_date    => p_end_date,
      p_report_date => p_report_date
    );
  end set_period; 
  
  /**
   * Процедура установки периода
   */
  procedure set_period(
    p_year number,
    p_report_date date default null
  ) is
    l_end_date date;
  begin
    if not p_year between 1995 and 2030 then
      fix_exception($$plsql_line, 'Year no correct: ' || p_year);
      raise utl_error_api.G_EXCEPTION;
    end if;
    --
    if p_year = extract(year from sysdate) then
      l_end_date := trunc(sysdate, 'MM') - .00001; --дата завершения - предыдущий месяц
    else
      l_end_date := to_date(p_year || '1231', 'yyyymmdd') + .99999;
    end if;
    --
    set_period(
      p_start_date  => to_date(p_year || '0101', 'yyyymmdd'),
      p_end_date    => l_end_date,
      p_report_date => p_report_date
    );
    --
  exception
    when others then
      fix_exception($$plsql_line, 'set_period(' || p_year || ')');
      raise;
  end set_period;
  
  /**
   *
   */
  function  get_last_update_date(p_year in number) return timestamp is
    l_result timestamp;
  begin
    --
    select max(p.created_at) last_update --to_char(max(p.created_at), 'dd.mm.yyyy hh24:mi:ss') last_update
    into   l_result
    from   dv_sr_lspv_prc_t p
    where  extract(year from p.end_date) = p_year;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'get_last_update_date(' || p_year || ')');
      raise;
  end get_last_update_date;
  
  /**
   */
  function get_process_row(
    p_process_id dv_sr_lspv_prc_t.id%type
  ) return dv_sr_lspv_prc_t%rowtype is
    l_result dv_sr_lspv_prc_t%rowtype;
  begin
    --
    select *
    into   l_result
    from   dv_sr_lspv_prc_t p
    where  p.id = p_process_id;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'get_process_row(' || p_process_id || ')');
      raise;
  end get_process_row;

  /**
   * Процедура create_process создает новый процесс в таблице dv_sr_lspv_prc_t
   */
  function create_process(
    p_process_name varchar2 default С_PRC_SYNCHRONIZE
  ) return dv_sr_lspv_prc_t.id%type is
    --
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
    --
    l_process_row.process_name := p_process_name;
    l_process_row.start_date := G_START_DATE;
    l_process_row.end_date   := G_END_DATE;
    --
    dv_sr_lspv_prc_api.set_process_state(
      p_process_row => l_process_row
    );
    --
    return l_process_row.id;
    --
  exception
    when others then
      rollback;
      fix_exception($$plsql_line, 'create_process');
      raise;
  end create_process;
  
  /**
   */
  procedure set_process_state(
    p_process_id      dv_sr_lspv_prc_t.id%type,
    p_state           dv_sr_lspv_prc_t.state%type,
    p_error_msg       dv_sr_lspv_prc_t.error_msg%type    default null,
    p_deleted_rows    dv_sr_lspv_prc_t.deleted_rows%type default null,
    p_error_rows      dv_sr_lspv_prc_t.error_rows%type   default null
  ) is
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
    --
    l_process_row.id              := p_process_id  ;
    l_process_row.state           := p_state       ;
    l_process_row.error_msg       := p_error_msg   ;
    l_process_row.deleted_rows    := p_deleted_rows;
    l_process_row.error_rows      := p_error_rows  ;
    
    dv_sr_lspv_prc_api.set_process_state(
      p_process_row => l_process_row
    );
    --
  exception
    when others then
      rollback;
      fix_exception($$plsql_line, 'set_process_state(' || p_process_id || ',' || p_state || ')');
      raise;
  end set_process_state;
  
  /**
   */
  function get_error_rows_cnt(
    p_process_id dv_sr_lspv_prc_t.id%type
  ) return dv_sr_lspv_prc_t.error_rows%type is
    l_result dv_sr_lspv_prc_t.error_rows%type;
  begin
    --
    select count(1)
    into   l_result
    from   err$_dv_sr_lspv_docs_t ed
    where  ed.process_id = p_process_id;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'get_error_rows_cnt(' || p_process_id || ')');
      raise;
  end get_error_rows_cnt;
  
  /**
   * Процедура update_sp_tax_residents_t обновляет историю изменений статуса налогового резидента контрагентов
   */
  procedure update_tax_residents_t(
    p_process_id dv_sr_lspv_prc_t.id%type
  ) is
    --
    cursor l_residents_cur is
      with sp_tax_residents_w as (
        select tr.id,
               tr.fk_contragent,
               tr.start_date,
               tr.end_date
        from   sp_tax_residents_t tr
        where  nvl(tr.is_disable, 'N') = 'N'
        and    tr.resident = 'N'
      )
      select r.fk_contragent,
             r.start_date,
             r.end_date,
             tr.id          start_id,
             tr.start_date  trg_start_date,
             tr2.id         end_id,
             tr2.end_date   trg_end_date
      from   sp_tax_residents_src_v r,
             sp_tax_residents_w     tr,
             sp_tax_residents_w     tr2
      where  1=1
      --
      and    r.end_date between tr2.start_date(+) and tr2.end_date(+)
      and    tr2.fk_contragent(+) = r.fk_contragent
      --
      and    r.start_date between tr.start_date(+) and tr.end_date(+)
      and    tr.fk_contragent(+) = r.fk_contragent
      --
      and    not exists (
               select 1
               from   sp_tax_residents_w tr
               where  tr.fk_contragent = r.fk_contragent
               and    tr.start_date = r.start_date
               and    tr.end_date = r.end_date
             );
    --
    type l_residents_type is table of l_residents_cur%rowtype;
    l_residents_tbl l_residents_type;
    l_disable_list  sys.odcinumberlist;
    --
    procedure append_disable_id_(p_id int) is
    begin
      l_disable_list.extend;
      l_disable_list(l_disable_list.last) := p_id;
    end;
    --
    --
    function prepare_row_(
      p_row in out nocopy l_residents_cur%rowtype
    ) return boolean is
      l_result   boolean := true;
      --
      cursor l_incl_rows_cur(p_start_date date, p_end_date date) is
        select tr.id
        from   sp_tax_residents_t tr
        where  tr.start_date > p_start_date
        and    nvl(tr.end_date, sysdate) < nvl(p_end_date, sysdate);
      --
    begin
      --
      if p_row.start_id is not null then
        append_disable_id_(p_row.start_id);
      end if;
      --
      if p_row.end_id is not null and p_row.end_id <> nvl(p_row.start_id, -1) then
        append_disable_id_(p_row.end_id);
      end if;
      --
      for r in l_incl_rows_cur(p_row.start_date, p_row.end_date) loop
        append_disable_id_(r.id);
      end loop;
      --
      return l_result;
      --
    exception
      when others then
        fix_exception($$plsql_line, 'get_error_rows_cnt(' || p_process_id || ')');
        raise;
    end prepare_row_;
    --
  begin
    --
    l_residents_tbl := l_residents_type();
    l_disable_list  := sys.odcinumberlist();
    --
    for r in l_residents_cur loop
      if prepare_row_(r) then
        l_residents_tbl.extend;
        l_residents_tbl(l_residents_tbl.last) := r;
      end if;
    end loop;
    --
    forall i in 1..l_disable_list.count
      update sp_tax_residents_t tr
      set    tr.is_disable = 'Y'
      where  tr.id = l_disable_list(i);
    --
    forall i in 1..l_residents_tbl.count
      insert into sp_tax_residents_t(
        fk_contragent,
        start_date,
        end_date,
        process_id
      ) values (
        l_residents_tbl(i).fk_contragent,
        l_residents_tbl(i).start_date,
        l_residents_tbl(i).end_date,
        p_process_id
      );
    --
  exception
    when others then
      fix_exception($$plsql_line, 'update_tax_residents_t');
      raise;
  end update_tax_residents_t;
  
  /**
   * Процедура update_sp_tax_residents_t обвертка для вызова
   *   update_tax_residents_t снаружи (устанавливает глобальные переменные по p_process_id)
   */
  procedure update_sp_tax_residents_t(
    p_process_id dv_sr_lspv_prc_t.id%type
  ) is
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
    --
    l_process_row := get_process_row(p_process_id => p_process_id);
    set_period(
      p_start_date => l_process_row.start_date, 
      p_end_date   => l_process_row.end_date
    );
    update_tax_residents_t(p_process_id => p_process_id);
    --
  exception
    when others then
      fix_exception($$plsql_line, 'update_sp_tax_residents_t(' || p_process_id || ')');
      raise;
  end update_sp_tax_residents_t;
  
  /**
   *
   */
  procedure update_dv_sr_lspv_docs_t(
    p_process_id dv_sr_lspv_prc_t.id%type
  ) is
    l_del_rows number;
  begin
    --
    set_process_state(
      p_process_id, 
      'PROCESSED'
    );
    --
    merge into dv_sr_lspv_docs_t d
    using (select dc.date_op, 
                  dc.ssylka_doc_op, 
                  dc.type_op, 
                  dc.date_doc, 
                  dc.ssylka_doc, 
                  dc.nom_vkl, 
                  dc.nom_ips, 
                  dc.ssylka_fl, 
                  dc.gf_person, 
                  dc.pen_scheme_code,
                  dc.tax_rate, 
                  dc.det_charge_type,
                  dc.revenue, 
                  dc.benefit, 
                  dc.tax,
                  dc.source_revenue, 
                  dc.source_benefit, 
                  dc.source_tax,
                  dc.is_tax_return
           from   dv_sr_lspv_docs_src_v  dc
           where  coalesce(abs(dc.revenue), 0) + 
                  coalesce(abs(dc.benefit), 0) + 
                  coalesce(abs(dc.tax),     0)
                   >= 0.01
         ) u
    on   (d.date_op       = u.date_op         and 
          d.ssylka_doc_op = u.ssylka_doc_op   and 
          d.date_doc      = u.date_doc        and 
          d.ssylka_doc    = u.ssylka_doc      and 
          d.nom_vkl       = u.nom_vkl         and 
          d.nom_ips       = u.nom_ips         and 
          d.gf_person     = u.gf_person       and 
          d.tax_rate      = u.tax_rate
         )
    when matched then
      update set
        d.type_op         = u.type_op,
        d.det_charge_type = u.det_charge_type,
        d.revenue         = u.revenue, 
        d.benefit         = u.benefit, 
        d.tax             = u.tax,
        d.source_revenue  = u.source_revenue,
        d.source_benefit  = u.source_benefit,
        d.source_tax      = u.source_tax,
        d.is_tax_return   = u.is_tax_return,
        d.process_id      = p_process_id,
        d.is_delete       = null
    when not matched then
      insert (
        id,
        date_op, 
        ssylka_doc_op, 
        type_op, 
        date_doc, 
        ssylka_doc, 
        nom_vkl, 
        nom_ips, 
        ssylka_fl, 
        gf_person, 
        pen_scheme_code, 
        tax_rate, 
        det_charge_type, 
        revenue, 
        benefit, 
        tax,
        source_revenue,
        source_benefit,
        source_tax,
        is_tax_return,
        process_id
      ) values (
        dv_sr_lspv_docs_seq.nextval,
        u.date_op, 
        u.ssylka_doc_op, 
        u.type_op,
        u.date_doc, 
        u.ssylka_doc, 
        u.nom_vkl, 
        u.nom_ips, 
        u.ssylka_fl, 
        u.gf_person, 
        u.pen_scheme_code,
        u.tax_rate, 
        u.det_charge_type,
        u.revenue, 
        u.benefit, 
        u.tax,
        u.source_revenue, 
        u.source_benefit, 
        u.source_tax,
        u.is_tax_return,
        p_process_id
      )
      log errors into err$_dv_sr_lspv_docs_t reject limit unlimited;
    --
    update dv_sr_lspv_docs_t d
    set    d.is_delete = 'Y'
    where  1=1
    and    d.is_delete is null
    and    d.process_id <> p_process_id
    and    (
            (d.date_doc between get_start_date and get_end_date)
            or
            (d.date_op between get_start_date and get_end_date)
           );
    --
    l_del_rows := sql%rowcount;
    --
    set_process_state(
      p_process_id, 
      'DOCS', 
      p_deleted_rows => l_del_rows,
      p_error_rows   => get_error_rows_cnt(p_process_id)
    );
    --
  exception
    when others then
      fix_exception($$plsql_line, 'update_dv_sr_lspv_docs_t');
      raise;
  end update_dv_sr_lspv_docs_t;

  /**
   * Процедура synchronize синхронизирует таблицу dv_sr_lspv_docs_t данными из таблицы fnd.dv_sr_lspv
   *  за указанный год (p_year)
   */
  procedure synchronize(p_year in number) is
    --
    l_process_id int;
    --
    function check_update_gf_persons_ return boolean is
      l_last_start date;
    begin
      select max(p.created_at)
      into   l_last_start
      from   dv_sr_lspv_prc_t p
      where  p.process_name = 'UPDATE_GF_PERSONS';
      --
      return trunc(sysdate) - trunc(l_last_start) >= 1;
    exception
      when no_data_found then
        return true;
      when others then
        fix_exception($$plsql_line, 'check_update_gf_persons_');
        raise;
    end check_update_gf_persons_;
    --
    --
    procedure stats_ is
    begin
      dbms_stats.gather_table_stats('FND', upper('dv_sr_lspv_docs_t'), cascade => true);
    end;
    --
  begin
    --Обновление GF_PERSONS запускает в процессе проверки ошибок, здесь только для страховки
    if check_update_gf_persons_ then
      update_gf_persons(p_year);
    end if;
    --
    set_period(p_year);
    --
    l_process_id := create_process;
    --
    update_dv_sr_lspv_docs_t(
      p_process_id => l_process_id
    );
    --
    update_tax_residents_t(
      p_process_id => l_process_id
    );
    --
    stats_;
    --
    set_process_state(
      l_process_id, 
      'SUCCESS', 
      p_error_rows   => get_error_rows_cnt(l_process_id)
    );
    --
  exception
    when others then
      fix_exception($$plsql_line, 'synchronize(' || p_year || ')');
      --
      if l_process_id is not null then
        set_process_state(
          l_process_id, 
          'ERROR', 
          p_error_msg => sqlerrm
        );
      end if;
      raise;
  end synchronize;
  
  /**
   * Процедура build_list_gf_persons строит список неактуальных / отсутствующих GF_PERSON
   *  в таблице DV_SR_LSPV_UID_PERS_T
   */
  procedure build_list_gf_persons(
    p_process_id int
  ) is
    --
    procedure insert_gf_persons_ is
    begin
      insert into dv_sr_gf_persons_t(
        contragent_type,
        nom_vkl,
        nom_ips,
        ssylka,
        gf_person_old,
        gf_person_new,
        process_id
      ) select gp.contragent_type,
               gp.nom_vkl,
               gp.nom_ips,
               gp.ssylka,
               case gp.gf_person when -1 then null else gp.gf_person end,
               (select max(m.fk_person_united)keep(dense_rank last order by m.lvl) 
                from   contragent_merge_log_v m
                where  1=1
                and    m.fk_person_removed_root = gp.gf_person
               ) gf_person_new,
               p_process_id
        from   sp_gf_persons_v        gp
        where  1=1
        and    gp.gf_person not in (
                 select p.fk_contragent
                 from   gf_people_v p
               );
    exception
      when others then
        fix_exception($$plsql_line, 'insert_gf_persons_(' || p_process_id || ')');
        raise;
    end insert_gf_persons_;
    --
    -- Определение GF_PERSON по ИНН (которые не определены изначально)
    --
    procedure update_gf_person_inn_ is
    begin
      update dv_sr_gf_persons_t  gp
      set    gp.gf_person_new = (
               select c.id
               from   sp_inn_fiz_lits     inn,
                      gazfond.contragents c
               where  1=1
               and    c.inn = inn.inn
               and    inn.ssylka = gp.ssylka
             )
      where  gp.gf_person_new is null
      and    gp.contragent_type = 'PENSIONER'
      and    gp.process_id = p_process_id;
    exception
      when others then
        fix_exception($$plsql_line, 'update_gf_person_inn_(' || p_process_id || ')');
        raise;
    end update_gf_person_inn_;
    --
    -- Определение GF_PERSON по ФИО + ДР
    --
    procedure update_gf_person_fio_ is
    begin
      update dv_sr_gf_persons_t  gp
      set    gp.gf_person_new = (
               select p.fk_contragent
               from   (
                       select p.fk_contragent,
                              count(1)over(partition by p.fk_contragent) cnt
                       from   sp_fiz_lits         fl,
                              gf_people_v         p
                       where  1=1
                       --
                       and    p.birthdate = fl.data_rogd
                       and    nvl(upper(p.secondname), '$NULL$') = nvl(upper(fl.otchestvo), '$NULL$')
                       and    upper(p.firstname) = upper(fl.imya)
                       and    upper(p.lastname) = upper(fl.familiya)
                       --
                       and    fl.ssylka = gp.ssylka
                      ) p
               where  p.cnt = 1
             )
      where  gp.gf_person_new is null
      and    gp.contragent_type = 'PENSIONER'
      and    gp.process_id = p_process_id;
      --
      update dv_sr_gf_persons_t  gp
      set    gp.gf_person_new = (
               select p.fk_contragent
               from   (
                       select p.fk_contragent,
                              count(1)over(partition by p.fk_contragent) cnt
                       from   sp_ritual_pos_v     fl,
                              gf_people_v         p
                       where  1=1
                       --
                       and    p.birthdate = fl.birth_date 
                       and    nvl(upper(p.secondname), '$NULL$') = nvl(upper(fl.second_name ), '$NULL$')
                       and    upper(p.firstname) = upper(fl.first_name )
                       and    upper(p.lastname) = upper(fl.last_name )
                       --
                       and    fl.ssylka = gp.ssylka
                      ) p
               where  p.cnt = 1
             )
      where  gp.gf_person_new is null
      and    gp.contragent_type = 'SUCCESSOR'
      and    gp.process_id = p_process_id;
    exception
      when others then
        fix_exception($$plsql_line, 'update_gf_person_inn_(' || p_process_id || ')');
        raise;
    end update_gf_person_fio_;
    --
  begin
    --
    insert_gf_persons_;
    update_gf_person_inn_;
    update_gf_person_fio_;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'build_list_gf_persons(' || p_process_id || ')');
      raise;
  end build_list_gf_persons;
  
  /**
   * Процедура update_gf_persons обновляет GF_PERSONS
   *  в таблицах SP_FIZ_LITS.GF_PERSON, POLUCH_POSOB.GF_PERSON, SP_RITUAL_POS.FK_CONTRAGENT, DV_SR_LSPV_DOCS_T.GF_PEROSN
   *  по таблице DV_SR_LSPV_UID_PERS_T
   */
  procedure update_gf_persons(
    p_process_id int
  ) is
    --
    -- Обновление GF_PERSON в sp_fiz_lits
    --
    procedure update_pensioners_ is
    begin
      update (select fl.ssylka,
                     fl.gf_person,
                     gp.gf_person_new
              from   dv_sr_gf_persons_t gp,
                     sp_fiz_lits        fl
              where  1=1
              and    nvl(fl.gf_person, -1) <> gp.gf_person_new
              and    fl.ssylka = gp.ssylka
              and    gp.contragent_type = 'PENSIONER'
              and    gp.process_id = p_process_id
             ) u
      set u.gf_person = u.gf_person_new;
    exception
      when others then
        fix_exception($$plsql_line, 'update_pensioners_(' || p_process_id || ')');
        raise;
    end update_pensioners_;
    --
    -- Обновление GF_PERSON в sp_ritual_pos
    --
    procedure update_successors_ is
    begin
      update (select fl.ssylka,
                     fl.fk_contragent,
                     gp.gf_person_new
              from   dv_sr_gf_persons_t gp,
                     sp_ritual_pos      fl
              where  1=1
              and    nvl(fl.fk_contragent, -1) <> gp.gf_person_new
              and    fl.ssylka = gp.ssylka
              and    gp.contragent_type = 'SUCCESSOR'
              and    gp.process_id = p_process_id
             ) u
      set u.fk_contragent = u.gf_person_new;
      --
      /*
      update (select fl.ssylka,
                     fl.fk_contragent,
                     gp.gf_person_new
              from   dv_sr_gf_persons_t gp,
                     vyplach_posob      fl
              where  1=1
              and    fl.ssylka = gp.ssylka
              and    gp.contragent_type = 'PENSIONER'
              and    gp.process_id = p_process_id
             ) u
      set u.fk_contragent = u.gf_person_new;
      --*/
    exception
      when others then
        fix_exception($$plsql_line, 'update_successors_(' || p_process_id || ')');
        raise;
    end update_successors_;
    --
    -- Обновление GF_PERSON в dv_sr_lspv_docs_t
    --
    procedure update_docs_t_ is
    begin
      merge into dv_sr_lspv_docs_t d
      using (select dd.id,
                    gp.gf_person_new
             from   dv_sr_gf_persons_t gp,
                    dv_sr_lspv_docs_t  dd
             where  1 = 1
             and    dd.gf_person = gp.gf_person_old
             and    gp.gf_person_old is not null
             and    gp.process_id = p_process_id
            ) u
      on    (d.id = u.id)
      when matched then
        update set
        d.gf_person = u.gf_person_new;
    exception
      when others then
        fix_exception($$plsql_line, 'update_docs_t_(' || p_process_id || ')');
        raise;
    end update_docs_t_;
    --
    -- Обновление GF_PERSON в f2ndfl_arh_nomspr
    --
    procedure update_arh_nomspr_t_ is
    begin
      merge into f2ndfl_arh_nomspr ns
      using (select ns.kod_na,
                    ns.god,
                    ns.ssylka,
                    ns.tip_dox,
                    ns.flag_otmena,
                    gp.gf_person_new
             from   dv_sr_gf_persons_t gp,
                    f2ndfl_arh_nomspr  ns
             where  1 = 1
             and    ns.fk_contragent = gp.gf_person_old
             and    gp.gf_person_old is not null
             and    gp.process_id = p_process_id
            ) u
      on    (ns.kod_na      = u.kod_na      and
             ns.god         = u.god         and
             ns.ssylka      = u.ssylka      and
             ns.tip_dox     = u.tip_dox     and
             ns.flag_otmena = u.flag_otmena
            )
      when matched then
        update set
        ns.fk_contragent = u.gf_person_new;
    exception
      when others then
        fix_exception($$plsql_line, 'update_arh_nomspr_t_(' || p_process_id || ')');
        raise;
    end update_arh_nomspr_t_;
    --
    -- Обновление GF_PERSON в f_ndfl_load_nalplat
    --
    procedure update_ndfl_load_nalplat_ is
    begin
      merge into f_ndfl_load_nalplat ns
      --KOD_NA, GOD, SSYLKA_TIP, NOM_VKL, NOM_IPS
      using (select ns.kod_na,
                    ns.god,
                    ns.ssylka_tip,
                    ns.nom_vkl,
                    ns.nom_ips,
                    gp.gf_person_new
             from   dv_sr_gf_persons_t  gp,
                    f_ndfl_load_nalplat ns
             where  1 = 1
             and    ns.gf_person  = gp.gf_person_old
             and    gp.gf_person_old is not null
             and    gp.process_id = p_process_id
            ) u
      on    (ns.kod_na      = u.kod_na      and
             ns.god         = u.god         and
             ns.ssylka_tip  = u.ssylka_tip      and
             ns.nom_vkl     = u.nom_vkl     and
             ns.nom_ips     = u.nom_ips
            )
      when matched then
        update set
        ns.gf_person = u.gf_person_new;
    exception
      when others then
        fix_exception($$plsql_line, 'update_ndfl_load_nalplat_(' || p_process_id || ')');
        raise;
    end update_ndfl_load_nalplat_;
    --
  begin
    --
    update_pensioners_;
    update_successors_;
    update_docs_t_;
    update_arh_nomspr_t_;
    update_ndfl_load_nalplat_;
    --
  exception
    when others then
      fix_exception($$plsql_line, 'update_gf_persons(' || p_process_id || ')');
      raise;
  end update_gf_persons;
  
  /**
   * Процедура обновления GF_PERSON по DV_SR_LSPV за заданный год
   *  Обновляет таблицы SP_FIZ_LITS.GF_PERSON, POLUCH_POSOB.GF_PERSON, SP_RITUAL_POS.FK_CONTRAGENT, DV_SR_LSPV_DOCS_T.GF_PEROSN
   *  Протокол работы в dv_sr_gf_persons_t
   */
  procedure update_gf_persons(
    p_year  in number
  ) is
    --
    l_process_id int;
    --
  begin
    --
    set_period(p_year);
    --
    l_process_id := create_process(
      p_process_name => C_PRC_UPDATE_GF_PERSONS
    );
    --
    build_list_gf_persons(
      p_process_id => l_process_id
    );
    --
    update_gf_persons(
      p_process_id => l_process_id
    );
    --
    set_process_state(
      l_process_id, 
      'SUCCESS'
    );
    --
  exception
    when others then
      fix_exception($$plsql_line, 'update_gf_persons(' || p_year || ')');
      if l_process_id is not null then
        set_process_state(
          l_process_id, 
          'ERROR', 
          p_error_msg => sqlerrm
        );
      end if;
      raise;
  end update_gf_persons;
  
  
  /**
   * Функция определяет является ли операция - возвратом налога по заявлению
   *
   *  На текущий момент, к таковым относятся:
   *    - операции коррекции налога по выкупным суммам
   *    - операции коррекции налога по пенсии, при наличии операции по 83 счету и этому же документу на обратную сумму
   */
  function is_tax_return(
    p_nom_vkl          fnd.dv_sr_lspv.nom_vkl%type,
    p_nom_ips          fnd.dv_sr_lspv.nom_ips%type,
    p_date_op          fnd.dv_sr_lspv.data_op%type,
    p_shifr_schet      fnd.dv_sr_lspv.shifr_schet%type,
    p_sub_shifr_schet  fnd.dv_sr_lspv.sub_shifr_schet%type,
    p_ssylka_doc       fnd.dv_sr_lspv.ssylka_doc%type,
    p_det_charge_type  varchar2,
    p_amount           fnd.dv_sr_lspv.summa%type
  ) return varchar2 is
    --
    l_result varchar2(1) := 'N';
    --
    cursor l_ret_tax_cur is
      select a.amount
      from   dv_sr_lspv_acc_v a
      where  1=1
      and    a.date_op         < p_date_op        
      and    a.shifr_schet     = 83
      and    a.ssylka_doc      = p_ssylka_doc
      and    a.nom_vkl         = p_nom_vkl        
      and    a.nom_ips         = p_nom_ips        ;
    --
  begin
    --
    if p_det_charge_type = 'PENSION' then
      for i in l_ret_tax_cur loop
        l_result := case abs(p_amount) when abs(i.amount) then 'Y' else 'N' end;
        exit;
      end loop;
    end if;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception('is_tax_return ' || p_nom_vkl || '/'
        || p_nom_ips         || '/'
        || p_date_op         || '/'
        || p_shifr_schet     || '/'
        || p_sub_shifr_schet || '/'
        || p_ssylka_doc      || '/'
        || p_det_charge_type || '/'
        || p_amount
      );
      return null;
  end is_tax_return;
  
  /**
   * Процедура build_tax_diff формирует данные по расхождению удержанного и исчисленного налога
   *   Данные пишутся в таблицу dv_sr_lspv_tax_diff_buf, таблица перед формированием очищается!
   *
   * @param p_end_date - дата окончания периода выборки (по умолчанию - дата окончания предыдущего месяца от текущей даты)
   *
   */
  procedure build_tax_diff(
    p_end_date date default null
  ) is
  begin
    --
    set_period(
      p_end_date => nvl(p_end_date, trunc(sysdate, 'MM') - 1)
    );
    set_is_buff;
    --
    execute immediate 'truncate table dv_sr_lspv_tax_diff_buf';
    --
    insert into dv_sr_lspv_tax_diff_buf(
      gf_person,
      lastname,
      firstname,
      secondname,
      ssylka_fl,
      nom_vkl,
      nom_ips,
      pen_scheme,
      revenue_shifr_schet,
      tax_shifr_schet,
      revenue,
      benefit,
      tax,
      tax_retained,
      tax_calc,
      tax_diff
    ) select d.gf_person,
             d.lastname, 
             d.firstname, 
             d.secondname,
             d.ssylka_fl,
             d.nom_vkl,
             d.nom_ips, 
             d.pen_scheme,
             d.revenue_shifr_schet,
             d.tax_shifr_schet,
             d.revenue, 
             d.benefit, 
             d.tax,
             case row_number()over(partition by d.gf_person order by d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips)
               when 1 then d.tax_retained
             end tax_retained,
             case row_number()over(partition by d.gf_person order by d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips)
               when 1 then d.tax_calc
             end tax_calc, 
             case row_number()over(partition by d.gf_person order by d.pen_scheme, d.det_charge_type, d.tax_rate_op, d.nom_vkl, d.nom_ips)
               when 1 then d.tax_diff
             end tax_diff
      from   dv_sr_lspv_tax_diff_det_v d;
    --
  exception
    when others then
      fix_exception($$plsql_line);
      dbms_output.put_line(utl_error_api.get_exception_full);
      raise;
  end build_tax_diff;

begin
  set_period(p_end_date => trunc(sysdate, 'MM') - 1);
end dv_sr_lspv_docs_api;
/
