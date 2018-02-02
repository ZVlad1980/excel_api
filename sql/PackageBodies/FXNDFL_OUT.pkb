CREATE OR REPLACE PACKAGE BODY FXNDFL_OUT AS

  gCurrentPersData number;  -- режим вывода персональных данных
  --  0  - копия справки из архива переданного в ГНИ
  --  1  - текущие персональные данные в GAZFOND
  gContragentID number;       -- идентификатор контрагента
  
  cXML clob;  -- сформированный файл
  -- тест Select FXNDFL_OUT.GetXML_XChFileF2(2) FXML from Dual;
  
  CrLf varchar2(50) := chr(13)||chr(10);
  rFXML F_NDFL_ARH_XML_FILES%rowtype;
  -- Структура с параметрами файла
  -- ID, FILENAME, KOD_FORMY, VERS_FORM, OKTMO, INN_YUL, KPP, NAIMEN_ORG, TLF, KOD_NO, GOD, KVARTAL, PRIZNAK_F
  
  rNALAG F2NDFL_SPR_NAL_AGENT%rowtype;
  -- Структура с параметрами Налогового Агента
  -- KOD_NA, OKTMO, PHONE, INN, KPP, NAZV, IFNS
  
  rSprData f2NDFL_ARH_SPRAVKI%rowtype; 
  -- Структура с параметрами справки
  -- ID, R_XMLID, KOD_NA, DATA_DOK, NOM_SPR, GOD, NOM_KORR, KVARTAL, PRIZNAK_S, INN_FL, INN_INO, 
  -- STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC  
  rSprData6 f6NDFL_ARH_SPRAVKI%rowtype;
  
  rITOG f2NDFL_ARH_ITOGI%rowtype;
  -- Структура с итоговыми суммами по справке для каждой ставки
  -- R_SPRID, KOD_STAVKI, SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS,SUM_OBL_NU, SUM_NAL_PER, DOLG_NA, VZYSK_IFNS
  
  rPODPISANT F2NDFL_SPR_PODPISANT%rowtype;
  -- Стурктура данных для тэга ПОДПИСАНТ
  -- KOD_PODP, GOD, PODPISANT_TYPE, FA, IM, OT, DOVER
  
  tag_SVED_NALAG varchar2(1000);
  tag_PODPISANT  varchar2(1000);
  
  ERR_Pref varchar2(255);
  ERR_SprID varchar2(100);
  
  procedure Ident_Right as
  begin
      CrLf:=CrLf||'   ';
  end Ident_Right;
  
  procedure Ident_Left as
  begin
      CrLf:=regexp_replace(CrLf,'\s{3}$','');
      if length(CrLf)<2 then  CrLf:=chr(13)||chr(10); end if;
  end Ident_Left;

  procedure Read_XML_TITLE(pFileId in number)  is
  begin
       Select * into rFXML from F_NDFL_ARH_XML_FILES where ID=pFileId;
  end Read_XML_TITLE;
  
  procedure Read_NA_PODPIS(pGod in number)  is  
  begin 
       ERR_Pref := 'Формирование документа / Подписант ';
       Select * into rPODPISANT from F2NDFL_SPR_PODPISANT where PKG_DFLT=1 and GOD=pGOD;  
       
       tag_PODPISANT:=  
         '<Подписант ПрПодп="'||rPODPISANT.PODPISANT_TYPE||'">'||CrLf
       ||'   <ФИО Фамилия="'||rPODPISANT.FA||'" Имя="'||rPODPISANT.IM||'" Отчество="'||rPODPISANT.OT||'" />'||CrLf
       ||'   <СвПред НаимДок="'||replace(rPODPISANT.DOVER,'"','&quot;')||'"/>'||CrLf
       ||'</Подписант>';
       
  end;
  
  procedure Read_NA_DATA2(pFileId in number)  is
  begin
       Select * into rNALAG from F2NDFL_SPR_NAL_AGENT 
              where (KOD_NA,GOD) = ( Select KOD_NA, GOD from f2NDFL_ARH_SPRAVKI where rownum=1 and R_XMLID=pFileId );
       tag_SVED_NALAG :=
               '<СвНА ОКТМО="'||rNALAG.OKTMO||'" Тлф="'||rNALAG.PHONE||'">'||CrLf
             ||'         <СвНАЮЛ НаимОрг="'||replace(rNALAG.NAZV,'"','&quot;')||'" ИННЮЛ="'||rNALAG.INN||'" КПП="'||rNALAG.KPP||'"/>'||CrLf
             ||'      </СвНА>';
             
       Read_NA_PODPIS( rNALAG.GOD );
             
  end Read_NA_DATA2;
  
  procedure Read_NA_DATA6(pFileId in number)  is
  begin
       Select * into rNALAG from F2NDFL_SPR_NAL_AGENT 
              where (KOD_NA,GOD) = ( Select KOD_NA,GOD from f6NDFL_ARH_SPRAVKI where rownum=1 and R_XMLID=pFileId );
       tag_SVED_NALAG :=
               '<СвНП ОКТМО="'||rNALAG.OKTMO||'" Тлф="'||rNALAG.PHONE||'">'||CrLf
             ||'         <НПЮЛ НаимОрг="'||replace(rNALAG.NAZV,'"','&quot;')||'" ИННЮЛ="'||rNALAG.INN||'" КПП="'||rNALAG.KPP||'"/>'||CrLf
             ||'      </СвНП>';
             
       Read_NA_PODPIS( rNALAG.GOD );
             
  end Read_NA_DATA6;
  
  
  function tag_DocumentHead return varchar2 as
  begin
         return
         '<Документ КНД="1151078" ДатаДок="'||to_char(rSprData.DATA_DOK,'dd.mm.yyyy')||'" НомСпр="'||rSprData.NOM_SPR
                   ||'" ОтчетГод="'||to_char(rSprData.GOD)||'" Признак="'||to_char(rSprData.PRIZNAK_S)
                   ||'" НомКорр="'||trim(to_char(rSprData.NOM_KORR,'00'))||'" КодНО="'||rNALAG.IFNS||'">';
  end tag_DocumentHead;       
  
  function tag_DocumentHead6 return varchar2 as
  begin
         return
         '<Документ КНД="1151099" ДатаДок="'||to_char(rSprData6.DATA_DOK,'dd.mm.yyyy')||'" Период="'||to_char(rSprData6.PERIOD)
                   ||'" ОтчетГод="'||to_char(rSprData6.GOD)||'" КодНО="'||rNALAG.IFNS
                   ||'" НомКорр="'||trim(to_char(rSprData6.NOM_KORR,'00'))||'" ПоМесту="'||to_char(rSprData6.PO_MESTU)||'">';
  end tag_DocumentHead6;     
  
                  -- построить именной элемент адреса
                function MakeAdrEl( pName varchar2, pAbrCode in number ) return varchar2 as
                Abr gazfond.ADDRESS_ABRVS.POST_ABRV%type;
                begin
                
                     if pName is Null then return ''; end if;
                     
                     if pAbrCode is not Null then
                        begin
                            Select POST_ABRV into Abr from gazfond.ADDRESS_ABRVS where ID = pAbrCode;
                        exception
                            when OTHERS then Abr := '';
                        end;    
                        end if;
                     
                     if Abr is Null then return pName; end if;
                     
                     return pName||' '||Abr;
                        
                end; 
  
  function tag_AdresPoluchDoh return varchar2 as
  vADR f2NDFL_ARH_ADR%rowtype;
  vTAG varchar2(500);
  vTMP varchar2(100);
  gfADR gazfond.Addresses%rowtype;  
  begin
         ERR_Pref := 'Формирование документа / Адрес ';
 
         if gCurrentPersData=1 and gContragentID>0 then
               -- текущий адрес регистрации в GAZFOND
               begin
                    Select * into gfADR from gazfond.Addresses where FK_CONTRAGENT=gContragentID and FK_ADDRESS_TYPE=1;
                    exception
                        when NO_DATA_FOUND then gfADR.ID := Null;
                         when OTHERS then Raise;
                    end;
                    
               if gfADR.ID is not Null then
                  
                  if gfADR.FK_COUNTRY_CODE<>643 then 
                           return  '<АдрИНО КодСтр="'||trim(to_char(gfADR.FK_COUNTRY_CODE,'000'))||'" АдрТекст="'||replace(gazfond.ADDRESS_PKG.Get_Address(gContragentID,1),'"','&quot;')||'" />'; 
                     end if;
                     
                            vTAG:='<АдрМЖРФ ';
                            
                            if gfADR.POST_INDEX is not Null then vTAG:=vTAG||'Индекс="'||gfADR.POST_INDEX||'" ';  end if;
                            if gfADR.FK_REGION_CODE is not Null then vTAG:=vTAG||'КодРегион="'||trim(to_char(gfADR.FK_REGION_CODE,'00'))||'" ';  end if;
                            if gfADR.DISTRICT is not Null then vTAG:=vTAG||'Район="'||replace(MakeAdrEl(gfADR.DISTRICT,gfADR.FK_DISTRICT_ABRV),'"','&quot;')||'" ';  end if;
                            if gfADR.CITY is not Null then vTAG:=vTAG||'Город="'||replace(MakeAdrEl(gfADR.CITY,gfADR.FK_CITY_ABRV),'"','&quot;')||'" ';  end if;
                            if gfADR.STATION is not Null then vTAG:=vTAG||'НаселПункт="'||replace(MakeAdrEl(gfADR.STATION,gfADR.FK_STATION_ABRV),'"','&quot;')||'" ';  end if;
                            if gfADR.STREET is not Null then vTAG:=vTAG||'Улица="'||replace(MakeAdrEl(gfADR.STREET,gfADR.FK_STREET_ABRV),'"','&quot;')||'" ';  end if;
                            vTMP := trim(nvl(gfADR.HOUSE1,'')||nvl(gfADR.HOUSEL,'')||case when gfADR.HOUSE2 is not null then '/'||gfADR.HOUSE2 else '' end);
                            if vTMP is not Null then vTAG:=vTAG||'Дом="'||replace(vTMP,'"','&quot;')||'" ';  end if;
                            vTMP := trim(nvl(gfADR.CORPS1,'')||nvl(gfADR.CORPSL,''));
                            if vTMP is not Null then vTAG:=vTAG||'Корпус="'||replace(vTMP,'"','&quot;')||'" ';  end if;
                            vTMP := trim(nvl(gfADR.APT1,'')||nvl(gfADR.APTL,''));
                            if vTMP is not Null then vTAG:=vTAG||'Кварт="'||replace(vTMP,'"','&quot;')||'" ';  end if;
                            
                            return vTAG||'/>'; 
                           
               end if;
                  
         end if;
         
                -- адрес из архива справок 2НДФЛ
                 begin
                        Select * into  vADR from f2NDFL_ARH_ADR where R_SPRID=rSprData.ID;
                        exception
                            when NO_DATA_FOUND then return Null;
                            when OTHERS then Raise;
                        end;       
                 if vADR.KOD_STR='643' then
                 
                    vTAG:='<АдрМЖРФ ';
                    if vADR.PINDEX is not Null then vTAG:=vTAG||'Индекс="'||vADR.PINDEX||'" ';  end if;
                    if vADR.KOD_REG is not Null then vTAG:=vTAG||'КодРегион="'||vADR.KOD_REG||'" ';  end if;
                    if vADR.RAYON is not Null then vTAG:=vTAG||'Район="'||replace(vADR.RAYON,'"','&quot;')||'" ';  end if;
                    if vADR.GOROD is not Null then vTAG:=vTAG||'Город="'||replace(vADR.GOROD,'"','&quot;')||'" ';  end if;
                    if vADR.PUNKT is not Null then vTAG:=vTAG||'НаселПункт="'||replace(vADR.PUNKT,'"','&quot;')||'" ';  end if;
                    if vADR.ULITSA is not Null then vTAG:=vTAG||'Улица="'||replace(vADR.ULITSA,'"','&quot;')||'" ';  end if;
                    if vADR.DOM is not Null then vTAG:=vTAG||'Дом="'||replace(vADR.DOM,'"','&quot;')||'" ';  end if;
                    if vADR.KOR is not Null then vTAG:=vTAG||'Корпус="'||replace(vADR.KOR,'"','&quot;')||'" ';  end if;
                    if vADR.KV is not Null then vTAG:=vTAG||'Кварт="'||replace(vADR.KV,'"','&quot;')||'" ';  end if;
                    
                    return vTAG||'/>'; 
                 
                 end if;
                 
                 return '<АдрИНО КодСтр="'|| vADR.KOD_STR||'" АдрТекст="'||replace(vADR.ADR_INO,'"','&quot;')||'" />';
     
               
  end tag_AdresPoluchDoh; 
  
  function tag_PoluchDoh return varchar2 as
  begin
        ERR_Pref := 'Формирование документа / Налогоплательщик ';  
        if rSprData.KOD_UD_LICHN in (1,22) then rSprData.KOD_UD_LICHN := 91; end if;
        return
          '<ПолучДох'|| case when rSprData.INN_FL is Null then Null else  ' ИННФЛ="'||rSprData.INN_FL||'"' end ||' Статус="'||to_char(rSprData.STATUS_NP)
                                            ||'" ДатаРожд="'||to_char(rSprData.DATA_ROZHD,'dd.mm.yyyy')||'" Гражд="'||rSprData.GRAZHD||'">'||CrLf
        ||'    <ФИО Фамилия="'||rSprData.FAMILIYA||'" Имя="'||rSprData.IMYA|| case when rSprData.OTCHESTVO is Null then Null else '" Отчество="'||rSprData.OTCHESTVO end ||'" />'||CrLf
        ||'    <УдЛичнФЛ КодУдЛичн="'||trim(to_char(rSprData.KOD_UD_LICHN,'00'))||'" СерНомДок="'||rSprData.SER_NOM_DOC||'"/>'||CrLf
        ||'    '||tag_AdresPoluchDoh||CrLf  
        ||'</ПолучДох>';
        
  end tag_PoluchDoh;
  
  procedure Insert_tagMesSvDohSumVych( pMES in number, pKodDOH in number ) as
  begin
        ERR_Pref := 'Цикл по ВЫЧЕТам / Ставка '||to_char(rITOG.KOD_STAVKI )||' / Месяц '||to_char(pMes)||' '||' / КодДоход '||to_char(pKodDOH)||' ';
        for rec in (Select VYCH_KOD_GNI, sum(VYCH_SUM) VYCH_MES_SUM
                          from f2NDFL_ARH_MES 
                          where R_SPRID=rSprData.ID and KOD_STAVKI=rITOG.KOD_STAVKI and MES=pMes and DOH_KOD_GNI=pKodDOH
                          group by VYCH_KOD_GNI
                       )       
        loop
             cXML:=cXML||CrLf||'<СвСумВыч КодВычет="'||trim(to_char(rec.VYCH_KOD_GNI))||'" СумВычет="'||trim(to_char(rec.VYCH_MES_SUM, '99999999999990.00'))||'"/>';
        end loop;                 
  end;
                  
  procedure Insert_tagMesSvDohVych( pMes in number ) as
  -- .F2NDFL_ARH_MES
  --  R_SPRID, KOD_STAVKI, MES, DOH_KOD_GNI, DOH_SUM, VYCH_KOD_GNI, VYCH_SUM
  begin 
        ERR_Pref := 'Цикл по ДОХОДам / Ставка '||to_char(rITOG.KOD_STAVKI )||' / Месяц '||to_char(pMes)||' ';
        for rec in (Select DOH_KOD_GNI, sum(DOH_SUM) DOH_MES_SUM, max(VYCH_KOD_GNI) MAX_VYCH_KOD -- макс код вычета как флажок <>0 "есть вычеты"
                          from f2NDFL_ARH_MES 
                          where R_SPRID=rSprData.ID and KOD_STAVKI=rITOG.KOD_STAVKI and MES=pMes
                          group by DOH_KOD_GNI
                          order by DOH_KOD_GNI
                       )  
        loop
           
          cXML:=cXML||CrLf||'<СвСумДох Месяц="'||trim(to_char(pMes,'00'))
                                                        ||'" КодДоход="'||trim(to_char(rec.DOH_KOD_GNI,'0000'))
                                                        ||'" СумДоход="'||trim(to_char(rec.DOH_MES_SUM, '99999999999990.00'))||'"';
                                                        
           if nvl(rec.MAX_VYCH_KOD,0) = 0 
              then cXML:=cXML||' />';
              else
                     cXML:=cXML||' >';  
                     Ident_Right;
                         Insert_tagMesSvDohSumVych( pMes, rec.DOH_KOD_GNI );  --                            <СвСумВыч КодВычет="508" СумВычет="50000.00"/>                       
                     Ident_Left;       
                     cXML:=cXML||CrLf||'</СвСумДох>';    
              end if;
              
        end loop;
  end;

  procedure Insert_tagMesDohVych as
  begin
       cXML:=cXML||CrLf||'<ДохВыч>';
       Ident_Right;
       
          ERR_Pref := 'Цикл по МЕСЯЦам / Ставка '||to_char(rITOG.KOD_STAVKI )||' ';
          for rec in (Select distinct MES from f2NDFL_ARH_MES where R_SPRID=rSprData.ID and KOD_STAVKI=rITOG.KOD_STAVKI order by MES)  loop
              Insert_tagMesSvDohVych( rec.MES );
              end loop;
       
       Ident_Left;   
       cXML:=cXML||CrLf||'</ДохВыч>';   
  end;
  
  procedure Insert_tagNalVychSSI as
  -- F2NDFL_ARH_VYCH
  --     R_SPRID, KOD_STAVKI, VYCH_KOD_GNI, VYCH_SUM_PREDOST, VYCH_SUM_ISPOLZ
  -- F2NDFL_ARH_UVED
  --     R_SPRID, KOD_STAVKI, SCHET_KRATN, NOMER_UVED, DATA_UVED, IFNS_KOD, UVED_TIP_VYCH
  nVychSSI number;
  begin
   
     ERR_Pref := 'Подсчет числа вычетов по ставке в справке ';
     Select count(*) into nVychSSI from F2NDFL_ARH_VYCH where VYCH_SUM_ISPOLZ>0 and KOD_STAVKI=rITOG.KOD_STAVKI and R_SPRID=rSprData.ID;  
     if nVychSSI=0 then return; end if;

       cXML:=cXML||CrLf||'<НалВычССИ>';
       Ident_Right;  
        
       ERR_Pref := 'Выборка вычетов по ставке в справке ';
       for rec in ( Select * from F2NDFL_ARH_VYCH where VYCH_SUM_ISPOLZ>0 and KOD_STAVKI=rITOG.KOD_STAVKI and R_SPRID=rSprData.ID order by VYCH_KOD_GNI )
       loop
           cXML:=cXML||CrLf||'<ПредВычССИ КодВычет="'||to_char(rec.VYCH_KOD_GNI)||'" СумВычет="'||trim(to_char( nvl(rec.VYCH_SUM_ISPOLZ,0),'99999999999990.00'))||'"/>';
          end loop;
          
       ERR_Pref := 'Выборка уведомлений о социальных вычетах ';   
       for rec in ( Select * from F2NDFL_ARH_UVED where KOD_STAVKI=rITOG.KOD_STAVKI and R_SPRID=rSprData.ID and UVED_TIP_VYCH=1 order by UVED_TIP_VYCH, SCHET_KRATN, DATA_UVED, NOMER_UVED )
       loop
           cXML:=cXML||CrLf||'<УведСоцВыч НомерУвед="'||trim(rec.NOMER_UVED)||'" ДатаУвед="'||to_char(rec.DATA_UVED,'dd.mm.yyyy')||'" ИФНСУвед="'||rec.IFNS_KOD||'"/>';
          end loop;
             
       ERR_Pref := 'Выборка уведомлений об имущественных вычетах ';   
       for rec in ( Select * from F2NDFL_ARH_UVED where KOD_STAVKI=rITOG.KOD_STAVKI and R_SPRID=rSprData.ID and UVED_TIP_VYCH=2 order by UVED_TIP_VYCH, SCHET_KRATN, DATA_UVED, NOMER_UVED )
       loop
           cXML:=cXML||CrLf||'<УведИмущВыч НомерУвед="'||trim(rec.NOMER_UVED)||'" ДатаУвед="'||to_char(rec.DATA_UVED,'dd.mm.yyyy')||'" ИФНСУвед="'||rec.IFNS_KOD||'"/>';
          end loop;   
          
       Ident_Left;   
       cXML:=cXML||CrLf||'</НалВычССИ>';   
  end;
  
  function tag_ItogiPoStavke return varchar2 as  
  begin
       return
       '<СумИтНалПер СумДохОбщ="'      ||trim(to_char( nvl(rITOG.SGD_SUM,0),            '99999999999990.00' ))
                            ||'" НалБаза="'            ||trim(to_char( nvl(rITOG.SUM_OBL,0),            '99999999999990.00' ))
                            ||'" НалИсчисл="'        ||trim(to_char( nvl(rITOG.SUM_OBL_NI,0),       '99999999999990' ))
                            ||'" АвансПлатФикс="' ||trim(to_char( nvl(rITOG.SUM_FIZ_AVANS,0), '99999999999990' ))
                            ||'" НалУдерж="'          ||trim(to_char( nvl(rITOG.SUM_OBL_NU,0),      '99999999999990' ))
                            ||'" НалПеречисл="'     ||trim(to_char( nvl(rITOG.SUM_NAL_PER,0),    '99999999999990' ))
                            ||'" НалУдержЛиш="'   ||trim(to_char( nvl(rITOG.DOLG_NA,0),             '99999999999990' ))
                            ||'" НалНеУдерж="'      ||trim(to_char( nvl(rITOG.VZYSK_IFNS,0),        '99999999999990' )) ||'"/>';
  end tag_ItogiPoStavke;
  
  procedure Insert_tagSvedStavka( pStavka in number ) as
  begin

     ERR_Pref := 'Выборка ИТОГОВ / Ставка '||to_char(pStavka )||' ';
     begin
           Select * into rITOG from f2NDFL_ARH_ITOGI where R_SPRID=rSprData.ID and KOD_STAVKI=pStavka;
           exception
               when NO_DATA_FOUND then return;
               when OTHERS then Raise;
           end;    
     
     cXML:=cXML||'<СведДох Ставка="'||to_char(pStavka)||'">';
     Ident_Right;
     
        Insert_tagMesDohVych;
        
        Insert_tagNalVychSSI;
        
        cXML:=cXML||CrLf||tag_ItogiPoStavke;
     
     Ident_Left;   
     cXML:=cXML||CrLf||'</СведДох>';     
     
  end Insert_tagSvedStavka;

  procedure Insert_tagDocument( pSpavId in number ) as
  nICID number;
  begin
      
      ERR_Pref := 'Выборка данных справки ';
      Select * into rSprData from f2NDFL_ARH_SPRAVKI where ID=pSpavId;
      if gCurrentPersData=1 and gContragentID>0 then
              Select INN into rSprData.INN_FL 
                  from gazfond.Contragents where ID=gContragentID; 
              Select Lastname, Firstname, Secondname, Birthdate, FK_IDCARD into rSprData.FAMILIYA,rSprData.IMYA, rSprData.OTCHESTVO,rSprData.DATA_ROZHD, nICID 
                   from gazfond.People where fk_Contragent=gContragentID;
              Select  FK_IDCARD_TYPE, SERIES||' '||NBR, trim(to_char(CITIZENSHIP,'000')) into rSprData.KOD_UD_LICHN, rSprData.SER_NOM_DOC, rSprData.GRAZHD
                   from gazfond.IDCards where ID=nICID;    
         end if;
      ERR_Pref := 'Формирование документа';
      Ident_Right;
      cXML:=cXML||CrLf||tag_DocumentHead;
              Ident_Right;
              cXML:=cXML||CrLf
                 ||tag_PODPISANT||CrLf
                 ||tag_SVED_NALAG||CrLf
                 ||tag_PoluchDoh||CrLf;
                
                 ERR_Pref := 'Цикл по ставкам в справке';       
                 for rec in (Select KOD_STAVKI from f2NDFL_ARH_ITOGI where R_SPRID=pSpavId order by KOD_STAVKI) loop
                     Insert_tagSvedStavka( rec.KOD_STAVKI );
                     end loop;
                 
              Ident_Left;   
      cXML:=cXML||CrLf||'</Документ>';
      Ident_Left;    
      cXML:=cXML||CrLf;  
            
  end Insert_tagDocument;

  -- Получить xml-файл 2 НДФЛ для передачи данных в ГНИ 
  -- параметры:
  --    pFileId  идентификатор в реестре файлов F_NDFL_ARH_XML_FILES
  function GetXML_XChFileF2(pFileId in number) return clob is
  begin
  
         gCurrentPersData := 0;
  
         cXML := Null;
         CrLf := chr(13)||chr(10);
         ERR_SprID :=' файл ';
         -- загрузим глобальные переменные
         -- данные для заголовка файла
         ERR_Pref := 'Чтение данных заголовка файла';
         Read_XML_TITLE(pFileId);
         if rFXML.KOD_FORMY<>2 then return 'ERR Запись в реестре файлов не содержит ссылку на тип формы 2НДФЛ.'; end if;
         -- данные налогового агента для справок
         ERR_Pref := 'Чтение данных Налогового Агента';
         Read_NA_DATA2(pFileId);
         
         cXML := '<?xml version="1.0" encoding="windows-1251"?>'||CrLf
                    ||'<Файл xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ИдФайл="' ||rFXML.FILENAME||'"  ВерсПрог="2" ВерсФорм="'||rFXML.VERS_FORM||'">'||CrLf
                    ||'   <СвРекв  ОКТМО="'||rFXML.OKTMO||'" ОтчетГод="'||to_char(rFXML.GOD)||'" ПризнакФ="'||rFXML.PRIZNAK_F||'">'||CrLf  
                    ||'   <СвЮЛ ИННЮЛ="'||rFXML.INN_YUL||'" КПП="'||rFXML.KPP||'" />'||CrLf
                    ||'   </СвРекв>'||CrLf;

         ERR_Pref := 'Выборка справок для файла.';  
         for rec in (Select ID from f2NDFL_ARH_SPRAVKI where R_XMLID=pFileId order by NOM_SPR) loop
              ERR_SprID := ' справка '||trim(to_char(rec.ID,'0000000000'))||' ';
              Insert_tagDocument( rec.ID );
              end loop;     

         cXML := cXML||'</Файл>'||CrLf;
         return cXML;

  exception
          when OTHERS then 
                return 'ERR '||ERR_SprID||ERR_Pref||' '||SQLERRM;
  end GetXML_XChFileF2;  
  
  -- Получить xml-файл для печати справки 
  -- параметры:
  --    код Налогового Агента по справочнику 1 - ГАЗФОНД
  --    налоговый год
  --    номер справки - строка с ведущими нулями
  --    номер корректировки - для первой справки 0
  --    0 - выводить архив справок в ГНИ /  1 - текущие персональные данные  
  function GetXML_SpravkaF2(  pKodNA in number, pGOD in number, pNomSpravki in varchar2, pNomKorr in number, pCurrentPersData in number default 0  ) return clob is
  nSprId  number;
  nFileId  number;
  begin
         
         gCurrentPersData := pCurrentPersData; 
  
         CrLf := chr(13)||chr(10);  
         ERR_Pref := 'Чтение идентификатора Справки';
         Select ID, R_XMLID into nSprId, nFileId from f2NDFL_ARH_SPRAVKI where KOD_NA=pKodNA and GOD=pGOD and NOM_SPR=pNomSpravki and NOM_KORR=pNomKorr;
                  
         -- данные налогового агента для справок
         ERR_Pref := 'Чтение данных Налогового Агента';
         Read_NA_DATA2(nFileId);
         
         cXML := '<?xml version="1.0" encoding="windows-1251"?>'
            ||CrLf||'<?xml-stylesheet type="text/xsl" href="2NDFL_2015.xsl"?>'
            ||CrLf||'<Файл ВерсФорм="5.04">';
            
            Insert_tagDocument( nSprId );
            
         cXML := cXML||'</Файл>'||CrLf;
         return cXML;    
  
  exception
          when OTHERS then 
                return 'ERR '||ERR_SprID||ERR_Pref||' '||SQLERRM;
  end GetXML_SpravkaF2;    


  -- окно для выкачивания файлов из БД
  procedure GetXML_All_XChFileF2( pXmlCursor out sys_refcursor, pErrInfo out varchar2, pFirstXmlID in number, pLastXmlID in number ) as
  begin
  
    open pXmlCursor for
        Select xf.*, GetXML_XChFileF2( xf.ID ) CLOBXML 
            from f_NDFL_ARH_XML_FILES xf 
            where xf.ID>=pFirstXmlID and xf.ID<=pLastXmlID;
        
    pErrInfo := Null;
    exception
          when OTHERS then  pErrInfo:=SQLERRM;
          
  end GetXML_All_XChFileF2;
  
  function GetXML_SpravkaF2CA(  pContragentID in number, pYear in number, pCurrentPersData in number default 0 ) return clob as
  vNOMKOR F2NDFL_ARH_SPRAVKI.NOM_KORR%type;
  rSPR    F2NDFL_ARH_SPRAVKI%rowtype;
  vRES    clob;
  fBAL    float;  
  begin
  
     gContragentID:=0;
  
     for ns in ( Select * from f2NDFL_ARH_NOMSPR where KOD_NA=1 and GOD=pYear and fk_CONTRAGENT=pContragentID and flag_OTMENA=0 and ROWNUM=1 )    -- test 3397318,  3026175
     loop
        
         begin 
             -- нашли последнюю (максимальную) неотменяющую (<99) корректировку
             Select max(NOM_KORR) into vNOMKOR from f2NDFL_ARH_SPRAVKI where KOD_NA=1 and NOM_KORR<99 and GOD=pYear and NOM_SPR=ns.NOM_SPR;
          exception
             when OTHERS then vNOMKOR:=Null;
          end;    
          
         begin 
             -- нашли саму справку
             Select * into rSPR from f2NDFL_ARH_SPRAVKI where KOD_NA=1 and GOD=pYear and NOM_SPR=ns.NOM_SPR and NOM_KORR=vNOMKOR;
             
             if pYear=2016 then
                 Select sum(VZYSK_IFNS) into fBAL from f2NDFL_ARH_ITOGI where R_SPRID = rSPR.ID;
                 if fBAL>=0.01 then
                    vRES:= 'ERR В справке обнаружена недоплата НДФЛ. Для вывода справки обратитесь к программистам.'; 
                    return vRES;
                    end if;
                 if rSPR.NOM_SPR in ( '119638','086778','021291','113280','140582','114332','009839' ) then
                    vRES:= 'ERR Есть вопрос по статусу налогового резиденства. Для вывода справки обратитесь к программистам.'; 
                    return vRES;                
                    end if;
                end if;    
             
          exception
             when OTHERS then rSPR.ID:=Null;
          end; 

        end loop;
        
        
     if  rSPR.ID is Null 
         then vRES:= 'ERR Не найдено актуальных справок для заданых контрагента и года'; 
         else gContragentID:=pContragentID;
                vRES:= GetXML_SpravkaF2(  1, pYear, rSPR.NOM_SPR, rSPR.NOM_KORR, pCurrentPersData  ); 
         end if;       
            
     return vRES;
  
     end;  
     
  -- получить за 2015 год список пенсионеров без ИНН
  procedure Get_Spisok_PenBezINN2015(  pSpPenBazINN out sys_refcursor, pErrInfo out varchar2 ) as
  begin
  -- перед пуском нужно установить в запросе необходимые фильтры 
     Open pSpPenBazINN for
     Select     lsv.NOM_OTDEL, 
                   sul.KR_NAZV, sfl.NOM_VKL,
                   sfl.PEN_SXEM,  lsv.DOGOVOR, lsv.DATA_DOG, 
                   sfl.SSYLKA, sfl.FAMILIYA, sfl.IMYA, sfl.OTCHESTVO, sfl.DATA_ROGD ,
                   substr(sfl.TAB_NOM,1,4) KOD_PODRAZD, sfl.TAB_NOM   -- для  Вкладчика   
        from SP_FIZ_LITS sfl   -- окончательно число  110 031
            inner join SP_UR_LITS sul on sul.SSYLKA=sfl.NOM_VKL   -- после связки число не изменилось  =112 179
            inner join (Select distinct NOM_VKL, SSYLKA_FL, GOD_DOG, NOM_DOG from SP_IPS where TIP_LITS=3 -- нормальные (не хватает 7 записей)
                            Union
                            Select distinct NOM_VKL, SSYLKA_FL, GOD_DOG, NOM_DOG from SP_IPS -- добавили траст (7 исключений)
                            where TIP_LITS=1 and  ( NOM_VKL,SSYLKA_FL) 
                               in ( Select      2,     1372  from dual union
                                     Select    15,     9436  from dual union
                                     Select      6,     5515  from dual union
                                     Select    16,     7949  from dual union
                                     Select  100,    10762  from dual union
                                     Select  144,    29372  from dual union
                                     Select    37,    35745  from dual  ) 
                             ) ips on ips.NOM_VKL=sfl.NOM_VKL and ips.SSYLKA_FL=sfl.SSYLKA 
            left join SP_LSV lsv on lsv.NOM_VKL=sfl.NOM_VKL and  lsv.GOD_DOG=ips.GOD_DOG and lsv.NOM_DOG=ips.NOM_DOG 
                                           -- после связки число не изменилось =112 139                 
            left join SP_RITUAL_POS srp on srp.SSYLKA=sfl.SSYLKA   -- убрали умерших из запроса
            left join SP_INN_FIZ_LITS inn on inn.SSYLKA=sfl.SSYLKA
            where sfl.SSYLKA 
                       in (  
                            Select distinct LS.SSYLKA 
                                from f2NDFL_LOAD_SPRAVKI LS
                                   where LS.R_SPRID -- всего справок без ИНН отправлено в ГНИ  =113 575
                                             in (Select ID from f2NDFL_ARH_SPRAVKI where  KOD_NA=1 and GOD=2015  and INN_FL is Null)                                 
                                   and LS.TIP_DOX=1   -- оставили только пенсионеров  =112 179, 
                                                                    -- остальные: ритуалки, выкупные, - в следующем году не повторятся
                           )
                  and  srp.DATA_SMERTI is Null        -- оставили живых 110 031
                  and sfl.NOM_VKL=15
                  -- and lsv.NOM_OTDEL=16
                  and inn.INN is Null
          order by lsv.NOM_OTDEL, sul.KR_NAZV, sfl.PEN_SXEM, lsv.DOGOVOR, substr(sfl.TAB_NOM,1,4), sfl.FAMILIYA, sfl.IMYA, sfl.OTCHESTVO, sfl.DATA_ROGD            
        ;
  
  
     pErrInfo := Null;
  
      exception
       when OTHERS then 
          pErrInfo := SQLERRM;
          pSpPenBazINN := Null;
    
  end Get_Spisok_PenBezINN2015;   
  
  procedure InsertTag6_ObobschPokaz as
  begin
        cXML:=cXML||CrLf||'<ОбобщПоказ КолФЛДоход="'   ||trim(to_char( nvl(rSprData6.KOL_FL_DOH,0)))
                                                        ||'" УдержНалИт="'    ||trim(to_char( nvl(rSprData6.UDERZH_NAL_IT,0),       '99999999999990' ))
                                                        ||'" НеУдержНалИт="'||trim(to_char( nvl(rSprData6.NE_UDERZH_NAL_IT,0),       '99999999999990' ))
                                                        ||'" ВозврНалИт="'     ||trim(to_char( nvl(rSprData6.VOZVRAT_NAL_IT,0),       '99999999999990' ))
                                                        ||'">';
        Ident_Right;   
        
        ERR_Pref := 'Цикл по ставкам. Открытие курсора.';
        for rec in (Select * from f6NDFL_ARH_ITOGI where R_SPRID =  rSprData6.ID )
        loop
            ERR_Pref := 'Шаг цикла по Ставке '||to_char(rITOG.KOD_STAVKI );
            cXML:=cXML||CrLf||'<СумСтавка Ставка="'||to_char(rec.KOD_STAVKI)
                              ||'" НачислДох="'       ||trim(to_char( nvl(rec.NACHISL_DOH, 0),     '99999999999990.00'))
                              ||'" НачислДохДив="' ||trim(to_char( nvl(rec.NACH_DOH_DIV,0),    '99999999999990' ))
                              ||'" ВычетНал="'        ||trim(to_char( nvl(rec.VYCHET_NAL, 0),        '99999999999990.00'))
                              ||'" ИсчислНал="'      ||trim(to_char( nvl(rec.ISCHISL_NAL,0),         '99999999999990' ))
                              ||'" ИсчислНалДив="'||trim(to_char( nvl(rec.ISCHISL_NAL_DIV,0),  '99999999999990' ))
                              ||'" АвансПлат="'       ||trim(to_char( nvl(rec.AVANS_PLAT,0),          '99999999999990' ))||'"/>';
        end loop;    
        
        Ident_Left;
        cXML:=cXML||CrLf||'</ОбобщПоказ>'||CrLf;            
  end InsertTag6_ObobschPokaz;
  
  procedure InsertTag6_DohNal as
  begin
        cXML:=cXML||CrLf||'<ДохНал>';
        Ident_Right;   
        
        ERR_Pref := 'Цикл по датам выплат. Открытие курсора.';
        for rec in (Select * from F6NDFL_ARH_SVEDDAT where R_SPRID =  rSprData6.ID )
        loop
            ERR_Pref := 'Шаг цикла по Дате дохода '||to_char( rec.DATA_FACT_DOH,'dd.mm.yyyy' );
            cXML:=cXML||CrLf
                    ||'<СумДата ДатаФактДох="'||to_char( rec.DATA_FACT_DOH,     'dd.mm.yyyy' )
                              ||'" ДатаУдержНал="'  ||to_char( rec.DATA_UDERZH_NAL, 'dd.mm.yyyy' )
                              ||'" СрокПрчслНал="'  ||to_char( rec.SROK_PERECH_NAL,'dd.mm.yyyy' )
                              ||'" ФактДоход="'        ||trim(to_char( nvl(rec.SUM_FACT_DOH, 0),     '99999999999990.00'))
                              ||'" УдержНал="'        ||trim(to_char( nvl(rec.SUM_UDERZH_NAL,0),   '99999999999990' ))||'"/>';
        end loop;    
        
        Ident_Left;
        cXML:=cXML||CrLf||'</ДохНал>'||CrLf;            
  end InsertTag6_DohNal;
  
  -- Получить xml-файл 6 НДФЛ для передачи данных в ГНИ 
  -- параметры:
  --    pFileId  идентификатор в реестре файлов F_NDFL_ARH_XML_FILES
  function GetXML_XChFileF6(pFileId in number) return clob is
  begin
  
         gCurrentPersData := 0;
  
         cXML := Null;
         CrLf := chr(13)||chr(10);
         ERR_SprID :=' файл ';
         -- загрузим глобальные переменные
         -- данные для заголовка файла
         ERR_Pref := 'Чтение данных заголовка файла';
         Read_XML_TITLE(pFileId);
         if rFXML.KOD_FORMY<>6 then return 'ERR Запись в реестре файлов не содержит ссылку на тип формы 2НДФЛ.'; end if;

         -- данные налогового агента для справок
         ERR_Pref := 'Чтение данных Налогового Агента';
         Read_NA_DATA6(pFileId);
         
         -- данные справки - тэг Документ
         ERR_Pref := 'Выборка данных справки ';
         Select * into rSprData6 from f6NDFL_ARH_SPRAVKI where R_XMLID=pFileId;
         
         cXML := '<?xml version="1.0" encoding="windows-1251"?>'||CrLf
                    ||'<Файл xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ИдФайл="' ||rFXML.FILENAME||'"  ВерсПрог="1" ВерсФорм="'||rFXML.VERS_FORM||'">'||CrLf;
         Ident_Right;
            cXML := cXML||CrLf           
                            ||tag_DocumentHead6||CrLf;
               Ident_Right;
               cXML := cXML||CrLf                                
                                   ||tag_SVED_NALAG||CrLf
                                   ||tag_PODPISANT||CrLf
                                   ||'<НДФЛ6>'||CrLf;
                  Ident_Right;    
                    InsertTag6_ObobschPokaz;
                    InsertTag6_DohNal;                  
               Ident_Left;
               cXML := cXML||CrLf||'</НДФЛ6>'||CrLf; 
            Ident_Left;
            cXML := cXML||CrLf||'</Документ>'||CrLf; 
         Ident_Left;
         cXML := cXML||CrLf||'</Файл>'||CrLf;
         return cXML;

  exception
          when OTHERS then 
                return 'ERR '||ERR_SprID||ERR_Pref||' '||SQLERRM;
  end GetXML_XChFileF6;  
  
    function List_CorrectionOpers( pTermEnd in date ) 
             return f6NDFL_CorOpsTbl pipelined is 
    type tLCO is REF CURSOR return f6NDFL_CorOpsRow;
    cLCO tLCO;  
    rLCO f6NDFL_CorOpsRow;   
    pTermBeg date;
    begin
        pTermBeg := trunc(pTermEnd,'Y');
        Open cLCO for 
            Select * from (
            Select  'ВС' CATEGOR, 
                    sop.DATA_OP,
                    extract(Year from sop.DATA_OP) GOD_OP,
                    trunc((extract(Month from sop.DATA_OP)+2)/3) KVART_OP,
                    sop.STAVKA,
                    sop.VYK_SUM DOHOD,
                    sop.NALOG_NPO NALOG,
                    case sop.OPER_TIP
                        when -1 then 'Окончательная'
                        when  0 then 'Промежуточная'
                        when +1 then 'Первичная'
                        else Null end TIP_KOR, 
                    sop.NOM_VKL, sop.NOM_IPS, sop.SSYLKA_DOC,
                    sfl.SSYLKA  SSYLKA_FL,
                    sfl.FAMILIYA, 
                    sfl.IMYA, 
                    sfl.OTCHESTVO, 
                    sfl.DATA_ROGD,
                    trunc((extract(Month from sop.DATA_KORR)+2)/3) KVART_KOR, 
                    min(extract(Year from sop.DATA_OP)) over(partition by sfl.SSYLKA) GOD_PERVOPER,
                    sop.DATA_KORR     
            from(
                Select * from (
                    with SPDOG as (Select /*+ MATERIALIZE */ distinct dv.NOM_VKL, dv.NOM_IPS 
                                    from DV_SR_LSPV dv 
                                    where dv.SERVICE_DOC=-1 
                                      and dv.DATA_OP>=pTermBeg
                                      and dv.SHIFR_SCHET=55
                                   )
                    Select connect_by_root  dv.DATA_OP DATA_KORR, 
                           least( connect_by_isleaf, dv.SERVICE_DOC ) OPER_TIP,
                           dv.NOM_VKL, dv.NOM_IPS, dv.DATA_OP, dv.SSYLKA_DOC, 
                           max( case when dv.SHIFR_SCHET in (85,86) 
                                  then case when mod(dv.SUB_SHIFR_SCHET,2)=0 then 13 else 30 end
                                  else Null end ) 
                               over( partition by connect_by_root dv.DATA_OP, 
                                     least( connect_by_isleaf, dv.SERVICE_DOC ), 
                                     dv.NOM_VKL, dv.NOM_IPS, dv.DATA_OP, dv.SSYLKA_DOC )
                           STAVKA,
                           dv.SHIFR_SCHET, 
                           dv.SUMMA
                    from DV_SR_LSPV dv 
                    where (dv.NOM_VKL, dv.NOM_IPS) in (Select NOM_VKL, NOM_IPS from SPDOG)
                    start with dv.SERVICE_DOC=-1       -- коррекция (начинаем поиск с -1)
                               and dv.DATA_OP >= pTermBeg  -- исправление после начала периода    
                    connect by  PRIOR dv.NOM_VKL=dv.NOM_VKL   -- поиск по цепочке исправлений до
                            and PRIOR dv.NOM_IPS=dv.NOM_IPS    -- неправильного начисления
                            and PRIOR dv.SHIFR_SCHET=dv.SHIFR_SCHET
                            and PRIOR dv.SUB_SHIFR_SCHET=dv.SUB_SHIFR_SCHET
                            and PRIOR dv.SSYLKA_DOC=dv.SERVICE_DOC)
                pivot( sum(SUMMA) for SHIFR_SCHET in ( 55 as VYK_SUM, 60 as PENS, 85 NALOG_NPO, 62 as RIT_POSOB, 86 NALOG_RIT  )
                      ) 
                ) sop   
                inner join SP_LSPV sp on sp.NOM_VKL=sop.NOM_VKL and sp.NOM_IPS=sop.NOM_IPS    
                inner join SP_FIZ_LITS sfl on sfl.SSYLKA=sp.SSYLKA_FL        
            ) order by KVART_KOR, GOD_PERVOPER, DATA_KORR, SSYLKA_FL, DATA_OP;
        loop
            fetch cLCO into rLCO;
            Exit when cLCO%NotFound;
            
            pipe row( rLCO );
            
            end loop;
        Close cLCO;      
        
    end List_CorrectionOpers; 
      
END FXNDFL_OUT;
/
