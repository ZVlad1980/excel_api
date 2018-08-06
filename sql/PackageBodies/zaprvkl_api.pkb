create or replace package body zaprvkl_api is
  
  -- ������ �������� ��� ������
  G_SRC_CHR  constant varchar2(200) := 'AOPEHBCXMK';
  G_DEST_CHR constant varchar2(200) := '����������';
  
  
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
   * ������� create_header - ������� ��������� ���������
   *
   * @param x_err_msg     - ��������� �� ������ (���� ����)
   * @param p_investor_id - ����� ��������� (��. fnd.sp_fiz_lits.nom_vkl).
   *                          ���� �� ����� - �� ����� ���������� ������ �������������� ��������� � ���������
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
        x_err_msg := '�������� (ssylka = ' || p_investor_id || ') �� ������.';
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
   * ��������� add_line_tmp ��������� ������������ ������ � tmp �������
   *   �������� API 
   *
   * @param p_last_name   - �������
   * @param p_first_name  - ���
   * @param p_second_name - ��������
   * @param p_birth_date  - ���� �������� � ������� ��.��.����
   * @param p_employee_id - ��������� �����
   * @param p_snils       - �����
   * @param p_inn         - ���
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
   * ��������� prepare - ���������� ������ ��� ���������
   *   ������ ������ ���� ��������� � ������� zaprvkl_lines_tmp
   * 
   * @param p_header_id - ID ��������� �������� (�.�. ������)
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
                 '������������ ������ ���� ��������. ���� ������ ���� � �������: ' || G_FMT_DATE
               when t.birth_date > sysdate or t.birth_date < to_date(19000101, 'yyyymmdd') then
                 '��������� ���� ��������, �������� ��� ������ �� ���������!'
             end,
             t.double_id
      from   zaprvkl_lines_tmp_v t;
    --
    execute immediate 'truncate table zaprvkl_lines_tmp';
    --
  end prepare_lines;
  
  /**
   * ��������� update_status_lines - ��������� ������� ����� (������ � ������� Create)
   *
   * @param p_header_id    - ID ���������
   * @param p_final_status - ��������� ������ ������ (���� ��� �� ������� � zaprvkl_cross_t)
   *                           ���� �� ����� - ������ �������� ��� ���������
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
   * ��������� full_ident - ����� �������, ��������� ����������� � ��������� (��� + ��)
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
   * ��������� part_ident - ����� �������, �������� ����������� � ���������
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
   * ��������� start_process ������������� ����� ��������� �������, �������� ������ �� zaprvkl_lines_tmp (���� ����)
   * 
   * @param x_err_msg   - ��������� ��� ������ (������� ���������� -1)
   * @param p_header_id - ID ����� ���������� ��������
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
   * ��������� start_process - �������� ��������� 
   * 
   * x_err_msg - ��������� ��� ������ (������� ���������� -1)
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
   * ��������� start_process ���������/������������� ������� ��������� ������
   * 
   * @param x_err_msg    - ��������� ��� ������ (������� ���������� -1)
   * @param p_header_id  - ID ��������� ��������
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
   * ��������� get_results - ���������� ����� ����������� � ������������ ���������
   *
   * @param x_result      - �������������� ������
   * @param x_err_msg     - ��������� �� ������
   * @param p_header_id   - ID ��������� ���������
   * @param p_result_code - ��� ������������� ������:
   *                          participants            - ���������
   *                          not_found               - �����������
   *                          possible_participants   - ��������� ���������
   *                          errors                  - ������
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
                     '�������'
                   when p.rasch_pen is not null then
                     '���������'
                   else
                     '��������'
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
                     '�������� � �������� ������'
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
   * ������� edit_distance ��������� ��������� ���� ���� �� ��������� ������������������
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
   * ������� edit_distance ��������� ��������� ���� ��� �� ��������� ������������������
   *   ��� ��������� ��������� �������������� ���� � ������ � ������ yyyymmdd
   */
  function edit_distance(
    plname in date,
    prname in date
  ) return number as
  begin
   return edit_distance(to_char(plname, 'yyyymmdd'), to_char(prname, 'yyyymmdd'));
  end edit_distance;
  
  /**
   * ������� ���������� ������ ����� (���) ��� ���������
   *  ��������������:
   *    - �������� ���������, ��������� � ������� �������� ��������
   *    - ������� �������
   *    - ���������� �������� � 0
   *    - �������� ����� �������� ����� ���������
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
   * ������� ��������������� ������ � ���� (���������� null � ������ ������)
   *  ���� ��������� � ������� ��������
   */
  function to_date$(p_date_str varchar2) return date is
  begin
    return to_date(p_date_str, G_FMT_DATE);
  exception
    when others then
      return null;
  end to_date$;
  
  
  /**
   * ������� �������� ��� ���������� ��������
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
