CREATE OR REPLACE PACKAGE BODY FXNDFL_OUT AS

  gCurrentPersData number;  -- ����� ������ ������������ ������
  --  0  - ����� ������� �� ������ ����������� � ���
  --  1  - ������� ������������ ������ � GAZFOND
  gContragentID number;       -- ������������� �����������
  
  cXML clob;  -- �������������� ����
  -- ���� Select FXNDFL_OUT.GetXML_XChFileF2(2) FXML from Dual;
  
  CrLf varchar2(50) := chr(13)||chr(10);
  rFXML F_NDFL_ARH_XML_FILES%rowtype;
  -- ��������� � ����������� �����
  -- ID, FILENAME, KOD_FORMY, VERS_FORM, OKTMO, INN_YUL, KPP, NAIMEN_ORG, TLF, KOD_NO, GOD, KVARTAL, PRIZNAK_F
  
  rNALAG F2NDFL_SPR_NAL_AGENT%rowtype;
  -- ��������� � ����������� ���������� ������
  -- KOD_NA, OKTMO, PHONE, INN, KPP, NAZV, IFNS
  
  rSprData f2NDFL_ARH_SPRAVKI%rowtype; 
  -- ��������� � ����������� �������
  -- ID, R_XMLID, KOD_NA, DATA_DOK, NOM_SPR, GOD, NOM_KORR, KVARTAL, PRIZNAK_S, INN_FL, INN_INO, 
  -- STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC  
  rSprData6 f6NDFL_ARH_SPRAVKI%rowtype;
  
  rITOG f2NDFL_ARH_ITOGI%rowtype;
  -- ��������� � ��������� ������� �� ������� ��� ������ ������
  -- R_SPRID, KOD_STAVKI, SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS,SUM_OBL_NU, SUM_NAL_PER, DOLG_NA, VZYSK_IFNS
  
  rPODPISANT F2NDFL_SPR_PODPISANT%rowtype;
  -- ��������� ������ ��� ���� ���������
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
       ERR_Pref := '������������ ��������� / ��������� ';
       Select * into rPODPISANT from F2NDFL_SPR_PODPISANT where PKG_DFLT=1 and GOD=pGOD;  
       
       tag_PODPISANT:=  
         '<��������� ������="'||rPODPISANT.PODPISANT_TYPE||'">'||CrLf
       ||'   <��� �������="'||rPODPISANT.FA||'" ���="'||rPODPISANT.IM||'" ��������="'||rPODPISANT.OT||'" />'||CrLf
       ||'   <������ �������="'||replace(rPODPISANT.DOVER,'"','&quot;')||'"/>'||CrLf
       ||'</���������>';
       
  end;
  
  procedure Read_NA_DATA2(pFileId in number)  is
  begin
       Select * into rNALAG from F2NDFL_SPR_NAL_AGENT 
              where (KOD_NA,GOD) = ( Select KOD_NA, GOD from f2NDFL_ARH_SPRAVKI where rownum=1 and R_XMLID=pFileId );
       tag_SVED_NALAG :=
               '<���� �����="'||rNALAG.OKTMO||'" ���="'||rNALAG.PHONE||'">'||CrLf
             ||'         <������ �������="'||replace(rNALAG.NAZV,'"','&quot;')||'" �����="'||rNALAG.INN||'" ���="'||rNALAG.KPP||'"/>'||CrLf
             ||'      </����>';
             
       Read_NA_PODPIS( rNALAG.GOD );
             
  end Read_NA_DATA2;
  
  procedure Read_NA_DATA6(pFileId in number)  is
  begin
       Select * into rNALAG from F2NDFL_SPR_NAL_AGENT 
              where (KOD_NA,GOD) = ( Select KOD_NA,GOD from f6NDFL_ARH_SPRAVKI where rownum=1 and R_XMLID=pFileId );
       tag_SVED_NALAG :=
               '<���� �����="'||rNALAG.OKTMO||'" ���="'||rNALAG.PHONE||'">'||CrLf
             ||'         <���� �������="'||replace(rNALAG.NAZV,'"','&quot;')||'" �����="'||rNALAG.INN||'" ���="'||rNALAG.KPP||'"/>'||CrLf
             ||'      </����>';
             
       Read_NA_PODPIS( rNALAG.GOD );
             
  end Read_NA_DATA6;
  
  
  function tag_DocumentHead return varchar2 as
  begin
         return
         '<�������� ���="1151078" �������="'||to_char(rSprData.DATA_DOK,'dd.mm.yyyy')||'" ������="'||rSprData.NOM_SPR
                   ||'" ��������="'||to_char(rSprData.GOD)||'" �������="'||to_char(rSprData.PRIZNAK_S)
                   ||'" �������="'||trim(to_char(rSprData.NOM_KORR,'00'))||'" �����="'||rNALAG.IFNS||'">';
  end tag_DocumentHead;       
  
  function tag_DocumentHead6 return varchar2 as
  begin
         return
         '<�������� ���="1151099" �������="'||to_char(rSprData6.DATA_DOK,'dd.mm.yyyy')||'" ������="'||to_char(rSprData6.PERIOD)
                   ||'" ��������="'||to_char(rSprData6.GOD)||'" �����="'||rNALAG.IFNS
                   ||'" �������="'||trim(to_char(rSprData6.NOM_KORR,'00'))||'" �������="'||to_char(rSprData6.PO_MESTU)||'">';
  end tag_DocumentHead6;     
  
                  -- ��������� ������� ������� ������
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
         ERR_Pref := '������������ ��������� / ����� ';
 
         if gCurrentPersData=1 and gContragentID>0 then
               -- ������� ����� ����������� � GAZFOND
               begin
                    Select * into gfADR from gazfond.Addresses where FK_CONTRAGENT=gContragentID and FK_ADDRESS_TYPE=1;
                    exception
                        when NO_DATA_FOUND then gfADR.ID := Null;
                         when OTHERS then Raise;
                    end;
                    
               if gfADR.ID is not Null then
                  
                  if gfADR.FK_COUNTRY_CODE<>643 then 
                           return  '<������ ������="'||trim(to_char(gfADR.FK_COUNTRY_CODE,'000'))||'" ��������="'||replace(gazfond.ADDRESS_PKG.Get_Address(gContragentID,1),'"','&quot;')||'" />'; 
                     end if;
                     
                            vTAG:='<������� ';
                            
                            if gfADR.POST_INDEX is not Null then vTAG:=vTAG||'������="'||gfADR.POST_INDEX||'" ';  end if;
                            if gfADR.FK_REGION_CODE is not Null then vTAG:=vTAG||'���������="'||trim(to_char(gfADR.FK_REGION_CODE,'00'))||'" ';  end if;
                            if gfADR.DISTRICT is not Null then vTAG:=vTAG||'�����="'||replace(MakeAdrEl(gfADR.DISTRICT,gfADR.FK_DISTRICT_ABRV),'"','&quot;')||'" ';  end if;
                            if gfADR.CITY is not Null then vTAG:=vTAG||'�����="'||replace(MakeAdrEl(gfADR.CITY,gfADR.FK_CITY_ABRV),'"','&quot;')||'" ';  end if;
                            if gfADR.STATION is not Null then vTAG:=vTAG||'����������="'||replace(MakeAdrEl(gfADR.STATION,gfADR.FK_STATION_ABRV),'"','&quot;')||'" ';  end if;
                            if gfADR.STREET is not Null then vTAG:=vTAG||'�����="'||replace(MakeAdrEl(gfADR.STREET,gfADR.FK_STREET_ABRV),'"','&quot;')||'" ';  end if;
                            vTMP := trim(nvl(gfADR.HOUSE1,'')||nvl(gfADR.HOUSEL,'')||case when gfADR.HOUSE2 is not null then '/'||gfADR.HOUSE2 else '' end);
                            if vTMP is not Null then vTAG:=vTAG||'���="'||replace(vTMP,'"','&quot;')||'" ';  end if;
                            vTMP := trim(nvl(gfADR.CORPS1,'')||nvl(gfADR.CORPSL,''));
                            if vTMP is not Null then vTAG:=vTAG||'������="'||replace(vTMP,'"','&quot;')||'" ';  end if;
                            vTMP := trim(nvl(gfADR.APT1,'')||nvl(gfADR.APTL,''));
                            if vTMP is not Null then vTAG:=vTAG||'�����="'||replace(vTMP,'"','&quot;')||'" ';  end if;
                            
                            return vTAG||'/>'; 
                           
               end if;
                  
         end if;
         
                -- ����� �� ������ ������� 2����
                 begin
                        Select * into  vADR from f2NDFL_ARH_ADR where R_SPRID=rSprData.ID;
                        exception
                            when NO_DATA_FOUND then return Null;
                            when OTHERS then Raise;
                        end;       
                 if vADR.KOD_STR='643' then
                 
                    vTAG:='<������� ';
                    if vADR.PINDEX is not Null then vTAG:=vTAG||'������="'||vADR.PINDEX||'" ';  end if;
                    if vADR.KOD_REG is not Null then vTAG:=vTAG||'���������="'||vADR.KOD_REG||'" ';  end if;
                    if vADR.RAYON is not Null then vTAG:=vTAG||'�����="'||replace(vADR.RAYON,'"','&quot;')||'" ';  end if;
                    if vADR.GOROD is not Null then vTAG:=vTAG||'�����="'||replace(vADR.GOROD,'"','&quot;')||'" ';  end if;
                    if vADR.PUNKT is not Null then vTAG:=vTAG||'����������="'||replace(vADR.PUNKT,'"','&quot;')||'" ';  end if;
                    if vADR.ULITSA is not Null then vTAG:=vTAG||'�����="'||replace(vADR.ULITSA,'"','&quot;')||'" ';  end if;
                    if vADR.DOM is not Null then vTAG:=vTAG||'���="'||replace(vADR.DOM,'"','&quot;')||'" ';  end if;
                    if vADR.KOR is not Null then vTAG:=vTAG||'������="'||replace(vADR.KOR,'"','&quot;')||'" ';  end if;
                    if vADR.KV is not Null then vTAG:=vTAG||'�����="'||replace(vADR.KV,'"','&quot;')||'" ';  end if;
                    
                    return vTAG||'/>'; 
                 
                 end if;
                 
                 return '<������ ������="'|| vADR.KOD_STR||'" ��������="'||replace(vADR.ADR_INO,'"','&quot;')||'" />';
     
               
  end tag_AdresPoluchDoh; 
  
  function tag_PoluchDoh return varchar2 as
  begin
        ERR_Pref := '������������ ��������� / ���������������� ';  
        if rSprData.KOD_UD_LICHN in (1,22) then rSprData.KOD_UD_LICHN := 91; end if;
        return
          '<��������'|| case when rSprData.INN_FL is Null then Null else  ' �����="'||rSprData.INN_FL||'"' end ||' ������="'||to_char(rSprData.STATUS_NP)
                                            ||'" ��������="'||to_char(rSprData.DATA_ROZHD,'dd.mm.yyyy')||'" �����="'||rSprData.GRAZHD||'">'||CrLf
        ||'    <��� �������="'||rSprData.FAMILIYA||'" ���="'||rSprData.IMYA|| case when rSprData.OTCHESTVO is Null then Null else '" ��������="'||rSprData.OTCHESTVO end ||'" />'||CrLf
        ||'    <�������� ���������="'||trim(to_char(rSprData.KOD_UD_LICHN,'00'))||'" ���������="'||rSprData.SER_NOM_DOC||'"/>'||CrLf
        ||'    '||tag_AdresPoluchDoh||CrLf  
        ||'</��������>';
        
  end tag_PoluchDoh;
  
  procedure Insert_tagMesSvDohSumVych( pMES in number, pKodDOH in number ) as
  begin
        ERR_Pref := '���� �� ������� / ������ '||to_char(rITOG.KOD_STAVKI )||' / ����� '||to_char(pMes)||' '||' / �������� '||to_char(pKodDOH)||' ';
        for rec in (Select VYCH_KOD_GNI, sum(VYCH_SUM) VYCH_MES_SUM
                          from f2NDFL_ARH_MES 
                          where R_SPRID=rSprData.ID and KOD_STAVKI=rITOG.KOD_STAVKI and MES=pMes and DOH_KOD_GNI=pKodDOH
                          group by VYCH_KOD_GNI
                       )       
        loop
             cXML:=cXML||CrLf||'<�������� ��������="'||trim(to_char(rec.VYCH_KOD_GNI))||'" ��������="'||trim(to_char(rec.VYCH_MES_SUM, '99999999999990.00'))||'"/>';
        end loop;                 
  end;
                  
  procedure Insert_tagMesSvDohVych( pMes in number ) as
  -- .F2NDFL_ARH_MES
  --  R_SPRID, KOD_STAVKI, MES, DOH_KOD_GNI, DOH_SUM, VYCH_KOD_GNI, VYCH_SUM
  begin 
        ERR_Pref := '���� �� ������� / ������ '||to_char(rITOG.KOD_STAVKI )||' / ����� '||to_char(pMes)||' ';
        for rec in (Select DOH_KOD_GNI, sum(DOH_SUM) DOH_MES_SUM, max(VYCH_KOD_GNI) MAX_VYCH_KOD -- ���� ��� ������ ��� ������ <>0 "���� ������"
                          from f2NDFL_ARH_MES 
                          where R_SPRID=rSprData.ID and KOD_STAVKI=rITOG.KOD_STAVKI and MES=pMes
                          group by DOH_KOD_GNI
                          order by DOH_KOD_GNI
                       )  
        loop
           
          cXML:=cXML||CrLf||'<�������� �����="'||trim(to_char(pMes,'00'))
                                                        ||'" ��������="'||trim(to_char(rec.DOH_KOD_GNI,'0000'))
                                                        ||'" ��������="'||trim(to_char(rec.DOH_MES_SUM, '99999999999990.00'))||'"';
                                                        
           if nvl(rec.MAX_VYCH_KOD,0) = 0 
              then cXML:=cXML||' />';
              else
                     cXML:=cXML||' >';  
                     Ident_Right;
                         Insert_tagMesSvDohSumVych( pMes, rec.DOH_KOD_GNI );  --                            <�������� ��������="508" ��������="50000.00"/>                       
                     Ident_Left;       
                     cXML:=cXML||CrLf||'</��������>';    
              end if;
              
        end loop;
  end;

  procedure Insert_tagMesDohVych as
  begin
       cXML:=cXML||CrLf||'<������>';
       Ident_Right;
       
          ERR_Pref := '���� �� ������� / ������ '||to_char(rITOG.KOD_STAVKI )||' ';
          for rec in (Select distinct MES from f2NDFL_ARH_MES where R_SPRID=rSprData.ID and KOD_STAVKI=rITOG.KOD_STAVKI order by MES)  loop
              Insert_tagMesSvDohVych( rec.MES );
              end loop;
       
       Ident_Left;   
       cXML:=cXML||CrLf||'</������>';   
  end;
  
  procedure Insert_tagNalVychSSI as
  -- F2NDFL_ARH_VYCH
  --     R_SPRID, KOD_STAVKI, VYCH_KOD_GNI, VYCH_SUM_PREDOST, VYCH_SUM_ISPOLZ
  -- F2NDFL_ARH_UVED
  --     R_SPRID, KOD_STAVKI, SCHET_KRATN, NOMER_UVED, DATA_UVED, IFNS_KOD, UVED_TIP_VYCH
  nVychSSI number;
  begin
   
     ERR_Pref := '������� ����� ������� �� ������ � ������� ';
     Select count(*) into nVychSSI from F2NDFL_ARH_VYCH where VYCH_SUM_ISPOLZ>0 and KOD_STAVKI=rITOG.KOD_STAVKI and R_SPRID=rSprData.ID;  
     if nVychSSI=0 then return; end if;

       cXML:=cXML||CrLf||'<���������>';
       Ident_Right;  
        
       ERR_Pref := '������� ������� �� ������ � ������� ';
       for rec in ( Select * from F2NDFL_ARH_VYCH where VYCH_SUM_ISPOLZ>0 and KOD_STAVKI=rITOG.KOD_STAVKI and R_SPRID=rSprData.ID order by VYCH_KOD_GNI )
       loop
           cXML:=cXML||CrLf||'<���������� ��������="'||to_char(rec.VYCH_KOD_GNI)||'" ��������="'||trim(to_char( nvl(rec.VYCH_SUM_ISPOLZ,0),'99999999999990.00'))||'"/>';
          end loop;
          
       ERR_Pref := '������� ����������� � ���������� ������� ';   
       for rec in ( Select * from F2NDFL_ARH_UVED where KOD_STAVKI=rITOG.KOD_STAVKI and R_SPRID=rSprData.ID and UVED_TIP_VYCH=1 order by UVED_TIP_VYCH, SCHET_KRATN, DATA_UVED, NOMER_UVED )
       loop
           cXML:=cXML||CrLf||'<���������� ���������="'||trim(rec.NOMER_UVED)||'" ��������="'||to_char(rec.DATA_UVED,'dd.mm.yyyy')||'" ��������="'||rec.IFNS_KOD||'"/>';
          end loop;
             
       ERR_Pref := '������� ����������� �� ������������� ������� ';   
       for rec in ( Select * from F2NDFL_ARH_UVED where KOD_STAVKI=rITOG.KOD_STAVKI and R_SPRID=rSprData.ID and UVED_TIP_VYCH=2 order by UVED_TIP_VYCH, SCHET_KRATN, DATA_UVED, NOMER_UVED )
       loop
           cXML:=cXML||CrLf||'<����������� ���������="'||trim(rec.NOMER_UVED)||'" ��������="'||to_char(rec.DATA_UVED,'dd.mm.yyyy')||'" ��������="'||rec.IFNS_KOD||'"/>';
          end loop;   
          
       Ident_Left;   
       cXML:=cXML||CrLf||'</���������>';   
  end;
  
  function tag_ItogiPoStavke return varchar2 as  
  begin
       return
       '<����������� ���������="'      ||trim(to_char( nvl(rITOG.SGD_SUM,0),            '99999999999990.00' ))
                            ||'" �������="'            ||trim(to_char( nvl(rITOG.SUM_OBL,0),            '99999999999990.00' ))
                            ||'" ���������="'        ||trim(to_char( nvl(rITOG.SUM_OBL_NI,0),       '99999999999990' ))
                            ||'" �������������="' ||trim(to_char( nvl(rITOG.SUM_FIZ_AVANS,0), '99999999999990' ))
                            ||'" ��������="'          ||trim(to_char( nvl(rITOG.SUM_OBL_NU,0),      '99999999999990' ))
                            ||'" �����������="'     ||trim(to_char( nvl(rITOG.SUM_NAL_PER,0),    '99999999999990' ))
                            ||'" �����������="'   ||trim(to_char( nvl(rITOG.DOLG_NA,0),             '99999999999990' ))
                            ||'" ����������="'      ||trim(to_char( nvl(rITOG.VZYSK_IFNS,0),        '99999999999990' )) ||'"/>';
  end tag_ItogiPoStavke;
  
  procedure Insert_tagSvedStavka( pStavka in number ) as
  begin

     ERR_Pref := '������� ������ / ������ '||to_char(pStavka )||' ';
     begin
           Select * into rITOG from f2NDFL_ARH_ITOGI where R_SPRID=rSprData.ID and KOD_STAVKI=pStavka;
           exception
               when NO_DATA_FOUND then return;
               when OTHERS then Raise;
           end;    
     
     cXML:=cXML||'<������� ������="'||to_char(pStavka)||'">';
     Ident_Right;
     
        Insert_tagMesDohVych;
        
        Insert_tagNalVychSSI;
        
        cXML:=cXML||CrLf||tag_ItogiPoStavke;
     
     Ident_Left;   
     cXML:=cXML||CrLf||'</�������>';     
     
  end Insert_tagSvedStavka;

  procedure Insert_tagDocument( pSpavId in number ) as
  nICID number;
  begin
      
      ERR_Pref := '������� ������ ������� ';
      Select * into rSprData from f2NDFL_ARH_SPRAVKI where ID=pSpavId;
      if gCurrentPersData=1 and gContragentID>0 then
              Select INN into rSprData.INN_FL 
                  from gazfond.Contragents where ID=gContragentID; 
              Select Lastname, Firstname, Secondname, Birthdate, FK_IDCARD into rSprData.FAMILIYA,rSprData.IMYA, rSprData.OTCHESTVO,rSprData.DATA_ROZHD, nICID 
                   from gazfond.People where fk_Contragent=gContragentID;
              Select  FK_IDCARD_TYPE, SERIES||' '||NBR, trim(to_char(CITIZENSHIP,'000')) into rSprData.KOD_UD_LICHN, rSprData.SER_NOM_DOC, rSprData.GRAZHD
                   from gazfond.IDCards where ID=nICID;    
         end if;
      ERR_Pref := '������������ ���������';
      Ident_Right;
      cXML:=cXML||CrLf||tag_DocumentHead;
              Ident_Right;
              cXML:=cXML||CrLf
                 ||tag_PODPISANT||CrLf
                 ||tag_SVED_NALAG||CrLf
                 ||tag_PoluchDoh||CrLf;
                
                 ERR_Pref := '���� �� ������� � �������';       
                 for rec in (Select KOD_STAVKI from f2NDFL_ARH_ITOGI where R_SPRID=pSpavId order by KOD_STAVKI) loop
                     Insert_tagSvedStavka( rec.KOD_STAVKI );
                     end loop;
                 
              Ident_Left;   
      cXML:=cXML||CrLf||'</��������>';
      Ident_Left;    
      cXML:=cXML||CrLf;  
            
  end Insert_tagDocument;

  -- �������� xml-���� 2 ���� ��� �������� ������ � ��� 
  -- ���������:
  --    pFileId  ������������� � ������� ������ F_NDFL_ARH_XML_FILES
  function GetXML_XChFileF2(pFileId in number) return clob is
  begin
  
         gCurrentPersData := 0;
  
         cXML := Null;
         CrLf := chr(13)||chr(10);
         ERR_SprID :=' ���� ';
         -- �������� ���������� ����������
         -- ������ ��� ��������� �����
         ERR_Pref := '������ ������ ��������� �����';
         Read_XML_TITLE(pFileId);
         if rFXML.KOD_FORMY<>2 then return 'ERR ������ � ������� ������ �� �������� ������ �� ��� ����� 2����.'; end if;
         -- ������ ���������� ������ ��� �������
         ERR_Pref := '������ ������ ���������� ������';
         Read_NA_DATA2(pFileId);
         
         cXML := '<?xml version="1.0" encoding="windows-1251"?>'||CrLf
                    ||'<���� xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ������="' ||rFXML.FILENAME||'"  ��������="2" ��������="'||rFXML.VERS_FORM||'">'||CrLf
                    ||'   <������  �����="'||rFXML.OKTMO||'" ��������="'||to_char(rFXML.GOD)||'" ��������="'||rFXML.PRIZNAK_F||'">'||CrLf  
                    ||'   <���� �����="'||rFXML.INN_YUL||'" ���="'||rFXML.KPP||'" />'||CrLf
                    ||'   </������>'||CrLf;

         ERR_Pref := '������� ������� ��� �����.';  
         for rec in (Select ID from f2NDFL_ARH_SPRAVKI where R_XMLID=pFileId order by NOM_SPR) loop
              ERR_SprID := ' ������� '||trim(to_char(rec.ID,'0000000000'))||' ';
              Insert_tagDocument( rec.ID );
              end loop;     

         cXML := cXML||'</����>'||CrLf;
         return cXML;

  exception
          when OTHERS then 
                return 'ERR '||ERR_SprID||ERR_Pref||' '||SQLERRM;
  end GetXML_XChFileF2;  
  
  -- �������� xml-���� ��� ������ ������� 
  -- ���������:
  --    ��� ���������� ������ �� ����������� 1 - �������
  --    ��������� ���
  --    ����� ������� - ������ � �������� ������
  --    ����� ������������� - ��� ������ ������� 0
  --    0 - �������� ����� ������� � ��� /  1 - ������� ������������ ������  
  function GetXML_SpravkaF2(  pKodNA in number, pGOD in number, pNomSpravki in varchar2, pNomKorr in number, pCurrentPersData in number default 0  ) return clob is
  nSprId  number;
  nFileId  number;
  begin
         
         gCurrentPersData := pCurrentPersData; 
  
         CrLf := chr(13)||chr(10);  
         ERR_Pref := '������ �������������� �������';
         Select ID, R_XMLID into nSprId, nFileId from f2NDFL_ARH_SPRAVKI where KOD_NA=pKodNA and GOD=pGOD and NOM_SPR=pNomSpravki and NOM_KORR=pNomKorr;
                  
         -- ������ ���������� ������ ��� �������
         ERR_Pref := '������ ������ ���������� ������';
         Read_NA_DATA2(nFileId);
         
         cXML := '<?xml version="1.0" encoding="windows-1251"?>'
            ||CrLf||'<?xml-stylesheet type="text/xsl" href="2NDFL_2015.xsl"?>'
            ||CrLf||'<���� ��������="5.04">';
            
            Insert_tagDocument( nSprId );
            
         cXML := cXML||'</����>'||CrLf;
         return cXML;    
  
  exception
          when OTHERS then 
                return 'ERR '||ERR_SprID||ERR_Pref||' '||SQLERRM;
  end GetXML_SpravkaF2;    


  -- ���� ��� ����������� ������ �� ��
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
             -- ����� ��������� (������������) ������������ (<99) �������������
             Select max(NOM_KORR) into vNOMKOR from f2NDFL_ARH_SPRAVKI where KOD_NA=1 and NOM_KORR<99 and GOD=pYear and NOM_SPR=ns.NOM_SPR;
          exception
             when OTHERS then vNOMKOR:=Null;
          end;    
          
         begin 
             -- ����� ���� �������
             Select * into rSPR from f2NDFL_ARH_SPRAVKI where KOD_NA=1 and GOD=pYear and NOM_SPR=ns.NOM_SPR and NOM_KORR=vNOMKOR;
             
             if pYear=2016 then
                 Select sum(VZYSK_IFNS) into fBAL from f2NDFL_ARH_ITOGI where R_SPRID = rSPR.ID;
                 if fBAL>=0.01 then
                    vRES:= 'ERR � ������� ���������� ��������� ����. ��� ������ ������� ���������� � �������������.'; 
                    return vRES;
                    end if;
                 if rSPR.NOM_SPR in ( '119638','086778','021291','113280','140582','114332','009839' ) then
                    vRES:= 'ERR ���� ������ �� ������� ���������� �����������. ��� ������ ������� ���������� � �������������.'; 
                    return vRES;                
                    end if;
                end if;    
             
          exception
             when OTHERS then rSPR.ID:=Null;
          end; 

        end loop;
        
        
     if  rSPR.ID is Null 
         then vRES:= 'ERR �� ������� ���������� ������� ��� ������� ����������� � ����'; 
         else gContragentID:=pContragentID;
                vRES:= GetXML_SpravkaF2(  1, pYear, rSPR.NOM_SPR, rSPR.NOM_KORR, pCurrentPersData  ); 
         end if;       
            
     return vRES;
  
     end;  
     
  -- �������� �� 2015 ��� ������ ����������� ��� ���
  procedure Get_Spisok_PenBezINN2015(  pSpPenBazINN out sys_refcursor, pErrInfo out varchar2 ) as
  begin
  -- ����� ������ ����� ���������� � ������� ����������� ������� 
     Open pSpPenBazINN for
     Select     lsv.NOM_OTDEL, 
                   sul.KR_NAZV, sfl.NOM_VKL,
                   sfl.PEN_SXEM,  lsv.DOGOVOR, lsv.DATA_DOG, 
                   sfl.SSYLKA, sfl.FAMILIYA, sfl.IMYA, sfl.OTCHESTVO, sfl.DATA_ROGD ,
                   substr(sfl.TAB_NOM,1,4) KOD_PODRAZD, sfl.TAB_NOM   -- ���  ���������   
        from SP_FIZ_LITS sfl   -- ������������ �����  110 031
            inner join SP_UR_LITS sul on sul.SSYLKA=sfl.NOM_VKL   -- ����� ������ ����� �� ����������  =112 179
            inner join (Select distinct NOM_VKL, SSYLKA_FL, GOD_DOG, NOM_DOG from SP_IPS where TIP_LITS=3 -- ���������� (�� ������� 7 �������)
                            Union
                            Select distinct NOM_VKL, SSYLKA_FL, GOD_DOG, NOM_DOG from SP_IPS -- �������� ����� (7 ����������)
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
                                           -- ����� ������ ����� �� ���������� =112 139                 
            left join SP_RITUAL_POS srp on srp.SSYLKA=sfl.SSYLKA   -- ������ ������� �� �������
            left join SP_INN_FIZ_LITS inn on inn.SSYLKA=sfl.SSYLKA
            where sfl.SSYLKA 
                       in (  
                            Select distinct LS.SSYLKA 
                                from f2NDFL_LOAD_SPRAVKI LS
                                   where LS.R_SPRID -- ����� ������� ��� ��� ���������� � ���  =113 575
                                             in (Select ID from f2NDFL_ARH_SPRAVKI where  KOD_NA=1 and GOD=2015  and INN_FL is Null)                                 
                                   and LS.TIP_DOX=1   -- �������� ������ �����������  =112 179, 
                                                                    -- ���������: ��������, ��������, - � ��������� ���� �� ����������
                           )
                  and  srp.DATA_SMERTI is Null        -- �������� ����� 110 031
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
        cXML:=cXML||CrLf||'<���������� ����������="'   ||trim(to_char( nvl(rSprData6.KOL_FL_DOH,0)))
                                                        ||'" ����������="'    ||trim(to_char( nvl(rSprData6.UDERZH_NAL_IT,0),       '99999999999990' ))
                                                        ||'" ������������="'||trim(to_char( nvl(rSprData6.NE_UDERZH_NAL_IT,0),       '99999999999990' ))
                                                        ||'" ����������="'     ||trim(to_char( nvl(rSprData6.VOZVRAT_NAL_IT,0),       '99999999999990' ))
                                                        ||'">';
        Ident_Right;   
        
        ERR_Pref := '���� �� �������. �������� �������.';
        for rec in (Select * from f6NDFL_ARH_ITOGI where R_SPRID =  rSprData6.ID )
        loop
            ERR_Pref := '��� ����� �� ������ '||to_char(rITOG.KOD_STAVKI );
            cXML:=cXML||CrLf||'<��������� ������="'||to_char(rec.KOD_STAVKI)
                              ||'" ���������="'       ||trim(to_char( nvl(rec.NACHISL_DOH, 0),     '99999999999990.00'))
                              ||'" ������������="' ||trim(to_char( nvl(rec.NACH_DOH_DIV,0),    '99999999999990' ))
                              ||'" ��������="'        ||trim(to_char( nvl(rec.VYCHET_NAL, 0),        '99999999999990.00'))
                              ||'" ���������="'      ||trim(to_char( nvl(rec.ISCHISL_NAL,0),         '99999999999990' ))
                              ||'" ������������="'||trim(to_char( nvl(rec.ISCHISL_NAL_DIV,0),  '99999999999990' ))
                              ||'" ���������="'       ||trim(to_char( nvl(rec.AVANS_PLAT,0),          '99999999999990' ))||'"/>';
        end loop;    
        
        Ident_Left;
        cXML:=cXML||CrLf||'</����������>'||CrLf;            
  end InsertTag6_ObobschPokaz;
  
  procedure InsertTag6_DohNal as
  begin
        cXML:=cXML||CrLf||'<������>';
        Ident_Right;   
        
        ERR_Pref := '���� �� ����� ������. �������� �������.';
        for rec in (Select * from F6NDFL_ARH_SVEDDAT where R_SPRID =  rSprData6.ID )
        loop
            ERR_Pref := '��� ����� �� ���� ������ '||to_char( rec.DATA_FACT_DOH,'dd.mm.yyyy' );
            cXML:=cXML||CrLf
                    ||'<������� �����������="'||to_char( rec.DATA_FACT_DOH,     'dd.mm.yyyy' )
                              ||'" ������������="'  ||to_char( rec.DATA_UDERZH_NAL, 'dd.mm.yyyy' )
                              ||'" ������������="'  ||to_char( rec.SROK_PERECH_NAL,'dd.mm.yyyy' )
                              ||'" ���������="'        ||trim(to_char( nvl(rec.SUM_FACT_DOH, 0),     '99999999999990.00'))
                              ||'" ��������="'        ||trim(to_char( nvl(rec.SUM_UDERZH_NAL,0),   '99999999999990' ))||'"/>';
        end loop;    
        
        Ident_Left;
        cXML:=cXML||CrLf||'</������>'||CrLf;            
  end InsertTag6_DohNal;
  
  -- �������� xml-���� 6 ���� ��� �������� ������ � ��� 
  -- ���������:
  --    pFileId  ������������� � ������� ������ F_NDFL_ARH_XML_FILES
  function GetXML_XChFileF6(pFileId in number) return clob is
  begin
  
         gCurrentPersData := 0;
  
         cXML := Null;
         CrLf := chr(13)||chr(10);
         ERR_SprID :=' ���� ';
         -- �������� ���������� ����������
         -- ������ ��� ��������� �����
         ERR_Pref := '������ ������ ��������� �����';
         Read_XML_TITLE(pFileId);
         if rFXML.KOD_FORMY<>6 then return 'ERR ������ � ������� ������ �� �������� ������ �� ��� ����� 2����.'; end if;

         -- ������ ���������� ������ ��� �������
         ERR_Pref := '������ ������ ���������� ������';
         Read_NA_DATA6(pFileId);
         
         -- ������ ������� - ��� ��������
         ERR_Pref := '������� ������ ������� ';
         Select * into rSprData6 from f6NDFL_ARH_SPRAVKI where R_XMLID=pFileId;
         
         cXML := '<?xml version="1.0" encoding="windows-1251"?>'||CrLf
                    ||'<���� xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ������="' ||rFXML.FILENAME||'"  ��������="1" ��������="'||rFXML.VERS_FORM||'">'||CrLf;
         Ident_Right;
            cXML := cXML||CrLf           
                            ||tag_DocumentHead6||CrLf;
               Ident_Right;
               cXML := cXML||CrLf                                
                                   ||tag_SVED_NALAG||CrLf
                                   ||tag_PODPISANT||CrLf
                                   ||'<����6>'||CrLf;
                  Ident_Right;    
                    InsertTag6_ObobschPokaz;
                    InsertTag6_DohNal;                  
               Ident_Left;
               cXML := cXML||CrLf||'</����6>'||CrLf; 
            Ident_Left;
            cXML := cXML||CrLf||'</��������>'||CrLf; 
         Ident_Left;
         cXML := cXML||CrLf||'</����>'||CrLf;
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
            Select  '��' CATEGOR, 
                    sop.DATA_OP,
                    extract(Year from sop.DATA_OP) GOD_OP,
                    trunc((extract(Month from sop.DATA_OP)+2)/3) KVART_OP,
                    sop.STAVKA,
                    sop.VYK_SUM DOHOD,
                    sop.NALOG_NPO NALOG,
                    case sop.OPER_TIP
                        when -1 then '�������������'
                        when  0 then '�������������'
                        when +1 then '���������'
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
                    start with dv.SERVICE_DOC=-1       -- ��������� (�������� ����� � -1)
                               and dv.DATA_OP >= pTermBeg  -- ����������� ����� ������ �������    
                    connect by  PRIOR dv.NOM_VKL=dv.NOM_VKL   -- ����� �� ������� ����������� ��
                            and PRIOR dv.NOM_IPS=dv.NOM_IPS    -- ������������� ����������
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
