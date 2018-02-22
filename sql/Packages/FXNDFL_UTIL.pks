CREATE OR REPLACE PACKAGE FXNDFL_UTIL AS
/******************************************************************************
   NAME:       FXNDFL_UTIL
   PURPOSE:  
             ���������� � ������ ������� � ������� � ������� ���������� ���
             �� ������
                    2-����
                    6-����
                    
             �������� ������ �� ����������
             �������������  ������������������
             ������������ ������ ������� �� �����������������
             ������ ������ � ��������� ��������

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        09/02/2016      Anikin       1. Created this package.
******************************************************************************/


  --��� ������ ��
  C_REVTYP_EMPL constant number := 9;

-- ������������� �������� ������� 
function Init_SchetchikSpravok( pKodNA in number, pGod in number, pTipDox in number, pNomKorr in number ) return number;
/* ���������:
    pKodNA - ��� ���������� ������
    pGod - ���
    pTipDox - ��� ������ �� ������������� ���������� ������
    pNomKorr - ����� ������������� ��� ����� ����������� �������
  
   ���������:
   ��� ������. 0 - ������ ���.
   
   ����������� ����� �������� ������ �� ������ ���������� ������ � ��������� _LOAD_.
   ����������� ������� ���, �������  pGod, pTipDox, pNomKorr ������ ����� � ����� �������.
   ����� ������������� ��������� ����� ��������� ��������� 
   ������������� ������������������, ����������� ������� ������� � ����������� ������ � �������.    
*/    
----------------------- ====  x-���� ==== -----------------------
-----------------------   ����� ���������  -----------------------

-- ��������� ������ ������������������ �� ��� �� �������� ������� �� ����
procedure Spisok_NalPlat_poLSPV( pErrInfo out varchar2, pSPRID in number  );

-- ���������� ������ �������� ������
-- ����� ������ ���� �������!
procedure Spisok_NalPlat_DohodNol( pSPRID in number );

-- ��������� ���
function Check_INN( pINN in varchar2 ) return number;

-- ��������� ��������� ������ ������������������, �������� �������� ������ 
procedure Oshibki_vSpisNalPlat( pReportCursor out sys_refcursor, pErrInfo out varchar2, pKodNA in number, pGod in number, pPeriod in number );

-- ���������� ����� ������������������, ������������ ���������� �����������
-- ��������� 
procedure Raschet_Chisla_SovpRabNp( pErrInfo out varchar2, pSPRID in number );

-- ���������� ����� ������������������, ���������� ��������� ����� � ������ ����
procedure Raschet_Chisla_NalPlat( pErrInfo out varchar2, pSPRID in number );


-- �������� �������� ������� � �����
-- ���� ��������� != 0, �� ��������� ������� ���������
function TestArhivBlok( pSPRID in number ) return number;

----------------------- ====  2-���� ==== -----------------------

-- �������� ������ � ������������� ������
-- ��� ����������� ������������ ������� 2-����

-- �������� ��������� ���������� ����������
-- ��� ���������� ����� ������ ����������
--
-- 03.11.2017 RFC_3779 - ������� ��������� ��� ������������ ����.�������
--
procedure InitGlobals( 
  pKODNA   in number, 
  pGOD     in number, 
  pTIPDOX  in number, 
  pNOMKOR  in number,
  pSPRID   in number   default null,
  pNOMSPR  in varchar2 default null,
  pDATDOK  in date     default null,
  pNOMVKL  in number   default null,
  pNOMIPS  in number   default null,
  pCAID    in number   default null,
  pCOMMIT  in boolean  default true,
  pNALRES_DEFFER in boolean default false,
  pACTUAL_DATE   in date    default sysdate --���� �� ������� ����������� ������ (������ �� ���� �������������)
);

-- ��������� ������ ������������������
-- (����� ������� 2-����)
    -- ����� ������ (TIP_DOX=1)
       -- ������  ���
       procedure Load_Pensionery_bez_Storno;
       -- ������  ����
       procedure Load_Pensionery_so_Storno;
    -- ����� ������� (TIP_DOX=2)
       -- ������  ���
       procedure Load_Posobiya_bez_Pravok; 
       -- ������  ����
       procedure Load_Posobiya_s_Ipravlen; 
    -- ����� �������� (TIP_DOX=3)
       -- ������  ���
       procedure Load_Vykupnye_bez_Pravok;
       -- ������  ����
       procedure Load_Vykupnye_s_Ipravlen; 
-- ����� �������� ������ ��

-- �������� ������� �� �������
    -- ����� ������ (TIP_DOX=1)
       -- ������ ���
       procedure Load_MesDoh_Pensia_bezIspr;
       -- ������ ����
       procedure Load_MesDoh_Pensia_sIspravl;
    -- ����� ������� (TIP_DOX=2)
       -- �����������  ���
       procedure Load_MesDoh_Posob_bezIspr;
       -- �����������  ����
       procedure Load_MesDoh_Posob_sIspravl;
    -- ����� �������� (TIP_DOX=3)
       -- �����������  ���
       procedure Load_MesDoh_Vykup_bezIspr;
       -- �����������  ����
       procedure Load_MesDoh_Vykup_sIspravl;
-- ����� �������� ������� �� �������       
 
-- �������� ������� ��� ����������� � ��������� �������� �����
-- ������ �� �� ������ ��� ����������
-- ������ ����������� ������� �� ���������������
   procedure Load_Vychety;
   
-- �������� ������ ������� 2-����
-- ������� ����� �������, �������, ���������� ������� �������� �� �������
    -- ����� ������   (TIP_DOX=1)
       procedure Load_Itogi_Pensia;
    -- ����� �������
       -- �����������  ���
       procedure Load_Itogi_Posob_bezIspr;       
    -- ����� �������� (TIP+DOX=3)
       -- �����������  ���
       procedure Load_Itogi_Vykup_bezIspr;
       -- �����������  ����
       procedure Load_Itogi_Vykup_sIspravl;       

-- �������� ������ ��� ���������� ������ ����� �����������
procedure Load_Itogi_Obnovit( pKODNA in number, pGOD in number, pSSYLKA in number, pTIPDOX in number, pNOMKOR in number );    


-- ��������� �������-��������� ������� �� ������� LOAD_SPRAVKI ��� ��������� ����
-- �������������� ������������ InitGlobals
procedure Load_Numerator; 

-- ���������� SSYLKA � FK_CONTRAGENT � ������� ������� ��� KOD_NA=1
function UstIdent_GAZFOND( pGod in number ) return number;

-- �������� SSYLKA � FK_CONTRAGENT � �������� ������� ��� KOD_NA=1
function SbrosIdent_GAZFOND( pGod in number ) return number;

-- ���������� ���, ���� �� �� ��������, �� ���� ������ ������� � ��� ��� ���� �� �����������
function ZapolnINN_izDrSpravki( pGod in number )  return number;

-- ���������� ����������� �� �������� ��
function ZapolnGRAZHD_poUdLichn( pGod in number ) return number;

-- �������� ������ ������������, ��� ������� � ������ �������� ������� ������ ������
procedure RaznDan_Kontragenta( pReportCursor out sys_refcursor, pErrInfo out varchar2, pGod in number );

-- �������� ������ �����������, ��� ������� ������� ����������� ���������� ������, ��������: ���, �������
procedure SovpDan_Kontragentov( pReportCursor out sys_refcursor, pErrInfo out varchar2, pGod in number );

-- �������� ������ ������� � ���������� ������� 
procedure OshibDan_vSpravke( pReportCursor out sys_refcursor, pErrInfo out varchar2, pGod in number );

-- ������������� ������� ��� ���������� ������ � �������� ����
procedure Numerovat_Spravki( pKodNA in number, pGod in number );
procedure Numerovat_Spravki_OTKAT( pKodNA in number, pGod in number );

-- ��� ��������� � ���������� ������
procedure Numerovat_KorSpravki;

-- ������ ����� ��������� ��������� ������
-- ������ ������� ����� �������������� ����������� � ������� ������� �������
-- (����� ��������������� ��������� ���������� InitGlobals)
procedure Load_Adresa_INO;
procedure Load_Adresa_vRF;

-- ���������� ������� � �������� � �����
-- �� �����  ������ ��������� ������� ���������� ��� ���������
-- function KopirSpr_vArhiv( pKodNA in number, pGod in number ) return number;

-- ���������� � ����� ����� �� �������� 
procedure KopirSprItog_vArhiv( pKodNA in number, pGod in number );

-- ���������� � ����� ����������� ������ �� ������� � �������� 
procedure KopirSprMes_vArhiv( pKodNA in number, pGod in number );

-- ���������� � ����� ������ �� ������� 
procedure KopirSprVych_vArhiv( pKodNA in number, pGod in number );

-- ���������� � ����� ����������� � ������� �� ������� 
function KopirSprUved_vArhiv( pKodNA in number, pGod in number ) return number;

-- ���������� � ����� ������ �� �� ������� 
procedure KopirSprAdres_vArhiv( pKodNA in number, pGod in number );

-- ���������� � ����� ������ �� �� ������ ������� GNI_ADR_SOOTV
-- (� ������ FL_ULIS ������ ���� ����� ����)
procedure Kopir_Adresa_vRF_izSOOTV( pPachka in number, pGod in number );

-- ������� ������ � ������� XML-������
 
  /*
    Declare 
        RC number;
    begin
        dbms_output.enable(10000);
        -- RC:=FXNDFL_UTIL.Numerovat_Spravki( 1, 2015 );   --   0'52"
        -- RC:=FXNDFL_UTIL.KopirSprItog_vArhiv( 1, 2015 );   --   0'02"
        -- RC:=FXNDFL_UTIL.KopirSprMes_vArhiv( 1, 2015 );  --   0'26"
        -- RC:=FXNDFL_UTIL.KopirSprVych_vArhiv( 1, 2015 ); --   0'01"
        -- RC:=FXNDFL_UTIL.KopirSprUved_vArhiv( 1, 2015 ); --   0'01"
        -- RC:=FXNDFL_UTIL.KopirSprAdres_vArhiv( 1, 2015 );  -- ����� �����?
        
        -- RC:=FXNDFL_UTIL.Zareg_XML( 1, 2015, 2 );
        
        dbms_output.put_line(to_char(RC));
    end;
  */
  
  -- ������� ������ � ������� XML-������
  function zareg_xml
  (
    pkodna    in number,
    pgod      in number,
    pforma    in number,
    ppriznak  in number,
    pcommit   in number default 1
  ) return number;
 

-- ������������ ������ ������� �� XML-������
procedure RaspredSpravki_poXML( pKodNA in number, pGod in number, pForma in number );


-- �������� ����� ������������ ������� 2���� �� ���� � ������ ��
-- ��� �������� ��������������� �������� �������
procedure Kopir_SprF2_dlya_KORR( pNOMSPRAV in varchar2, pGod in number);


-- ---------------------------------- ====  6-���� ==== ----------------------------------
-- ������ 6-����

-- ������� ������������� �������, ���� ���, �� ������� �����
procedure Naiti_Spravku_f6 ( pErrInfo out varchar2, pSprId out number, pKodNA in number, pGod in number, pKodPeriod in number, pNomKorr in number, pPoMestu in number default 213 );

-- �������� ��������������� ������ ������� �� ����� 6-����
function Sozdat_Spravku_f6 ( pKodNA in number, pGod in number, pKodPeriod in number, pNomKorr in number, pPoMestu in number default 213 ) return varchar2;

-- ������������ ������� �� ����� 6-����
procedure Kopir_SprF6_vArhiv ( pErrInfo out varchar2, pSPRID in number );

-- ����� ����������� �������, ����� ���������� � ��������

-- ����� ��-����� ��� ����������� ������� � ������������ ������
procedure Zapoln_Buf_NalogIschisl( pSPRID in number );

-- ������ 020 ������� 
-- "����� ������������ ������"
-- ����������� ������ � ������ ���� 
-- �� �������� ��������� ������
function SumNachislDoh( pSPRID in number, pSTAVKA in number ) return float;

-- ������ 030 ������� 
-- "����� ��������� �������"
-- ������ ������������ �����,
-- �� ����������� �����
-- ����������� ������ � ������ ���� 
-- �� �������� ��������� ������
function SumIspolzVych( pSPRID in number, pSTAVKA in number ) return float;

-- ������ 040 ������� 
-- "����� ������������ ������"
-- ����������� ������ � ������ ���� 
-- �� �������� ��������� ������
function SumIschislNal( pSPRID in number, pSTAVKA in number ) return float;

-- ������ 060 ������� 
-- "���������� ���������� ���, ���������� �����"
-- � ������ ����
-- ����� ������������������
function KolichNP( pSPRID in number ) return number;


-- ������ 070 ������� 
-- "����� ����������� ������"
-- � ������ ���� 
-- �� ���� ��������� �������
function SumUderzhNal( pSPRID in number ) return float;

-- ������ 080 ������� 
-- "����� �� ����������� ������"
-- � ������ ���� 
-- �� ���� ��������� �������
function SumNeUderzhNal( pSPRID in number ) return float;


   -- ��������������� ����������
   
   -- ����� ������, ������������� ��������� �������
   -- ����������� ������ ���������� �������� (���� 83)
   function SumVozvraNal83( pSPRID in number ) return float;
   
   -- ����� ������, ������������� ��������� �������
   -- ������� ������������ ���������� �����/����� ������ � ���������� ������
   -- ������������� ����������� ������ � �������� �����
   -- �� �������������� �����������
      
   function SumVozvraNalDoc( pSPRID in number ) return float;   
   

-- ������ 090 ������� 
-- "����� ������������� ������"
-- � ������ ���� 
-- �� ���� ��������� �������
function SumVozvraNal( pSPRID in number ) return float;


-- ������ 2 ������� 6����
-- ������ ������ ������� ������ ��������� ��������� ������:
-- 100 ���� ������������ ��������� ������
-- 110 ���� ��������� ������
-- 120 ���� ������������ ������
-- 130 ����� ���������� ����������� ������
-- 140 ����� ����������� ������ 
procedure ZaPeriodPoDatam( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number, pKorKV in number default 0 );

-- ���������� ����������� ������ ��� 6���� �� �������� ������� �� ����
procedure ZagruzTabl_poLSPV( pErrInfo out varchar2, pSPRID in number );

-- ������ 2 ������� 6����
-- ������� ����������� �� ���������� � ��������
procedure ZaPeriodPoDokum( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number );

-- ������ ��� ������ ���� ������ �� ���������� ������ ��� ������ � ����������� �������
procedure Sverka_KvOtchet( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number );

-- ������������ ����������� � ���������� ���� �������
procedure Sverka_NesovpadNal( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number );
-- ������ 2 (�������)
procedure Sverka_NesovpadNal_v2( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number );

-- ��������� ����� �� ��������� ���������� ��� 6����
procedure f6_ZagrSvedDoc( pSPRID in number );

-- ��������� ������ �� �����������
procedure Parse_xml_izBuh(
  x_err_info out varchar2,
  p_spr_id   in  number,
  p_xml_info in  varchar2,
  p_kod_podr in  number default 1
);

-- ����� 6-���� 
-- ---------------------------------- ====  6-���� ==== ----------------------------------



  /**
   */
  procedure copy_adr(
    p_src_ref_id    f2ndfl_arh_spravki.id%type,
    p_trg_ref_id    f2ndfl_arh_spravki.id%type
  );
--
-- RFC_3779: ������� ����������� ������� � ������ � ��������� �������
--
  function copy_ref_2ndfl(
    p_ref_row in out nocopy f2ndfl_arh_spravki%rowtype
  ) return f2ndfl_arh_spravki.id%type;

  --
  -- RFC_3779: ������������ � ��������� ����� �������������� ������� � ������� F2NDFL_ARH_VYCH
  --
  procedure calc_benefit_usage(
    p_code_na f2ndfl_arh_spravki.kod_na%type,
    p_year    f2ndfl_arh_spravki.god%type,
    p_spr_id  f2ndfl_arh_spravki.id%type default null
  );
  
  
  /**
   * ��������� copy_load_address ������� ����� ���� ������� F2NDFL_LOAD_ADR, ����������� � �������� ������� 
   */
  procedure copy_load_address(
    p_src_ref_id f2ndfl_load_spravki.r_sprid%type,
    p_nom_corr   f2ndfl_load_spravki.nom_korr%type
  );
  
  /**
   * ��������� copy_load_employees ������� ����� ������� �� ������� ����������� �����
   *   ���������� ���� ���, ��� ���������� �����!
   *  ����� ��������� � �������� f2ndfl_load_spravki, f2ndfl_load_mes, f2ndfl_load_itogi, f2ndfl_load_vych
   */
  procedure copy_load_employees(
    p_src_ref_id   f2ndfl_load_spravki.r_sprid%type,
    p_corr_ref_id  f2ndfl_load_spravki.r_sprid%type,
    p_nom_corr     f2ndfl_load_spravki.nom_korr%type
  );
  
  procedure fill_ndfl_load_nalplat(
    p_code_na   f_ndfl_load_nalplat.kod_na%type,
    p_year      f_ndfl_load_nalplat.god%type,
    p_from_date date,
    p_end_date  date,
    p_term_year date,
    p_period    number
  );
  
  procedure set_zero_nalplat(
    p_code_na   f_ndfl_load_nalplat.kod_na%type,
    p_year      f_ndfl_load_nalplat.god%type,
    p_from_date date,
    p_end_date  date,
    p_term_year date
  );
  
  /**
   * ��������� fill_ndfl_load_nalplat - ���������� �������
   *  f_ndfl_load_nalplat, � �������� �� � ������� �������
   */
  procedure fill_ndfl_load_nalplat(
    p_code_na     int,
    p_load_date   date
  );
  
  /**
   * ������� ���������� ��� �������� 6���� �� ����
   */
  function get_quarter_row(
    p_date date
  ) return sp_quarters_v%rowtype;
  
  /**
   * ��������� create_f2ndfl_arh_spravki ��������� ������� � f2ndfl_arh_spravki
   *
   * @param p_code_na       - 
   * @param p_year          - 
   * @param p_contragent_id - CDM.CONTRAGENTS.ID
   * @param p_nom_spr       - ����� ������� (����������, ���� ����� ����������)
   * @param p_nom_korr      - ����� �������������
   * 
   */
  procedure create_f2ndfl_arh_spravki(
    p_code_na       int,
    p_year          int,
    p_contragent_id f2ndfl_arh_spravki.ui_person%type default null,
    p_nom_spr       f2ndfl_arh_spravki.nom_spr%type   default null,
    p_nom_korr      f2ndfl_arh_spravki.nom_korr%type  default 0
  );
  
  /**
   * ��������� create_arh_spravki_prz2 ������� ������� � ��������� 2
   *   �� ������������, � ������� ������������ �����!
   */
  procedure create_arh_spravki_prz2(
    p_code_na int,
    p_year    int
  );
    
  /**
   * ��������� enum_refs - ��������� ������� 2����
   *  ���������� ������ ����� ������� ������������ Loads � NOMSPR �� ���������� f2ndfl_arh_spravki
   * ������ � 0, ��� ������ ����!
   */
   /*
   TODO: owner="V.Zhuravov" created="01.02.2018"
   text="�������� ����������� ���������� �������, �������� ������ ����������� ������"
   */
  procedure enum_refs(
    p_code_na int,
    p_year    int
  );
  
  /**
   */
  function Check_ResidentTaxRate(
    p_code_na   int,
    p_year      int,
    p_nom_spr   varchar2,
    p_resident  int
  ) return number RESULT_CACHE;
  
  /**
   * ��������� ���������� ���������� ARH_SPRAVKI (����������� PRIZNAK_S ������� � �.�.
   */
  procedure update_spravki_finally(
    p_code_na int,
    p_year    int
  ); 
  
END FXNDFL_UTIL;
/
