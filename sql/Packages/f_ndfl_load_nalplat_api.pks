create or replace package f_ndfl_load_nalplat_api is

  -- Author  : V.ZHURAVOV
  -- Created : 25.01.2018 12:51:06
  -- Purpose : 
  
  -- Public type declarations
  
  
  /**
   * ��������� fill_ndfl_load_nalplat - ���������� �������
   *  f_ndfl_load_nalplat, � �������� �� � ������� �������
   */
  procedure fill_ndfl_load_nalplat(
    p_code_na     int,
    p_load_date   date
  );

end f_ndfl_load_nalplat_api;
/
