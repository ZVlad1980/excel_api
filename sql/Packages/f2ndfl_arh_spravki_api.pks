create or replace package f2ndfl_arh_spravki_api is

  -- Author  : V.ZHURAVOV
  -- Created : 02.11.2017 15:54:23
  -- Purpose : API ������������ ������� 2����
  
  /** ���� ��� �������
   * ��������� calc_reference ������ ����� �������
   *
   * @param p_ref_row    - ������� f2ndfl_arh_spravki%rowtype
   * @param p_src_ref_id - ID ���������� �������
   *
   /
  procedure calc_reference(
    p_ref_row     in out nocopy f2ndfl_arh_spravki%rowtype
  );
  --*/
  /**
   * ��������� create_reference_corr �������� �������������� ������� 2����
   *
   * @param p_code_na       - ��� ����������������� (���=1)
   * @param p_year          - ���, �� ������� ���� ������������ �������������
   * @param p_contragent_id - ID �����������, �� �������� ����������� ������� (CDM.CONTRAGENTS.ID)
   *
   */
  procedure create_reference_corr(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_contragent_id  f2ndfl_arh_nomspr.fk_contragent%type
  );

end f2ndfl_arh_spravki_api;
/
