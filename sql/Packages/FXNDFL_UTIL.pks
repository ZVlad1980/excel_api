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
  pCOMMIT  in boolean  default true
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
function Zareg_XML( pKodNA in number, pGod in number, pForma in number, pCommit in number default 1 ) return number;
 

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
    p_spr_id f2ndfl_arh_spravki.id%type
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
  
END FXNDFL_UTIL;
/
