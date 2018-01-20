create or replace package body gateway_user_pkg is

  C_DATE_FMT     constant varchar2(20) := 'dd.mm.yyyy';

  
  -- Строки символов для замены
  C_SRC_CHR  constant varchar2(200) := 'AOPEHBCXMK';
  C_DEST_CHR constant varchar2(200) := 'АОРЕНВСХМК';
  
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
   * Функция конвертирования строки в дату (возвращает null в случае ошибки)
   *  Дата ожидается в формате ГГГГММДД
   */
  function to_date$(p_date_str varchar2) return date is
  begin
    return to_date(p_date_str, C_DATE_FMT);
  exception
    when others then
      return null;
  end to_date$;
  
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
           trim(
             regexp_replace(
               p_str, '  +', ' '
             )
           ),
         C_SRC_CHR,
         C_DEST_CHR
       );
   end prepare_str$;
  
  /**
   * Процедура get_report возвращает курсор с данными отчета
   * 
   * @param x_result      - курсор с данными
   * @param x_err_msg     - сообщение об ошибке
   * @param p_report_code - код отчета
   * @param p_year        - год формирования отчета
   * @param p_month       - месяц формирования отчета
   * @param p_report_date - дата, на которую формируется отчет
   *
   */
  procedure get_report(
    x_result      out sys_refcursor, 
    x_err_msg     out varchar2,
    p_report_code     varchar2,
    p_year            number,
    p_month           number,
    p_report_date     varchar2
  ) is
  begin
    --
    gateway_pkg.get_report(
      x_result      => x_result      ,
      x_err_msg     => x_err_msg     ,
      p_report_code => p_report_code ,
      p_year        => p_year        ,
      p_month       => p_month       ,
      p_report_date => p_report_date
    );
    --
  end get_report;
  
  /**
   * Процедура load_employees запускает загрузки сотрудников в f_ndfl_load_spisrab
   *   (из tmp таблицы, см. процедуру add_line)
   */
  procedure load_employees(
    x_err_msg   out varchar2,
    p_load_date varchar2
  ) is
  begin
    --
    gateway_pkg.load_employees(
      x_err_msg   => x_err_msg  ,
      p_load_date => p_load_date
    );
    --
  end load_employees;
  
  /**
   * Процедура load_employees добавляет персональные данные в tmp таблицу
   *   Вызывает API 
   *
   * @param p_last_name   - фамилия
   * @param p_first_name  - имя
   * @param p_second_name - отчество
   * @param p_birth_date  - дата рождения в формате ДД.ММ.ГГГГ
   * @param p_snils       - СНИЛС
   * @param p_inn         - ИНН
   *
   */
  procedure load_employees(
    p_last_name    varchar2,
    p_first_name   varchar2,
    p_second_name  varchar2,
    p_birth_date   varchar2,
    p_snils        varchar2,
    p_inn          varchar2
  ) is
  begin
    --
    gateway_pkg.load_employees(
      p_last_name   => p_last_name  ,
      p_first_name  => p_first_name ,
      p_second_name => p_second_name,
      p_birth_date  => p_birth_date ,
      p_snils       => p_snils      ,
      p_inn         => p_inn        
    );
    --
  end load_employees;
  
end gateway_user_pkg;
/
