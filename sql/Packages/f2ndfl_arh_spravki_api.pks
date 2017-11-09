create or replace package f2ndfl_arh_spravki_api is

  -- Author  : V.ZHURAVOV
  -- Created : 02.11.2017 15:54:23
  -- Purpose : API ������������ ������� 2����

  /**
   * ������� get_reference_last ���������� ����� 2���� ������� �� ���� � �����������
   *
   * @param p_kod_na        - ��� ��
   * @param p_year          - ���
   * @param p_contragent_id - ID �����������
   *
   * @return - f2ndfl_arh_nomspr.nom_spr%type
   *
   */
  function get_reference_num(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_contragent_id  f2ndfl_arh_nomspr.fk_contragent%type
  ) return f2ndfl_arh_nomspr.nom_spr%type;
  
  /**
   * ������� get_reference_last_id ���������� ID ������� �� ���� � ������
   *  ���� ������� ��������� - ���������� ID ��������� �������������
   *
   * @param p_code_na - ��� ��
   * @param p_year    - ���
   * @param p_ref_num - ����� ������� 2����
   *
   * @return - f2ndfl_arh_spravki.id%type
   *
   */
  function get_reference_last_id(
    p_code_na   f2ndfl_arh_spravki.kod_na%type,
    p_year      f2ndfl_arh_spravki.god%type,
    p_ref_num   f2ndfl_arh_spravki.nom_spr%type,
    p_load_exists varchar2 default 'Y'
  ) return f2ndfl_arh_spravki.id%type;
  
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

  /**
   * ��������� delete_reference ������� ������ ������� �� ������ F2NDFL_, ����� F2NDFL_ARH_NOMSPR
   *  ���� ������ ������� �������� � XML ��� ��� - �������� ����������.
   * ��������: ��� �������� ������� (����.�����=0) ������ �� ����������� ����� �� ���������, ����� �� ��������� ������ �� 9 ���� ������ (��)
   *   �.�. ���� ������� ��������� � ���������� �����, �� ����������� ������������ - ��� �� ����� �������, 
   *        ���� ��������� �������� ������������ - ����� ������� ������ �� ���� ����� ������, ����� 9 (��)
   *
   * @param p_ref_id - ID ��������� �������
   * @param p_commit - ���� �������� ����������
   *
   */
  procedure delete_reference(
    p_ref_id f2ndfl_arh_spravki.id%type,
    p_commit boolean default false
  );

end f2ndfl_arh_spravki_api;
/
