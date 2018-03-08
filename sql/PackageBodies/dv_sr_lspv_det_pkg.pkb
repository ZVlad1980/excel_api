create or replace package body dv_sr_lspv_det_pkg is

  -- Private type declarations
  GC_PACKAGE_NAME   constant varchar2(32)                       := $$plsql_unit;  
  GС_PRC_UPDATE_DET constant dv_sr_lspv_prc_t.process_name%type := 'UPDATE_DETAIL';
  --GC_CHUNK_SIZE     constant int                                := 10000;
  --
  GC_ROW_STS_NEW    constant varchar2(1)                        := 'N';
  --GC_ROW_STS_UPDATE constant varchar2(1)                        := 'U';
  --GC_ROW_STS_DELETE constant varchar2(1)                        := 'D';
  --
  G_LEGACY       varchar2(1);
  
  /**
   * Обвертки обработки ошибок
   */
  procedure fix_exception(p_line number, p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => GC_PACKAGE_NAME || '(' || p_line || '): ' || ' ' || p_msg
    );
  end fix_exception;
  --
  
  function legacy return varchar2 deterministic is begin return nvl(G_LEGACY, 'N'); end legacy;
  --
  
  function get_os_user return varchar2 deterministic is
    l_result dv_sr_lspv_det_t.created_by%type;
  begin
    select substrb(sys_context( 'userenv', 'os_user'), 1,32)
    into   l_result
    from dual;
    --
    return l_result;
  exception
    when others then
      return null;
  end get_os_user;

  /**
   * Процедура create_process создает новый процесс в таблице dv_sr_lspv_prc_t
   */
  function create_process(
    p_process_name varchar2 default GС_PRC_UPDATE_DET
  ) return dv_sr_lspv_prc_t.id%type is
    --
    l_process_row dv_sr_lspv_prc_t%rowtype;
  begin
    --
    l_process_row.process_name := p_process_name;
    --
    dv_sr_lspv_prc_api.create_process(
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
    --
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
   *
   */
  function get_errors_cnt(
    p_process_id dv_sr_lspv_det_t.process_id%type
  ) return int is
    l_result int;
  begin
    --
    select count(1)
    into   l_result
    from   err$_dv_sr_lspv_det_t e
    where  e.process_id = p_process_id;
    --
    return l_result;
    --
  exception
    when others then
      rollback;
      fix_exception($$plsql_line, 'get_errors_cnt(' || p_process_id || ')');
      raise;
  end;
  
  /**
   * 
   */
  procedure update_benefits(
    p_process_id dv_sr_lspv_det_t.process_id%type,
    p_date       date,
    p_nom_vkl    int,
    p_nom_ips    int
  ) is
    --
    procedure pre_update_(p_year int) is
      l_ids sys.odcinumberlist;
    begin
      --выбираем детализации по удаленным вычетам
      select dt.id
      bulk collect into l_ids
      from   dv_sr_lspv_det_v  dt
        left join sp_ogr_benefits_v b
          on     b.pt_rid(+) = dt.addition_id
          and    b.shifr_schet = dt.shifr_schet
          and    trunc(b.regdate) <= dt.date_op
          and    dt.date_op between b.start_date and b.end_date
          and    b.nom_ips = dt.nom_ips
          and    b.nom_vkl = dt.nom_vkl
      where  1=1
      and    b.pt_rid is null
      --только счета, которые будут обрабатываться!
      and    (dt.nom_vkl, dt.nom_ips) in (
               select d.nom_vkl, d.nom_ips
               from   dv_sr_lspv#_v d
               where  d.year_op = p_year
               and    d.date_op = p_date
               and    d.status = 'N'
               and    d.nom_ips = nvl(p_nom_ips, d.nom_ips)
               and    d.nom_vkl = nvl(p_nom_vkl, d.nom_vkl)
             )
      and    dt.addition_id <> -1
      and    dt.detail_type = 'BENEFIT'
      and    dt.date_op < p_date --to_date(20180209, 'yyyymmdd')--addition_code < 0
      and    dt.year_op = p_year;
      --
      insert into dv_sr_lspv_det_t(
        detail_type,
        fk_dv_sr_lspv,
        amount,
        addition_code,
        addition_id,
        process_id,
        fk_dv_sr_lspv_det
      ) select dt.charge_type,
               fk_dv_sr_lspv,
               amount,
               dt.shifr_schet,
               -1,
               p_process_id,
               dt.id
        from   table(l_ids) t,
               dv_sr_lspv_det_v dt
        where  dt.id = t.column_value
      log errors into err$_dv_sr_lspv_det_t('pre_update_') reject limit unlimited;
      --
      update dv_sr_lspv_det_t dt
      set    dt.is_deleted = 'Y'
      where  dt.id in (select t.column_value from table(l_ids) t);
      --
      dbms_output.put_line('pre_update_: ' || l_ids.count || ' row(s) moved to shifr_schet and mark as deleted');
      --
    exception
      when others then
        fix_exception($$PLSQL_LINE, 'pre_update_');
        raise;
    end pre_update_;
    --
    -- 
    --
    procedure insert_new_ is
    begin
      --
      insert into dv_sr_lspv_det_t(
        detail_type,
        fk_dv_sr_lspv,
        amount,
        addition_code,
        addition_id,
        fk_dv_sr_lspv_trg,
        fk_dv_sr_lspv_det,
        process_id
      ) select 'BENEFIT',
               b.fk_dv_sr_lspv,
               b.benefit_amount,
               b.benefit_code,
               b.pt_rid,
               b.fk_dv_sr_lspv_trg,
               b.fk_dv_sr_lspv_det,
               p_process_id
        from   dv_sr_lspv_acc_ben_v b
        where  b.nom_ips = nvl(p_nom_ips, b.nom_ips)
        and    b.nom_vkl = nvl(p_nom_vkl, b.nom_vkl)
      log errors into err$_dv_sr_lspv_det_t('insert_new_') reject limit unlimited;
      --
      dbms_output.put_line('insert_new_: insert ' || sql%rowcount || ' row(s)');
      --
    exception
      when others then
        fix_exception($$PLSQL_LINE, 'insert_new_');
        raise;
    end insert_new_;
    --
    --
    --
    procedure post_update_ is
      cursor c_cur is
        select dt.year_op,
               dt.detail_type,
               dt.nom_vkl,
               dt.nom_ips,
               dt.fk_dv_sr_lspv,
               (round(dt.src_amount, 2) - sum(dt.amount)) corr_amount,
               dt.shifr_schet
        from   dv_sr_lspv_det_v  dt
        where  1=1
        and    dt.nom_ips = nvl(p_nom_ips, dt.nom_ips)
        and    dt.nom_vkl = nvl(p_nom_vkl, dt.nom_vkl)
        and    dt.src_service_doc >= 0
        and    dt.src_status = GC_ROW_STS_NEW
        and    dt.detail_type = 'BENEFIT'
        and    dt.date_op = p_date
        group by dt.year_op,
                 dt.detail_type,
                 dt.nom_vkl,
                 dt.nom_ips,
                 dt.fk_dv_sr_lspv,
                 dt.src_amount,
                 dt.shifr_schet
        having   (round(dt.src_amount, 2) - sum(dt.amount)) <> 0
       union all
        select d.year_op,
               'BENEFIT',
               d.nom_vkl,
               d.nom_ips,
               d.id,
               d.amount,
               d.shifr_schet
        from   dv_sr_lspv#_acc_v d
        where  1=1
        and    not exists (
                 select 1
                 from   dv_sr_lspv_det_t dt
                 where  dt.fk_dv_sr_lspv = d.id
                 and    dt.detail_type = 'BENEFIT'
                 and    dt.is_disabled is null
               )
        and    d.nom_ips = nvl(p_nom_ips, d.nom_ips)
        and    d.nom_vkl = nvl(p_nom_vkl, d.nom_vkl)
        and    d.service_doc >= 0
        and    d.charge_type = 'BENEFIT'
        and    d.date_op = p_date
        and    d.status = GC_ROW_STS_NEW;
      --
      type lt_cur_tbl_type is table of c_cur%rowtype;
      l_cur_tbl lt_cur_tbl_type;
      --
      --
      --
      procedure backdating_benefits_ is
      begin
        --
        open c_cur;
        fetch c_cur
          bulk collect into l_cur_tbl;
        close c_cur;
        --
        forall i in 1..l_cur_tbl.count
          insert into dv_sr_lspv_det_t(
            detail_type,
            fk_dv_sr_lspv,
            amount,
            addition_code,
            addition_id,
            process_id
          ) with w_benefits as (
              select b.pt_rid,
                     b.benefit_code,
                     ( select coalesce(sum(d.amount), 0)
                         from   dv_sr_lspv_det_v d
                         where  1=1
                         and    d.year_op = b.start_year
                         and    d.date_op < b.end_date
                         and    d.addition_id = b.pt_rid
                         and    d.detail_type = 'BENEFIT'
                       )                                                  total_benefits,
                     (b.end_month - b.start_month + 1) * b.benefit_amount benefit_amount
              from   sp_ogr_benefits_v b
              where  b.nom_vkl = l_cur_tbl(i).nom_vkl
              and    b.nom_ips = l_cur_tbl(i).nom_ips
              and    l_cur_tbl(i).year_op between b.start_year and b.end_year
              and    b.end_date < p_date
              and    b.regdate < p_date
            ) select 'BENEFIT',
                     l_cur_tbl(i).fk_dv_sr_lspv,
                     b.benefit_amount - nvl(b.total_benefits, 0),
                     b.benefit_code,
                     b.pt_rid,
                     p_process_id
              from   w_benefits b
              where  (abs(benefit_amount) - abs(nvl(total_benefits, 0))) > 0.01
            log errors into err$_dv_sr_lspv_det_t('backdating_benefits_') reject limit unlimited;
        --
        if l_cur_tbl.count > 0 then
          dbms_output.put_line('backdating_benefits_: insert ' || sql%rowcount || ' row(s)');
        end if;
        --
      exception
        when others then
          fix_exception($$PLSQL_LINE, 'backdating_benefits_');
          raise;
      end backdating_benefits_;
      --
      --
      --
      procedure balanced_ is
      begin
        --
        open c_cur;
        fetch c_cur
          bulk collect into l_cur_tbl;
        close c_cur;
        --
        forall i in 1..l_cur_tbl.count
          insert into dv_sr_lspv_det_t(
            detail_type,
            fk_dv_sr_lspv,
            amount,
            addition_code,
            addition_id,
            process_id
          ) values (
            l_cur_tbl(i).detail_type   ,
            l_cur_tbl(i).fk_dv_sr_lspv ,
            l_cur_tbl(i).corr_amount   ,
            l_cur_tbl(i).shifr_schet   ,
            -1,
            p_process_id
          )
          log errors into err$_dv_sr_lspv_det_t('balanced_') reject limit unlimited;
        --
        dbms_output.put_line('balanced_: insert ' || l_cur_tbl.count || ' row(s)');
        --
      exception
        when others then
          fix_exception($$PLSQL_LINE, 'backdating_benefits_');
          raise;
      end balanced_;
      --
    begin
      --
      backdating_benefits_;
      --
      balanced_;
      --
    exception
      when others then
        fix_exception($$PLSQL_LINE, 'post_update_');
        raise;
    end post_update_;
    --
  begin
    --обработка существующих детализаций по актуальному журналу регистрации вычетов
    pre_update_(extract(year from p_date));
    --обработка новых движений по вычетам
    insert_new_;
    --пост обработка для списания зависших сумм
    post_update_;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_details');
      raise;
  end update_benefits;
  
  /**
   * 
   */
  procedure update_details(
    p_process_id dv_sr_lspv_det_t.process_id%type,
    p_commit     boolean,
    p_year       int,
    p_nom_vkl    int,
    p_nom_ips    int
  ) is
    --
    type lt_date_rec is record(
      date_op date,
      benefit_exists varchar2(1),
      ritual_exists varchar2(1),
      corr_exists varchar2(1)
    );
    type lt_dates_tbl is table of lt_date_rec;
    l_dates_tbl lt_dates_tbl;
    l_month     int;
    --
    procedure build_dates_list_ is
    begin
      select a.date_op,
             max(case when a.shifr_schet > 1000 then 'Y' end)    benefit_exists,
             max(case when a.shifr_schet = 62 then 'Y' end)      ritual_exists,
             max(
               case 
                 when a.service_doc <> 0 or 
                   (a.shifr_schet <> 85 and
                    a.amount < 0
                   ) 
                   then 'Y' 
               end
             )                                                      corr_exists --*/
      bulk collect into l_dates_tbl
      from   dv_sr_lspv#_v a
      where  a.status = GC_ROW_STS_NEW
      and    a.nom_ips = nvl(p_nom_ips, a.nom_ips)
      and    a.nom_vkl = nvl(p_nom_vkl, a.nom_vkl)
      and    a.year_op = nvl(p_year,    a.year_op)
      group by a.date_op
      order by a.date_op;
      --
    end build_dates_list_;
    --
    --Сброс статусов 
    -- 
    procedure reset_statuses_ is
    begin
      --return;--... обработанных
      update dv_sr_lspv#_v d   
      set    d.status = null
      where  d.id in (
               select dt.fk_dv_sr_lspv
               from   dv_sr_lspv_det_t dt
               where  1=1
               and    dt.is_deleted is null
               and    dt.process_id = p_process_id
             );
      --
      if p_commit then
        commit;
      end if;
      --
    end reset_statuses_;
    --
  begin
    --
    build_dates_list_;
    --
    l_month := extract(month from l_dates_tbl(1).date_op);
    for i in 1..l_dates_tbl.count loop
      if l_month <> extract(month from l_dates_tbl(i).date_op) then
        reset_statuses_;
      end if;
      dv_sr_lspv_docs_api.set_period(
        p_start_date  => trunc(l_dates_tbl(i).date_op, 'Y'),
        p_end_date    => l_dates_tbl(i).date_op,
        p_report_date => l_dates_tbl(i).date_op
      );
      if l_dates_tbl(i).benefit_exists = 'Y' then
        dbms_output.put_line(chr(10) || 'Start update benefit: ' || to_char(l_dates_tbl(i).date_op, 'dd.mm.yyyy'));
        update_benefits(
          p_process_id,
          l_dates_tbl(i).date_op,
          p_nom_vkl,
          p_nom_ips
        );
      end if;
      l_month := extract(month from l_dates_tbl(i).date_op);
    end loop;
    --
    reset_statuses_;
    --
    dbms_output.put_line(chr(10) || 'update_details: errors ' || get_errors_cnt(p_process_id) || ' row(s)');
    --
  exception
    when others then
      if p_commit then
        rollback;
      end if;
      --
      fix_exception($$PLSQL_LINE, 'update_details');
      raise;
  end update_details;
  
  /**
   * Процедура update_details обновляет данные таблицы 
   *   dv_sr_lspv_det_t данными из dv_sr_lspv, строки в статусе N или U
   *   и сбрасывает их статус в null
   */
  procedure update_details(
    p_year    int default null,
    p_nom_vkl int default null,
    p_nom_ips int default null,
    p_commit  boolean
  ) is
    l_process_id dv_sr_lspv_det_t.process_id%type;
  begin
    --
    utl_error_api.init_exceptions;
    --
    l_process_id := create_process;
    --
    G_LEGACY := 'Y';
    --
    update_details(
      l_process_id, 
      p_commit,
      p_year   ,
      p_nom_vkl,
      p_nom_ips
    );
    --
    set_process_state(
      l_process_id, 
      'SUCCESS'
    );
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'update_details');
      if l_process_id is not null then
        set_process_state(
          l_process_id, 
          'ERROR', 
          p_error_msg => sqlerrm
        );
      end if;
      raise;
  end update_details;
  
  /**
   * Процедура update_details обновляет данные таблицы 
   *   dv_sr_lspv_det_t данными из dv_sr_lspv, строки в статусе N или U
   *   и сбрасывает их статус в null
   */
  procedure update_details(
    p_commit  boolean default false
  ) is
  begin
    --
    update_details(
      p_year    => null,
      p_nom_vkl => null,
      p_nom_ips => null,
      p_commit  => p_commit
    );
    --
  end update_details;
  
  /**
   * Процедура purge_details удаляет детализацию
   *  по заданному контрагенту и году
   */
  procedure purge_details(
    p_year    int,
    p_nom_vkl int,
    p_nom_ips int
  ) is
  begin
    --
    delete from dv_sr_lspv_det_t dt
    where  dt.id in (
             select dtt.id
             from   dv_sr_lspv_det_v dtt
             where  dtt.year_op = p_year
             and    dtt.nom_vkl = p_nom_vkl
             and    dtt.nom_ips = p_nom_ips
           );
    --
    update dv_sr_lspv#_v dd
    set    dd.status = 'N'
    where  1=1
    and    dd.nom_vkl = p_nom_vkl
    and    dd.nom_ips = p_nom_ips
    and    dd.year_op = p_year;
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'purge_details(' || p_year || ', ' || p_nom_vkl || ', ' || p_nom_ips || ')');
      raise;
  end purge_details;
  
  /**
   * Процедура recalc_pers_details пересчитывает детализацию 
   *  по заданному контрагенту и году
   */
  procedure recalc_pers_details(
    p_commit    boolean default false,
    p_year      int,
    p_ssylka_fl int
  ) is
    l_nom_vkl int;
    l_nom_ips int;
    --
    procedure define_nom_ is
    begin
      select sl.nom_vkl, sl.nom_ips
      into   l_nom_vkl,  l_nom_ips
      from   sp_lspv sl
      where  sl.ssylka_fl = p_ssylka_fl;
    exception
      when others then
        fix_exception($$PLSQL_LINE, 'define_nom_');
        raise;
    end define_nom_;
  begin
    --
    define_nom_;
    --
    purge_details(
      p_year,
      l_nom_vkl,
      l_nom_ips
    );
    --
    update_details(
      p_year    => p_year,
      p_nom_vkl => l_nom_vkl,
      p_nom_ips => l_nom_ips,
      p_commit  => p_commit
    );
    --
  exception
    when others then
      fix_exception($$PLSQL_LINE, 'recalc_pers_details(' || p_year || ', ' || p_ssylka_fl || ')');
      raise;
  end recalc_pers_details;
  
  /**
   *
   */
  function get_remains_shifr_schet(
    p_year         int,
    p_nom_vkl      int,
    p_nom_ips      int,
    p_shifr_schet  int
  ) return number is
    l_result number;
  begin
    select sum(dt.amount)
    into   l_result
    from   dv_sr_lspv_det_v dt
    where  dt.detail_type = 'BENEFIT'
    and    dt.year_op = p_year
    and    dt.nom_vkl = p_nom_vkl
    and    dt.nom_ips = p_nom_ips
    and    dt.shifr_schet = p_shifr_schet
    and    dt.addition_code = p_shifr_schet;
    --
    return l_result;
  end get_remains_shifr_schet;
  
end dv_sr_lspv_det_pkg;
/
