create or replace package body f2ndfl_load_empl_api is

  -- Private type declarations
  
  /**
   * Обвертки обработки ошибок
   */
  procedure fix_exception(p_msg varchar2 default null) is
  begin
    utl_error_api.fix_exception(
      p_err_msg => p_msg
    );
  end;
  
  /**
   * Процедура загрузки XML данных
   *   Пока ручная загрузка
   */
  procedure load_xml(
    p_code_na    int,
    p_year       int,
    p_xml        xmltype
  ) is
  begin
    --
    utl_error_api.init_exceptions;
    --
    insert into f_ndfl_load_employees_xml(
      code_na,
      year,
      api_version,
      form_version,
      xml_data
    ) select p_code_na,
             p_year   ,
             t.api    ,
             t.form   ,
             p_xml
      from   xmltable('/Файл' passing(p_xml)
               columns
                 api           varchar2(20) path '@ВерсПрог',
                 form          varchar2(10) path '@ВерсФорм',
                 report_year   number       path 'СвРекв/@ОтчетГод',
                 documents     xmltype      path 'Документ'
             ) t
      where  t.report_year = p_year;
    --
    if sql%rowcount = 0 then
      fix_exception('load_xml: в XML данных не найдена данные за ' || p_year || ' год.');
      raise no_data_found;
    end if;
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception('load_xml(' || p_code_na || ', '||p_year||')');
      raise;
  end load_xml;
  
  /**
   *
   */
  procedure load_adr(
    p_data_id        int
  ) is
  begin
    --
    dbms_output.put_line('load_adr функционал не реализован');
    --
  exception
    when others then
      fix_exception('load_adr(' || p_data_id || ')');
      raise;
  end load_adr;
  
  /**
   *
   */
  procedure load_employees(
    p_data_id        int,
    p_year           int
  ) is
  begin
    --
    delete from zaprvkl_lines_tmp;
    --
    insert into zaprvkl_lines_tmp(
      excel_id        ,
      last_name       ,
      first_name      ,
      second_name     ,
      birth_date_str  ,
      birth_date      ,
      inn
    ) select rownum,
             d.familiya    ,
             d.imya        ,
             d.otchestvo   ,
             d.data_rozhd  ,
             to_date(d.data_rozhd, 'dd.mm.yyyy')  ,
             d.inn_fl
      from   f_ndfl_load_employees_xml t,
             xmltable('/Файл/Документ' passing(t.xml_data)
               columns
                 inn_fl          varchar2(12)   path 'ПолучДох/@ИННФЛ',
                 familiya        varchar2(100)  path 'ПолучДох/ФИО/@Фамилия',
                 imya            varchar2(100)  path 'ПолучДох/ФИО/@Имя',
                 otchestvo       varchar2(100)  path 'ПолучДох/ФИО/@Отчество',
                 data_rozhd      varchar2(10)   path 'ПолучДох/@ДатаРожд'
             ) d
      where  t.id = p_data_id;
    --
    f_ndfl_load_spisrab_api.load_from_tmp(
      p_load_date => to_date(p_year || '1231', 'yyyymmdd')
    );
    --
  exception
    when others then
      fix_exception('load_spravki(' || p_data_id || ')');
      raise;
  end load_employees;
  
  /**
   *
   */
  procedure load_spravki(
    p_data_id        int
  ) is
    l_err_tag varchar2(30) := 'LOAD_EMPL:' || p_data_id;
  begin
    --
    insert into f2ndfl_load_spravki(
      kod_na,
      god,
      ssylka,
      tip_dox,
      nom_korr,
      data_dok,
      nom_spr,
      kvartal,
      priznak,
      inn_fl,
      inn_ino,
      status_np,
      grazhd,
      familiya,
      imya,
      otchestvo,
      data_rozhd,
      kod_ud_lichn,
      ser_nom_doc
    )
      select t.code_na,
             t.year,
             sr.uid_np ssylka,
             9 tip_dox,
             d.doc_corr,
             to_date(d.doc_date, 'dd.mm.yyyy'),
             -1 * to_number(d.doc_num) doc_num, --фейковый, потом надо затереть
             4 kvartal,
             1 priznak, --????
             coalesce(d.inn_fl, sr.inn_fl),
             null inn_ino,
             d.resident status_np,
             d.grazhd,
             d.familiya    ,
             d.imya        ,
             d.otchestvo   ,
             to_date(d.data_rozhd, 'dd.mm.yyyy')  ,
             d.kod_id_lichn,
             d.ser_nom_doc 
      from   f_ndfl_load_employees_xml t
             inner join
               xmltable('/Файл/Документ' passing(t.xml_data)
                 columns
                   doc_num         varchar2(10)   path '@НомСпр',
                   doc_date        varchar2(10)   path '@ДатаДок',
                   doc_corr        varchar2(5)    path '@НомКорр',
                   inn_fl          varchar2(12)   path 'ПолучДох/@ИННФЛ',
                   resident        varchar2(1)    path 'ПолучДох/@Статус',
                   grazhd          varchar2(3)    path 'ПолучДох/@Гражд',
                   familiya        varchar2(100)  path 'ПолучДох/ФИО/@Фамилия',
                   imya            varchar2(100)  path 'ПолучДох/ФИО/@Имя',
                   otchestvo       varchar2(100)  path 'ПолучДох/ФИО/@Отчество',
                   data_rozhd      varchar2(10)   path 'ПолучДох/@ДатаРожд',
                   kod_id_lichn    varchar2(2)    path 'ПолучДох/УдЛичнФЛ/@КодУдЛичн',
                   ser_nom_doc     varchar2(15)   path 'ПолучДох/УдЛичнФЛ/@СерНомДок'
               ) d on 1 = 1
             left join f_ndfl_load_spisrab sr
               on  sr.familiya   = d.familiya  
               and sr.imya       = d.imya      
               and sr.otchestvo  = d.otchestvo 
               and to_char(sr.data_rozhd, 'dd.mm.yyyy') = d.data_rozhd
               and nvl(sr.inn_fl, 'xxx') = case when sr.inn_fl is null then 'xxx' else coalesce(d.inn_fl, sr.inn_fl) end
               and sr.god = t.year
               and sr.kod_na = t.code_na
      where  t.id = p_data_id
      and    not exists ( --многократная загрузка
               select 1
               from   f2ndfl_load_spravki ls
               where  ls.god = t.year
               and    ls.kod_na = t.code_na
               and    ls.ssylka = sr.uid_np
               and    ls.tip_dox = 9
               and    ls.nom_korr = d.doc_corr
             )
      log errors (l_err_tag) reject limit unlimited;
    --
    dbms_output.put_line('load_spravki: inserted ' || sql%rowcount || ' row(s)');
    for i in (select 1 from err$_f2ndfl_load_spravki s where s.ora_err_tag$ = l_err_tag and rownum = 1) loop
      dbms_output.put_line('Не все записи загружены');
    end loop;
    --
  exception
    when others then
      fix_exception('load_spravki(' || p_data_id || ')');
      raise;
  end load_spravki;
  
  /**
   *
   */
  procedure load_mes(
    p_data_id        int
  ) is
  begin
    --
    insert into f2ndfl_load_mes(
      kod_na,
      god,
      ssylka,
      tip_dox,
      nom_korr,
      mes,
      doh_kod_gni,
      doh_sum,
      vych_kod_gni,
      vych_sum,
      kod_stavki
    ) select t.code_na,
             t.year,
             s.ssylka,
             9 tip_dox,
             s.nom_korr,
             to_number(r.month),
             r.rev_code,
             to_number(replace(r.rev_amount, ',', '.'), '99999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''') rev_amount,
             coalesce(r.ben_code, '0'),
             to_number(replace(r.ben_amount, ',', '.'), '99999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''') ben_amount,
             r.tax_rate
      from   f_ndfl_load_employees_xml t,
             xmltable('/Файл/Документ' passing(t.xml_data)
               columns
                 doc_num         varchar2(10)   path '@НомСпр',
                 rev_data        xmltype        path 'СведДох'
             ) d,
             xmltable('/СведДох/ДохВыч/СвСумДох' passing(d.rev_data)
               columns
                 tax_rate     number        path '@Ставка',
                 month        varchar2(2)   path '@Месяц',
                 rev_code     varchar2(5)   path '@КодДоход',
                 rev_amount   varchar2(10)  path '@СумДоход',
                 ben_code     varchar2(5)   path 'СвСумВыч/@КодВычет',
                 ben_amount   varchar2(10)   path 'СвСумВыч/@СумВычет'
             ) r,
             f2ndfl_load_spravki s
      where  1=1
      and    s.tip_dox = 9
      and    s.nom_spr = -d.doc_num
      and    s.god = t.year
      and    s.kod_na = t.code_na
      and    t.id = p_data_id
      --
      and    not exists (
               select 1
               from   f2ndfl_load_mes v
               where  v.kod_na = t.code_na
               and    v.god = t.year
               and    v.ssylka = s.ssylka
               and    v.tip_dox = 9
               and    v.nom_korr = s.nom_korr
               and    v.mes = to_number(r.month)
             );
    --
  exception
    when others then
      fix_exception('load_mes(' || p_data_id || ')');
      raise;
  end load_mes;
  
  /**
   *
   */
  procedure load_vych(
    p_data_id        int
  ) is
  begin
    --
    insert into f2ndfl_load_vych(
      kod_na,
      god,
      ssylka,
      tip_dox,
      nom_korr,
      mes,
      vych_kod_gni,
      vych_sum,
      kod_stavki
    ) select t.code_na,
             t.year,
             s.ssylka,
             9 tip_dox,
             s.nom_korr,
             12,
             b.ben_code,
             to_number(replace(b.ben_amount, ',', '.'), '999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')  amount,
             r.tax_rate
      from   f_ndfl_load_employees_xml t,
             xmltable('/Файл/Документ' passing(t.xml_data)
               columns
                 doc_num         varchar2(10)   path '@НомСпр',
                 rev_data        xmltype        path 'СведДох'
             ) d,
             xmltable('/СведДох' passing(d.rev_data)
               columns
                 tax_rate        number         path '@Ставка',
                 benefits        xmltype        path 'НалВычССИ'
             ) r,
             xmltable('/НалВычССИ/ПредВычССИ' passing(r.benefits)
               columns
                 ben_code        varchar2(5)    path '@КодВычет',
                 ben_amount      varchar2(20)   path '@СумВычет'
             ) b,
             f2ndfl_load_spravki s
      where  1=1
      and    s.tip_dox = 9
      and    s.nom_spr = -d.doc_num
      and    s.god = t.year
      and    s.kod_na = t.code_na
      and    t.id = p_data_id
      --
      and    not exists (
               select 1
               from   f2ndfl_load_vych v
               where  v.kod_na = t.code_na
               and    v.god = t.year
               and    v.ssylka = s.ssylka
               and    v.tip_dox = 9
               and    v.nom_korr = s.nom_korr
               and    v.mes = 12
             )
      ;
    --
  exception
    when others then
      fix_exception('load_vych(' || p_data_id || ')');
      raise;
  end load_vych;
  
  /**
   *
   */
  procedure load_itogi(
    p_data_id        int
  ) is
  begin
    --
    insert into f2ndfl_load_itogi(
      kod_na,
      god,
      ssylka,
      tip_dox,
      nom_korr,
      kod_stavki,
      sgd_sum,
      sum_obl,
      sum_obl_ni,
      sum_fiz_avans,
      sum_obl_nu,
      sum_nal_per,
      dolg_na,
      vzysk_ifns
    ) select t.code_na,
             t.year,
             s.ssylka,
             9 tip_dox,
             s.nom_korr,
             r.tax_rate,
             to_number(replace(r.sgd_sum      , ',', '.'), '999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')  sgd_sum        ,
             to_number(replace(r.sum_obl      , ',', '.'), '999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')  sum_obl        ,
             to_number(replace(r.sum_obl_ni   , ',', '.'), '999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')  sum_obl_ni     ,
             to_number(replace(r.sum_obl_nu   , ',', '.'), '999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')  sum_obl_nu     ,
             to_number(replace(r.sum_obl_per  , ',', '.'), '999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')  sum_obl_per    ,
             to_number(replace(r.sum_fiz_avans, ',', '.'), '999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')  sum_fiz_avans  ,
             to_number(replace(r.dolg_na      , ',', '.'), '999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')  dolg_na        ,
             to_number(replace(r.vzysk_ifns   , ',', '.'), '999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')  vzysk_ifns
      from   f_ndfl_load_employees_xml t,
             xmltable('/Файл/Документ' passing(t.xml_data)
               columns
                 doc_num         varchar2(10)   path '@НомСпр',
                 doc_corr        number         path '@НомКорр',
                 rev_data        xmltype        path 'СведДох'
             ) d,
             xmltable('/СведДох' passing(d.rev_data)
               columns
                 tax_rate       number path '@Ставка',
                 sgd_sum        varchar2(20) path 'СумИтНалПер/@СумДохОбщ',
                 sum_obl        varchar2(20) path 'СумИтНалПер/@НалБаза',
                 sum_obl_ni     varchar2(20) path 'СумИтНалПер/@НалИсчисл',
                 sum_obl_nu     varchar2(20) path 'СумИтНалПер/@НалУдерж',
                 sum_obl_per    varchar2(20) path 'СумИтНалПер/@НалПеречисл',
                 sum_fiz_avans  varchar2(20) path 'СумИтНалПер/@АвансПлатФикс',
                 dolg_na        varchar2(20) path 'СумИтНалПер/@НалУдержЛиш',
                 vzysk_ifns     varchar2(20) path 'СумИтНалПер/@НалНеУдерж'
             ) r,
             f2ndfl_load_spravki s
      where  1=1
      and    s.nom_korr = d.doc_corr
      and    s.tip_dox = 9
      and    s.nom_spr = -d.doc_num
      and    s.god = t.year
      and    s.kod_na = t.code_na
      and    t.id = p_data_id
      --
      and    not exists (
               select 1
               from   f2ndfl_load_itogi v
               where  v.kod_na = t.code_na
               and    v.god = t.year
               and    v.ssylka = s.ssylka
               and    v.tip_dox = 9
               and    v.nom_korr = s.nom_korr
             );
    --
  exception
    when others then
      fix_exception('load_itogi(' || p_data_id || ')');
      raise;
  end load_itogi;
  
  /**
   *
   */
  procedure load_nomspr(
    p_year        int
  ) is
  begin
    --
    insert into f2ndfl_arh_nomspr(
      kod_na,
      god,
      ssylka,
      tip_dox,
      flag_otmena,
      nom_spr,
      fk_contragent,
      ssylka_fl,
      ui_person
    )  with w_employees as (
         select t.kod_na,
                t.god,
                t.ssylka,
                t.tip_dox,
                0 lfag_otmena,
                t.nom_spr,
                s.gf_person fk_contragent,
                (select n.ssylka_real from f_ndfl_load_nalplat n where rownum = 1 and n.god = s.god and n.kod_na = s.kod_na and n.gf_person = s.gf_person) ssylka_fl
         from   f2ndfl_load_spravki t,
                f_ndfl_load_spisrab s
         where  1=1
         and    s.uid_np = t.ssylka
         and    s.kod_na = t.kod_na
         and    s.god = t.god
         and    t.kod_na = 1
         and    t.god = 2017
         and    t.tip_dox = 9
       )
       select t.kod_na,
              t.god,
              t.ssylka,
              t.tip_dox,
              t.lfag_otmena,
              t.nom_spr,
              t.fk_contragent,
              t.ssylka_fl,
              case when t.ssylka_fl is null then t.ssylka else t.fk_contragent end ui_person
       from   w_employees t
       where  not exists (
                select 1
                from   f2ndfl_arh_nomspr ns
                where  ns.kod_na = t.kod_na
                and    ns.god = t.god
                and    ns.ssylka = t.ssylka
                and    ns.tip_dox = t.tip_dox
              );
    --
  exception
    when others then
      fix_exception('load_nomspr(' || p_year || ')');
      raise;
  end load_nomspr;

  /**
   *
   */
  procedure parse_xml(
    p_parser_version int,
    p_data_id        int,
    p_year           int
  ) is
    procedure finally_ is
    begin
      update f2ndfl_load_spravki s
      set    s.nom_spr = null
      where  s.kod_na = 1
      and    s.god = p_year
      and    s.tip_dox = 9;
    exception
      when others then
        fix_exception('finally_');
        raise;
    end finally_;
  begin
    --
    utl_error_api.init_exceptions;
    --
    load_employees(p_data_id => p_data_id, p_year => p_year);
    load_spravki(p_data_id => p_data_id);
    load_adr(p_data_id => p_data_id);
    load_mes(p_data_id => p_data_id);
    load_vych(p_data_id => p_data_id);
    load_itogi(p_data_id => p_data_id);
    load_nomspr(p_year => p_year);
    finally_;
    --
  exception
    when others then
      fix_exception('parse_xml(' || p_parser_version || ', ' || p_data_id || ')');
      raise;
  end parse_xml;
  
  /**
   * Процедура загрузки данных в таблицы load
   */
  procedure merge_load_xml(
    p_code_na    int,
    p_year       int
  ) is
    l_data_row       f_ndfl_load_employees_xml%rowtype;
    l_parser_version int;
  begin
    --
    select n.id, n.code_na, n.year, n.api_version, n.form_version
    into   l_data_row.id,
           l_data_row.code_na,
           l_data_row.year,
           l_data_row.api_version,
           l_data_row.form_version
    from   f_ndfl_load_employees_xml n
    where  n.id = (
             select max(nn.id)keep(dense_rank last order by nn.created_at)
             from   f_ndfl_load_employees_xml nn
             where  nn.code_na = p_code_na
             and    nn.year = p_year
           );
    --
    l_parser_version := 
      case substr(l_data_row.api_version, 1, 2)
        when '1С' then
          case 
            when l_data_row.form_version in ('5.04') then
              1
          end
      end;
    if l_parser_version is null then
      fix_exception('merge_load_data(rowID='||l_data_row.id||'): необрабатываемый формат ' || l_data_row.api_version || ':' || l_data_row.form_version);
      raise no_data_found;
    end if;
    --
    parse_xml(
      p_parser_version => l_parser_version,
      p_data_id        => l_data_row.id,
      p_year           => p_year
    );
    --
    commit;
    --
  exception
    when others then
      rollback;
      fix_exception('merge_load_xml(' || p_code_na || ', '||p_year||')');
      raise;
  end merge_load_xml;
  
end f2ndfl_load_empl_api;
/
