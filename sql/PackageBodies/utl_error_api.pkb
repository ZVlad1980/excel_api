create or replace noneditionable package body utl_error_api is

  type g_exception_rec_type is record (
    routine     varchar2(200),
    params      varchar2(2000),
    err_msg     varchar2(2000),
    err_code    number,
    error_stack varchar2(2000),
    backtrace   varchar2(2000),
    call_stack  varchar2(2000)
  );
  type g_exception_stack_type is table of g_exception_rec_type;

  g_exception_stack g_exception_stack_type;

  /**
   *
   *
   *
   */
  procedure init_exceptions is
  begin
    g_exception_stack := g_exception_stack_type();
  end init_exceptions;

  /**
   *
   *
   *
   */
  procedure push_exception(
    p_routine varchar2 default null,
    p_params  varchar2 default null,
    p_err_msg varchar2 default null
  ) is
  begin
    if g_exception_stack is null then init_exceptions; end if;
    --
    g_exception_stack.extend;
    --
    g_exception_stack(g_exception_stack.count).routine     := p_routine;
    g_exception_stack(g_exception_stack.count).params      := p_params ;
    g_exception_stack(g_exception_stack.count).err_msg     := p_err_msg;
    g_exception_stack(g_exception_stack.count).err_code    := nvl(sqlcode, 0);
    g_exception_stack(g_exception_stack.count).error_stack := substr(dbms_utility.format_error_stack, 1, 2000);
    g_exception_stack(g_exception_stack.count).backtrace   := substr(dbms_utility.format_error_backtrace, 1, 2000);
    g_exception_stack(g_exception_stack.count).call_stack  := substr(dbms_utility.format_call_stack, 1, 2000);
    --
  end push_exception;

  /**
   *
   *
   *
   */
  function serialize_params(
    p_params  sys.odcivarchar2list
  ) return varchar2 is
    l_result varchar2(2000);
  begin
    --
    if p_params is not null and p_params.count > 0 then
      for i in 1..p_params.count / 2 loop
        l_result := l_result ||
          case when l_result is not null then ',' || chr(10) end ||
          p_params(i * 2 - 1) || ' => ' || p_params(i * 2);
      end loop;
    end if;
    --
    return l_result;
    --
  end serialize_params;

  /**
   *
   *
   *
   */
  procedure fix_exception(
    p_routine varchar2,
    p_params  sys.odcivarchar2list,
    p_err_msg varchar2
  ) is
  begin
    push_exception(
      p_routine => p_routine,
      p_params  => serialize_params(p_params => p_params),
      p_err_msg => p_err_msg
    );
  end fix_exception;

  /**
   *
   *
   *
   */
  procedure fix_exception(
    p_err_msg varchar2
  ) is
  begin
    fix_exception(
      p_routine => null,
      p_params  => null,
      p_err_msg => p_err_msg
    );
  end fix_exception;

  /**
   *
   *
   *
   */
  function get_exception(
    p_ind integer default 1
  ) return varchar2 is
    l_result varchar2(32767);
    --
    procedure push_(
      p_msg varchar2
    ) is
    begin
      if p_msg is not null then
        l_result := l_result || substr(p_msg, 1, (2000 - length(l_result))) || chr(10);
      end if;
    end push_;
    --
  begin
    --
    if g_exception_stack is not null and g_exception_stack.exists(p_ind) then
      push_(g_exception_stack(p_ind).routine    );
      push_(g_exception_stack(p_ind).params     );
      push_(g_exception_stack(p_ind).err_msg    );
      push_(g_exception_stack(p_ind).call_stack );
      if g_exception_stack(p_ind).err_code <> 0 then
        push_(g_exception_stack(p_ind).error_stack);
        push_(g_exception_stack(p_ind).backtrace  );
      end if;
    end if;
    --
    return l_result;
    --
  end get_exception;

  /**
   *
   */
  function get_error_msg return varchar2 is
    l_result varchar2(4000);
  begin
    return get_exception(1);
  end get_error_msg;
  /**
   *
   *
   *
   */
  function get_exception_full
    return varchar2 is
    --
    l_result varchar2(32767);
    --
  begin
    if g_exception_stack is not null then
      for i in 1..g_exception_stack.count loop
        l_result := l_result || substr(get_exception(i), 1, 32767 - nvl(length(l_result), 0));
      end loop;
    end if;
    --
    return l_result;
    --
  end get_exception_full;

end utl_error_api;
/
