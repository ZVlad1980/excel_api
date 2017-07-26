create or replace package zaprvkl_lines_tmp_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.07.2017 9:28:37
  -- Purpose : API tmp таблицы (загрузка данных из Excel)
  
  procedure purge;
  
  procedure flush_to_table;
  
  procedure add_line(
    p_line in out nocopy zaprvkl_lines_tmp%rowtype
  );
  
end zaprvkl_lines_tmp_api;
/
