CREATE OR REPLACE PACKAGE FXNDFL_UTIL AS
/******************************************************************************
   NAME:       FXNDFL_UTIL
   PURPOSE:  
             Подготовка и выдача справок о доходах и налогах физических лиц
             по формам
                    2-НДФЛ
                    6-НДФЛ
                    
             Загрузка данных из источников
             Идентификация  налогоплательщиков
             Формирование данных справки по налогоплательщику
             Выдача данных в требуемых форматах

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        09/02/2016      Anikin       1. Created this package.
******************************************************************************/

-- инициализация счетчика справок 
function Init_SchetchikSpravok( pKodNA in number, pGod in number, pTipDox in number, pNomKorr in number ) return number;
/* Параметры:
    pKodNA - код налогового агента
    pGod - год
    pTipDox - тип дохода по классификации налогового агента
    pNomKorr - номер корректировки для ранее загруженных справок
  
   Результат:
   код ошибки. 0 - ошибок нет.
   
   Выполняется после загрузки данных по одному налоговому агенту в структуру _LOAD_.
   Запускается столько раз, сколько  pGod, pTipDox, pNomKorr должно войти в новые справки.
   После инициализации счетчиков можно запускать процедуры 
   идентификации налогоплательщиков, расстановки номеров справок и объединения данных в справки.    
*/    
----------------------- ====  x-НДФЛ ==== -----------------------
-----------------------   общие процедуры  -----------------------

-- заполнить список налогоплательзиков за год по движению средств на ЛСПВ
procedure Spisok_NalPlat_poLSPV( pErrInfo out varchar2, pSPRID in number  );

-- установить флажок нулевого дохода
-- комит должен быть внешний!
procedure Spisok_NalPlat_DohodNol( pSPRID in number );

-- проверить созданный список налогоплательщиков, получить перечень ошибок 
procedure Oshibki_vSpisNalPlat( pReportCursor out sys_refcursor, pErrInfo out varchar2, pKodNA in number, pGod in number, pPeriod in number );

-- определить число Налогоплательщиков, одновременно являющихся работниками
-- заполняет 
procedure Raschet_Chisla_SovpRabNp( pErrInfo out varchar2, pSPRID in number );

-- определить число Налогоплательщиков, получивших ненулевой доход с начала года
procedure Raschet_Chisla_NalPlat( pErrInfo out varchar2, pSPRID in number );


-- проверка переноса справки в архив
-- если результат != 0, то изменения справки запрещены
function TestArhivBlok( pSPRID in number ) return number;

----------------------- ====  2-НДФЛ ==== -----------------------

-- загрузка данных в промежуточные буферы
-- для дальнейшего формирования справок 2-НДФЛ

-- утановка значениий глоабльных переменных
-- для уменьшения длины списка параметров
--
-- 03.11.2017 RFC_3779 - добавил параметры для формирования корр.справок
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

-- загрузить список налогоплательщиков
-- (шапки справок 2-НДФЛ)
    -- доход пенсия (TIP_DOX=1)
       -- сторно  нет
       procedure Load_Pensionery_bez_Storno;
       -- сторно  есть
       procedure Load_Pensionery_so_Storno;
    -- доход пособия (TIP_DOX=2)
       -- правки  нет
       procedure Load_Posobiya_bez_Pravok; 
       -- правки  есть
       procedure Load_Posobiya_s_Ipravlen; 
    -- доход выкупные (TIP_DOX=3)
       -- правки  нет
       procedure Load_Vykupnye_bez_Pravok;
       -- правки  есть
       procedure Load_Vykupnye_s_Ipravlen; 
-- конец загрузки списка НП

-- загрузка доходов по месяцам
    -- доход пенсия (TIP_DOX=1)
       -- сторно нет
       procedure Load_MesDoh_Pensia_bezIspr;
       -- сторно есть
       procedure Load_MesDoh_Pensia_sIspravl;
    -- доход пособия (TIP_DOX=2)
       -- исправления  нет
       procedure Load_MesDoh_Posob_bezIspr;
       -- исправления  есть
       procedure Load_MesDoh_Posob_sIspravl;
    -- доход выкупные (TIP_DOX=3)
       -- исправления  нет
       procedure Load_MesDoh_Vykup_bezIspr;
       -- исправления  есть
       procedure Load_MesDoh_Vykup_sIspravl;
-- конец загрузки доходов по месяцам       
 
-- загрузка вычетов для пенсионеров и забравших выкупные суммы
-- вычеты по НК только для резидентов
-- вычеты получателям пособий не предоставляются
   procedure Load_Vychety;
   
-- загрузка итогов справок 2-НДФЛ
-- годовые суммы доходов, вычетов, удержанных налогов отдельно по ставкам
    -- доход пенсия   (TIP_DOX=1)
       procedure Load_Itogi_Pensia;
    -- доход пособия
       -- исправления  нет
       procedure Load_Itogi_Posob_bezIspr;       
    -- доход выкупные (TIP+DOX=3)
       -- исправления  нет
       procedure Load_Itogi_Vykup_bezIspr;
       -- исправления  есть
       procedure Load_Itogi_Vykup_sIspravl;       

-- пересчет итогов для конкретной ссылки после исправления
procedure Load_Itogi_Obnovit( pKODNA in number, pGOD in number, pSSYLKA in number, pTIPDOX in number, pNOMKOR in number );    


-- заполнить таблицу-нумератор справок по таблице LOAD_SPRAVKI для заданного года
-- предварительно использовать InitGlobals
procedure Load_Numerator; 

-- проставить SSYLKA и FK_CONTRAGENT в счетчик справок для KOD_NA=1
function UstIdent_GAZFOND( pGod in number ) return number;

-- очистить SSYLKA и FK_CONTRAGENT в счетчике справок для KOD_NA=1
function SbrosIdent_GAZFOND( pGod in number ) return number;

-- проставить ИНН, если он не заполнен, но есть другая справка с ИНН для того же контрагента
function ZapolnINN_izDrSpravki( pGod in number )  return number;

-- проставить ГРАЖДАНСТВО по паспорту РФ
function ZapolnGRAZHD_poUdLichn( pGod in number ) return number;

-- получить список Контрагентов, для которых в разных справках указаны разные данные
procedure RaznDan_Kontragenta( pReportCursor out sys_refcursor, pErrInfo out varchar2, pGod in number );

-- получить список Котрагентов, для которых указаны недопустимо одинаковые данные, например: ИНН, паспорт
procedure SovpDan_Kontragentov( pReportCursor out sys_refcursor, pErrInfo out varchar2, pGod in number );

-- получить список справок с ошибочными данными 
procedure OshibDan_vSpravke( pReportCursor out sys_refcursor, pErrInfo out varchar2, pGod in number );

-- пренумеровать справки для Налогового Агента в заданном году
procedure Numerovat_Spravki( pKodNA in number, pGod in number );
procedure Numerovat_Spravki_OTKAT( pKodNA in number, pGod in number );

-- для коррекций в полуручном режиме
procedure Numerovat_KorSpravki;

-- ТОЛЬКО ПОЛСЕ НУМЕРАЦИИ ЗАГРУЖАЕМ АДРЕСА
-- номера справок нужно предварительно скопировать в таблицу разбора адресов
-- (нужна предварительная установка параметров InitGlobals)
procedure Load_Adresa_INO;
procedure Load_Adresa_vRF;

-- копировать справки с номерами в архив
-- НЕ НУЖНО  данные загловков справок копируются при нумерации
-- function KopirSpr_vArhiv( pKodNA in number, pGod in number ) return number;

-- копировать в архив итоги по справкам 
procedure KopirSprItog_vArhiv( pKodNA in number, pGod in number );

-- копировать в архив расшифровки дохода по месяцам в справках 
procedure KopirSprMes_vArhiv( pKodNA in number, pGod in number );

-- копировать в архив вычеты из справок 
procedure KopirSprVych_vArhiv( pKodNA in number, pGod in number );

-- копировать в архив уведомления о вычетах из справок 
function KopirSprUved_vArhiv( pKodNA in number, pGod in number ) return number;

-- копировать в архив адреса НП из справок 
procedure KopirSprAdres_vArhiv( pKodNA in number, pGod in number );

-- копировать в архив адреса НП из буфера разбора GNI_ADR_SOOTV
-- (в буфере FL_ULIS должен быть равен году)
procedure Kopir_Adresa_vRF_izSOOTV( pPachka in number, pGod in number );

-- создать запись в Реестре XML-файлов
function Zareg_XML( pKodNA in number, pGod in number, pForma in number, pCommit in number default 1 ) return number;
 

-- распределить данные справок по XML-файлам
procedure RaspredSpravki_poXML( pKodNA in number, pGod in number, pForma in number );


-- Добавить копию существующей справки 2НДФЛ по году и ссылке ФЛ
-- для создания корректирующего варианта справки
procedure Kopir_SprF2_dlya_KORR( pNOMSPRAV in varchar2, pGod in number);


-- ---------------------------------- ====  6-НДФЛ ==== ----------------------------------
-- раздел 6-НДФЛ

-- Выбрать идентификатор справки, если нет, то создать новую
procedure Naiti_Spravku_f6 ( pErrInfo out varchar2, pSprId out number, pKodNA in number, pGod in number, pKodPeriod in number, pNomKorr in number, pPoMestu in number default 213 );

-- Создание регистрационной записи справки по форме 6-НДФЛ
function Sozdat_Spravku_f6 ( pKodNA in number, pGod in number, pKodPeriod in number, pNomKorr in number, pPoMestu in number default 213 ) return varchar2;

-- Архивировать справку по форме 6-НДФЛ
procedure Kopir_SprF6_vArhiv ( pErrInfo out varchar2, pSPRID in number );

-- после регистрации справки, можно обращаться к сервисам

-- буфер НП-Доход для определения вычетов и исчисленного налога
procedure Zapoln_Buf_NalogIschisl( pSPRID in number );

-- строка 020 справки 
-- "Сумма начисленного дохода"
-- нарастающим итогом с начала года 
-- по заданной налоговой ставке
function SumNachislDoh( pSPRID in number, pSTAVKA in number ) return float;

-- строка 030 справки 
-- "Сумма налоговых вычетов"
-- только используемая часть,
-- не превышающая доход
-- нарастающим итогом с начала года 
-- по заданной налоговой ставке
function SumIspolzVych( pSPRID in number, pSTAVKA in number ) return float;

-- строка 040 справки 
-- "Сумма исчисленного налога"
-- нарастающим итогом с начала года 
-- по заданной налоговой ставке
function SumIschislNal( pSPRID in number, pSTAVKA in number ) return float;

-- строка 060 справки 
-- "Количество физических лиц, получивших доход"
-- с начала года
-- число налогоплательщиков
function KolichNP( pSPRID in number ) return number;


-- строка 070 справки 
-- "Сумма удержанного налога"
-- с начала года 
-- по всем налоговым ставкам
function SumUderzhNal( pSPRID in number ) return float;

-- строка 080 справки 
-- "Сумма НЕ удержанного налога"
-- с начала года 
-- по всем налоговым ставкам
function SumNeUderzhNal( pSPRID in number ) return float;


   -- вспомогательные вычисления
   
   -- Сумма налога, возвращенного налоговым агентом
   -- исправление ошибок предыдущих периодов (шифр 83)
   function SumVozvraNal83( pSPRID in number ) return float;
   
   -- Сумма налога, возвращенного налоговым агентом
   -- цепочка исправленных документов доход/налог уходит в предыдущий период
   -- соответствует исправлению налога с выкупной суммы
   -- по предоставлению уведомления
      
   function SumVozvraNalDoc( pSPRID in number ) return float;   
   

-- строка 090 справки 
-- "Сумма возвращенного налога"
-- с начала года 
-- по всем налоговым ставкам
function SumVozvraNal( pSPRID in number ) return float;


-- Раздел 2 справки 6НДФЛ
-- каждая запись курсора должна содержать следующие данные:
-- 100 Дата фактического получения дохода
-- 110 Дата удержания налога
-- 120 Дата перечисления налога
-- 130 Сумма фактически полученного дохода
-- 140 Сумма удержанного налога 
procedure ZaPeriodPoDatam( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number, pKorKV in number default 0 );

-- Заполнение загрузочных таблиц для 6НДФЛ по движению средств на ЛСПВ
procedure ZagruzTabl_poLSPV( pErrInfo out varchar2, pSPRID in number );

-- Раздел 2 справки 6НДФЛ
-- попытка группировки по документам с деньгами
procedure ZaPeriodPoDokum( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number );

-- курсор для вывода сумм налога по пенсионным схемам для сверки с квартальным отчетом
procedure Sverka_KvOtchet( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number );

-- несовпадения исчисленных и удержанных сумм налогов
procedure Sverka_NesovpadNal( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number );
-- версия 2 (отладка)
procedure Sverka_NesovpadNal_v2( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number );

-- загрузить суммы по выплатным документам для 6НДФЛ
procedure f6_ZagrSvedDoc( pSPRID in number );

-- загрузить данные от бухгалтерии
procedure Parse_xml_izBuh(
  x_err_info out varchar2,
  p_spr_id   in  number,
  p_xml_info in  varchar2,
  p_kod_podr in  number default 1
);

-- конец 6-НДФЛ 
-- ---------------------------------- ====  6-НДФЛ ==== ----------------------------------


--
-- RFC_3779: выделил копирование справки и адреса в отдельную функцию
--
  function copy_ref_2ndfl(
    p_ref_row in out nocopy f2ndfl_arh_spravki%rowtype
  ) return f2ndfl_arh_spravki.id%type;

--
-- RFC_3779: рассчитывает и обновляет сумму использованных вычетов в таблице F2NDFL_ARH_VYCH
--
  procedure calc_benefit_usage(
    p_spr_id f2ndfl_arh_spravki.id%type
  );
  
  
  /**
   * Процедура copy_load_address создает копию всех адресов F2NDFL_LOAD_ADR, привязанных к заданной справке 
   */
  procedure copy_load_address(
    p_src_ref_id f2ndfl_load_spravki.r_sprid%type,
    p_nom_corr   f2ndfl_load_spravki.nom_korr%type
  );
  
  /**
   * Процедура copy_load_employees создает копию справок по доходам сотрудников фонда
   *   Вызывается один раз, для сотрудника фонда!
   *  Копии создаются в таблицах f2ndfl_load_spravki, f2ndfl_load_mes, f2ndfl_load_itogi, f2ndfl_load_vych
   */
  procedure copy_load_employees(
    p_src_ref_id   f2ndfl_load_spravki.r_sprid%type,
    p_corr_ref_id  f2ndfl_load_spravki.r_sprid%type,
    p_nom_corr     f2ndfl_load_spravki.nom_korr%type
  );
  
END FXNDFL_UTIL;
/
