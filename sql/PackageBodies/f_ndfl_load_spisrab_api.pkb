create or replace package body f_ndfl_load_spisrab_api is

  C_KOD_NA constant integer := 1;
  
  type g_identified_rec_type is record(
    uid_np number(10),
    ssylka_sips   number(10),
    ssylka_real   number(10),
    gf_person     number(10),
    inn           varchar2(12)
  );
  type g_identified_list_type is table of g_identified_rec_type;
  
  /**
   * �������� ��������� ������
   */
  procedure fix_exception(p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => p_msg
    );
  end;
  
  /**
   * ������� ���������� ��� �������� 6���� �� ����
   */
  function get_quarter_code(
    p_date date
  ) return ndfl6_quarters_v.code%type is
    l_result ndfl6_quarters_v.code%type;
  begin
    --
    select q.code
    into   l_result
    from   ndfl6_quarters_v q
    where  extract(month from p_date) between q.month_start and q.month_end;
    --
    return l_result;
    --
  exception
    when others then
      fix_exception;
      raise;
  end get_quarter_code;
  
  /**
   * ��������� �������� ������ �� ������� zaprvkl_lines_tmp
   */
  procedure load_from_tmp(
    p_year    integer,
    p_quarter integer
  ) is
  begin
    --
    insert into f_ndfl_load_spisrab(
      kod_na,
      god, 
      uid_np, 
      familiya, 
      imya, 
      otchestvo, 
      data_rozhd,
      inn_fl,
      kvartal_kod
    ) select C_KOD_NA,
             p_year,
             f_ndfl_spisrab_seq.nextval,
             lin.last_name,
             lin.first_name,
             lin.second_name,
             lin.birth_date,
             lin.inn,
             p_quarter
      from   zaprvkl_lines_tmp lin
      where  1=1
      and    not exists (
               select 1
               from   f_ndfl_load_spisrab s
               where  1=1
               and    nvl(s.inn_fl, nvl(lin.inn, '*NULL*')) = nvl(lin.inn, nvl(s.inn_fl, '*NULL*'))
               and    s.data_rozhd = lin.birth_date
               and    s.otchestvo = lin.second_name
               and    s.imya = lin.first_name
               and    s.familiya = lin.last_name
               and    s.god = p_year
               and    s.kod_na = C_KOD_NA
             );
    --
    --dbms_output.put_line('load_from_tmp: inserted ' || sql%rowcount || ' row(s)');
    --
  exception
    when others then
      fix_exception;
      raise;
  end load_from_tmp;
  
  
  /**
   *
   */
  procedure update_identified_list(
    p_year in integer,
    p_idetified_list in out nocopy g_identified_list_type
  ) is
  begin
    --
    forall i in 1..p_idetified_list.count
      update f_ndfl_load_spisrab emp
      set    emp.ssylka_sips   = nvl(emp.ssylka_sips, p_idetified_list(i).ssylka_sips) ,
             emp.ssylka_real   = nvl(emp.ssylka_real, p_idetified_list(i).ssylka_real) ,
             emp.gf_person     = nvl(emp.gf_person  , p_idetified_list(i).gf_person  ) ,
             emp.inn_fl        = nvl(emp.inn_fl     , p_idetified_list(i).inn        )
      where  emp.uid_np = p_idetified_list(i).uid_np
      and    emp.god    = p_year;
    --
  exception
    when others then
      fix_exception;
      raise;
  end update_identified_list;
  
  /**
   * ��������� ������������� ����������� ����� ��
   *   ������ ����������� ���� (fnd.f_ndfl_load_spisrab)
   */
  procedure identify_prev_year(
    p_year    integer
  ) is
    l_idetified_list g_identified_list_type;
  begin
    --
    select e.target_uid_np  ,
           e.ssylka_sips    ,
           e.ssylka_real    ,
           e.gf_person      ,
           null
    bulk collect into
           l_idetified_list
    from   (select row_number() over(partition by s.uid_np order by sp.god desc) rn,
                   s.uid_np                           target_uid_np,
                   sp.ssylka_sips                     ssylka_sips,
                   sp.ssylka_real                     ssylka_real,
                   nvl(s.gf_person, sp.gf_person)     gf_person
            from   f_ndfl_load_spisrab s,
                   f_ndfl_load_spisrab sp
            where  1 = 1
            and    (
                     (sp.ssylka_sips is not null and sp.ssylka_sips <> nvl(s.ssylka_sips, -1))
                     or
                     (sp.ssylka_real is not null and sp.ssylka_real <> nvl(s.ssylka_real, -1))
                     or
                     (sp.gf_person is not null and sp.gf_person <> nvl(s.gf_person, -1))
                   )
            and    sp.data_rozhd = s.data_rozhd
            and    sp.otchestvo = s.otchestvo
            and    sp.imya = s.imya
            and    sp.familiya = s.familiya
                  --
            and    sp.god <> s.god
            --
            and    (s.gf_person is null or s.ssylka_sips is null or s.ssylka_real is null)
            and    s.god = p_year
           ) e
    where  e.rn = 1;
    --
    update_identified_list(
      p_year           => p_year,
      p_idetified_list => l_idetified_list
    );
    --
  exception
    when others then
      fix_exception;
      raise;
  end identify_prev_year;
  
  /**
   * ��������� ������������� ����������� ����� �� �������
   *   GAZFOND.PEOPLE
   */
  procedure identify_gf_person(
    p_year    integer
  ) is
    l_idetified_list g_identified_list_type;
  begin
    --
    select e.uid_np    ,
           null        ,
           null        ,
           e.gf_person ,
           null
    bulk collect into
           l_idetified_list
    from   (select row_number() over(partition by s.uid_np order by p.fk_contragent) rn,
                   s.uid_np,
                   p.fk_contragent gf_person
            from   f_ndfl_load_spisrab s,
                   gazfond.people      p
            where  1 = 1
            --
            and    p.birthdate = s.data_rozhd
            and    p.secondname = s.otchestvo
            and    p.firstname = s.imya
            and    p.lastname = s.familiya
            --
            and    s.gf_person is null
            and    s.god = p_year
           ) e
    where  e.rn = 1;
    --
    update_identified_list(
      p_year           => p_year,
      p_idetified_list => l_idetified_list
    );
    --
  exception
    when others then
      fix_exception;
      raise;
  end identify_gf_person;
  
  /**
   * ��������� ������������� ����������� ����� �� �������
   *  FND.SP_FIZ_LITS
   */
  procedure identify_fiz_lits(
    p_year    integer
  ) is
    l_idetified_list g_identified_list_type;
  begin
    --
    select e.uid_np      ,
           null          ,
           e.ssylka_real ,
           e.gf_person   ,
           e.inn
    bulk collect into
           l_idetified_list
    from   (select row_number() over(partition by s.uid_np order by f.ssylka) rn,
                   s.uid_np,
                   f.ssylka ssylka_real,
                   f.gf_person,
                   inn.inn
            from   f_ndfl_load_spisrab s,
                   fnd.sp_fiz_lits     f,
                   fnd.sp_inn_fiz_lits inn
            where  1 = 1
            and    inn.ssylka(+) = f.ssylka
            --
            and    (
                    (f.gf_person is not null and f.gf_person <> nvl(s.gf_person, -1))
                    or
                    (s.ssylka_real is null)
                    or
                    (inn.inn is not null and (inn.inn <> nvl(s.inn_fl, '*NULL*')))
                   )
            --
            and    f.data_rogd = s.data_rozhd
            and    f.otchestvo = s.otchestvo
            and    f.imya = s.imya
            and    f.familiya = s.familiya
            --
            and    (s.gf_person is null or s.ssylka_real is null)
            and    s.god = p_year
           ) e
    where  e.rn = 1;
    --
    update_identified_list(
      p_year           => p_year,
      p_idetified_list => l_idetified_list
    );
    --
  exception
    when others then
      fix_exception;
      raise;
  end identify_fiz_lits;
  
  /**
   * ��������� ������������� ����������� ����� �� ���� ���������� �����
   */
  procedure identify_residents(
    p_year       integer,
    p_header_id  ndfl6_headers_t.header_id%type
  ) is
  begin
    --
    update f_ndfl_load_spisrab s
    set    s.nalres_status = 
           nvl(
             (select case max(p.tax_rate)
                       when 30 then
                         0
                       else
                         1
                     end
              from   ndfl6_lines_t     p
              where  p.gf_person = s.gf_person
              and    p.header_id = p_header_id
              group by p.gf_person
             ),
             1
           )
    where  1=1
    and    s.god = p_year;
    --
  exception
    when others then
      fix_exception;
      raise;
  end identify_residents;
  
  /**
   * ��������� ������������� ����������� ����� �� ���� ���������� �����
   */
  procedure identify_employees(
    p_year       integer,
    p_header_id  ndfl6_headers_t.header_id%type
  ) is
  begin
    --
    identify_prev_year(p_year => p_year);
    --
    identify_fiz_lits(p_year => p_year);
    --
    identify_gf_person(p_year => p_year);
    --
    identify_residents(
      p_year      => p_year,
      p_header_id => p_header_id
    );
    --
  exception
    when others then
      fix_exception;
      raise;
  end identify_employees;
  
  /**
   * ��������� �������� ������ ����������� �� ������� zaprvkl_lines_tmp
   *   � ����������� �������������� �� ���� ���������� �����
   */
  procedure load_from_tmp(
    p_load_date  date,
    p_header_id  ndfl6_headers_t.header_id%type
  ) is
    l_year    integer;
    l_quarter ndfl6_quarters_v.code%type;
  begin
    --
    l_year    := extract(year from p_load_date);
    l_quarter := get_quarter_code(p_date => p_load_date);
    --
    load_from_tmp(
      p_year    => l_year,
      p_quarter => l_quarter
    );
    --
    identify_employees(
      p_year      => l_year,
      p_header_id => p_header_id
    );
    --
  exception
    when others then
      fix_exception;
      raise;
  end load_from_tmp;

end f_ndfl_load_spisrab_api;
/
