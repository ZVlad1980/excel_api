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
  
  /*
   * ������������� ������ load � arh (�� 16 ��� - �������������������!)
   *  
   * @param p_code_na  - ��� ��
   * @param p_year     - ���
   * @param p_ref_id   - optional, f2ndfl_arh_spravki.id
   *
   */
  procedure synhonize_load(
    p_code_na        f2ndfl_arh_spravki.kod_na%type,
    p_year           f2ndfl_arh_spravki.god%type,
    p_ref_id         f2ndfl_arh_spravki.id%type default null
  );
  
  /**
   * ������� validate_pers_info - ��������� ����.������
   *
   * @param p_code_na       - 
   * @param p_year          -
   * @param p_fk_contragent - 
   * @param p_last_name     - 
   * @param p_first_name    - 
   * @param p_middle_name   - 
   * @param p_birth_date    - 
   * @param p_doc_code      - ��� ��
   * @param p_doc_num       - ����� � ����� ��
   * @param p_inn           - ���
   * @param p_citizenship   - ����������� (��� ������)
   * @param p_resident      - �������� (1/2 - ��/���)
   * @param p_inn_dbl       - ���������� ������� � ���������� ���  count(distinct case when s.inn_fl is not null then s.ui_person end) over(partition by s.kod_na, s.god, s.inn_fl)
   * @param p_fiod_dbl      - ���������� ������� � ���������� ���� count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.ser_nom_doc)
   * @param p_doc_dbl       - ���������� ������� � ���������� ��   count(distinct s.ui_person) over(partition by s.kod_na, s.god, s.familiya, s.imya, s.otchestvo, s.data_rozhd)
   * @param p_invalid_doc   - ������� ����������������� �������� (Y/N)
   *
   * @return varchar2- ������ �� ������� ������ �/� ������ (��. ���. sp_ndfl_errors)
   *
   */
  function validate_pers_info(
    p_code_na        int,  
    p_year           int,
    p_nom_spr        varchar2,
    p_fk_contragent  int,
    p_doc_code       int,
    p_doc_num        varchar2,
    p_inn            varchar2,
    p_citizenship    varchar2,
    p_resident       int,
    p_inn_dbl        int,
    p_fiod_dbl       int,
    p_doc_dbl        int,
    p_invalid_doc    varchar2
  ) return varchar2;
  
end f2ndfl_arh_spravki_api;
/
