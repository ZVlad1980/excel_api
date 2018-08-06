create or replace package body zaprvkl_api is
  
  -- Строки символов для замены
  G_SRC_CHR  constant varchar2(200) := 'AOPEHBCXMK';
  G_DEST_CHR constant varchar2(200) := 'АОРЕНВСХМК';
  
  
  procedure plog(p_msg varchar2) is
    pragma autonomous_transaction;
  begin
    return;
    dbms_output.put_line(p_msg);
    --insert into test_tbl(msg) values(substr(p_msg, 1, 20));
    commit;
  exception
    when others then
      rollback;
      raise;
  end plog;
  
  
  
  /**
   * Функция create_header - создает заголовок обработки
   *
   * @param x_err_msg     - сообщение об ошибке (если есть)
   * @param p_investor_id - номер вкладчика (см. fnd.sp_fiz_lits.nom_vkl).
   *                          Если не задан - не будет выполнятся анализ принадлежности участника к вкладчику
   *
   */
  function create_header(
    x_err_msg       out varchar2,
    p_investor_id   fnd.sp_ur_lits.ssylka%type default null
  ) return zaprvkl_headers_t.id%type is
    --
    l_header_row    zaprvkl_headers_t%rowtype;
    --
    function get_investor_id_ return fnd.sp_ur_lits.ssylka%type is
      l_result fnd.sp_ur_lits.ssylka%type;
    begin
      if p_investor_id >= 0 then
        --
        select u.ssylka
        into   l_result
        from   fnd.sp_ur_lits u
        where  u.ssylka = p_investor_id;
        --
      end if;
      --
      return l_result;
      --
    exception
      when no_data_found then
        x_err_msg := 'Вкладчик (ssylka = ' || p_investor_id || ') не найден.';
        raise;
    end get_investor_id_;
    --
  begin
    --
    l_header_row.investor_id := get_investor_id_;
    l_header_row.status := zaprvkl_headers_tapi.G_HDR_STS_CREATED;
    zaprvkl_headers_tapi.ins(l_header_row);
    --
    return l_header_row.id;
    --
  exception
    when others then
      x_err_msg := nvl(x_err_msg, sqlerrm);
      return -1;
  end create_header;
  
  /**
   * Процедура add_line_tmp добавляет персональные данные в tmp таблицу
   *   Вызывает API 
   *
   * @param p_last_name   - фамилия
   * @param p_first_name  - имя
   * @param p_second_name - отчество
   * @param p_birth_date  - дата рождения в формате ДД.ММ.ГГГГ
   * @param p_employee_id - табельный номер
   * @param p_snils       - СНИЛС
   * @param p_inn         - ИНН
   *
   */
  procedure add_line_tmp(
    p_excel_id     number,
    p_last_name    varchar2,
    p_first_name   varchar2,
    p_second_name  varchar2,
    p_birth_date   varchar2,
    p_employee_id  varchar2,
    p_snils        varchar2,
    p_inn          varchar2
  ) is
    l_line zaprvkl_lines_tmp%rowtype;
  begin
    if p_excel_id is null then
      return;
    end if;
    
    l_line.excel_id    := p_excel_id                   ;
    l_line.last_name   := prepare_str$(p_last_name    );
    l_line.first_name  := prepare_str$(p_first_name   );
    l_line.second_name := prepare_str$(p_second_name  );
    l_line.birth_date  := to_date$(p_birth_date       );
    l_line.employee_id := p_employee_id                ;
    l_line.snils       := p_snils                      ;
    l_line.inn         := p_inn                        ;
    --
    zaprvkl_lines_tmp_api.add_line(
      p_line => l_line
    );
    --
  end add_line_tmp;
  
  /**
   * Процедура prepare - подготовка данных для обработки
   *   Данные должны быть загружены в таблицу zaprvkl_lines_tmp
   * 
   * @param p_header_id - ID заголовка процесса (д.б. создан)
   * 
   */
  procedure prepare_lines(
    p_header_id zaprvkl_headers_t.id%type
  ) is
  begin
    --
    zaprvkl_lines_tmp_api.flush_to_table;
    --
    insert into zaprvkl_lines_t(
      header_id,
      excel_id,
      status,
      last_name,
      first_name,
      second_name,
      birth_date,
      employee_id,
      snils,
      inn,
      err_msg,
      double_id
    ) select p_header_id,
             t.excel_id,
             case
               when (t.birth_date is null and t.birth_date_str is not null) or
                   t.birth_date > sysdate or t.birth_date < to_date(19000101, 'yyyymmdd') then
                 G_LN_STS_ERROR_IDENT
               when t.double_row_num > 1 then
                 G_LN_STS_DOUBLE_IDENT
               else
                 G_LN_STS_CREATED
             end,
             t.last_name,
             t.first_name,
             t.second_name,
             t.birth_date,
             t.employee_id,
             t.snils,
             t.inn,
             case
               when t.birth_date is null and t.birth_date_str is not null then
                 'Некорректный формат даты рождения. Дата должна быть в формате: ' || G_FMT_DATE
               when t.birth_date > sysdate or t.birth_date < to_date(19000101, 'yyyymmdd') then
                 'Проверьте дату рождения, возможно она задана не корректна!'
             end,
             t.double_id
      from   zaprvkl_lines_tmp_v t;
    --
    execute immediate 'truncate table zaprvkl_lines_tmp';
    --
  end prepare_lines;
  
  /**
   * Процедура update_status_lines - обновляет статусы строк (только в статусе Create)
   *
   * @param p_header_id    - ID обработки
   * @param p_final_status - финальный статус строки (если она не найдена в zaprvkl_cross_t)
   *                           Если не задан - статус остается без изменений
   *
   */
  procedure update_status_lines(
    p_header_id       zaprvkl_headers_t.id%type,
    p_final_status    varchar2 default null
  ) is
  begin
    
    plog('start update status');
    update zaprvkl_lines_t s
    set    s.status = nvl((select c.status from zaprvkl_cross_t c where c.line_id = s.id and rownum = 1), nvl(p_final_status, s.status))
    where  1 = 1
    and    s.status = G_LN_STS_CREATED
    and    s.header_id = p_header_id;
    plog('end update status');
  end update_status_lines;
  
  /**
   * Процедура full_ident - отбор записей, полностью совпадающих с заданными (фио + др)
   */
  procedure full_ident(
    p_header_row in out nocopy zaprvkl_headers_t%rowtype
  ) is
  begin
    --
    plog('start full ident');
    insert into zaprvkl_cross_t(
      line_id,
      person_id,
      header_id,
      status
    ) select f.line_id,
             f.person_id,
             f.header_id,
             case
               when p_header_row.investor_id is null or p_header_row.investor_id = f.investor_id then
                 zaprvkl_api.get_ln_sts_full_ident
               else
                 zaprvkl_api.get_ln_sts_part_ident
             end
      from   zaprvkl_full_ident_v f
      where  1=1
      and    f.pen_scheme in (1, 8)
      and    f.header_id = p_header_row.id;
    --
    plog('end fill ident');
  end full_ident;
  
  /**
   * Процедура part_ident - отбор записей, частично совпадающих с заданными
   */
  procedure part_ident(
    p_header_row in out nocopy zaprvkl_headers_t%rowtype
  ) is
  begin
    --
    plog('start part ident');
    insert into zaprvkl_cross_t(
      line_id,
      person_id,
      header_id,
      diff_name,
      status
    ) select f.line_id,
             f.person_id,
             f.header_id,
             f.diff_name,
             case 
               when f.edit_distance = 0 and 
                    (p_header_row.investor_id is null or p_header_row.investor_id = f.investor_id)
                  then zaprvkl_api.get_ln_sts_full_ident
               else zaprvkl_api.get_ln_sts_part_ident
             end
      from   zaprvkl_part_ident_v f
      where  1=1
      and    f.edit_distance < 3
      and    f.pen_scheme in (1, 8)
      and    f.header_id = p_header_row.id;
    --
    plog('end part ident');
  end part_ident;
  
  /**
   * Процедура start_process перезапускает ранее созданный процесс, добавляя строки из zaprvkl_lines_tmp (если есть)
   * 
   * @param x_err_msg   - сообщение обо ошибке (функция возвратила -1)
   * @param p_header_id - ID ранее созданного процесса
   * 
   */
  procedure process(
    p_header_row in out nocopy zaprvkl_headers_t%rowtype
  ) is
  begin
    --
    full_ident(p_header_row);
    update_status_lines(p_header_row.id);
    commit;
    --
    part_ident(p_header_row);
    update_status_lines(p_header_row.id, G_LN_STS_NONE_IDENT);
    commit;
    --
  exception
    when others then
      rollback;
      raise;
  end process;

  /**
   * Процедура start_process - основная обработка 
   * 
   * x_err_msg - сообщение обо ошибке (функция возвратила -1)
   * 
   */
  procedure start_process(
    x_err_msg out varchar2,
    p_header_row in out nocopy zaprvkl_headers_t%rowtype
  ) is
    --
    --
    --
    procedure set_status_header_(
      p_status     varchar2
    ) is
      pragma autonomous_transaction;
    begin
      --
      p_header_row.status := p_status;
      if p_status = zaprvkl_headers_tapi.G_HDR_STS_ERROR then
        p_header_row.err_msg := substr(dbms_utility.format_error_stack || chr(10) || dbms_utility.format_error_backtrace, 1, 2000);
      end if;
      --
      zaprvkl_headers_tapi.upd(p_header_row);
      --
      commit;
      --
    exception
      when others then
        rollback;
        raise;
    end set_status_header_;
    --
  begin
    --
    set_status_header_(zaprvkl_headers_tapi.G_HDR_STS_PROCESS);
    --
    process(p_header_row);
    --
    set_status_header_(zaprvkl_headers_tapi.G_HDR_STS_SUCCESS);
    --
  exception
    when others then
      x_err_msg := sqlerrm;
      set_status_header_(zaprvkl_headers_tapi.G_HDR_STS_ERROR);
      raise;
  end start_process;
  
  /**
   * Процедура start_process запускает/перезапускает процесс обработки данных
   * 
   * @param x_err_msg    - сообщение обо ошибке (функция возвратила -1)
   * @param p_header_id  - ID заголовка процесса
   * 
   */
  procedure start_process(
    x_err_msg     out varchar2,
    p_header_id   zaprvkl_headers_t.id%type
  ) is
    --
    l_header_row zaprvkl_headers_t%rowtype;
  begin
    --
    l_header_row.id := p_header_id;
    zaprvkl_headers_tapi.slct(l_header_row);
    --
    if l_header_row.status = zaprvkl_headers_tapi.G_HDR_STS_CREATED then
      prepare_lines(l_header_row.id);
    end if;
    --
    start_process(x_err_msg, l_header_row);
    --
  exception
    when others then
      x_err_msg := nvl(x_err_msg, sqlerrm);
  end start_process;
  
  /**
   * Процедура get_results - возвращает набор рекордсетов с результатами обработки
   *
   * @param x_result      - результирующий курсор
   * @param x_err_msg     - сообщение об ошибке
   * @param p_header_id   - ID заголовка обработки
   * @param p_result_code - код запрашиваемых данных:
   *                          participants            - участники
   *                          not_found               - неучастники
   *                          possible_participants   - возможные участники
   *                          errors                  - ошибки
   *
   */
  procedure get_results(
    x_result      out sys_refcursor,
    x_err_msg     out varchar2,
    p_header_id   integer,
    p_result_name varchar2
  ) is
  begin
    case p_result_name
      when 'participants' then
        open x_result for 
          select lin.excel_id,
                 p.ips_num,
                 p.last_name,
                 p.first_name,
                 p.second_name,
                 to_char(p.birth_date, zaprvkl_api.get_fmt_date) birth_date,
                 p.sex,
                 p.employee_id,
                 to_char(
                   p.accession_date, 
                   zaprvkl_api.get_fmt_date
                 )                           accession_date,
                 nvl(p.rasch_pen, p.dop_pen) pension_amount,
                 case
                   when p.is_disabled = 'Y' then
                     'Инвалид'
                   when p.rasch_pen is not null then
                     'Пенсионер'
                   else
                     'Участник'
                 end person_type,
                 to_char(
                   nvl(
                     p.pay_start_date, 
                     p.supposed_pay_start_date
                   ),
                   zaprvkl_api.get_fmt_date
                 )                           pay_start_date,
                 p.investor,
                 p.pen_schem_num
          from   zaprvkl_cross_t       c,
                 zaprvkl_persons_rep_v p,
                 zaprvkl_lines_t       lin
          where  1=1
          and    lin.id = c.line_id
          --
          and    p.person_id = c.person_id
          --
          and    c.status = zaprvkl_api.get_ln_sts_full_ident
          and    c.header_id = p_header_id
          order by p.last_name, 
                   p.first_name, 
                   p.second_name, 
                   p.birth_date;
      when 'possible_participants' then
        open x_result for
          select p.excel_id,
                 p.ips_num, 
                 p.last_name, 
                 p.first_name, 
                 p.second_name, 
                 to_char(p.birth_date, zaprvkl_api.get_fmt_date) birth_date, 
                 p.sex,
                 p.employee_id,
                 p.snils,
                 to_char(p.accession_date, zaprvkl_api.get_fmt_date) accession_date,
                 nvl(p.rasch_pen, p.dop_pen) pension_amount,
                 p.person_type,
                 to_char(
                   nvl(
                     p.pay_start_date, 
                     p.supposed_pay_start_date
                   ),
                   zaprvkl_api.get_fmt_date
                 )                           pay_start_date,
                 p.investor,
                 p.pen_schem_num
          from   zaprvkl_part_rep_v p
          where  p.header_id = p_header_id
          order by line_id, 
                   p.ips_num nulls first, 
                   last_name, 
                   first_name, 
                   second_name, 
                   p.birth_date;
      when 'not_found' then
        open x_result for 
          select lin.excel_id,
                 lin.last_name,
                 lin.first_name,
                 lin.second_name,
                 to_char(lin.birth_date, zaprvkl_api.get_fmt_date) birth_date,
                 lin.employee_id
          from   zaprvkl_lines_v lin
          where  1=1
          and    lin.status = zaprvkl_api.get_ln_sts_none_ident
          and    lin.header_id = p_header_id;
      when 'errors' then
        open x_result for 
          select lin.excel_id,
                 lin.last_name,
                 lin.first_name,
                 lin.second_name,
                 to_char(lin.birth_date, zaprvkl_api.get_fmt_date) birth_date,
                 lin.employee_id,
                 case lin.status
                   when zaprvkl_api.get_ln_sts_double_ident then
                     'Дубликат в исходном списке'
                   else
                     lin.err_msg
                 end err_msg,
                 lin.double_id
          from   zaprvkl_lines_v lin
          where  1=1
          and    lin.status in (zaprvkl_api.get_ln_sts_double_ident, zaprvkl_api.get_ln_sts_error_ident)
          and    lin.header_id = p_header_id;
    end case;
  exception
    when others then
      x_err_msg := sqlerrm;
      x_result := null;
  end get_results;
  
  /**
   * Функция edit_distance выполняет сравнение двух имен по рассоянию Дамерау–Левенштейна
   */
  function edit_distance
  (
    plname in varchar2,
    prname in varchar2
  ) return number as
  begin
   
    if plname is null or prname is null then
      return null;
    end if;
  
    return utl_match.edit_distance(regexp_replace(plname, '\W', ''),
                                   regexp_replace(prname, '\W', ''));
  
  end edit_distance;
  
  /**
   * Функция edit_distance выполняет сравнение двух дат по рассоянию Дамерау–Левенштейна
   *   Для сравнения выполняет преобразование даты в строку в формат yyyymmdd
   */
  function edit_distance(
    plname in date,
    prname in date
  ) return number as
  begin
   return edit_distance(to_char(plname, 'yyyymmdd'), to_char(prname, 'yyyymmdd'));
  end edit_distance;
  
  /**
   * Функция подготовки строки имени (ФИО) для обработки
   *  Преобразования:
   *    - удаление начальных, хвостовых и двойных пробелов пробелов
   *    - верхний регистр
   *    - трансляция латиницы и 0
   *    - удаление любых символов кроме кириллицы
   */
   function prepare_str$(p_str varchar2) return varchar2 is
   begin
     return 
       translate(
         upper(
           trim(
             regexp_replace(
               p_str, '  +', ' '
             )
           )
         ),
         G_SRC_CHR,
         G_DEST_CHR
       );
   end prepare_str$;
  
  /**
   * Функция конвертирования строки в дату (возвращает null в случае ошибки)
   *  Дата ожидается в формате ГГГГММДД
   */
  function to_date$(p_date_str varchar2) return date is
  begin
    return to_date(p_date_str, G_FMT_DATE);
  exception
    when others then
      return null;
  end to_date$;
  
  
  /**
   * Функции обвертки для глобальных констант
   */
  --
  function get_ln_sts_created      return varchar2 deterministic is begin return G_LN_STS_CREATED     ; end get_ln_sts_created     ;
  function get_ln_sts_full_ident   return varchar2 deterministic is begin return G_LN_STS_FULL_IDENT  ; end get_ln_sts_full_ident  ;
  function get_ln_sts_part_ident   return varchar2 deterministic is begin return G_LN_STS_PART_IDENT  ; end get_ln_sts_part_ident  ;
  function get_ln_sts_none_ident   return varchar2 deterministic is begin return G_LN_STS_NONE_IDENT  ; end get_ln_sts_none_ident  ;
  function get_ln_sts_double_ident return varchar2 deterministic is begin return G_LN_STS_DOUBLE_IDENT; end get_ln_sts_double_ident;
  function get_ln_sts_multy_ident  return varchar2 deterministic is begin return G_LN_STS_MULTY_IDENT ; end get_ln_sts_multy_ident ;
  function get_ln_sts_error_ident  return varchar2 deterministic is begin return G_LN_STS_ERROR_IDENT ; end get_ln_sts_error_ident ;
  --
  function get_fmt_date return varchar2 deterministic is begin return G_FMT_DATE; end get_fmt_date;
  --
end zaprvkl_api;
/
