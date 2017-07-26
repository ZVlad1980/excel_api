create or replace package body zaprvkl_lines_tmp_api is

  -- 
  type g_lines_tmp_type is table of zaprvkl_lines_tmp%rowtype;
  g_lines_tmp g_lines_tmp_type;
  
  
  /**
   *
   *
   */
  procedure purge is
  begin
    --
    if g_lines_tmp is null then
      g_lines_tmp := g_lines_tmp_type();
    elsif g_lines_tmp.count > 0 then
      g_lines_tmp.trim(g_lines_tmp.count);
    end if;
    --
  end purge;
  
  /**
   *
   *
   */
  procedure flush_to_table is
  begin
    --
    if g_lines_tmp is not null and g_lines_tmp.count > 0 then
      forall i in 1..g_lines_tmp.count
        insert into zaprvkl_lines_tmp values g_lines_tmp(i);
      purge;
    end if;
    --
  end flush_to_table;
  
  /**
   *
   *
   */
  procedure add_line(
    p_line in out nocopy zaprvkl_lines_tmp%rowtype
  ) is
  begin
    --
    if g_lines_tmp is null then
      g_lines_tmp := g_lines_tmp_type();
    end if;
    --
    g_lines_tmp.extend;
    g_lines_tmp(g_lines_tmp.last) := p_line;
    --
    if g_lines_tmp(g_lines_tmp.last).excel_id is null then
      g_lines_tmp(g_lines_tmp.last).excel_id := g_lines_tmp.last;
    end if;
    --
    if g_lines_tmp.count = 1000 then
      flush_to_table;
    end if;
    --
  end add_line;

end zaprvkl_lines_tmp_api;
/
