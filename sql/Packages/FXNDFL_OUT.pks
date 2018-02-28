CREATE OR REPLACE PACKAGE FXNDFL_OUT AS
/******************************************************************************
   NAME:       FXNDFL_OUT
   PURPOSE:  Вывод справок по форме 2НДФЛ

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        20/02/2016      Anikin       1. Created this package.
******************************************************************************/

type f6NDFL_CorOpsRow is record( 
  CATEGOR       VARCHAR2(5),
  DATA_OP       DATE,
  GOD_OP        NUMBER,
  KVART_OP      NUMBER,
  STAVKA        NUMBER,
  DOHOD         FLOAT,
  NALOG         FLOAT,
  TIP_KOR       VARCHAR2(32 BYTE),
  NOM_VKL       NUMBER(10),
  NOM_IPS       NUMBER(10),
  SSYLKA_DOC    NUMBER(10),
  SSYLKA_FL     NUMBER(10),
  FAMILIYA      VARCHAR2(32 BYTE),
  IMYA          VARCHAR2(32 BYTE),
  OTCHESTVO     VARCHAR2(32 BYTE),
  DATA_ROGD     DATE,
  KVART_KOR     NUMBER,
  GOD_PERVOPER  NUMBER,
  DATA_KORR     DATE) ;
type  f6NDFL_CorOpsTbl  is table of f6NDFL_CorOpsRow;  

  function List_CorrectionOpers( pTermEnd in date ) return f6NDFL_CorOpsTbl pipelined; 

  -- Получить xml-файл для передачи данных в ГНИ 
  -- параметры:
  --    pFileId   - идентификатор в реестре файлов F_NDFL_ARH_XML_FILES
  --    pFormDate - дата на которую формируется справка (влияет на подписанта)
  function GetXML_XChFileF2(
    pFileId   in number,
    pFormDate date default sysdate
  ) return clob;
  
  -- окно для выкачивания файлов из БД
  procedure GetXML_All_XChFileF2(
    pXmlCursor out sys_refcursor, 
    pErrInfo out varchar2, 
    pFirstXmlID in number, 
    pLastXmlID in number ,
    pFormDate date default sysdate
  );
  
  -- Получить xml-файл для печати справки 
  -- параметры:
  --    код Налогового Агента по справочнику 1 - ГАЗФОНД
  --    налоговый год
  --    номер справки - строка с ведущими нулями
  --    номер корректировки - для первой справки 0
  --    0 - выводить архив справок в ГНИ /  1 - текущие персональные данные
  --    pFormVersion - версия формы (def.=5.04), если NULL - будет определяться автоматически
  function GetXML_SpravkaF2(  
    pKodNA in number, 
    pGOD in number, 
    pNomSpravki in varchar2, 
    pNomKorr in number, 
    pCurrentPersData in number default 0  ,
    pFormDate date default sysdate
  ) return clob;
  
  -- test:   Select FXNDFL_OUT.GetXML_SpravkaF2(  1, 2015, '000186', 0  ) from dual;
  /**
   * Справка 2НДФЛ в XML формате по заданному контрагенту
   *
   *  pFormDate    - дата для определения подписанта
   *  pFormVersion - версия формы (def.=5.04), если NULL - будет определяться автоматически
   *
   */
  function GetXML_SpravkaF2CA(  
    pContragentID in number, 
    pYear in number, 
    pCurrentPersData in number default 0,
    pPRIZNAK in number default 1,
    pFormDate date default sysdate
  ) return clob;
  
  -- получить за 2015 год список пенсионеров без ИНН
  procedure Get_Spisok_PenBezINN2015(  pSpPenBazINN out sys_refcursor , pErrInfo out varchar2 );


  -- Получить xml-файл 6 НДФЛ для передачи данных в ГНИ 
  -- параметры:
  --    pFileId  идентификатор в реестре файлов F_NDFL_ARH_XML_FILES
  function GetXML_XChFileF6(
    pFileId in number,
    pFormDate date default sysdate
  ) return clob;
  

END FXNDFL_OUT;
/
