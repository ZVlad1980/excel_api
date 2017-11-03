CREATE OR REPLACE PACKAGE BODY FXNDFL_UTIL AS

-- ���������� ����������
gl_FLAGDEF number := 0;
gl_KODNA   number := Null;
gl_GOD     number := Null;
gl_TIPDOX  number := Null;
gl_NOMKOR  number := Null;
gl_DATAS   date   := Null;
gl_DATADO  date   := Null;

procedure InitGlobals( pKODNA in number, pGOD in number, pTIPDOX in number, pNOMKOR in number ) as
begin

    gl_FLAGDEF  := 1234509876;
    gl_KODNA    := pKODNA;
    gl_GOD      := pGOD;
    gl_TIPDOX   := pTIPDOX;
    gl_NOMKOR   := pNOMKOR;
    gl_DATAS    := to_date( '01.01.'||trim(to_char(gl_GOD  ,'0000')), 'dd.mm.yyyy');
    gl_DATADO   := to_date( '01.01.'||trim(to_char(gl_GOD+1,'0000')), 'dd.mm.yyyy');
    
end InitGlobals;

procedure CheckGlobals as
begin
    
    if gl_FLAGDEF <> 1234509876 then
       Raise_Application_Error( -20001,'����� FXNFL_UTIL: �� ���������������� ���������� ��������� ��� �������� ������ 2-����.' );
    end if;

end;

-- ��������� ������ ������������������ �� ������ �� �������� ������� �� ����
-- ������ ��������� � ������� F_NDFL_LOAD_NALPLAT
/*
            declare 
            RC varchar2(4000);
            begin
                dbms_output.enable(10000); 
                FXNDFL_UTIL.Spisok_NalPlat_poLSPV( RC, 149565 );
                dbms_output.put_line( nvl(RC,'��') );
            end;
*/

procedure Zapoln_Buf_NalogIschisl( pSPRID in number ) as 
  dTermBeg date;
  dTermEnd date;
  dTermKor date;
  nKodNA    number;
  nGod        number;
  nPeriod    number;
  nKFLUch number;
  nKFLRab number;
  nKFLObs number;
begin
        -- ������� ������� �������
        Select KOD_NA,GOD, PERIOD into  nKodNA,nGod, nPeriod  from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
         
        dTermBeg  :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
         
        case nPeriod
               when 21 then dTermEnd := add_months(dTermBeg,3);         
               when 31 then dTermEnd := add_months(dTermBeg,6);        
               when 33 then dTermEnd := add_months(dTermBeg,9);        
               when 34 then dTermEnd := add_months(dTermBeg,12);      
               else return;                
        end case;
        
        -- ����� ������� ��� ����
        dTermKor := dTermEnd;
           
    -- ���������� ��������� ������� ��� �������� ������������ ������
    -- ������� ��������� �� ������
    
    -- ���������� ���������� ������, ��� �����������
        -- ������       
        Insert into F2NDFL_LOAD_NALISCH( GF_PERSON, TIP_DOX, SUM_DOH )
        Select np.GF_PERSON, 10 TIP, sum(ds.SUMMA) DOX_SUM 
            from DV_SR_LSPV ds
                inner join F_NDFL_LOAD_NALPLAT np
                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS                  
                left join 
                   (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV 
                        where DATA_OP>=dTermBeg and DATA_OP< dTermEnd
                          and SHIFR_SCHET=85 and SUB_SHIFR_SCHET=1 and SERVICE_DOC=0 
                   )n30 
                    on n30.NOM_VKL=ds.NOM_VKL and n30.NOM_IPS=ds.NOM_IPS 
            where ds.DATA_OP>=dTermBeg
              and ds.DATA_OP< dTermEnd
              and ds.SERVICE_DOC=0
              and ds.SHIFR_SCHET=60
              and ds.NOM_VKL<991
              and n30.NOM_VKL is Null
            group by np.GF_PERSON;
            
        -- �������     
        Insert into F2NDFL_LOAD_NALISCH( GF_PERSON, TIP_DOX, SUM_DOH )            
        Select np.GF_PERSON, 20 TIP, sum(ds.SUMMA) DOX_SUM                  
            from DV_SR_LSPV ds
                inner join F_NDFL_LOAD_NALPLAT np
                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=1 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS                
                left join DV_SR_LSPV n30 
                    on n30.NOM_VKL=ds.NOM_VKL and n30.NOM_IPS=ds.NOM_IPS and n30.SHIFR_SCHET=86 and n30.SUB_SHIFR_SCHET=1
                       and n30.DATA_OP=ds.DATA_OP and n30.SSYLKA_DOC=ds.SSYLKA_DOC and n30.SERVICE_DOC=0                   
            where ds.DATA_OP>=dTermBeg
              and ds.DATA_OP< dTermEnd
              and ds.SERVICE_DOC=0
              and ds.SHIFR_SCHET=62
              and n30.NOM_VKL is Null  
            group by np.GF_PERSON;    
            
        -- ��������        
        Insert into F2NDFL_LOAD_NALISCH( GF_PERSON, TIP_DOX, SUM_DOH ) 
        Select np.GF_PERSON, 30 TIP, sum(ds.SUMMA) DOX_SUM
            from DV_SR_LSPV ds
                inner join F_NDFL_LOAD_NALPLAT np
                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS                    
                left join DV_SR_LSPV n30 
                    on n30.NOM_VKL=ds.NOM_VKL and n30.NOM_IPS=ds.NOM_IPS and n30.SHIFR_SCHET=85 and n30.SUB_SHIFR_SCHET=3
                       and n30.DATA_OP=ds.DATA_OP and n30.SSYLKA_DOC=ds.SSYLKA_DOC and n30.SERVICE_DOC=0                   
                where ds.DATA_OP>=dTermBeg
                  and ds.DATA_OP< dTermEnd
                  and ds.SERVICE_DOC=0
                  and ds.SHIFR_SCHET=55   
                  and n30.NOM_VKL is Null
            group by np.GF_PERSON;      
                
    -- �����������
        -- ������
        Insert into F2NDFL_LOAD_NALISCH( GF_PERSON, TIP_DOX, SUM_DOH ) 
        Select np.GF_PERSON, 11 TIP, sum(dox.SUMMA) DOX_SUM
        from
           (Select * from (    
                Select ds.*        -- ��� ����������� ������ ������ ����������� � ������� ����
                from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                    where  ds.SERVICE_DOC<>0
                    start with   ds.SHIFR_SCHET= 60          -- ������
                             and ds.NOM_VKL<991              -- � ������ �� ����
                             and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                             and ds.DATA_OP >= dTermBeg      -- ����������� ������� ����� ������ �������
                             and ds.DATA_OP <  dTermKor      -- �� ����� ��������, � ������� ����������� �������������
                    connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                             and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                             and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                             and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                             and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor               
            ) dox 
            inner join F_NDFL_LOAD_NALPLAT np
                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=dox.NOM_VKL and np.NOM_IPS=dox.NOM_IPS
            left join   
               (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV 
                    where DATA_OP>=dTermBeg and DATA_OP< dTermEnd
                      and SHIFR_SCHET=85 and SUB_SHIFR_SCHET=1 and SERVICE_DOC=0 
               )n30 
                on n30.NOM_VKL=dox.NOM_VKL and n30.NOM_IPS=dox.NOM_IPS                                    
           -- left join DV_SR_LSPV n30 
           --           on n30.NOM_VKL=dox.NOM_VKL and n30.NOM_IPS=dox.NOM_IPS and n30.SHIFR_SCHET=85 and n30.SUB_SHIFR_SCHET=1
           --              and n30.DATA_OP=dox.DATA_OP and n30.SSYLKA_DOC=dox.SSYLKA_DOC and n30.SERVICE_DOC=dox.SERVICE_DOC
        where n30.NOM_VKL is Null 
        group by np.GF_PERSON  
        having sum(dox.SUMMA)<>0;                  
                        
        -- �������  
        Insert into F2NDFL_LOAD_NALISCH( GF_PERSON, TIP_DOX, SUM_DOH )                   
        Select np.GF_PERSON, 21 TIP, sum(dox.SUMMA) DOX_SUM
            from
               (Select * from (    
                    Select ds.*        -- ��� ����������� ������� ������ ����������� � ������� ����
                    from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                        where  ds.SERVICE_DOC<>0
                        start with   ds.SHIFR_SCHET= 62          -- �������
                                 and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                 and ds.DATA_OP >= dTermBeg      -- ����������� ������� ����� ������ �������
                                 and ds.DATA_OP <  dTermKor      -- �� ����� ��������, � ������� ����������� �������������
                        connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                 and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                                 and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                 and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                 and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                    ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor               
                ) dox 
                inner join F_NDFL_LOAD_NALPLAT np
                        on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=1 and np.NOM_VKL=dox.NOM_VKL and np.NOM_IPS=dox.NOM_IPS                        
                left join DV_SR_LSPV n30 
                          on n30.NOM_VKL=dox.NOM_VKL and n30.NOM_IPS=dox.NOM_IPS and n30.SHIFR_SCHET=86 and n30.SUB_SHIFR_SCHET=1
                             and n30.DATA_OP=dox.DATA_OP and n30.SSYLKA_DOC=dox.SSYLKA_DOC and n30.SERVICE_DOC=dox.SERVICE_DOC    
            where n30.NOM_VKL is Null     
            group by np.GF_PERSON  
            having sum(dox.SUMMA)<>0;
                
        -- �������� 
        Insert into F2NDFL_LOAD_NALISCH( GF_PERSON, TIP_DOX, SUM_DOH )           
        Select np.GF_PERSON, 31 TIP,sum(dox.SUMMA) DOX_SUM
            from
               (Select * from (    
                    Select ds.*, min(DATA_OP) over(partition by ds.NOM_VKL, ds.NOM_IPS) MINDATOP
                    from DV_SR_LSPV ds
                        where  ds.SERVICE_DOC<>0
                        start with   ds.SHIFR_SCHET= 55        -- ������
                                 and ds.SERVICE_DOC=-1         -- ��������� (�������� ����� � -1)
                                 and ds.DATA_OP >= dTermBeg   -- ����������� ������� ����� ������ �������
                        connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                 and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                 and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                 and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                 and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                    ) where  MINDATOP>=dTermBeg and DATA_OP>=dTermBeg and DATA_OP<dTermEnd               
                ) dox 
                inner join F_NDFL_LOAD_NALPLAT np
                        on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=dox.NOM_VKL and np.NOM_IPS=dox.NOM_IPS                        
                left join DV_SR_LSPV n30 
                          on n30.NOM_VKL=dox.NOM_VKL and n30.NOM_IPS=dox.NOM_IPS and n30.SHIFR_SCHET=85 and n30.SUB_SHIFR_SCHET=3
                             and n30.DATA_OP=dox.DATA_OP and n30.SSYLKA_DOC=dox.SSYLKA_DOC and n30.SERVICE_DOC=dox.SERVICE_DOC  
            group by np.GF_PERSON  
            having sum(dox.SUMMA)<>0;
                     
    -- ����� ������ - �������� �����
    -- ��� ������ ������� ���������� ��������� 
    
end Zapoln_Buf_NalogIschisl;         


procedure Spisok_NalPlat_poLSPV( pErrInfo out varchar2, pSPRID in number ) as 
  dTermBeg date;
  dTermEnd date;
  dTermYear date;
  nKodNA    number;
  nGod        number;
  nPeriod    number;
  nKFLUch number;
  nKFLRab number;
  nKFLObs number;
begin
         pErrInfo := Null;  
         
         -- ������� ������� �������
         Select KOD_NA,GOD, PERIOD into  nKodNA,nGod, nPeriod  from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
         
         dTermBeg  :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
         dTermYear := add_months(dTermBeg,12); 
         
         case nPeriod
               when 21 then dTermEnd := add_months(dTermBeg,3);         
               when 31 then dTermEnd := add_months(dTermBeg,6);        
               when 33 then dTermEnd := add_months(dTermBeg,9);        
               when 34 then dTermEnd := add_months(dTermBeg,12);      
               else pErrInfo :='������: �������� '||to_char(nPeriod)||' ��������� pPeriod �� ����� 21, 31, 33 ��� 34 (���� ���������).'; return;                
         end case;
    
         -- ��� ������� ������ ���� �� ����������
         -- ������ ��� ����������, ������� ��� �� ���� ������� � ������
         
         -- ��� ������ 
         --   0 - ������ ��� �������� (������ ������ ����������)
         --   1 - ������� (������ ��������, � �� ����������)
         
         -- 1.  ������ ���, � ���� �� ���� ����������� ������  
        
         -- 1.1. ���������� �������� �����
         Insert into F_NDFL_LOAD_NALPLAT ( KOD_NA, GOD, NOM_VKL, NOM_IPS, SSYLKA_SIPS, SSYLKA_TIP, SSYLKA_REAL, GF_PERSON, NALRES_STATUS, KVARTAL_KOD ) 
         Select distinct nKodNA, nGod, ds.NOM_VKL, ds.NOM_IPS, lspv.SSYLKA_FL, 0, lspv.SSYLKA_FL, sfl.GF_PERSON, sfl.NAL_REZIDENT, nPeriod
                from DV_SR_LSPV ds
                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                        left join (Select NOM_VKL, NOM_IPS from F_NDFL_LOAD_NALPLAT 
                                       where KOD_NA=nKodNA and GOD=nGod and SSYLKA_TIP=0  -- ���������
                                    ) np on np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS                        
                where ds.DATA_OP>=dTermBeg
                   and ds.DATA_OP < dTermEnd
                   and ds.SHIFR_SCHET=55  -- ������� ��������
                   and ds.SERVICE_DOC=0
                   and np.NOM_VKL is Null;    -- �����, ������� ��� �� ����
                 
         -- 1.2. ���������� ������
         Insert into F_NDFL_LOAD_NALPLAT ( KOD_NA, GOD, NOM_VKL, NOM_IPS, SSYLKA_SIPS, SSYLKA_TIP, SSYLKA_REAL, GF_PERSON, NALRES_STATUS, KVARTAL_KOD ) 
         Select distinct nKodNA, nGod, ds.NOM_VKL, ds.NOM_IPS, lspv.SSYLKA_FL, 0, lspv.SSYLKA_FL, sfl.GF_PERSON, sfl.NAL_REZIDENT, nPeriod
                from DV_SR_LSPV ds
                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                        left join (Select NOM_VKL, NOM_IPS from F_NDFL_LOAD_NALPLAT 
                                       where KOD_NA=nKodNA and GOD=nGod and SSYLKA_TIP=0  -- ���������
                                    ) np on np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS                        
                where ds.DATA_OP>=dTermBeg
                   and ds.DATA_OP < dTermEnd
                   and ds.SHIFR_SCHET=60  -- ����� ������ ��������
                   and ds.NOM_VKL < 991     -- ����� ������ �� ������ �������
                   and ds.SERVICE_DOC=0
                   and np.NOM_VKL is Null;                   
                 
         -- 1.3. ����������� ������� ��������� ������� ��������   
         Insert into F_NDFL_LOAD_NALPLAT ( KOD_NA, GOD, NOM_VKL, NOM_IPS, SSYLKA_SIPS, SSYLKA_TIP, SSYLKA_REAL, GF_PERSON, NALRES_STATUS, KVARTAL_KOD ) 
         Select distinct nKodNA, nGod, ds.NOM_VKL, ds.NOM_IPS, lspv.SSYLKA_FL, vrp.NOM_VIPL, vrp.SSYLKA_POLUCH, vrp.GF_PERSON, vrp.NAL_REZIDENT, nPeriod
                from DV_SR_LSPV ds
                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                        inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, NOM_VIPL, SSYLKA_POLUCH, GF_PERSON, NAL_REZIDENT   
                                            from VYPLACH_POSOB 
                                            where TIP_VYPL=1010
                                               and DATA_VYPL>=dTermBeg 
                                               and DATA_VYPL < dTermEnd
                                        ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC     
                        left join (Select NOM_VKL, NOM_IPS, SSYLKA_TIP from F_NDFL_LOAD_NALPLAT 
                                       where KOD_NA=nKodNA and GOD=nGod
                                    ) np on np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS and vrp.NOM_VIPL=np.SSYLKA_TIP                       
                where ds.DATA_OP>=dTermBeg
                   and ds.DATA_OP < dTermEnd
                   and ds.SHIFR_SCHET=62  -- �������� � ����������� �����
                   and ds.SERVICE_DOC=0
                   and np.NOM_VKL is Null;    
                   
                   
         -- 2. ���� ����������� ������, ����������� � �������� �������
         
         -- 2.1. ������ � �������� ����� (�������� 12.04.2017 �����)         
         Insert into F_NDFL_LOAD_NALPLAT ( KOD_NA, GOD, NOM_VKL, NOM_IPS, SSYLKA_SIPS, SSYLKA_TIP, SSYLKA_REAL, GF_PERSON, NALRES_STATUS, KVARTAL_KOD ) 
         Select nKodNA, nGod, NOM_VKL, NOM_IPS, SSYLKA_FL, 0, SSYLKA_FL, GF_PERSON, NAL_REZIDENT, nPeriod
         from (Select distinct NOM_VKL, NOM_IPS, SSYLKA_FL, GF_PERSON, NAL_REZIDENT -- ds.NOM_VKL, ds.NOM_IPS, lspv.SSYLKA_FL, sfl.GF_PERSON, sfl.NAL_REZIDENT 
               from(Select ds.NOM_VKL, ds.NOM_IPS, lspv.SSYLKA_FL, sfl.GF_PERSON, sfl.NAL_REZIDENT, CONNECT_BY_ISLEAF ISLEAF, ds.DATA_OP 
                        from  DV_SR_LSPV ds            
                                    inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                    inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                    left join (Select NOM_VKL, NOM_IPS from F_NDFL_LOAD_NALPLAT 
                                                   where KOD_NA=nKodNA 
                                                      and GOD=nGod
                                                      and SSYLKA_TIP=0
                                                ) np on np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS
                        where sfl.PEN_SXEM<>7                  -- �� ���  
                          and np.NOM_VKL is Null               -- ���������� ���, ���� ��� ���             
                         start with ( ds.SHIFR_SCHET= 55       -- ��������, ����������� �������� ����� ���� ����� ���������� ���� 
                                      or ( ds.SHIFR_SCHET=60   -- ������
                                           and ds.NOM_VKL<991  -- �� �� ����� �������
                                           and ds.DATA_OP < dTermYear -- ����������� ������ ������ �� ����� �������� ����
                                          ) 
                                    ) 
                                and ds.SERVICE_DOC=-1          -- ��������� (�������� ����� � -1)
                                and ds.DATA_OP>=dTermBeg       -- ����������� ������� �� ����� ������ �������� ����                                                                
                         connect by PRIOR ds.NOM_VKL=ds.NOM_VKL        -- ����� �� ������� ����������� ��
                                    and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                    and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                    and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                    and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                    ) where ISLEAF=1           -- ������������ ������ (������������ ������ ����������)
                       and  DATA_OP >=dTermBeg -- ������������ ������� ������ ���� 
                       and  DATA_OP < dTermEnd -- � ������� �������� �������
              );                                           
                   
         -- 2.2. ���������� ������� � ����������� �����
         Insert into F_NDFL_LOAD_NALPLAT ( KOD_NA, GOD, NOM_VKL, NOM_IPS, SSYLKA_SIPS, SSYLKA_TIP, SSYLKA_REAL, GF_PERSON, NALRES_STATUS, KVARTAL_KOD ) 
         Select nKodNA, nGod, NOM_VKL, NOM_IPS, SSYLKA_FL, 0, SSYLKA_FL, GF_PERSON, NAL_REZIDENT, nPeriod
         from (Select lspv.NOM_VKL, lspv.NOM_IPS, lspv.SSYLKA_FL, vrp.GF_PERSON, vrp.NAL_REZIDENT
                    from(
                            Select  ds.NOM_VKL, ds.NOM_IPS, 
                                       min( ds.SSYLKA_DOC ) SSDOC,       -- ������ �������� � �������, ������������ 
                                       min(ds.DATA_OP) DATA_OSH_DOH,  -- ���� ������ �� ������� ���������
                                       sum(SUMMA) DOH_POLUCH
                             from  DV_SR_LSPV ds       
                                     left join (Select NOM_VKL, NOM_IPS from F_NDFL_LOAD_NALPLAT 
                                                   where KOD_NA=nKodNA 
                                                      and GOD=nGod
                                                      and SSYLKA_TIP=1           -- ������ ��������, � �� ����������� �����
                                                 ) np on np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS                                         
                             where np.NOM_VKL is Null 
                             start with ds.SHIFR_SCHET=62   -- �������� � ����������� ������
                                    and ds.SERVICE_DOC= -1  -- ��������� (�������� � -1)
                                    and ds.DATA_OP>=dTermBeg    -- ����������� �������
                                    -- ����������� ����� ���� ������� � �����, ���� ���������, ����� �� ������������ �������� ������?                                    
                                    and ds.DATA_OP < dTermEnd    -- � ������� �������� �������
                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL  
                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS
                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC                             
                             group by ds.NOM_VKL, ds.NOM_IPS
                             having min(ds.DATA_OP)>=dTermBeg   -- ��������� ���������� �������
                                 and min(ds.DATA_OP) < dTermEnd    -- � ������� �������� �������  
                           ) dvs
                     inner join SP_LSPV lspv on lspv.NOM_VKL=dvs.NOM_VKL and lspv.NOM_IPS=dvs.NOM_IPS 
                     inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                       from VYPLACH_POSOB 
                                            where TIP_VYPL=1010
                                               and DATA_VYPL>=dTermBeg
                                               and DATA_VYPL < dTermEnd
                                 ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=dvs.SSDOC and vrp.DATA_VYPL=dvs.DATA_OSH_DOH          
                     group by  lspv.NOM_VKL, lspv.NOM_IPS, lspv.SSYLKA_FL, vrp.GF_PERSON, vrp.NAL_REZIDENT
              ); 
                                    
        -- ���������� ������ �������� ������
        Spisok_NalPlat_DohodNol( pSPRID );
                
                               
         -- ������������� ����������
         -- ������� ��� ���, ��� ����� ���������� �����
         Update f_NDFL_LOAD_NALPLAT np
           set np.GF_PERSON= (Select tc.FK_CONTRAGENT from GAZFOND.TRANSFORM_CONTRAGENTS tc where tc.SSYLKA_TS=np.SSYLKA_REAL)
           where np.GF_PERSON is Null and np.SSYLKA_TIP=0;
         -- ����� ��� ����  
         Update f_NDFL_LOAD_NALPLAT np
           set np.GF_PERSON= (Select tc.FK_CONTRAGENT from GAZFOND.TRANSFORM_CONTRAGENTS tc where tc.SSYLKA_FL=np.SSYLKA_REAL)
           where np.GF_PERSON is Null and np.SSYLKA_TIP=0;  
           
         -- ������������� ����������� �������, ������� �������� �����������  
         -- ������� ��� ���, ��� ����� ���������� �����
         Update f_NDFL_LOAD_NALPLAT np
           set np.GF_PERSON= (Select tc.FK_CONTRAGENT from GAZFOND.TRANSFORM_CONTRAGENTS tc where tc.SSYLKA_TS=np.SSYLKA_REAL)
           where np.GF_PERSON is Null and np.SSYLKA_TIP=1 and np.SSYLKA_REAL>0;
         -- ����� ��� ����  
         Update f_NDFL_LOAD_NALPLAT np
           set np.GF_PERSON= (Select tc.FK_CONTRAGENT from GAZFOND.TRANSFORM_CONTRAGENTS tc where tc.SSYLKA_FL=np.SSYLKA_REAL)
           where np.GF_PERSON is Null and np.SSYLKA_TIP=1 and np.SSYLKA_REAL>0;   
        

         -- ������� ���� ������� �������������� �� ������ �������� � ������ ����������� �������
         Update VYPLACH_POSOB vp  
           set vp.GF_PERSON= (Select sr.FK_CONTRAGENT from SP_RITUAL_POS sr
                              where sr.SSYLKA=vp.SSYLKA)
           where  vp.GF_PERSON is Null
              and vp.TIP_VYPL=1010
              and vp.NOM_VIPL=1
              and vp.DATA_VYPL>=dTermBeg 
              and vp.DATA_VYPL < dTermEnd; 
                          
         -- ������������� ����������� �������, ������� �� �������� ����������� �����
         Update f_NDFL_LOAD_NALPLAT np
           set np.GF_PERSON= (Select distinct sr.FK_CONTRAGENT 
                                 from SP_RITUAL_POS sr
                                    inner join VYPLACH_POSOB vp on vp.SSYLKA=sr.SSYLKA 
                                 where vp.TIP_VYPL=1010
                                   and vp.NOM_VIPL=1
                                   and vp.DATA_VYPL>=dTermBeg
                                   and vp.DATA_VYPL < dTermEnd
                                   and vp.SSYLKA=np.SSYLKA_SIPS ) 
           where np.GF_PERSON is Null and np.SSYLKA_TIP=1 and np.SSYLKA_REAL=0;         


         -- ��������� ������� � ���              
         Update SP_FIZ_LITS sfl
            set sfl.GF_PERSON = (Select distinct np.GF_PERSON
                                     from f_NDFL_LOAD_NALPLAT np
                                     where np.SSYLKA_REAL=sfl.SSYLKA
                                       and np.KOD_NA=nKodNA and np.GOD=nGod and np.SSYLKA_TIP=0
                                       and np.GF_PERSON is not Null)
            where sfl.GF_PERSON is Null
              and sfl.SSYLKA 
                  in (Select distinct SSYLKA_REAL
                         from f_NDFL_LOAD_NALPLAT
                         where KOD_NA=nKodNA and GOD=nGod and SSYLKA_TIP=0
                           and SSYLKA_REAL>0
                           and GF_PERSON is not Null);      
                              
         -- ����� ������������� ����� ������������������                
         Update F6NDFL_LOAD_SPRAVKI
           set KOL_FL_DOHOD= 0
           where R_SPRID = pSPRID;                              
                          
           
         Commit;          
                 
exception
   when OTHERS then
         pErrInfo := SQLERRM;     
         Rollback;
           
end Spisok_NalPlat_poLSPV;      

-- ��� ��������� ������ ����� � ������ ��,
-- � ������� ����� ���� ������� � ���������� �����������
-- (�������: ������� ����� �������, � ��� ������������ �����)
-- ����� �� �� ����� �������� � �������
-- ��� �� ������ ����� � ����� ���, ���������� �����
--
-- ������ ���� ��������� ���������� ������ ����������� ������
--
-- ����� ������ ���� �������!
procedure Spisok_NalPlat_DohodNol( pSPRID in number ) as
  dTermBeg  date;
  dTermEnd  date;
  dTermYear date; 
  nKodNA    number;
  nGod      number;
  nPeriod   number;
  nNomKor   number;
  nRIT      number;
begin
     
      -- ������� ������� �������
      Select KOD_NA,GOD, PERIOD, NOM_KORR into  nKodNA,nGod, nPeriod, nNomKor  from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
     
      dTermBeg  := to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
      dTermYear := add_months(dTermBeg,12);       
     
      case nPeriod
           when 21 then dTermEnd := add_months(dTermBeg,3);         
           when 31 then dTermEnd := add_months(dTermBeg,6);        
           when 33 then dTermEnd := add_months(dTermBeg,9);        
           when 34 then dTermEnd := add_months(dTermBeg,12);      
           else Raise_Application_Error( -20001,'������: �������� '||to_char(nPeriod)||' ��������� pPeriod �� ����� 21, 31, 33 ��� 34 (���� ���������).');                
      end case; 
      
         -- ��������� ������ �������� �������� ������
         -- ������ �������� ���� �� ���
         
         -- �����
         Update F_NDFL_LOAD_NALPLAT np
             set  np.SGD_ISPRVNOL=0
             where np.KOD_NA=nKodNA and np.GOD=nGod
                and np.SGD_ISPRVNOL<>0;
                      
         -- ���������� ������
         -- ��� ������ (������ ����������)
         Update F_NDFL_LOAD_NALPLAT np
             set  np.SGD_ISPRVNOL=1
             where np.KOD_NA=nKodNA and np.GOD=nGod         
                and (np.NOM_VKL, np.NOM_IPS, np.SSYLKA_TIP ) 
                    in (Select ds.NOM_VKL, ds.NOM_IPS, 0 SSTYP  
                            from DV_SR_LSPV ds
                                 inner join (Select distinct NOM_VKL, NOM_IPS
                                                from DV_SR_LSPV
                                                where NOM_VKL<991          -- �� �� ����� �������    
                                                  and SHIFR_SCHET=60       -- ������    
                                                  and DATA_OP >= dTermBeg  -- �� ����  
                                                  and DATA_OP <  dTermYear -- ���
                                                  and SUMMA<=0
                                            ) ns  -- ������ ���� ������� �� � ����, � ������ ����� ���, � ���� ���� ������������� ����� 
                                            on  ns.NOM_VKL=ds.NOM_VKL and ns.NOM_IPS=ds.NOM_IPS 
                            where ds.NOM_VKL<991             -- �� �� ����� �������    
                              and ds.SHIFR_SCHET=60          -- ������    
                              and ds.DATA_OP >= dTermBeg     -- �� ����  
                              and ds.DATA_OP <  dTermYear    -- ���
                            group by  ds.NOM_VKL, ds.NOM_IPS   
                            having abs(sum(ds.SUMMA))<0.01   -- �������� ����� - ����           
                        );            
         
         -- ��� �������� (������ ����������)
         Update F_NDFL_LOAD_NALPLAT np
             set  np.SGD_ISPRVNOL=1
             where np.KOD_NA=nKodNA and np.GOD=nGod         
                and (np.NOM_VKL, np.NOM_IPS, np.SSYLKA_TIP ) 
                       in ( Select ds.NOM_VKL, ds.NOM_IPS, 0 SSTYP   
                                from DV_SR_LSPV ds
                                where (ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET) 
                                    in (Select NOM_VKL, NOM_IPS, SHIFR_SCHET
                                        from(Select ds.*, CONNECT_BY_ISLEAF ISLEAF
                                                from  DV_SR_LSPV ds            
                                                 where   ds.NOM_VKL<>1001           -- �� ���                  
                                                 start with ds.SHIFR_SCHET= 55      -- ��������
                                                        and ds.SERVICE_DOC=-1       -- ��������� (�������� ����� � -1)
                                                        and ds.DATA_OP >= dTermBeg  -- ����������� ������� �� ����� ������ ����                             
                                                 connect by PRIOR ds.NOM_VKL=ds.NOM_VKL        -- ����� �� ������� ����������� ��
                                                            and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������ ������
                                                            and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                            and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                            and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                            ) where ISLEAF=1
                                                and DATA_OP >= dTermBeg  -- ���� ������������ ������ 
                                                and DATA_OP <  dTermYear -- � �������� ����
                                        )  
                                group by ds.NOM_VKL, ds.NOM_IPS  
                                having abs(sum(ds.SUMMA))<0.01  
                           );          
                          
         -- ��� �������� � ���������� (������ ������� ����������, � �� ����������� ������)
         Select count(*) into nRIT
             from DV_SR_LSPV 
                where SHIFR_SCHET=62 and (SERVICE_DOC<>0 or SUMMA<0) 
                  and DATA_OP>=dTermBeg and DATA_OP<dTermYear;
         
    if nRIT>0 then
 
         Raise_Application_Error( -20001,'��������� Spisok_NalPlat_DohodNol. ���������� ����������� ����������� ���� ��� ���������� ������. ����� �������������� ������.');

         Update F_NDFL_LOAD_NALPLAT np
             set  np.SGD_ISPRVNOL=1
             where np.KOD_NA=nKodNA and np.GOD=nGod         
                and (np.NOM_VKL, np.NOM_IPS, np.SSYLKA_TIP ) 
                       in ( Select dvs.NOM_VKL, dvs.NOM_IPS, 1 SSTYP   
                                from ( Select  ds.NOM_VKL, ds.NOM_IPS,
                                                      max(case when SERVICE_DOC=-1 then ds.SSYLKA_DOC else 0 end) SSDOC,
                                                      min(ds.DATA_OP) DATA_OSH_DOH, 
                                                      sum(SUMMA) DOH_POLUCH
                                            from  DV_SR_LSPV ds      
                                            where not exists( Select * from DV_SR_LSPV dsz
                                                                         where dsz.DATA_OP>=dTermBeg  and dsz.DATA_OP <  dTermEnd 
                                                                            and dsz.NOM_VKL=ds.NOM_VKL and dsz.NOM_IPS=ds.NOM_IPS 
                                                                            and dsz.SHIFR_SCHET=62 and dsz.SERVICE_DOC=0)  -- ��� �������������� ������ �� ������ ������ 
                                            start with ds.SHIFR_SCHET=62  -- �������� � ����������� ������
                                                    and ds.SERVICE_DOC=-1  -- ��������� (�������� � -1)
                                                    and ds.DATA_OP>=dTermBeg    -- ����������� �������
                                                    -- ����������� ����� ���� ������� � �����, ���� ���������, ����� �� ������������ �������� ������?                                    
                                                    and ds.DATA_OP < dTermEnd    -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL  
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC              
                                             group by ds.NOM_VKL, ds.NOM_IPS
                                             having min(ds.DATA_OP)>=dTermBeg   -- ��������� ���������� �������
                                                 and min(ds.DATA_OP) < dTermEnd    -- � ������� �������� �������
                                             ) dvs
                                 inner join SP_LSPV lspv on lspv.NOM_VKL=dvs.NOM_VKL and lspv.NOM_IPS=dvs.NOM_IPS 
                                 left join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON   
                                                   from VYPLACH_POSOB 
                                                        where TIP_VYPL=1010    
                                                           and DATA_VYPL>=dTermBeg
                                                           and DATA_VYPL < dTermEnd
                                                           -- ���� ����������� 2 � �����, �� �� ���������������� ��-�� ������ ������ ���
                                                           and SSYLKA not in (Select distinct SSYLKA from VYPLACH_POSOB where NOM_VIPL>1)
                                             ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=dvs.SSDOC         
                                 group by dvs.NOM_VKL, dvs.NOM_IPS
                                 having sum( dvs.DOH_POLUCH)=0
                          );     
    end if;  -- ����� �������� � �������������
                               
exception
   when OTHERS then       
         Rollback;     
         Raise;
              
end Spisok_NalPlat_DohodNol;                  

-- ���������� ����� ������������������, ���������� ��������� ����� � ������ ����
--        ����� ������� ������ ���� ������������ ������ ������������������:
--        ���������� � ����������
--  ��������� ������������ �  F6NDFL_LOAD_SPRAVKI
--                KOL_FL_DOHOD - ����� �� ���� ������� 060 ������ 1 ����� �����
--                KFL_UCH - ����� ��-���������� � ������� ������ ����
--                KFL_RAB - ����� ��-���������� � ������� ������ ����
--                KFL_SOVP - ����� �� ������������ � ���� �������      
procedure Raschet_Chisla_NalPlat( pErrInfo out varchar2, pSPRID in number ) as 
  dTermBeg date;
  dTermEnd date;
  nKodNA   number;
  nGod     number;
  nPeriod  number;
  nNomKor  number;
  nKFLUch  number;
  nKFLRab  number;
  nKFLObs  number;
begin
          pErrInfo := Null;  
         
          -- ������� ������� �������
          Select KOD_NA,GOD, PERIOD, NOM_KORR into  nKodNA,nGod, nPeriod, nNomKor  from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
         
          dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
         
          case nPeriod
               when 21 then dTermEnd := add_months(dTermBeg,3);         
               when 31 then dTermEnd := add_months(dTermBeg,6);        
               when 33 then dTermEnd := add_months(dTermBeg,9);        
               when 34 then dTermEnd := add_months(dTermBeg,12);      
               else pErrInfo :='������: �������� '||to_char(nPeriod)||' ��������� pPeriod �� ����� 21, 31, 33 ��� 34 (���� ���������).'; return;                
          end case;          
                         
          begin  
             Select count(distinct np.GF_PERSON) into nKFLUch
                from F_NDFL_LOAD_NALPLAT np 
                where  np.KOD_NA=nKodNA and np.GOD=nGod and np.KVARTAL_KOD<=nPeriod
                    and np.SGD_ISPRVNOL=0;
          exception
             when NO_DATA_FOUND then nKFLUch:=0;
             when OTHERS then Raise;
             end;
             
          Update F6NDFL_LOAD_SUMGOD 
             set KOL_FL_SOVPAD = 0,
                 KOL_FL_DOHOD  = nKFLUch
             where KOD_NA=nKodNA and GOD=nGod and PERIOD=nPeriod and NOM_KORR=nNomKor and KOD_PODR=0; 
             
                
          begin
             Select nvl(sum(KOL_FL_DOHOD),0), nvl(sum(KOL_FL_SOVPAD),0) into nKFLRab, nKFLObs 
                from F6NDFL_LOAD_SUMGOD sr 
                where  sr.KOD_NA=nKodNA and sr.GOD=nGod and sr.PERIOD=nPeriod and NOM_KORR=nNomKor and KOD_PODR>0;
          exception
             when NO_DATA_FOUND then nKFLRab:=0;  nKFLObs:=0;
             when OTHERS then Raise;
             end;   
    
         Update F6NDFL_LOAD_SPRAVKI
           set KOL_FL_DOHOD= nKFLUch+nKFLRab-nKFLObs
           where R_SPRID = pSPRID;    
          
         Commit;          
                 
exception
   when OTHERS then
         pErrInfo := SQLERRM;     
         Rollback;
           
end Raschet_Chisla_NalPlat;

-- ���������� ����� ������������������, ������������ ���������� �����������
procedure Raschet_Chisla_SovpRabNp( pErrInfo out varchar2, pSPRID in number ) as
  dTermBeg date;
  dTermEnd date;
  nKodNA   number;
  nGod     number;
  nPeriod  number;
  nNomKor  number;
  nKFLUch  number;
  nKFLRab  number;
  nKFLObs  number;
begin
          pErrInfo := Null;  
         
          -- ������� ������� �������
          Select KOD_NA,GOD, PERIOD, NOM_KORR into  nKodNA,nGod, nPeriod, nNomKor  from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
         
          dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
         
          case nPeriod
               when 21 then dTermEnd := add_months(dTermBeg,3);         
               when 31 then dTermEnd := add_months(dTermBeg,6);        
               when 33 then dTermEnd := add_months(dTermBeg,9);        
               when 34 then dTermEnd := add_months(dTermBeg,12);      
               else pErrInfo :='������: �������� '||to_char(nPeriod)||' ��������� pPeriod �� ����� 21, 31, 33 ��� 34 (���� ���������).'; return;                
          end case; 
          
            Select count(distinct sr.GF_PERSON) into nKFLObs
            from DV_SR_LSPV ds
              inner join SP_LSPV lspv           on ds.NOM_VKL=lspv.NOM_VKL and ds.NOM_IPS=lspv.NOM_IPS
              inner join SP_FIZ_LITS sfl        on sfl.SSYLKA=lspv.SSYLKA_FL  
              inner join f_NDFL_LOAD_SPISRAB sr on sr.GF_PERSON=sfl.GF_PERSON
            where ds.DATA_OP >= dTermBeg
              and ds.DATA_OP <  dTermEnd
              and ds.SHIFR_SCHET=85
              and sr.KOD_NA=nKodNA and sr.GOD=nGod and sr.KVARTAL_KOD<=nPeriod
          ; 
         
         Commit;          
                 
exception
   when OTHERS then
         pErrInfo := SQLERRM;     
         Rollback;
           
end Raschet_Chisla_SovpRabNp;

-- ��������� ��������� ������ ������������������, �������� �������� ������ 
procedure Oshibki_vSpisNalPlat( pReportCursor out sys_refcursor, pErrInfo out varchar2, pKodNA in number, pGod in number, pPeriod in number ) as
begin
   pErrInfo:=Null;
   
   Open pReportCursor for
   -- ������ � ��������
   Select * from (
           Select 1000 KODOSH, 
                     np.NOM_VKL, np.NOM_IPS, np.SSYLKA_REAL SSYLKA, np.SSYLKA_TIP, np.GF_PERSON, sfl.FAMILIYA||' '||sfl.IMYA||' '||sfl.OTCHESTVO FIO, sfl.DATA_ROGD, np.NALRES_STATUS, ifl.INN, '' TEXTOSH
                 from F_NDFL_LOAD_NALPLAT np
                         left join SP_FIZ_LITS sfl on sfl.SSYLKA=np.SSYLKA_REAL
                         left join SP_INN_FIZ_LITS ifl on ifl.SSYLKA=np.SSYLKA_REAL
                 where np.KOD_NA=pKodNA
                    and np.GOD=pGod
                    and np.GF_PERSON is Null -- �� ������������������ ����������������
                    and np.SSYLKA_TIP=0
            UNION    
            -- �������� � �������
            Select 1001 KODOSH, 
                      np.NOM_VKL, np.NOM_IPS, np.SSYLKA_REAL SSYLKA, np.SSYLKA_TIP, np.GF_PERSON, vp.FIO, cast(Null as date) DATA_ROGD, np.NALRES_STATUS, ifl.INN, '' TEXTOSH
                 from F_NDFL_LOAD_NALPLAT np
                         left join VYPLACH_POSOB vp on vp.SSYLKA=np.SSYLKA_SIPS and vp.NOM_VIPL=np.SSYLKA_TIP
                         left join SP_INN_FIZ_LITS ifl on ifl.SSYLKA=np.SSYLKA_REAL
                 where np.KOD_NA=pKodNA
                    and np.GOD=pGod
                    and np.GF_PERSON is Null -- �� ������������������ ����������������
                    and np.SSYLKA_TIP<>0    
                    and vp.TIP_VYPL=1010
            UNION
            Select * from(
            -- ��� ����������� ID �����������
            With q as (Select  n1.*, 
                    s1.SSYLKA SS1, s1.FAMILIYA||' '||s1.IMYA||' '||s1.OTCHESTVO FIO1, s1.DATA_ROGD DR1, i1.INN INN1, s1.NAL_REZIDENT SNR1, s1.NOM_VKL NV1,
                    s2.SSYLKA SS2, s2.FAMILIYA||' '||s2.IMYA||' '||s2.OTCHESTVO FIO2, s2.DATA_ROGD DR2, i2.INN INN2, s2.NAL_REZIDENT SNR2, s2.NOM_VKL NV2            
                    from F_NDFL_LOAD_NALPLAT n1,F_NDFL_LOAD_NALPLAT n2, SP_FIZ_LITS s1, SP_FIZ_LITS s2, SP_INN_FIZ_LITS i1, SP_INN_FIZ_LITS i2,
                            (Select GF_PERSON from F_NDFL_LOAD_NALPLAT where KOD_NA=pKodNA and GOD=pGod and SSYLKA_TIP=0 group by GF_PERSON having count(*)>1) q        
                    where n1.GF_PERSON=q.GF_PERSON
                       and n2.GF_PERSON=q.GF_PERSON
                       and n1.SSYLKA_TIP=0 -- ���������� ����������,
                       and n2.SSYLKA_TIP=0 -- � �� �� �����������  
                       and s1.SSYLKA=n1.SSYLKA_SIPS
                       and s2.SSYLKA=n2.SSYLKA_SIPS
                       and s1.SSYLKA<s2.SSYLKA
                       and i1.SSYLKA(+)=s1.SSYLKA
                       and i2.SSYLKA(+)=s2.SSYLKA )
                -- ������ ���       
                Select 2000 KODOSH, NOM_VKL, NOM_IPS, SSYLKA_SIPS SSYLKA, SSYLKA_TIP, GF_PERSON, FIO1 FIO, DR1 DATA_ROGD, SNR1 NALRES_STATUS, INN1 INN,
                          FIO2||'   ��� '||to_char(NV2)||'/'||to_char(SS2) TEXTOSH
                          from q
                          where q.FIO1<>q.FIO2
                UNION          
                -- ������ ��
                Select 2001 KODOSH, NOM_VKL, NOM_IPS, SSYLKA_SIPS SSYLKA, SSYLKA_TIP, GF_PERSON, FIO1 FIO, DR1 DATA_ROGD, SNR1 NALRES_STATUS, INN1 INN,
                          FIO2||'   ��� '||to_char(NV2)||'/'||to_char(SS2)||'  �� '||to_char(DR2,'dd.mm.yyyy') TEXTOSH
                          from q
                          where q.DR1<>q.DR2      
                UNION       
                -- ������ ���                 
                Select 2002 KODOSH, NOM_VKL, NOM_IPS, SSYLKA_SIPS SSYLKA, SSYLKA_TIP, GF_PERSON, FIO1 FIO, DR1 DATA_ROGD, SNR1 NALRES_STATUS, INN1 INN,
                          FIO2||'   ��� '||to_char(NV2)||'/'||to_char(SS2)||'  ��� '||to_char(nvl(q.INN2,'--')) TEXTOSH
                          from q
                          where nvl(q.INN1,'--')<>nvl(q.INN2,'--')  
                UNION        
                -- -- ������ ������ ���������� ���������  
                Select 2003 KODOSH, NOM_VKL, NOM_IPS, SSYLKA_SIPS SSYLKA, SSYLKA_TIP, GF_PERSON, FIO1 FIO, DR1 DATA_ROGD, SNR1 NALRES_STATUS, INN1 INN,
                          FIO2||'   ��� '||to_char(NV2)||'/'||to_char(SS2)||'  ��� '||to_char(q.SNR2) TEXTOSH
                          from q
                          where q.SNR1<>q.SNR2
            )                      
     ) order by  KODOSH, FIO      
     ; -- ����� ������� �� �������
   
exception
   when OTHERS then   pErrInfo := SQLERRM;     
end Oshibki_vSpisNalPlat;


    -- ������������� �������� ������� 
    function Init_SchetchikSpravok( pKodNA in number, pGod in number, pTipDox in number, pNomKorr in number ) return number as
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
     begin
     
        if pNomKorr=99 then return 2; end if; -- ��� ������ ����� �������� �� �������������, � �������� ��������
     
        insert into f2ndfl_arh_nomspr(
          kod_na,
          god,
          ssylka,
          tip_dox,
          flag_otmena
        ) select ld.kod_na,
                 ld.god,
                 ld.ssylka,
                 ld.tip_dox,
                 ld.kor_otmena
          from   fnd.f2ndfl_load_spravki ld
           left  join f2ndfl_arh_nomspr ss
            on   ss.kod_na = ld.kod_na
            and  ss.god = ld.god
            and  ss.ssylka = ld.ssylka
            and  ss.tip_dox = ld.tip_dox
            and  ss.flag_otmena = ld.kor_otmena
          where  ss.kod_na is null -- ������ ��, ��� ��� �� ���������
          and    ld.kod_na = pkodna
          and    ld.god = pgod
          and    ld.tip_dox = ptipdox
          and    ld.nom_korr = pnomkorr;
      
        Commit;
        return 0;
        
     exception
        
        when OTHERS then
           Rollback;
           return 1;   
           
     end Init_SchetchikSpravok;
     
-- �������� SSYLKA � FK_CONTRAGENT � �������� ������� ��� KOD_NA=1
   function SbrosIdent_GAZFOND( pGod in number ) return number as     
   begin
    
        Update F2NDFL_ARH_NOMSPR ns
        set ns.SSYLKA_FL=Null,
             ns.FK_CONTRAGENT=Null
        where KOD_NA=1   -- ������ ��� �������                 
           and GOD=pGod
           and FLAG_OTMENA=0;
           
        Commit;   
        
        return 0;
        
     exception
        
        when OTHERS then
           Rollback;
           return 1;   
           
     end SbrosIdent_GAZFOND;   
     
-- ��������� �������-��������� ������� �� ������� LOAD_SPRAVKI ��� ��������� ����
-- �������������� ������������ InitGlobals
procedure Load_Numerator as
dTermBeg  date;
dTermEnd  date;
begin 

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;

    -- ������� ��������� ��� �������� ���������� ������ � ����
    Delete from F2NDFL_ARH_NOMSPR where KOD_NA=gl_KODNA and GOD=gl_GOD;

    -- ��������� ����� (������ � ��������)
    Insert into F2NDFL_ARH_NOMSPR( KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, SSYLKA_FL, UI_PERSON )
    Select  
       ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, 0 FLAG_OTMENA, sfl.GF_PERSON FK_CONTRAGENT, sfl.SSYLKA SSYLKA_FL, sfl.GF_PERSON UI_PERSON
    from f2NDFL_LOAD_SPRAVKI ls
         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=ls.SSYLKA
    where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX in (1,3) and ls.NOM_KORR=gl_NOMKOR;  

    -- ���������� �������
    Insert into F2NDFL_ARH_NOMSPR( KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, SSYLKA_FL, UI_PERSON )
    Select  
       ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, 0 FLAG_OTMENA, vp.GF_PERSON FK_CONTRAGENT, vp.SSYLKA_POLUCH SSYLKA_FL, vp.GF_PERSON UI_PERSON
    from f2NDFL_LOAD_SPRAVKI ls
         inner join (
                     Select distinct SSYLKA, SSYLKA_POLUCH, GF_PERSON  
                        from  VYPLACH_POSOB 
                        where DATA_VYPL >= dTermBeg
                          and DATA_VYPL <  dTermEnd
                          and TIP_VYPL=1010
                          and NOM_VIPL=1
                    ) vp on vp.SSYLKA=ls.SSYLKA
    where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=2 and ls.NOM_KORR=gl_NOMKOR; 

    -- ��������� �����
    Insert into F2NDFL_ARH_NOMSPR( KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, SSYLKA_FL, UI_PERSON )
    Select  
       ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, 0 FLAG_OTMENA, Null FK_CONTRAGENT, Null SSYLKA_FL, ls.SSYLKA UI_PERSON
    from f2NDFL_LOAD_SPRAVKI ls
    where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=9 and ls.NOM_KORR=gl_NOMKOR;

    Commit;

end Load_Numerator;        
     
-- ���������� SSYLKA � FK_CONTRAGENT � ������� ��� KOD_NA=1
   function UstIdent_GAZFOND( pGod in number ) return number as
   dTermBeg date;
   dTermEnd date;
   begin

        dTermBeg := to_date( '01.01.'||trim(to_char(pGOD  ,'0000')),'dd.mm.yyyy');
        dTermEnd := to_date( '01.01.'||trim(to_char(pGOD+1,'0000')),'dd.mm.yyyy');

/*
    ���������� ������ ����������
    ����� ������ ��� ������� � ��������� ���������   

        Update F2NDFL_ARH_NOMSPR 
              set SSYLKA_FL = SSYLKA
              where SSYLKA_FL is Null 
                 and GOD=pGod
                 and FLAG_OTMENA=0
                 and KOD_NA=1   -- ������ ��� �������
                 and TIP_DOX in (1,3);   -- ������ � ��������
        Commit;
        
*/
     
/* ��� ��� �������
   ����� ����������� ������� ������ ������
   
   ���� ������ ��� ����� ������������� 
      
        Update F2NDFL_ARH_NOMSPR ns
        set ns.SSYLKA_FL 
             = (Select distinct SSYLKA_POLUCH from  VYPLACH_POSOB vp 
                     where vp.SSYLKA=mod(ns.SSYLKA,100000000) 
                         and vp.NOM_VIPL= trunc(ns.SSYLKA/100000000)+1
                          and vp.SSYLKA_POLUCH>0) 
        where KOD_NA=1 and TIP_DOX=2   -- ����������
            and GOD=pGod
            and FLAG_OTMENA=0
            and SSYLKA_FL is Null 
            and SSYLKA>100000000             -- ���� ������ ������
            and (Select distinct SSYLKA_POLUCH from  VYPLACH_POSOB vp 
                       where vp.SSYLKA=mod(ns.SSYLKA,100000000) 
                           and vp.NOM_VIPL= trunc(ns.SSYLKA/100000000)+1
                           and vp.SSYLKA_POLUCH>0)>0;
        Commit;
*/        

/*
    ����� ���� ��� �� �����
    ������ ��� ������� ������� � ��������� �����������

        Update F2NDFL_ARH_NOMSPR ns
        set ns.SSYLKA_FL 
             = (Select distinct SSYLKA_POLUCH from  VYPLACH_POSOB vp 
                     where vp.SSYLKA=ns.SSYLKA and vp.NOM_VIPL=1
                         and vp.SSYLKA_POLUCH>0)
        where KOD_NA=1 and TIP_DOX=2   -- ����������
            and GOD=pGod
            and FLAG_OTMENA=0
            and SSYLKA_FL is Null
            and SSYLKA<100000000             -- ������ ���������
            and  (Select distinct SSYLKA_POLUCH from  VYPLACH_POSOB vp 
                          where vp.SSYLKA=ns.SSYLKA and vp.NOM_VIPL=1
                             and SSYLKA_POLUCH>0
                             and vp.SSYLKA_POLUCH>0) >0;    
        Commit;
*/        

/*
   � ���������� ��� ������� �����������
   
        Update F2NDFL_ARH_NOMSPR ns
        set ns.FK_CONTRAGENT
           = (Select tc.FK_CONTRAGENT from gazfond.Transform_Contragents tc
                      where tc.SSYLKA_FL=ns.SSYLKA_FL)
        where KOD_NA=1    
           and GOD=pGod
           and FLAG_OTMENA=0
           and SSYLKA_FL is not Null
           and FK_CONTRAGENT is Null;
        Commit;   
*/     


-- �������, ������� ������ �� �����!
   
        return 0;
        
     exception
        
        when OTHERS then
           Rollback;
           return 1;   
           
     end UstIdent_GAZFOND;     
     
-- ���������� ���, ���� �� �� ��������, �� ���� ������ ������� � ��� ��� ���� �� �����������
    function ZapolnINN_izDrSpravki( pGod in number )  return number as
    CAID number;
    LINN varchar2(20);
    begin
    
        CAID:=-1;
        
        for rec in ( Select * from (   
                            Select         
                                   count(*) over(partition by ns.FK_CONTRAGENT) CCID,
                                   count(*) over(partition by ns.FK_CONTRAGENT, ls.INN_FL) CFLD,
                                   ns.FK_CONTRAGENT,  
                                   ls.* 
                            from  f2NDFL_ARH_NOMSPR ns
                                     inner join f2NDFL_LOAD_SPRAVKI ls
                                                   on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0
                               where FK_CONTRAGENT 
                                         in (Select FK_CONTRAGENT from  f2NDFL_ARH_NOMSPR 
                                                   where FK_CONTRAGENT is not Null 
                                                   group by FK_CONTRAGENT 
                                                   having count(*)>1)      
                            ) where CCID<>CFLD    
                              order by FK_CONTRAGENT, INN_FL    
                        )
        loop
            
            if CAID<>rec.FK_CONTRAGENT 
                then CAID:=rec.FK_CONTRAGENT; 
                       if rec.INN_FL is not Null  then LINN:= rec.INN_FL;  end if;
                else
                    if rec.INN_FL is not Null
                       then LINN:= rec.INN_FL;
                       else
                              Update f2NDFL_LOAD_SPRAVKI  
                                Set INN_FL = LINN
                              where KOD_NA=rec.KOD_NA and GOD=rec.GOD and SSYLKA=rec.SSYLKA and TIP_DOX=rec.TIP_DOX and NOM_KORR=rec.NOM_KORR
                                        and INN_FL is Null;
                       end if;  
            end if;
            
        end loop;
        
        Commit;
    
        return 0;
        
     exception
        
        when OTHERS then
           Rollback;
           return 1;   
           
     end ZapolnINN_izDrSpravki;     
     
-- ���������� ����������� �� �������� ��     
   function ZapolnGRAZHD_poUdLichn( pGod in number ) return number as
   begin
   
       Update f2NDFL_LOAD_SPRAVKI
          set GRAZHD=643,
               ZAM_GRA=GRAZHD
          where GRAZHD is Null
             and KOD_UD_LICHN=21;
       Commit;
       
       /*
       Update   f2NDFL_LOAD_SPRAVKI
            set KOD_UD_LICHN=21,
                 ZAM_KUL=KOD_UD_LICHN
            where KOD_UD_LICHN<>21 
               and GRAZHD=643
               and regexp_like(SER_NOM_DOC,'^\d{2}\s\d{2}\s\d{6}$');  
       */
    
       return 0;
        
     exception
        
        when OTHERS then
           Rollback;
           return 1;   
           
     end ZapolnGRAZHD_poUdLichn;   
     
procedure RaznDan_Kontragenta( pReportCursor out sys_refcursor, pErrInfo out varchar2, pGod in number ) as
begin

   open pReportCursor for  
   
        Select * from (   
                Select  '���_�'  ERFLD,
                        count(*) over(partition by ns.FK_CONTRAGENT, ls.FAMILIYA) CFLD,
                        ns.CCID,
                        ns.FK_CONTRAGENT,  
                        ls.* 
                    from  ( Select * from(
                           Select KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, count(*) over( partition by FK_CONTRAGENT) CCID 
                           from  f2NDFL_ARH_NOMSPR 
                               where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and FK_CONTRAGENT is not Null 
                           ) where CCID>1    
                       ) ns
                    inner join f2NDFL_LOAD_SPRAVKI ls
                                   on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0            
                ) where CCID<>CFLD         

        Union   
                 
        Select * from (   
                Select  '���_�'  ERFLD,
                        count(*) over(partition by ns.FK_CONTRAGENT, ls.IMYA) CFLD,
                        ns.CCID,
                        ns.FK_CONTRAGENT,  
                        ls.* 
                    from  ( Select * from(
                           Select KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, count(*) over( partition by FK_CONTRAGENT) CCID 
                           from  f2NDFL_ARH_NOMSPR 
                               where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and FK_CONTRAGENT is not Null 
                           ) where CCID>1    
                       ) ns
                    inner join f2NDFL_LOAD_SPRAVKI ls
                                   on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0            
                ) where CCID<>CFLD         

        Union             
                  
        Select * from (   
                Select  '���_�'  ERFLD,
                        count(*) over(partition by ns.FK_CONTRAGENT, ls.OTCHESTVO) CFLD,
                        ns.CCID,
                        ns.FK_CONTRAGENT,  
                        ls.* 
                    from  ( Select * from(
                           Select KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, count(*) over( partition by FK_CONTRAGENT) CCID 
                           from  f2NDFL_ARH_NOMSPR 
                               where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and FK_CONTRAGENT is not Null 
                           ) where CCID>1    
                       ) ns
                    inner join f2NDFL_LOAD_SPRAVKI ls
                                   on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0            
                ) where CCID<>CFLD          

        Union

        Select * from (   
                Select  '��'  ERFLD,
                        count(*) over(partition by ns.FK_CONTRAGENT, ls.DATA_ROZHD) CFLD,
                        ns.CCID,
                        ns.FK_CONTRAGENT,  
                        ls.* 
                    from  ( Select * from(
                           Select KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, count(*) over( partition by FK_CONTRAGENT) CCID 
                           from  f2NDFL_ARH_NOMSPR 
                               where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and FK_CONTRAGENT is not Null 
                           ) where CCID>1    
                       ) ns
                    inner join f2NDFL_LOAD_SPRAVKI ls
                                   on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0            
                ) where CCID<>CFLD          

        Union

        Select * from (   
                Select  '�����'  ERFLD,
                        count(*) over(partition by ns.FK_CONTRAGENT, ls.SER_NOM_DOC) CFLD,
                        ns.CCID,
                        ns.FK_CONTRAGENT,  
                        ls.* 
                    from  ( Select * from(
                           Select KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, count(*) over( partition by FK_CONTRAGENT) CCID 
                           from  f2NDFL_ARH_NOMSPR 
                               where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and FK_CONTRAGENT is not Null 
                           ) where CCID>1    
                       ) ns
                    inner join f2NDFL_LOAD_SPRAVKI ls
                                   on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0            
                ) where CCID<>CFLD       

        Union

        Select * from (   
                Select  '�����'  ERFLD,
                        count(*) over(partition by ns.FK_CONTRAGENT, ls.GRAZHD) CFLD,
                        ns.CCID,
                        ns.FK_CONTRAGENT,  
                        ls.* 
                    from  ( Select * from(
                           Select KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, count(*) over( partition by FK_CONTRAGENT) CCID 
                           from  f2NDFL_ARH_NOMSPR 
                               where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and FK_CONTRAGENT is not Null 
                           ) where CCID>1    
                       ) ns
                    inner join f2NDFL_LOAD_SPRAVKI ls
                                   on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0            
                ) where CCID<>CFLD 
                
        Union

        Select * from (   
                Select  '���'  ERFLD,
                        count(*) over(partition by ns.FK_CONTRAGENT, ls.INN_FL) CFLD,
                        ns.CCID,
                        ns.FK_CONTRAGENT,  
                        ls.* 
                    from  ( Select * from(
                           Select KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, count(*) over( partition by FK_CONTRAGENT) CCID 
                           from  f2NDFL_ARH_NOMSPR 
                               where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and FK_CONTRAGENT is not Null 
                           ) where CCID>1    
                       ) ns
                    inner join f2NDFL_LOAD_SPRAVKI ls
                                   on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0            
                ) where CCID<>CFLD   

        Union

        Select * from (   
                Select  '������'  ERFLD,
                        count(*) over(partition by ns.FK_CONTRAGENT, ls.STATUS_NP) CFLD,
                        ns.CCID,
                        ns.FK_CONTRAGENT,  
                        ls.* 
                    from  ( Select * from(
                           Select KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, FK_CONTRAGENT, count(*) over( partition by FK_CONTRAGENT) CCID 
                           from  f2NDFL_ARH_NOMSPR 
                               where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and FK_CONTRAGENT is not Null 
                           ) where CCID>1    
                       ) ns
                    inner join f2NDFL_LOAD_SPRAVKI ls
                                   on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0            
                ) where CCID<>CFLD   
                ; 
                         
        
     pErrInfo := Null; 
 
     exception
        when OTHERS then pErrInfo := SQLERRM;     
           
     end RaznDan_Kontragenta;     
     
procedure Vastavka_SOOTV_iz_XMLIN as
begin
-- ��� ������� ������
/*
Insert into GNI_ADR_SOOTV (
   SSYLKA, 
   TIP_ADR, 
   TIP_DOX,  
   DAT_ISP, 
   STR_NAM, 
   REG_NAM, 
   REG_SKR, 
   RON_NAM, 
   RON_SKR, 
   GOR_NAM, 
   GOR_SKR, 
   PUN_NAM, 
   PUN_SKR, 
   ULI_NAM, 
   ULI_SKR, 
   STR_KOD, 
   REG_GNK, 
   RON_GNK, 
   GOR_GNK, 
   PUN_GNK, 
   ULI_GNK, 
   ADR_FND, 
   ADR_SRC, 
   PINDEX,  
   TXT_DOM, 
   TXT_KOR, 
   TXT_KV
)  --FROM FND.GNI_ADR_SOOTV;
Select ad.SSYLKA,
          -(ad.KOD_NA*10+ad.TIP_DOX) TIP_ADR,
          ad.TIP_DOX,  
          Null DAT_ISP,
          (Select NAZV from GNI_STRANY where NB_KOD=STR_KOD) STR_NAM,
          (Select NAZV from GNI_KLADR where KLCODE=REG_KOD||'00000000000') REG_NAM,
          (Select SOCR from GNI_KLADR where KLCODE=REG_KOD||'00000000000') REG_SKR,
          trim(regexp_replace( RAY_TEXT,' \S+$','' )) RON_NAM,
          trim(regexp_substr( RAY_TEXT,' \S+$' )) RON_SKR,       
          trim(regexp_replace( GOR_TEXT,' \S+$','' )) GOR_NAM,
          trim(regexp_substr( GOR_TEXT,' \S+$' )) GOR_SKR,  
          trim(regexp_replace( PUN_TEXT,' \S+$','' )) PUN_NAM,
          trim(regexp_substr( PUN_TEXT,' \S+$' )) PUN_SKR,       
          trim(regexp_replace( ULI_TEXT,' \S+$','' )) ULI_NAM,
          trim(regexp_substr( ULI_TEXT,' \S+$' )) ULI_SKR,       
          STR_KOD,     
          REG_KOD||'00000000000' REG_GNK,
   Null RON_GNK, 
   Null GOR_GNK, 
   Null PUN_GNK, 
   Null ULI_GNK,
   Null ADR_FND, 
   -2 ADR_SRC,
   ad.PINDEX,
   ad.DOM_TEXT TXT_DOM,
   ad.KOR_TEXT TXT_KOR,
   AD.KV_TEXT TXT_KV
from f2NDFL_XMLIN_ADR ad;
*/
  Null;
end;    

-- �������� ������ �����������, ��� ������� ������� ����������� ���������� ������, ��������: ���, �������
   procedure SovpDan_Kontragentov( pReportCursor out sys_refcursor, pErrInfo out varchar2, pGod in number ) as
   begin 
   
       open pReportCursor for  
   
           Select 
            ns.SUM_CODE,
            case ns.SUM_CODE
            when 1 then '���'
            when 2 then '���'
            when 3 then '���+���'
            when 4 then '����'
            when 5 then '����+���'
            when 6 then '����+���'
            when 7 then '��'
            else Null
            end  ER_TIP,
            ns.CAID FK_CONTRAGENT, 
            ls.SSYLKA, ls.TIP_DOX, ls.INN_FL, ls.GRAZHD, ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD, ls.KOD_UD_LICHN, ls.SER_NOM_DOC, ls.STATUS_NP
            from f2NDFL_LOAD_SPRAVKI ls
            inner join(
            
                  Select  KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, sum(SOVP_CODE) SUM_CODE, min(FK_CONTRAGENT) CAID from (
                        Select * from(
                        Select 
                            ns.KOD_NA,
                            ns.GOD,
                            ns.SSYLKA,
                            ns.TIP_DOX,
                            ns.FLAG_OTMENA,
                            ns.FK_CONTRAGENT,
                            1 SOVP_CODE,
                            count(*) over( partition by ls.INN_FL) CF,
                            count(*) over( partition by ls.INN_FL, ns.FK_CONTRAGENT ) CK, 
                            count(*) over( partition by ls.INN_FL, ns.UI_PERSON ) CU
                        from f2NDFL_LOAD_SPRAVKI ls
                                inner join f2NDFL_ARH_NOMSPR ns
                                        on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0
                                where ls.INN_FL is not Null
                                  and ls.GOD=pGod        
                        ) where CF<>CU --CF<>CK and CF<>CU 
                        
                        union
                        
                        Select * from(
                        Select 
                            ns.KOD_NA,
                            ns.GOD,
                            ns.SSYLKA,
                            ns.TIP_DOX,
                            ns.FLAG_OTMENA,
                            ns.FK_CONTRAGENT,
                            2 SOVP_CODE,
                            count(*) over( partition by ls.SER_NOM_DOC) CF,
                            count(*) over( partition by ls.SER_NOM_DOC, ns.FK_CONTRAGENT ) CK, 
                            count(*) over( partition by ls.SER_NOM_DOC, ns.UI_PERSON ) CU
                        from f2NDFL_LOAD_SPRAVKI ls
                                inner join f2NDFL_ARH_NOMSPR ns
                                        on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0
                        where ls.GOD=pGod                 
                       ) where CF<>CU --CF<>CK and CF<>CU 
                        
                       union
                       
                       Select * from(
                        Select 
                            ns.KOD_NA,
                            ns.GOD,
                            ns.SSYLKA,
                            ns.TIP_DOX,
                            ns.FLAG_OTMENA,
                            ns.FK_CONTRAGENT,
                            4 SOVP_CODE,
                            count(*) over( partition by  ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD) CF,
                            count(*) over( partition by  ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD, ns.FK_CONTRAGENT ) CK, 
                            count(*) over( partition by  ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD, ns.UI_PERSON ) CU
                        from f2NDFL_LOAD_SPRAVKI ls
                                inner join f2NDFL_ARH_NOMSPR ns
                                        on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0
                        where ls.GOD=pGod                
                        ) where CF<>CU --CF<>CK and CF<>CU 
                        
                  ) group by KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA    
                  
                 )  ns
                 on  ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0     
                 
                 order by ns.SUM_CODE desc, 
                              case ns.SUM_CODE
                                    when 1 then INN_FL||FAMILIYA
                                    when 2 then SER_NOM_DOC||FAMILIYA
                                    when 3 then INN_FL||FAMILIYA
                                    when 4 then FAMILIYA
                                    when 5 then INN_FL||FAMILIYA
                                    when 6 then SER_NOM_DOC||FAMILIYA
                                    when 7 then INN_FL||FAMILIYA
                                    else Null
                                    end ;
                            
     pErrInfo := Null; 
 
     exception
        when OTHERS then pErrInfo := SQLERRM;     
           
     end SovpDan_Kontragentov;     
     
-- �������� ������ ������� � ���������� ������� 
   procedure OshibDan_vSpravke( pReportCursor out sys_refcursor, pErrInfo out varchar2, pGod in number ) as
   begin
   
       open pReportCursor for 
       
       Select          
            ls.ECODE, ls.EINFO,
            ns.FK_CONTRAGENT, 
            ls.SSYLKA, ls.TIP_DOX, ls.INN_FL, ls.GRAZHD, ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD, ls.KOD_UD_LICHN, ls.SER_NOM_DOC, ls.STATUS_NP
            from (
                           Select 1 ECODE, 
                                     '������: ����������� �� ������' EINFO,
                                     x.* 
                                 from f2NDFL_LOAD_SPRAVKI x
                                  where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and GRAZHD is Null
                                  
                       Union
                       
                           Select 2 ECODE, 
                                     '������: ����������� �� �� ������������� ��' EINFO,
                                     x.* 
                                 from f2NDFL_LOAD_SPRAVKI x
                                  where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and GRAZHD=643
                                     and KOD_UD_LICHN in (10,11,12,13,15,19)
                                     
                       Union                                     
                       
                           Select 3 ECODE, 
                                     '������: ����������� ���� �� ������������� �� ��' EINFO,
                                     x.* 
                                 from f2NDFL_LOAD_SPRAVKI x
                                  where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and (GRAZHD<>643)
                                     and (KOD_UD_LICHN not in (10,11,12,13,15,19,23))
                       
                       Union                                     
                       
                           Select 4 ECODE, 
                                     '������: ��� �� ����������� ��������' EINFO,
                                     x.* 
                                 from f2NDFL_LOAD_SPRAVKI x
                                  where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and KOD_UD_LICHN not in (3,7,8,10,11,12,13,14,15,19,21,23,24,91) 
                                  
                       Union                                     
                       
                           Select 6 ECODE, 
                                     '������: ������������ ������ �������� ��' EINFO,
                                     x.* 
                                 from f2NDFL_LOAD_SPRAVKI x
                                  where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and KOD_UD_LICHN =21 and not regexp_like(SER_NOM_DOC,'^\d{2}\s\d{2}\s\d{6}$')            
                                  
                       Union                                     
                       
                           Select 7 ECODE, 
                                     '������: ������������ ������ ���� �� ���������� � ��' EINFO,
                                     x.* 
                                 from f2NDFL_LOAD_SPRAVKI x
                                  where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and KOD_UD_LICHN =12 and not regexp_like(SER_NOM_DOC,'^\d{2}\s\d{7}$')            
                                  
                       Union                                     
                       
                           Select 91 ECODE, 
                                     '��������������: ��������� �������� � ����������� ��� �� �� ��' EINFO,
                                     x.* 
                                 from f2NDFL_LOAD_SPRAVKI x
                                  where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and STATUS_NP=1 
                                    and  ((GRAZHD is Null or GRAZHD<>643) and KOD_UD_LICHN in (10,11,13,15,19))   
                       
                       Union                                     
                       
                           Select 92 ECODE, 
                                     '��������������: ��������� �������� � ��� �� ���������� ��' EINFO,
                                     x.* 
                                 from f2NDFL_LOAD_SPRAVKI x
                                  where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and STATUS_NP=1 
                                    and  ((GRAZHD is Null or GRAZHD<>643) and KOD_UD_LICHN=12)
                                      
                       Union 
                                                          
                           Select 93 ECODE, 
                                     '��������������: �������� ����������� � ������ ������������� ������������� ���� �������� ��' EINFO,
                                     x.* 
                                 from f2NDFL_LOAD_SPRAVKI x
                                  where KOD_NA=1 and GOD=pGOD and TIP_DOX>0 and KOD_UD_LICHN<>21 
                                   and GRAZHD=643
                                   and regexp_like(SER_NOM_DOC,'^\d{2}\s\d{2}\s\d{6}$')
                                   
                     ) ls
            inner join f2NDFL_ARH_NOMSPR ns
                                        on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0
            order by ECODE, FAMILIYA;
            
        pErrInfo := Null; 
 
     exception
        when OTHERS then pErrInfo := SQLERRM;     
           
     end OshibDan_vSpravke;  
      
     
/*
-- ����������� ����������� �� GAZFOND.IDCARDS.CITIZENSHIP � �������
begin
for rec in (
                Select ic.CITIZENSHIP, ls.* 
                from f2NDFL_LOAD_SPRAVKI ls
                inner join f2NDFL_ARH_NOMSPR ns
                                                        on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0
                inner join gazfond.People pe
                                                        on pe.FK_CONTRAGENT=ns.FK_CONTRAGENT
                inner join gazfond.IdCards ic
                                                        on ic.ID=pe.FK_IDCARD          
                                                        
                where ((ic.CITIZENSHIP<>ls.GRAZHD) or (ls.GRAZHD is Null and ic.CITIZENSHIP is not Null))       
                          and ic.SERIES||' '||ic.NBR=ls.SER_NOM_DOC    
                          and ls.TIP_DOX in (1,3)
                )
loop
    Update f2NDFL_LOAD_SPRAVKI
       set GRAZHD = trim(to_char(rec.CITIZENSHIP,'000'))
       where SSYLKA=rec.SSYLKA and TIP_DOX=rec.TIP_DOX;        
end loop;
Commit;
end;      
     */
     
/*

-- ����������� UI_PERSON
-- ������ ������ ������ ������������ � ���� �������
-- ��� ���������� �Ѩ � ����+��

declare 
UIP number;
CID number;
begin
 UIP :=  -1;
 for rec in ( 
     Select 
            ns.SUM_CODE,
            min(rownum) over(partition by ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD,  ls.SER_NOM_DOC ) UIP,
            ns.CAID FK_CONTRAGENT, 
            ls.SSYLKA, ls.TIP_DOX, ls.INN_FL, ls.GRAZHD, ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD, ls.KOD_UD_LICHN, ls.SER_NOM_DOC, ls.STATUS_NP
            from f2NDFL_LOAD_SPRAVKI ls
            inner join(
            
                  Select  KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA, sum(SOVP_CODE) SUM_CODE, min(FK_CONTRAGENT) CAID from (
                        Select * from(
                        Select 
                            ns.KOD_NA,
                            ns.GOD,
                            ns.SSYLKA,
                            ns.TIP_DOX,
                            ns.FLAG_OTMENA,
                            ns.FK_CONTRAGENT,
                            1 SOVP_CODE,
                            count(*) over( partition by ls.INN_FL) CF,
                            count(*) over( partition by ls.INN_FL, ns.FK_CONTRAGENT ) CK, 
                            count(*) over( partition by ls.INN_FL, ns.UI_PERSON ) CU
                        from f2NDFL_LOAD_SPRAVKI ls
                                inner join f2NDFL_ARH_NOMSPR ns
                                        on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0
                                where ls.INN_FL is not Null        
                        ) where CF<>CK and CF<>CU 
                        
                        union
                        
                        Select * from(
                        Select 
                            ns.KOD_NA,
                            ns.GOD,
                            ns.SSYLKA,
                            ns.TIP_DOX,
                            ns.FLAG_OTMENA,
                            ns.FK_CONTRAGENT,
                            2 SOVP_CODE,
                            count(*) over( partition by ls.SER_NOM_DOC) CF,
                            count(*) over( partition by ls.SER_NOM_DOC, ns.FK_CONTRAGENT ) CK, 
                            count(*) over( partition by ls.SER_NOM_DOC, ns.UI_PERSON ) CU
                        from f2NDFL_LOAD_SPRAVKI ls
                                inner join f2NDFL_ARH_NOMSPR ns
                                        on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0
                       ) where CF<>CK and CF<>CU
                        
                       union
                       
                       Select * from(
                        Select 
                            ns.KOD_NA,
                            ns.GOD,
                            ns.SSYLKA,
                            ns.TIP_DOX,
                            ns.FLAG_OTMENA,
                            ns.FK_CONTRAGENT,
                            4 SOVP_CODE,
                            count(*) over( partition by  ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD) CF,
                            count(*) over( partition by  ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD, ns.FK_CONTRAGENT ) CK, 
                            count(*) over( partition by  ls.FAMILIYA, ls.IMYA, ls.OTCHESTVO, ls.DATA_ROZHD, ns.UI_PERSON ) CU
                        from f2NDFL_LOAD_SPRAVKI ls
                                inner join f2NDFL_ARH_NOMSPR ns
                                        on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0
                        ) where CF<>CK and CF<>CU
                        
                  ) group by KOD_NA, GOD, SSYLKA, TIP_DOX, FLAG_OTMENA    
                  
                 )  ns
                 on  ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX and ns.FLAG_OTMENA=0 and ls.NOM_KORR=0     
                 where SUM_CODE in (7,6)
                 order by ns.SUM_CODE desc, UIP, FK_CONTRAGENT
  ) loop
  
      if UIP<>rec.UIP then
         UIP:=rec.UIP;
         CID:=rec.FK_CONTRAGENT;
      end if;
  
      Update f2NDFL_ARH_NOMSPR ns
         set ns.UI_PERSON = CID
         where ns.KOD_NA=1 and ns.GOD=2015 and ns.SSYLKA=rec.SSYLKA and ns.TIP_DOX=rec.TIP_DOX and ns.FLAG_OTMENA=0;
  
    end loop;
    
end;               
                              
*/     

/*
-- ���������� ������� � ������ �������

INSERT INTO FND.F2NDFL_ARH_ADR ( R_SPRID, KOD_STR, ADR_INO, PINDEX, KOD_REG, RAYON, GOROD, PUNKT, ULITSA, DOM, KOR, KV)  
Select 
          sp.ID,
          STR_KOD,
          Null ADR_FND,
          PINDEX,
          substr(PUN_GNK,1,2) REG,
          (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(PUN_GNK,1,5)||'00000000') RON,
          (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(PUN_GNK,1,8)||'00000') GOR,
          (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=PUN_GNK) PUN,
          (Select NAZV||' '||SOCR from GNI_STREET where KLCODE=ULI_GNK) ULI,
          TXT_DOM,
          TXT_KOR,
          TXT_KV
          from GNI_ADR_SOOTV ga
                  inner join f2NDFL_ARH_NOMSPR ns
                     on ns.KOD_NA=ga.ADR_SRC and ns.GOD=2015 and ns.SSYLKA=ga.SSYLKA and ns.TIP_DOX=ga.TIP_DOX and ns.FLAG_OTMENA=0
                  inner join f2NDFL_ARH_SPRAVKI sp 
                      on sp.KOD_NA=ns.KOD_NA and sp.GOD=ns.GOD and sp.NOM_SPR=ns.NOM_SPR 
             where ga.TIP_DOX=9 and ga.ADR_SRC=2 and ga.TIP_ADR=-29 
                and ga.STR_KOD=643
UNION
Select 
          sp.ID,
          STR_KOD,
          ADR_FND,
          Null PINDEX,
          Null  REG,
          Null  RON,
          Null  GOR,
          Null  PUN,
          Null  ULI,
          Null TXT_DOM,
          Null  TXT_KOR,
          Null TXT_KV
          from GNI_ADR_SOOTV ga
                  inner join f2NDFL_ARH_NOMSPR ns
                     on ns.KOD_NA=ga.ADR_SRC and ns.GOD=2015 and ns.SSYLKA=ga.SSYLKA and ns.TIP_DOX=ga.TIP_DOX and ns.FLAG_OTMENA=0
                  inner join f2NDFL_ARH_SPRAVKI sp 
                      on sp.KOD_NA=ns.KOD_NA and sp.GOD=ns.GOD and sp.NOM_SPR=ns.NOM_SPR 
             where ga.TIP_DOX=9 and ga.ADR_SRC=2 and ga.TIP_ADR=-29 and sp.GOD=2015
                 and ga.STR_KOD<>643          
;

*/

-- ������������� ������� ��� ���������� ������ � �������� ����
-- begin  RC:= FXNDFL_UTIL.Numerovat_Spravki( 1, 2016 ); end;
procedure Numerovat_Spravki( pKodNA in number, pGod in number ) as
  
  nNomSprav number;
  cNomSprav varchar2(10);
  nArhSprId   number;
  
  begin
  
    execute immediate 'ALTER SESSION SET NLS_SORT = RUSSIAN';
  
        
        -- ������ ������������ �������� ����� ������� ��� �� ��� ��� ��
        Select max(ns.NOM_SPR) into cNomSprav from f2NDFL_ARH_NOMSPR ns where ns.KOD_NA=pKodNA and ns.GOD=pGod;
        nNomSprav:=to_number( nvl(cNomSprav,'0'));
        -- ���� ������ ��� �� ����������, �� ��������� �� ��������� ��������
        Case  pKodNA
          when 1 then  
                if nNomSprav<100 then nNomSprav:=100; end if;      
          --when 2 then  
          --      if nNomSprav<50 then nNomSprav:=50; end if;
          else raise_application_error( -20001,'��� ���������� ������ �� ����� 1');
        end case;                    
  
                for rec in(
                           Select q.*
                              from (                                                 
                                    Select  ns.UI_PERSON,
                                            count(*) over(partition by ns.UI_PERSON order by ns.UI_PERSON rows unbounded preceding)  RPTCNT,
                                            ls.*
                                    from f2NDFL_LOAD_SPRAVKI ls
                                            inner join f2NDFL_ARH_NOMSPR ns
                                              on ns.KOD_NA=ls.KOD_NA and ns.GOD=ls.GOD and ns.SSYLKA=ls.SSYLKA and ns.TIP_DOX=ls.TIP_DOX  
                                    where ls.KOD_NA=pKodNA and ls.GOD=pGod and ls.TIP_DOX>0 and ls.NOM_KORR = 0  -- �������� ������� �������� ������� �� ��� �� ��������� ��
                                      and ns.FLAG_OTMENA=0 and ns.NOM_SPR is Null  -- ������ ��� �� ���� ����������� � �������� �������� �� �������� (����������)     
                                    ) q
                              order by upper(q.FAMILIYA), upper(q.IMYA), upper(q.OTCHESTVO), 
                                       q.DATA_ROZHD, q.UI_PERSON, q.RPTCNT  -- ����� ���������� ��� ��������� � �����        
                          )
                loop
                   
                    -- ��������� ����������� ������� ����� ��������������� ������ ������ �������
                    -- ���������� ����� ������� ������ ��� ������ ������ �� ����� ������
                    if rec.RPTCNT=1 then  
                       nNomSprav:=nNomSprav+1;
                       cNomSprav:=trim(to_char( nNomSprav,'000000'));
                       Insert into f2NDFL_ARH_SPRAVKI
                                   ( R_XMLID, KOD_NA, NOM_SPR, GOD, NOM_KORR, KVARTAL, PRIZNAK_S, INN_FL, INN_INO, 
                                     STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC ) 
                        values ( Null, rec.KOD_NA, cNomSprav, rec.GOD, rec.NOM_KORR, rec.KVARTAL, rec.PRIZNAK, rec.INN_FL, rec.INN_INO, 
                                    rec.STATUS_NP, rec.GRAZHD, rec.FAMILIYA, rec.IMYA, rec.OTCHESTVO, rec.DATA_ROZHD, rec.KOD_UD_LICHN, rec.SER_NOM_DOC )
                       returning ID into nArhSprId;  
                       end if;
                       
                   Update f2NDFL_ARH_NOMSPR ns
                       set ns.NOM_SPR = cNomSprav
                       where ns.KOD_NA=rec.KOD_NA and ns.GOD=rec.GOD and ns.SSYLKA=rec.SSYLKA and ns.TIP_DOX=rec.TIP_DOX 
                          and ns.NOM_SPR is Null and ns.FLAG_OTMENA=0; -- ���� ������ ����� ���������� ���������
                       
                   Update f2NDFL_LOAD_SPRAVKI ls
                       set ls.NOM_SPR = cNomSprav,
                            ls.R_SPRID = nArhSprId
                       where ls.KOD_NA=rec.KOD_NA and ls.GOD=rec.GOD and ls.SSYLKA=rec.SSYLKA and ls.TIP_DOX=rec.TIP_DOX 
                           and ls.NOM_KORR=0;   -- �������� ������ ������� �������� �������
                       
                end loop; -- 52 ���
        
        Commit;
        
        
     exception
        
        when OTHERS then
           Rollback;
           Raise;
   
  end  Numerovat_Spravki;
  
  procedure Numerovat_Spravki_OTKAT( pKodNA in number, pGod in number ) as
  begin
        Update f2NDFL_ARH_NOMSPR ns
            set ns.NOM_SPR = Null
            where ns.KOD_NA=pKodNA and ns.GOD=pGod and ns.TIP_DOX>0 and ns.FLAG_OTMENA=0;
            
        Update f2NDFL_LOAD_SPRAVKI ls
            set ls.NOM_SPR = Null,
                ls.R_SPRID = Null
            where ls.KOD_NA=pKodNA and ls.GOD=pGod and ls.TIP_DOX>0 and ls.NOM_KORR=0;     
            
        Delete from f2NDFL_ARH_SPRAVKI sa
            where sa.KOD_NA=pKodNA and sa.GOD=pGod;       
               
        Commit;
        
    exception
        when OTHERS then
           Rollback;
           Raise;
                         
  end Numerovat_Spravki_OTKAT;
  
  
  
  procedure Numerovat_KorSpravki as
  sprId number;
  begin
    for rec in (Select count(*) over(partition by ls.NOM_SPR order by ls.SSYLKA, ls.TIP_DOX rows unbounded preceding) CNT,
                       ls.*
                    from 
                      f2NDFL_ARH_SPRAVKI sp
                    inner join
                      f2NDFL_ARH_ITOGI it on sp.ID=it.R_SPRID  
                    inner join
                      f2NDFL_ARH_NOMSPR ns on ns.NOM_SPR=sp.NOM_SPR   
                    inner join 
                      f2NDFL_LOAD_SPRAVKI ls on ls.NOM_KORR=1 
                      and ls.KOD_NA=ns.KOD_NA and ls.GOD=ns.GOD and ls.SSYLKA=ns.SSYLKA and ls.TIP_DOX=ns.TIP_DOX  
                    where it.VZYSK_IFNS in (1,2) or it.DOLG_NA>0
                    order by ls.NOM_SPR, ls.SSYLKA, ls.TIP_DOX)
    loop
    
        if rec.CNT=1 then
            Insert into f2NDFL_ARH_SPRAVKI (
               KOD_NA, DATA_DOK, NOM_SPR, GOD, NOM_KORR, KVARTAL, PRIZNAK_S, INN_FL, INN_INO, 
               STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC) 
            values (
               rec.KOD_NA, trunc(SYSDATE), rec.NOM_SPR, rec.GOD, rec.NOM_KORR, rec.KVARTAL, 1, rec.INN_FL, rec.INN_INO, 
               rec.STATUS_NP, rec.GRAZHD, rec.FAMILIYA, rec.IMYA, rec.OTCHESTVO, rec.DATA_ROZHD, rec.KOD_UD_LICHN, rec.SER_NOM_DOC           
               )
            returning f2NDFL_ARH_SPRAVKI.ID into sprId;
        end if;

        Update f2NDFL_LOAD_SPRAVKI ls
           set ls.R_SPRID = sprId,
               ls.DATA_DOK = trunc(SYSDATE)
           where ls.KOD_NA=rec.KOD_NA and ls.GOD=rec.GOD and ls.SSYLKA=rec.SSYLKA and ls.TIP_DOX=rec.TIP_DOX and ls.NOM_KORR=rec.NOM_KORR;    
               
    end loop;

 -- Commit;
 -- exception
 --    when OTHERS then Rollback; Raise;  
    
  end Numerovat_KorSpravki;
  

-- ���������� ������� � �������� � �����
-- �� �����  ������ ��������� ������� ���������� ��� ���������
/*
  function KopirSpr_vArhiv( pKodNA in number, pGod in number ) return number as
  begin

       Insert into f2NDFL_ARH_SPRAVKI (
                KOD_NA, DATA_DOK, NOM_SPR, GOD, NOM_KORR, KVARTAL, PRIZNAK_S, 
                INN_FL, INN_INO, STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, 
                DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC )         
       Select 
                pKodNA, trunc(SYSDATE) DATA_DOK, NOM_SPR, GOD, NOM_KORR, KVARTAL, PRIZNAK, 
                INN_FL, INN_INO, STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, 
                DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC 
       from f2NDFL_LOAD_SPRAVKI       
       where NOM_SPR is not Null
          and KOD_NA=pKodNA and GOD=pGod;    
       
       Commit;
       
       return 0;
        
     exception
        
        when OTHERS then
           Rollback;
           return 1;
              
  end  KopirSpr_vArhiv;    
*/
  
-- ���������� ����� �� �������� � �����
  procedure KopirSprItog_vArhiv( pKodNA in number, pGod in number ) as
  begin
      
        Insert into f2NDFL_ARH_ITOGI ( R_SPRID, KOD_STAVKI, SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, SUM_OBL_NU, SUM_NAL_PER, DOLG_NA, VZYSK_IFNS )
        -- 13% (���������� � ��������� ������������ ������)
            Select rs.R_SPRID, 13 KOD_STAVKI, rs.DOX SGD_SUM, rs.BASA SUM_OBL, rs.NALI SUM_OBL_NI, 0 SUM_FIZ_AVANS, 
                   rs.NALU SUM_OBL_NU, rs.NALU SUM_NAL_PER, round(GREATEST( NALU - NALI,0 ),0) DOLG_NA, round(GREATEST( NALI - NALU,0 ),0) VZYSK_IFNS
            from(
                Select R_SPRID, DOX, VYCH, NAL NALU, BASA, round(0.13*BASA,0) NALI 
                from(
                    Select R_SPRID, DOX, VYCH, NAL, greatest(DOX-VYCH,0) BASA
                    from(
                        Select R_SPRID, sum(SGD_SUM) DOX, sum(ALLVYCH) VYCH, sum(SUM_OBL_NU) NAL
                        from (
                                Select ls.R_SPRID, it.*, nvl(vc.SGD_VYCH,0) ALLVYCH 
                                from f2NDFL_LOAD_ITOGI it
                                     inner join f2NDFL_LOAD_SPRAVKI ls
                                        on ls.KOD_NA=it.KOD_NA and ls.GOD=it.GOD and ls.SSYLKA=it.SSYLKA and ls.TIP_DOX=it.TIP_DOX and ls.NOM_KORR=it.NOM_KORR
                                     inner join f2NDFL_ARH_NOMSPR ns 
                                        on ns.KOD_NA=it.KOD_NA and ns.GOD=it.GOD and ns.SSYLKA=it.SSYLKA and ns.TIP_DOX=it.TIP_DOX and ns.FLAG_OTMENA=0 and it.NOM_KORR=0
                                     left join (
                                        Select KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, sum(SGD_VYCH_PRED) SGD_VYCH
                                        from(
                                          Select KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, sum(VYCH_SUM) SGD_VYCH_PRED 
                                                from F2NDFL_LOAD_VYCH
                                                where KOD_NA=pKodNA and GOD=pGod
                                                group by KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI    
                                          union all
                                          Select KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, sum(VYCH_SUM) SGD_VYCH_PRED             
                                                from F2NDFL_LOAD_MES
                                                where KOD_NA=pKodNA and GOD=pGod and VYCH_KOD_GNI>0
                                                group by KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI
                                         ) group by KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI           
                                     ) vc
                                     on vc.KOD_NA=it.KOD_NA and vc.GOD=it.GOD and vc.SSYLKA=it.SSYLKA and vc.TIP_DOX=it.TIP_DOX 
                                        and vc.NOM_KORR=it.NOM_KORR and vc.KOD_STAVKI=it.KOD_STAVKI
                                 where it.KOD_NA=pKodNA and it.GOD=pGod and it.KOD_STAVKI=13 
                             ) group by R_SPRID   
                        )   
                    )     
                ) rs      
        union all
        -- 30% (���������� �� ������� ��, ��� ��������� ��� �������� ������ �� ������ 30)
            Select rs.R_SPRID, 30 KOD_STAVKI, rs.DOX SGD_SUM, rs.DOX SUM_OBL, rs.NALI SUM_OBL_NI, 0 SUM_FIZ_AVANS, 
                   rs.NALU SUM_OBL_NU, rs.NALU SUM_NAL_PER, round(GREATEST( NALU - NALI,0 ),0) DOLG_NA, round(GREATEST( NALI - NALU,0 ),0) VZYSK_IFNS
            from(
                 Select ls.R_SPRID, sum(SGD_SUM) DOX, sum(SUM_OBL_NI) NALI,  sum(SUM_OBL_NU) NALU
                    from f2NDFL_LOAD_ITOGI it
                         inner join f2NDFL_LOAD_SPRAVKI ls
                            on ls.KOD_NA=it.KOD_NA and ls.GOD=it.GOD and ls.SSYLKA=it.SSYLKA and ls.TIP_DOX=it.TIP_DOX and ls.NOM_KORR=it.NOM_KORR
                         inner join f2NDFL_ARH_NOMSPR ns 
                            on ns.KOD_NA=it.KOD_NA and ns.GOD=it.GOD and ns.SSYLKA=it.SSYLKA and ns.TIP_DOX=it.TIP_DOX and ns.FLAG_OTMENA=0 and it.NOM_KORR=0
                     where it.KOD_NA=pKodNA and it.GOD=pGod and it.KOD_STAVKI=30  
                     group by ls.R_SPRID                       
                ) rs 
        union all
        -- 35% (������ �������� ��, ��� �������� �����������)
            Select ar.ID R_SPRID, it.KOD_STAVKI, it.SGD_SUM, it.SUM_OBL, it.SUM_OBL_NI, it.SUM_FIZ_AVANS, it.SUM_OBL_NU, it.SUM_NAL_PER, it.DOLG_NA, it.VZYSK_IFNS
            from f2NDFL_LOAD_ITOGI it
                 inner join f2NDFL_ARH_NOMSPR ns 
                    on ns.KOD_NA=it.KOD_NA and ns.GOD=it.GOD and ns.SSYLKA=it.SSYLKA and ns.TIP_DOX=it.TIP_DOX and ns.FLAG_OTMENA=0 and it.NOM_KORR=0
                 inner join f2NDFL_ARH_SPRAVKI ar on ns.KOD_NA=ar.KOD_NA and ns.GOD=ar.GOD and ar.NOM_SPR=ns.NOM_SPR   
             where it.KOD_NA=pKodNA and it.GOD=pGod and it.KOD_STAVKI=35  
        ;

       Commit;
       
        
     exception
        
        when OTHERS then
           Rollback;
           Raise;
              
  end  KopirSprItog_vArhiv;    
  
-- ���������� � ����� ����������� ������ �� ������� � �������� 
procedure KopirSprMes_vArhiv( pKodNA in number, pGod in number )  as
  begin
      
            Insert into f2NDFL_ARH_MES   ( R_SPRID, KOD_STAVKI, MES, DOH_KOD_GNI, DOH_SUM, VYCH_KOD_GNI, VYCH_SUM )
            Select ls.R_SPRID, MO.KOD_STAVKI, MO.MES, MO.DOH_KOD_GNI, sum( MO.DOH_SUM ) DOHSUM, MO.VYCH_KOD_GNI, sum( MO.VYCH_SUM ) VYCHSUM
                from f2NDFL_LOAD_MES mo
                        inner join f2NDFL_LOAD_SPRAVKI ls on ls.KOD_NA=mo.KOD_NA and ls.GOD=mo.GOD and ls.SSYLKA=mo.SSYLKA and ls.TIP_DOX=mo.TIP_DOX and ls.NOM_KORR=mo.NOM_KORR
                where mo.KOD_NA=pKodNA and mo.GOD=pGod 
                group by  ls.R_SPRID, mo.KOD_STAVKI, mo.MES, mo.DOH_KOD_GNI, mo.VYCH_KOD_GNI;  
       Commit;
        
     exception
        
        when OTHERS then
           Rollback;
           Raise;
              
  end KopirSprMes_vArhiv;
  
-- ���������� � ����� ������ �� ������� 
  procedure KopirSprVych_vArhiv( pKodNA in number, pGod in number ) as
  begin
      
        Insert into f2NDFL_ARH_VYCH 
                 ( R_SPRID, KOD_STAVKI, VYCH_KOD_GNI, VYCH_SUM_PREDOST, VYCH_SUM_ISPOLZ )
        Select ls.R_SPRID, MO.KOD_STAVKI, MO.VYCH_KOD_GNI, sum( MO.VYCH_SUM ) VYCHSUM, 0 POLZSUM
            from f2NDFL_LOAD_VYCH mo
                    inner join f2NDFL_LOAD_SPRAVKI ls on ls.KOD_NA=mo.KOD_NA and ls.GOD=mo.GOD and ls.SSYLKA=mo.SSYLKA and ls.TIP_DOX=mo.TIP_DOX and ls.NOM_KORR=mo.NOM_KORR
            where mo.KOD_NA=pKodNA and mo.GOD=pGod 
            group by  ls.R_SPRID, mo.KOD_STAVKI, mo.VYCH_KOD_GNI;
            
       Commit;
        
     exception
        
        when OTHERS then
           Rollback;
           Raise;
              
  end  KopirSprVych_vArhiv;
  
-- ���������� � ����� ����������� � ������� �� ������� 
  function KopirSprUved_vArhiv( pKodNA in number, pGod in number ) return number as
  begin
      
       Insert into f2NDFL_ARH_UVED
                       ( R_SPRID, KOD_STAVKI, SCHET_KRATN, NOMER_UVED, DATA_UVED, IFNS_KOD, UVED_TIP_VYCH )
            Select ls.R_SPRID, MO.KOD_STAVKI, MO.SCHET_KRATN, MO.NOMER_UVED, MO.DATA_UVED, MO.IFNS_KOD, MO.UVED_TIP_VYCH
            from f2NDFL_LOAD_UVED mo
                    inner join f2NDFL_LOAD_SPRAVKI ls on ls.KOD_NA=mo.KOD_NA and ls.GOD=mo.GOD and ls.SSYLKA=mo.SSYLKA and ls.TIP_DOX=mo.TIP_DOX and ls.NOM_KORR=mo.NOM_KORR
            where mo.KOD_NA=pKodNA and mo.GOD=pGod;
            /*           
            Select a2.ID, MO.KOD_STAVKI, MO.SCHET_KRATN, MO.NOMER_UVED, MO.DATA_UVED, MO.IFNS_KOD, MO.UVED_TIP_VYCH
            from f2NDFL_LOAD_UVED mo
                    inner join f2NDFL_ARH_NOMSPR ns on ns.KOD_NA=mo.KOD_NA and ns.GOD=mo.GOD and ns.SSYLKA=mo.SSYLKA and ns.TIP_DOX=mo.TIP_DOX and ns.FLAG_OTMENA=0 and mo.NOM_KORR=0
                    inner join f2NDFL_ARH_SPRAVKI a2 on a2.KOD_NA=ns.KOD_NA and a2.GOD=ns.GOD and a2.NOM_SPR=ns.NOM_SPR and a2.NOM_KORR=mo.NOM_KORR
            where mo.KOD_NA=pKodNA and mo.GOD=pGod;
            */
       Commit;
       return 0;
        
     exception
        
        when OTHERS then
           Rollback;
           return 1;
              
  end KopirSprUved_vArhiv;
  
-- ���������� � ����� ������ �� �� ������� 
  procedure KopirSprAdres_vArhiv( pKodNA in number, pGod in number )  as  
  begin
       
       -- ���� �����, ���� �������� �� ���� �������
       Insert into f2NDFL_ARH_ADR( R_SPRID, KOD_STR, ADR_INO,  PINDEX, KOD_REG, RAYON, GOROD, PUNKT, ULITSA,  DOM, KOR, KV )
           Select R_SPRID, F2_KODSTR, ADR_FULL, F2_INDEX, F2_KODREG, F2_RAYON, F2_GOROD, F2_PUNKT, F2_ULITSA, F2_DOM, F2_KOR,  F2_KV
           from ( Select 
                       count(*) over( partition by  ls.R_SPRID ) CN,
                       count(*) over( partition by  ls.R_SPRID, F2_KODSTR, F2_KODREG, F2_RAYON, F2_GOROD, F2_PUNKT, F2_ULITSA, F2_DOM, F2_KOR,  F2_KV ) CA, 
                       ls.R_SPRID, mo.* 
                    from f2NDFL_LOAD_ADR mo
                            inner join f2NDFL_LOAD_SPRAVKI ls on ls.KOD_NA=mo.KOD_NA and ls.GOD=mo.GOD and ls.SSYLKA=mo.SSYLKA and ls.TIP_DOX=mo.TIP_DOX and ls.NOM_KORR=mo.NOM_KORR
                    where mo.KOD_NA=pKodNA and mo.GOD=pGod
                  ) where CN=1;   -- �� � ����� ����������
                  
       -- ���������� ������ �� ���� ���������� �� ���� �������           
       Insert into f2NDFL_ARH_ADR( R_SPRID, KOD_STR, ADR_INO,  PINDEX, KOD_REG, RAYON, GOROD, PUNKT, ULITSA,  DOM, KOR, KV )
            Select R_SPRID, F2_KODSTR, ADR_FULL, F2_INDEX, F2_KODREG, F2_RAYON, F2_GOROD, F2_PUNKT, F2_ULITSA, F2_DOM, F2_KOR,  F2_KV from(
                       Select  min(rownum) over( partition by R_SPRID)  FR,  rownum RN,
                                  R_SPRID, F2_KODSTR, ADR_FULL, F2_INDEX, F2_KODREG, F2_RAYON, F2_GOROD, F2_PUNKT, F2_ULITSA, F2_DOM, F2_KOR,  F2_KV
                       from ( Select 
                                   count(*) over( partition by  ls.R_SPRID ) CN,
                                   count(*) over( partition by  ls.R_SPRID, F2_KODSTR, F2_KODREG, F2_RAYON, F2_GOROD, F2_PUNKT, F2_ULITSA, F2_DOM, F2_KOR,  F2_KV ) CA, 
                                   ls.R_SPRID, mo.* 
                                from f2NDFL_LOAD_ADR mo
                                        inner join f2NDFL_LOAD_SPRAVKI ls on ls.KOD_NA=mo.KOD_NA and ls.GOD=mo.GOD and ls.SSYLKA=mo.SSYLKA and ls.TIP_DOX=mo.TIP_DOX and ls.NOM_KORR=mo.NOM_KORR
                                where mo.KOD_NA=pKodNA and mo.GOD=pGod
                              ) where (CN>1 and CN=CA)  -- ���������� ������ 
            ) where FR=RN;   -- ��� ������ ����������, ���������� ������  

       --  �������� ������ ������ �� ������ ����������� ��� ����� �������

       Commit;

        
     exception
        
        when OTHERS then
           Rollback;
           Raise;
              
  end KopirSprAdres_vArhiv;  
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
 function Zareg_XML( pKodNA in number, pGod in number, pForma in number, pCommit in number default 1 ) return number as
 rNALAG F2NDFL_SPR_NAL_AGENT%rowtype;
 nXMLID number;
 frmFmt  varchar2(10);
 begin
 
     Case pForma 
         when 2 then frmFmt := '5.04';
         when 6 then frmFmt := '5.01';
         else 
                 return Null; 
     end case;

                 Select * into rNALAG from F2NDFL_SPR_NAL_AGENT where KOD_NA=pKodNA and GOD=pGOD;
                 Select F_NDFL_XMLID_SEQ.Nextval into nXMLID from dual;
                 Insert into F_NDFL_ARH_XML_FILES
                           ( ID, FILENAME, KOD_FORMY, VERS_FORM, OKTMO, INN_YUL, KPP, NAIMEN_ORG, TLF, KOD_NO, GOD, KVARTAL, PRIZNAK_F)
                 values ( nXMLID, 'NO_NDFL'||trim(to_char(pForma))||'_'||rNALAG.IFNS||'_'||rNALAG.IFNS||'_'||rNALAG.INN||rNALAG.KPP||'_'||to_char(SYSDATE,'YYYYMMDD')||'_'||trim(to_char(nXMLID,'0000000000')),
                             pForma,  frmFmt, rNALAG.OKTMO, rNALAG.INN, rNALAG.KPP, rNALAG.NAZV, rNALAG.PHONE, rNALAG.IFNS, pGOD, 4, 1 );
                 if pCommit<>0 then 
                    Commit;
                    end if;
                 return  nXMLID;   
   
    exception
        when OTHERS then
           Rollback;
           return Null;             
 
 end Zareg_XML;  
 

-- ������������ ������ ������� �� XML-������
procedure RaspredSpravki_poXML( pKodNA in number, pGod in number, pForma in number ) as
 maxSprNo number;
 nXMLID number;
 nXML number;
 vFirstSN number;
 vLastSN number;
 begin
 
             Case pForma 
                 when 2 then 
                       Select to_number(max(NOM_SPR)) into maxSprNo from f2NDFL_ARH_SPRAVKI where KOD_NA=pKodNA and GOD=pGod; -- and R_XMLID is Null;
                       nXML := trunc( (maxSprNo+2999) / 3000 );
                           for iXML in 1 .. nXML loop
                                  nXMLID := Zareg_XML( pKodNA, pGod, pForma, 0 );
                                  vLastSN :=  iXML*3000;
                                  vFirstSN := iXML*3000 - 2999;
                                  Update f2NDFL_ARH_SPRAVKI
                                       set R_XMLID =  nXMLID
                                       where R_XMLID is Null  and  to_number(NOM_SPR)>= vFirstSN  and to_number(NOM_SPR)<= vLastSN;        
                           end loop;
                       Commit;   
                 else 
                       Raise_application_Error( -20001, '�������� pForma �� ����� 2.' ); 
             end case;
   
    exception
        when OTHERS then
           Rollback;
           Raise;
 
 end RaspredSpravki_poXML;  
 
 
 ----------------------- ====  6-���� ==== -----------------------
 
 -- ������� ������������� �������, ���� ���, �� ������� �����
 procedure Naiti_Spravku_f6 ( pErrInfo out varchar2, pSprId out number, pKodNA in number, pGod in number, pKodPeriod in number, pNomKorr in number, pPoMestu in number default 213 ) as
 nSPRID number;
 begin
 
     -- ����� ������������ �������
     begin
        Select Id into nSPRID from f6NDFL_ARH_SPRAVKI 
             where KOD_NA=pKodNA and GOD=pGod and PERIOD=pKodPeriod and NOM_KORR=pNomKorr;
     exception
        when NO_DATA_FOUND then nSPRID:=Null;
        when OTHERS then 
             pErrInfo :=  '����� ������ � ������� � ������� ��������. '||SQLERRM;
             pSprId   :=  Null;     
             return;
     end;
     
     if nSPRID>0 then  
        -- ������� � ��������� ����������� ������� �������
        pErrInfo := Null;
        pSprId   := nSPRID;
        Return;  
        end if; 
     
     Insert into f6NDFL_ARH_SPRAVKI
                    ( KOD_NA, GOD, PERIOD,      NOM_KORR, PO_MESTU )
          values( pKodNA,  pGod, pKodPeriod, pNomKorr,    pPoMestu    )
          returning ID into nSPRID;
                    
     Insert into f6NDFL_LOAD_SPRAVKI
                    ( KOD_NA, GOD, PERIOD,      NOM_KORR, PO_MESTU, R_SPRID )
           values( pKodNA,  pGod, pKodPeriod, pNomKorr,    pPoMestu,    nSPRID    );
     
     Commit;
     
        pErrInfo := Null;
        pSprId   := nSPRID;
        
 exception
    when OTHERS then 
           Rollback;
           pErrInfo :=  '������� ������ � ����� ������� � ������� ��������. '||SQLERRM;     
           pSprId   :=  Null;
           
 end Naiti_Spravku_f6; 
  
 
 -- ������� ������� 6���� � ������� �������� 
 function Sozdat_Spravku_f6 ( pKodNA in number, pGod in number, pKodPeriod in number, pNomKorr in number, pPoMestu in number default 213 ) return varchar2 as
 nSPRID number;
 begin
  
     Insert into f6NDFL_ARH_SPRAVKI
                    ( KOD_NA, GOD, PERIOD,      NOM_KORR, PO_MESTU )
          values( pKodNA,  pGod, pKodPeriod, pNomKorr,    pPoMestu    )
          returning ID into nSPRID;
                    
     Insert into f6NDFL_LOAD_SPRAVKI
                    ( KOD_NA, GOD, PERIOD,      NOM_KORR, PO_MESTU, R_SPRID )
           values( pKodNA,  pGod, pKodPeriod, pNomKorr,    pPoMestu,    nSPRID    );
     
     Commit;
     return Null;
     
     exception
        when OTHERS then
           Rollback;
           return '������� ������ � ����� ������� � ������� ��������. '||SQLERRM;
 
 end Sozdat_Spravku_f6;
 
 
 /*
 declare
RC varchar2(1000);
begin
  dbms_output.enable(10000);  
  FXNDFL_UTIL.Kopir_SprF6_vArhiv( RC, 15000x );
  dbms_output.put_line( nvl(RC,'��') );
END;
*/
 -- ������������ ������� �� ����� 6-����
 procedure Kopir_SprF6_vArhiv ( pErrInfo out varchar2, pSPRID in number ) as
 dTermBeg date;
 dTermEnd date;
 nKodNA   number;
 nGod     number;
 nPeriod  number; 
 nKorr    number;
 ErrPref  varchar2(100);
 begin

    -- ������� ������� �������
    ErrPref := '������� ���������� �������. ';
    Select KOD_NA, GOD, PERIOD, NOM_KORR into nKodNA, nGod, nPeriod, nKorr from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
    dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
    case nPeriod
       when 21 then dTermEnd := add_months(dTermBeg,3);         
       when 31 then dTermEnd := add_months(dTermBeg,6);        
       when 33 then dTermEnd := add_months(dTermBeg,9);        
       when 34 then dTermEnd := add_months(dTermBeg,12);      
       else  pErrInfo := '������ ������������ ��� ������� '||to_char(nPeriod)||' ��� ������� ID='||to_char(pSPRID);
             return;                
    end case;
   
    ErrPref := '������ ����� ������ �������. ';
    Update F6NDFL_ARH_SPRAVKI ar 
      set ar.DATA_DOK = trunc(SYSDATE),
          (ar.KOL_FL_DOH, ar.UDERZH_NAL_IT, ar.NE_UDERZH_NAL_IT, ar.VOZVRAT_NAL_IT)
            =(Select nvl(sum(KOL_FL_DOHOD)-sum(KOL_FL_SOVPAD),0) KFL,
                     nvl(sum(UDERZH_NAL),0)    UDERNAL,
                     nvl(sum(NE_UDERZH_NAL),0) NEUDNAL,
                     nvl(sum(VOZVRAT_NAL),0)   VOZVNAL 
                from F6NDFL_LOAD_SUMGOD  
                  where KOD_NA=nKodNA and GOD=nGod and PERIOD=nPeriod and NOM_KORR=nKorr)
      where ar.ID=pSPRID;
      
    ErrPref := '������ ����� ��������� ������ ������� �� �������. ';  
    Delete from F6NDFL_ARH_ITOGI where R_SPRID=pSPRID;  
    
    ErrPref := '������ ������ ������� �� �������. ';
    Insert into F6NDFL_ARH_ITOGI
          ( R_SPRID, KOD_STAVKI, NACHISL_DOH, NACH_DOH_DIV, VYCHET_NAL, 
            ISCHISL_NAL, ISCHISL_NAL_DIV, AVANS_PLAT)    
    Select
            pSPRID, KOD_STAVKI, nvl(sum(NACHISL_DOH),0) ND, nvl(sum(NACH_DOH_DIV),0) NDD, 
            nvl(sum(VYCHET_ISPOLZ),0) VI, nvl(sum(ISCHISL_NAL),0) ISN, 
            nvl(sum(ISCHISL_NAL_DIV),0) ISND, nvl(sum(AVANS_PLAT),0) AP
    from F6NDFL_LOAD_SUMPOSTAVKE
      where KOD_NA=nKodNA and GOD=nGod and PERIOD=nPeriod and NOM_KORR=nKorr
      group by KOD_STAVKI  
    ;

    ErrPref := '������ ����� ��������� ������ �� ����� ������. ';  
    Delete from F6NDFL_ARH_SVEDDAT where R_SPRID=pSPRID; 
        
    ErrPref := '������ ������ �� ����� ������. ';
    Insert into F6NDFL_ARH_SVEDDAT (
       R_SPRID, DATA_FACT_DOH, SROK_PERECH_NAL, 
       DATA_UDERZH_NAL, SUM_FACT_DOH, SUM_UDERZH_NAL, 
       DESCR_ZP_PEN) 
    Select
       pSPRID SID, DATA_FACT_DOH, SROK_PERECH_NAL, max(DATA_UDERZH_NAL), 
       sum(SUM_FACT_DOH), sum(SUM_UDERZH_NAL), max(KOD_PODR)
    from F6NDFL_LOAD_SVED
      where 
       (  (KOD_PODR=0 and DATA_FACT_DOH>=add_months(dTermEnd,-3) and DATA_FACT_DOH<dTermEnd)
        or KOD_PODR=1)
       and KOD_NA=nKodNA and GOD=nGod and PERIOD=nPeriod and NOM_KORR=nKorr
      group by DATA_FACT_DOH, SROK_PERECH_NAL 
    ; 
    
   pErrInfo := Null;
   Commit;
     
 exception
        when OTHERS then
           pErrInfo := '������: '||ErrPref||SQLERRM;
           Rollback;
 end Kopir_SprF6_vArhiv;
 
/*  
-- ����� 
declare
RC varchar2(1000);
begin
  dbms_output.enable(10000);  
  RC:=FXNDFL_UTIL.Sozdat_Spravku_f6 ( 1, 2015, 21, 0, 213 );
  dbms_output.put_line( nvl(RC,'��') );
END;
*/

function KolichNP( pSPRID in number ) return number as
nKolNP     number;
dTermBeg date;
dTermEnd date;
nKodNA    number;
nGod        number;
nPeriod    number; 
begin

   -- ������� ������� �������
   Select KOD_NA, GOD, PERIOD into nKodNA, nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
   dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
   case nPeriod
       when 21 then dTermEnd := add_months(dTermBeg,3);         
       when 31 then dTermEnd := add_months(dTermBeg,6);        
       when 33 then dTermEnd := add_months(dTermBeg,9);        
       when 34 then dTermEnd := add_months(dTermBeg,12);      
       else  return Null;                
   end case;
   
   -- ������� ����� ������������������ (��), ���������� ����� �� ������, ��������������� �������
   -- ��� ������ 060 ������� 1 ������� 6-����
   -- ������� � ������ ���� ����������� ������

   -- ����  ������� ID=149565  1 ������� 2016 ����, ������������� 0 
   --   Select FXNDFL_UTIL.KolichNP( 149565 ) N from Dual;
  
   Select count(*) into nKolNP
   from(
           Select GF_PERSON,  sum( DOH_POLUCH ) SUM_DOH
           from ( -- ��� ������
                     -- ������ 
                     -- ������ (��� ������������ �������)
                     Select sfl.GF_PERSON,  ds.SUMMA DOH_POLUCH
                        from DV_SR_LSPV ds
                                inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL       
                        where ds.SHIFR_SCHET=60   -- ������
                            and ds.NOM_VKL<991 -- ������ �� �� ����
                            and ds.SERVICE_DOC=0  -- �������
                            and ds.DATA_OP>=dTermBeg  -- � ������ ���� 
                            and ds.DATA_OP < dTermEnd  -- �� ����� ��������� ������� �������
                     UNION
                     -- �����������  � �������
                        Select GF_PERSON, DOH_POLUCH from (
                        Select sfl.GF_PERSON, min(ds.DATA_OP) DATA_OSH_DOH, sum(SUMMA) DOH_POLUCH 
                        from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                         start with ds.SHIFR_SCHET=60  -- ������
                                and ds.NOM_VKL<991 -- ������ �� �� ����
                                and ds.SERVICE_DOC=-1  -- ��������� (�������� � -1)
                                and ds.DATA_OP>=dTermBeg    -- ����������� �������
                                and ds.DATA_OP < dTermEnd    -- � ������� �������� �������
                         connect by PRIOR ds.NOM_VKL=ds.NOM_VKL  
                                    and PRIOR ds.NOM_IPS=ds.NOM_IPS
                                    and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                    and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC         
                         group by sfl.GF_PERSON
                         )            
                         where DATA_OSH_DOH>=dTermBeg    -- ��������� ���������� �������
                            and DATA_OSH_DOH < dTermEnd    -- � ������� �������� �������           
                     UNION       
                    -- �������� � ����������� ������
                     Select vrp.GF_PERSON,  ds.SUMMA DOH_POLUCH
                     from DV_SR_LSPV ds
                             inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                             inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON   
                                                from VYPLACH_POSOB 
                                                where TIP_VYPL=1010
                                                   and DATA_VYPL>=dTermBeg 
                                                   and DATA_VYPL < dTermEnd
                                            ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                     where ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                        and ds.SERVICE_DOC=0  -- ������� �� ����������������
                        and ds.DATA_OP>=dTermBeg  
                        and ds.DATA_OP < dTermEnd           
                     UNION
                     -- ����������� � ���������
                        Select vrp.GF_PERSON,  dvs.DOH_POLUCH 
                        from (
                        Select  ds.NOM_VKL, ds.NOM_IPS,
                                  max(case when SERVICE_DOC=-1 then ds.SSYLKA_DOC else 0 end) SSDOC,
                                  min(ds.DATA_OP) DATA_OSH_DOH, 
                                  sum(SUMMA) DOH_POLUCH
                        from  DV_SR_LSPV ds                
                         start with ds.SHIFR_SCHET=62  -- �������� � ����������� ������
                                and ds.SERVICE_DOC=-1  -- ��������� (�������� � -1)
                                and ds.DATA_OP>=dTermBeg    -- ����������� �������
                                and ds.DATA_OP < dTermEnd    -- � ������� �������� �������
                         connect by PRIOR ds.NOM_VKL=ds.NOM_VKL  
                                    and PRIOR ds.NOM_IPS=ds.NOM_IPS
                                    and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                    and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC                              
                         group by ds.NOM_VKL, ds.NOM_IPS
                         ) dvs
                         inner join SP_LSPV lspv on lspv.NOM_VKL=dvs.NOM_VKL and lspv.NOM_IPS=dvs.NOM_IPS 
                         left join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON   
                                           from VYPLACH_POSOB 
                                                where TIP_VYPL=1010
                                                    and DATA_VYPL>=dTermBeg
                                                   and DATA_VYPL < dTermEnd
                                     ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=dvs.SSDOC                                    
                         where dvs.DATA_OSH_DOH>=dTermBeg   -- ��������� ���������� �������
                             and dvs.DATA_OSH_DOH < dTermEnd    -- � ������� �������� �������         
                     UNION       
                     -- �������� �����
                     Select sfl.GF_PERSON,  ds.SUMMA DOH_POLUCH
                     from DV_SR_LSPV ds
                             inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                             inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL                  
                     where ds.SHIFR_SCHET=55 -- �������� �����
                        and ds.SERVICE_DOC=0  -- ������� �� ����������������
                        and ds.DATA_OP>=dTermBeg  
                        and ds.DATA_OP < dTermEnd           
                     UNION
                     -- ����������� � ��������
                        Select GF_PERSON, DOH_POLUCH from (
                        Select sfl.GF_PERSON, min(ds.DATA_OP) DATA_OSH_DOH, sum(SUMMA) DOH_POLUCH 
                        from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                         start with ds.SHIFR_SCHET=55  -- �������� �����, ���������� �����
                                and ds.SERVICE_DOC=-1  -- ��������� (�������� � -1)
                                and ds.DATA_OP>=dTermBeg    -- ����������� �������
                                and ds.DATA_OP < dTermEnd    -- � ������� �������� �������
                         connect by PRIOR ds.NOM_VKL=ds.NOM_VKL  
                                    and PRIOR ds.NOM_IPS=ds.NOM_IPS
                                    and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                    and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC         
                         group by sfl.GF_PERSON
                         )            
                         where DATA_OSH_DOH>=dTermBeg    -- ��������� ���������� �������
                            and DATA_OSH_DOH < dTermEnd    -- � ������� �������� �������                           
                    )
                group by  GF_PERSON
                having sum( DOH_POLUCH )>0
           );   
   
   
   return nKolNP;
   
   end KolichNP;
   
   function SumIspolzVych( pSPRID in number, pSTAVKA in number ) return float as
   fSIV        float;
   dTermBeg date;
   dTermEnd date;
   dTermKor date;
   nKodNA   number;
   nGod     number;
   nPeriod  number; 
   nNalRez  number;
   begin
   
   -- ������� �� ���� ������ � ���� ���������� ���������
   case pSTAVKA
      when 13 then 
              nNalRez:=1;    -- 
      when 30 then 
              nNalRez:=2;    -- ��� ������������ ������ ������� �� ����, ������� �� ������
              return 0;         -- ����� ������� ����� 0
      else 
              return Null;    
   end case;  

   -- ������ ������ ������ ��� ��������� ����������

   -- ������� ������� �������
   Select KOD_NA, GOD, PERIOD into nKodNA, nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
   dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
   case nPeriod
       when 21 then dTermEnd := add_months(dTermBeg,3);         
       when 31 then dTermEnd := add_months(dTermBeg,6);        
       when 33 then dTermEnd := add_months(dTermBeg,9);        
       when 34 then dTermEnd := add_months(dTermBeg,12);      
       else  return Null;                
   end case;
  
   dTermKor := dTermEnd;
   
            Select sum(VYCH_ISPOLZ) into fSIV
                       --sum(DOX_SUMMA) DOX, sum(VYCH_ISPOLZ) VCHI, sum(NAL_ISCHISL) NALI, sum(DLT_NEG_NEDOPL) NEG_ZNACH_NEDOPL       
                from(
                    Select sgd.GF_PERSON, sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0) VYCH_PRED, least(sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0)) VYCH_ISPOLZ 
                        --   sgd.DOX_SUMMA - least(sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0)) OBL_BAZA,
                        --   round( 0.13*(sgd.DOX_SUMMA - least(sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0))),0) NAL_ISCHISL,
                        --   nvl(nal.NAL_SUMMA,0) NAL_UDERZH,
                        --   nvl(nal.NAL_SUMMA,0)+nvl(kor.NAL_KOR83,0)-round( 0.13*(sgd.DOX_SUMMA - least(sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0))),0) DLT_NEG_NEDOPL
                    from                 
                        (Select GF_PERSON, sum(SUM_DOH) DOX_SUMMA from F2NDFL_LOAD_NALISCH group by  GF_PERSON) sgd
                    left join
                        (-- ��������������� ������ �� �������� �� ��������� ������    
                        Select GF_PERSON, sum(VYCH_SUMMA) VYCH_PREDOST
                        from(    
                            -- ��������� ������, ���������� ���������� ��� �����������
                            Select np.GF_PERSON, sum(SUMMA) VYCH_SUMMA
                            from DV_SR_LSPV ds    
                                inner join F_NDFL_LOAD_NALPLAT np
                                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS          
                                where ds.DATA_OP>=dTermBeg   -- ������������� � ��������� �������
                                  and ds.DATA_OP< dTermEnd   -- ������ ���� - ����� ��������� ��������
                                  and ds.SERVICE_DOC=0        -- �������������� ������
                                  and ds.SHIFR_SCHET>1000     -- ������
                            group by np.GF_PERSON
                                  having sum(ds.SUMMA)<>0      
                          UNION ALL
                            -- ��������� ����������� �������
                            Select np.GF_PERSON, sum(vc.VYCH_SUM) VYCH_SUMMA
                            from
                               (Select NOM_VKL, NOM_IPS, sum(SUMMA) VYCH_SUM
                                from(Select * from (    
                                        Select ds.*        -- ��� ����������� ������ ������ ����������� � ������� ����
                                        from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                                            where  ds.SERVICE_DOC<>0
                                            start with   ds.SHIFR_SCHET>1000         -- �����
                                                     and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                                     and ds.DATA_OP >= dTermBeg     -- ����������� ������� ����� ������ �������
                                                     and ds.DATA_OP <  dTermKor     -- �� ����� ��������, � ������� ����������� �������������
                                            connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                                     and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                                                     and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                     and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                     and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                                        ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor 
                                    ) group by NOM_VKL, NOM_IPS
                                      having sum(SUMMA)<>0
                                ) vc        
                                inner join F_NDFL_LOAD_NALPLAT np
                                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=vc.NOM_VKL and np.NOM_IPS=vc.NOM_IPS     
                                group by np.GF_PERSON 
                            ) group by GF_PERSON
                        ) vch   
                          on vch.GF_PERSON=sgd.GF_PERSON 
           /*         left join
                        (
                          Select GF_PERSON, sum(NAL_SUM) NAL_SUMMA 
                          from(
                                -- ��������� ������, ���������� ���������� ��� �����������
                                Select np.GF_PERSON, sum(SUMMA) NAL_SUM
                                from DV_SR_LSPV ds    
                                    inner join F_NDFL_LOAD_NALPLAT np
                                        on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS          
                                    where ds.DATA_OP>=dTermBeg   -- �������� � ��������� �������
                                      and ds.DATA_OP< dTermEnd   -- ������ ���� - ����� ��������� ��������
                                      and ds.SERVICE_DOC=0        -- �������������� ������
                                      and ds.SHIFR_SCHET=85       -- �����
                                      and ds.SUB_SHIFR_SCHET in (0,2)  -- 13%
                                    group by np.GF_PERSON
                                    having sum(ds.SUMMA)<>0    
                              UNION ALL
                                Select np.GF_PERSON, sum(SUMMA) NAL_SUM
                                from DV_SR_LSPV ds    
                                    inner join F_NDFL_LOAD_NALPLAT np
                                        on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=1 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS          
                                    where ds.DATA_OP>=dTermBeg   -- �������� � ��������� �������
                                      and ds.DATA_OP< dTermEnd   -- ������ ���� - ����� ��������� ��������
                                      and ds.SERVICE_DOC=0        -- �������������� ������
                                      and ds.SHIFR_SCHET=86       -- �����
                                      and ds.SUB_SHIFR_SCHET=0    -- 13%
                                    group by np.GF_PERSON
                                    having sum(ds.SUMMA)<>0    
                              UNION ALL              
                                -- ��������� ����������� �������
                                Select np.GF_PERSON, sum(nl.NAL_SUM) NAL_SUM
                                from
                                   (Select NOM_VKL, NOM_IPS, sum(SUMMA) NAL_SUM
                                    from(Select * from (    
                                            Select ds.*        -- ��� ����������� ������ ������ ����������� � ������� ����
                                            from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                                                where  ds.SERVICE_DOC<>0
                                                start with   ds.SHIFR_SCHET in 85   -- �����
                                                         and ds.SUB_SHIFR_SCHET in (0,2) -- 13%
                                                         and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                                         and ds.DATA_OP >= dTermBeg     -- ����������� ������� ����� ������ �������
                                                         and ds.DATA_OP <  dTermKor     -- �� ����� ��������, � ������� ����������� �������������
                                                connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                                         and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                                                         and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                         and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                         and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                                            ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor 
                                        ) group by NOM_VKL, NOM_IPS
                                          having sum(SUMMA)<>0
                                ) nl        
                                inner join F_NDFL_LOAD_NALPLAT np
                                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=nl.NOM_VKL and np.NOM_IPS=nl.NOM_IPS     
                                group by np.GF_PERSON   
                            ) group by GF_PERSON                                    
                        ) nal    
                          on nal.GF_PERSON=sgd.GF_PERSON 
                    left join
                       (Select np.GF_PERSON, 83 TIP, sum(ds.SUMMA) NAL_KOR83
                        from DV_SR_LSPV ds
                            inner join F_NDFL_LOAD_NALPLAT np
                                on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS                                   
                            where ds.DATA_OP>=dTermBeg
                              and ds.DATA_OP< dTermEnd
                              and ds.SERVICE_DOC=0
                              and ds.SHIFR_SCHET=83  
                        group by np.GF_PERSON
                        ) kor
                          on kor.GF_PERSON=sgd.GF_PERSON   */
                  ); -- where abs(DLT_NEG_NEDOPL)   >=0.01
/*
        -- ������ ����� �������������� �������
        with q as (
                               -- ������ � �������� (������ ���������)
                               -- ���������� ����������, ��� �����������
                              Select  sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                         inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                           where SHIFR_SCHET=85
                                                               and DATA_OP>=dTermBeg  
                                                               and DATA_OP < dTermEnd ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                 where  ds.DATA_OP>=dTermBeg        -- � ������ ����
                                     and ds.DATA_OP < dTermEnd        -- �� ����� ��������� �������  
                                     and ds.SERVICE_DOC=0              -- ������� ��� ����������� �����������
                                     and sfl.NAL_REZIDENT=1              -- �� ������ 13%
                                     and sfl.PEN_SXEM<>7  -- �� ���
                                     and ( ds.SHIFR_SCHET= 55 -- ��������
                                             or ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 ) --  ��� ������ �� ����
                                             or ds.SHIFR_SCHET>1000 )  -- ��������������� ����� �������  
                               UNION  ALL 
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               Select GF_PERSON, SHIFR_SCHET, MINDATOP DATA_OP, SUMKORR SUMMA from (
                                            Select sfl.GF_PERSON, ds.SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                           where SHIFR_SCHET=85 
                                                               and DATA_OP>=dTermBeg  
                                                               and DATA_OP < dTermEnd ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                            where  sfl.NAL_REZIDENT=1                 -- �� ������ 13%        
                                                 and sfl.PEN_SXEM<>7  -- �� ���
                                             start with ( ds.SHIFR_SCHET= 55 -- ��������
                                                             or ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 ) --  ��� ������ �� ����
                                                             or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg       -- ����������� �������
                                                    -- ����������� ����� ���� ������� � �����, ���� ���������, ����� �� ������������ �������� ������?                              
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  sfl.GF_PERSON, ds.SHIFR_SCHET          
                                       )  where MINDATOP>=dTermBeg               -- ������������ ���������� ����
                                             and MINDATOP < dTermEnd               -- � ������� �������� �������       
                            UNION  ALL 
                              -- �������� � ����������� ������
                               -- ���������� ����������, ��� �����������
                               Select vrp.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                     from DV_SR_LSPV ds
                                             inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                             inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                                                from VYPLACH_POSOB 
                                                                where TIP_VYPL=1010                -- �������� � ����������� ������
                                                                   and NAL_REZIDENT=1             -- �� ������ 13%      
                                                                   and DATA_VYPL>=dTermBeg    -- � ������ ����
                                                                   and DATA_VYPL < dTermEnd    -- �� ����� ��������� ������� 
                                                            ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                                     where (ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                                               or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                        and ds.SERVICE_DOC=0  -- ������� �� ����������������
                                        and ds.DATA_OP>=dTermBeg  
                                        and ds.DATA_OP < dTermEnd         
                    --      UNION
                               -- �������� � ����������� ������
                               -- ����������� � ����������������� � ������� �������
                     --          � � � � �   � � � � � � � � (���� ����� ��� ��� - ��� �������)
                                                                                        
                     )
    Select sum(SUMGOD_ISPOLZ_VYCH) into fSIV from (                    
        Select    -- ������ ������ ��� ��������� ���������� 
                     case 
                         when nvl(vyc.SUMGOD_VYC,0)>doh.SUMGOD_DOH 
                            then doh.SUMGOD_DOH 
                            else nvl(vyc.SUMGOD_VYC,0) 
                     end SUMGOD_ISPOLZ_VYCH          
        from (    Select GF_PERSON,  sum(SUMMA) SUMGOD_DOH from q   
                              where  SHIFR_SCHET<1000    -- ������
                              group by GF_PERSON
                ) doh
        left join ( Select GF_PERSON, sum(SUMMA)  SUMGOD_VYC from  q 
                              where SHIFR_SCHET>1000   --  ��� ������ 
                              group by GF_PERSON
                ) vyc  
                 on vyc.GF_PERSON=doh.GF_PERSON              
       );
 */      
       return fSIV;
  
   end SumIspolzVych; 
   
   function SumNachislDoh( pSPRID in number, pSTAVKA in number ) return float as
   fSND        float;
   dTermBeg date;
   dTermEnd date;
   dTermKor date;
   nGod        number;
   nPeriod    number; 
   nNalRez   number;
   nPenSSS    number;
   nVykSSS    number;
   begin
   
   -- ������� �� ���� ������ � ���� ���������� ���������
   -- � ����� ��������� ������
   case pSTAVKA
      when 13 then 
              nNalRez := 1;
              nPenSSS := 0;
              nVykSSS := 2;
      when 30 then 
              nNalRez := 2;  
              nPenSSS := 1;
              nVykSSS := 3;               
      else 
              return Null;    
   end case;  

   -- ������� ������� �������
   Select GOD, PERIOD into nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
   dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
   case nPeriod
       when 21 then dTermEnd := add_months(dTermBeg,3);         
       when 31 then dTermEnd := add_months(dTermBeg,6);        
       when 33 then dTermEnd := add_months(dTermBeg,9);        
       when 34 then dTermEnd := add_months(dTermBeg,12);      
       else  return Null;                
   end case;
   -- ����� ��������, � ������� ����������� �������������� ������ 
   dTermKor := dTermEnd;  -- ���������, ����� ����� ��������� ���������
                          -- ����� �������� ������� � ����������� � ����� ��������
                          -- � � �����������
                          
        -- ��������� 18-04-2017  �� ������ 1� ������� 2017 ����
        
        -- ������ ����� ������������ ������,
        -- ����������� �� ��������� ������
        Select sum(NACH_DOH) into fSND 
        from (  -- ���������� ����������, ��� �����������
                -- ������
                Select nvl(sum(ds.SUMMA),0) NACH_DOH 
                from DV_SR_LSPV ds
                     left join DV_SR_LSPV n13 
                            on n13.NOM_VKL=ds.NOM_VKL and n13.NOM_IPS=ds.NOM_IPS and n13.SHIFR_SCHET=85 and n13.SUB_SHIFR_SCHET=1
                           and n13.DATA_OP=ds.DATA_OP and n13.SSYLKA_DOC=ds.SSYLKA_DOC and n13.SERVICE_DOC=0                
                    where ds.DATA_OP>=dTermBeg
                      and ds.DATA_OP< dTermEnd
                      and ds.SERVICE_DOC=0
                      and ds.SHIFR_SCHET=60
                      and ds.NOM_VKL<991
                      and nvl(n13.SUB_SHIFR_SCHET,0)=nPenSSS
                union all  
                -- ������� 
                Select nvl(sum(ds.SUMMA),0) NACH_DOH                 
                from DV_SR_LSPV ds
                     left join DV_SR_LSPV n13 
                            on n13.NOM_VKL=ds.NOM_VKL and n13.NOM_IPS=ds.NOM_IPS and n13.SHIFR_SCHET=86 and n13.SUB_SHIFR_SCHET=1
                           and n13.DATA_OP=ds.DATA_OP and n13.SSYLKA_DOC=ds.SSYLKA_DOC and n13.SERVICE_DOC=0                   
                    where ds.DATA_OP>=dTermBeg
                      and ds.DATA_OP< dTermEnd
                      and ds.SERVICE_DOC=0
                      and ds.SHIFR_SCHET=62
                      and nvl(n13.SUB_SHIFR_SCHET,0)=nPenSSS
                union all  
                -- �������� 
                Select nvl(sum(ds.SUMMA),0) NACH_DOH
                from DV_SR_LSPV ds
                     left join DV_SR_LSPV n13 
                            on n13.NOM_VKL=ds.NOM_VKL and n13.NOM_IPS=ds.NOM_IPS and n13.SHIFR_SCHET=85 and n13.SUB_SHIFR_SCHET=3
                           and n13.DATA_OP=ds.DATA_OP and n13.SSYLKA_DOC=ds.SSYLKA_DOC and n13.SERVICE_DOC=0                   
                    where ds.DATA_OP>=dTermBeg
                      and ds.DATA_OP< dTermEnd
                      and ds.SERVICE_DOC=0
                      and ds.SHIFR_SCHET=55   
                      and nvl(n13.SUB_SHIFR_SCHET,2)=nVykSSS
                -- �����������
                union all                     
                -- ������
                Select nvl(sum(dox.SUMMA),0) NACH_DOH
                from
                   (Select * from (    
                        Select ds.*        -- ��� ����������� ������ ������ ����������� � ������� ����
                        from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                            where  ds.SERVICE_DOC<>0
                            start with   ds.SHIFR_SCHET= 60          -- ������
                                     and ds.NOM_VKL<991              -- � ������ �� ����
                                     and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                     and ds.DATA_OP >= dTermBeg      -- ����������� ������� ����� ������ �������
                                     and ds.DATA_OP <  dTermKor      -- �� ����� ��������, � ������� ����������� �������������
                            connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                     and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                                     and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                     and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                     and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                        ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor               
                    ) dox 
                    left join DV_SR_LSPV n13 
                              on n13.NOM_VKL=dox.NOM_VKL and n13.NOM_IPS=dox.NOM_IPS and n13.SHIFR_SCHET=85 and n13.SUB_SHIFR_SCHET=1
                                 and n13.DATA_OP=dox.DATA_OP and n13.SSYLKA_DOC=dox.SSYLKA_DOC and n13.SERVICE_DOC=dox.SERVICE_DOC    
                    where nvl(n13.SUB_SHIFR_SCHET,0)=nPenSSS         
                union all                     
                -- �������
                Select nvl(sum(dox.SUMMA),0) NACH_DOH
                from
                   (Select * from (    
                        Select ds.*        -- ��� ����������� ������� ������ ����������� � ������� ����
                        from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                            where  ds.SERVICE_DOC<>0
                            start with   ds.SHIFR_SCHET= 62          -- �������
                                     and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                     and ds.DATA_OP >= dTermBeg      -- ����������� ������� ����� ������ �������
                                     and ds.DATA_OP <  dTermKor      -- �� ����� ��������, � ������� ����������� �������������
                            connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                     and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                                     and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                     and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                     and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                        ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor               
                    ) dox 
                    left join DV_SR_LSPV n13 
                              on n13.NOM_VKL=dox.NOM_VKL and n13.NOM_IPS=dox.NOM_IPS and n13.SHIFR_SCHET=86 and n13.SUB_SHIFR_SCHET=1
                                 and n13.DATA_OP=dox.DATA_OP and n13.SSYLKA_DOC=dox.SSYLKA_DOC and n13.SERVICE_DOC=dox.SERVICE_DOC    
                    where nvl(n13.SUB_SHIFR_SCHET,0)=nPenSSS                               
                union all                     
                -- ��������
                Select nvl(sum(dox.SUMMA),0) NACH_DOH
                from
                   (Select * from (    
                        Select ds.*, min(DATA_OP) over(partition by ds.NOM_VKL, ds.NOM_IPS) MINDATOP
                        from DV_SR_LSPV ds
                            where  ds.SERVICE_DOC<>0
                            start with   ds.SHIFR_SCHET= 55        -- ������
  --                                 and ds.NOM_VKL<991            -- � ������ �� ����
                                     and ds.SERVICE_DOC=-1         -- ��������� (�������� ����� � -1)
                                     and ds.DATA_OP >= dTermBeg   -- ����������� ������� ����� ������ �������
                            connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                     and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                     and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                     and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                     and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                        ) where  MINDATOP>=dTermBeg and DATA_OP>=dTermBeg and DATA_OP<dTermEnd               
                    ) dox 
                    left join DV_SR_LSPV n13 
                              on n13.NOM_VKL=dox.NOM_VKL and n13.NOM_IPS=dox.NOM_IPS and n13.SHIFR_SCHET=85 and n13.SUB_SHIFR_SCHET=3
                                 and n13.DATA_OP=dox.DATA_OP and n13.SSYLKA_DOC=dox.SSYLKA_DOC and n13.SERVICE_DOC=dox.SERVICE_DOC    
                    where nvl(n13.SUB_SHIFR_SCHET,2)=nVykSSS                               
               );           
                       
      return fSND;
   
   end SumNachislDoh;   
   
   function SumIschislNal( pSPRID in number, pSTAVKA in number ) return float as
   fSIN         float;
   dTermBeg date;
   dTermEnd date;
   dTermKor date;
   nKodNA   number;
   nGod     number;
   nPeriod  number; 
   nNalRez  number;
   begin

          -- ������� ������� �������
       Select KOD_NA, GOD, PERIOD into nKodNA, nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
       dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
       case nPeriod
           when 21 then dTermEnd := add_months(dTermBeg,3);         
           when 31 then dTermEnd := add_months(dTermBeg,6);        
           when 33 then dTermEnd := add_months(dTermBeg,9);        
           when 34 then dTermEnd := add_months(dTermBeg,12);      
           else  return Null;                
       end case;
       
       -- ���� ����� ������� ������������� ��������
       -- �� ���������� ����������� � ����������� ���������,
       -- �� �������� ����� ��������� ��� ���������� ������������� 
       dTermKor := dTermEnd;   --  ���� ������ ����� ���������
   
       -- ������� �� ���� ������ � ���� ���������� ���������
       case pSTAVKA
          
          when 13 then 
               nNalRez:=1;
               -- ��� ��������� ����������
               -- ����� ����������� � �������� ������������ �����, 
               -- ������������ �� ����� �������, � ����������� ����������� ����������
               
                Select sum(NAL_ISCHISL) into fSIN
                       --sum(DOX_SUMMA) DOX, sum(VYCH_ISPOLZ) VCHI, sum(NAL_ISCHISL) NALI, sum(DLT_NEG_NEDOPL) NEG_ZNACH_NEDOPL       
                from(
                    Select sgd.GF_PERSON, sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0) VYCH_PRED, least(sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0)) VYCH_ISPOLZ,
                           sgd.DOX_SUMMA - least(sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0)) OBL_BAZA,
                           round( 0.13*(sgd.DOX_SUMMA - least(sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0))),0) NAL_ISCHISL,
                           nvl(nal.NAL_SUMMA,0) NAL_UDERZH,
                           nvl(nal.NAL_SUMMA,0)+nvl(kor.NAL_KOR83,0)-round( 0.13*(sgd.DOX_SUMMA - least(sgd.DOX_SUMMA, nvl(vch.VYCH_PREDOST,0))),0) DLT_NEG_NEDOPL
                    from                 
                        (Select GF_PERSON, sum(SUM_DOH) DOX_SUMMA from F2NDFL_LOAD_NALISCH group by  GF_PERSON) sgd
                    left join
                        (-- ��������������� ������ �� �������� �� ��������� ������    
                        Select GF_PERSON, sum(VYCH_SUMMA) VYCH_PREDOST
                        from(    
                            -- ��������� ������, ���������� ���������� ��� �����������
                            Select np.GF_PERSON, sum(SUMMA) VYCH_SUMMA
                            from DV_SR_LSPV ds    
                                inner join F_NDFL_LOAD_NALPLAT np
                                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS          
                                where ds.DATA_OP>=dTermBeg   -- ������������� � ��������� �������
                                  and ds.DATA_OP< dTermEnd   -- ������ ���� - ����� ��������� ��������
                                  and ds.SERVICE_DOC=0        -- �������������� ������
                                  and ds.SHIFR_SCHET>1000     -- ������
                            group by np.GF_PERSON
                                  having sum(ds.SUMMA)<>0      
                          UNION ALL
                            -- ��������� ����������� �������
                            Select np.GF_PERSON, sum(vc.VYCH_SUM) VYCH_SUMMA
                            from
                               (Select NOM_VKL, NOM_IPS, sum(SUMMA) VYCH_SUM
                                from(Select * from (    
                                        Select ds.*        -- ��� ����������� ������ ������ ����������� � ������� ����
                                        from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                                            where  ds.SERVICE_DOC<>0
                                            start with   ds.SHIFR_SCHET>1000         -- �����
                                                     and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                                     and ds.DATA_OP >= dTermBeg     -- ����������� ������� ����� ������ �������
                                                     and ds.DATA_OP <  dTermKor     -- �� ����� ��������, � ������� ����������� �������������
                                            connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                                     and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                                                     and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                     and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                     and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                                        ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor 
                                    ) group by NOM_VKL, NOM_IPS
                                      having sum(SUMMA)<>0
                                ) vc        
                                inner join F_NDFL_LOAD_NALPLAT np
                                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=vc.NOM_VKL and np.NOM_IPS=vc.NOM_IPS     
                                group by np.GF_PERSON 
                            ) group by GF_PERSON
                        ) vch   
                          on vch.GF_PERSON=sgd.GF_PERSON 
                    left join
                        (
                          Select GF_PERSON, sum(NAL_SUM) NAL_SUMMA 
                          from(
                                -- ��������� ������, ���������� ���������� ��� �����������
                                Select np.GF_PERSON, sum(SUMMA) NAL_SUM
                                from DV_SR_LSPV ds    
                                    inner join F_NDFL_LOAD_NALPLAT np
                                        on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS          
                                    where ds.DATA_OP>=dTermBeg   -- �������� � ��������� �������
                                      and ds.DATA_OP< dTermEnd   -- ������ ���� - ����� ��������� ��������
                                      and ds.SERVICE_DOC=0        -- �������������� ������
                                      and ds.SHIFR_SCHET=85       -- �����
                                      and ds.SUB_SHIFR_SCHET in (0,2)  -- 13%
                                    group by np.GF_PERSON
                                    having sum(ds.SUMMA)<>0    
                              UNION ALL
                                Select np.GF_PERSON, sum(SUMMA) NAL_SUM
                                from DV_SR_LSPV ds    
                                    inner join F_NDFL_LOAD_NALPLAT np
                                        on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=1 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS          
                                    where ds.DATA_OP>=dTermBeg   -- �������� � ��������� �������
                                      and ds.DATA_OP< dTermEnd   -- ������ ���� - ����� ��������� ��������
                                      and ds.SERVICE_DOC=0        -- �������������� ������
                                      and ds.SHIFR_SCHET=86       -- �����
                                      and ds.SUB_SHIFR_SCHET=0    -- 13%
                                    group by np.GF_PERSON
                                    having sum(ds.SUMMA)<>0    
                              UNION ALL              
                                -- ��������� ����������� �������
                                Select np.GF_PERSON, sum(nl.NAL_SUM) NAL_SUM
                                from
                                   (Select NOM_VKL, NOM_IPS, sum(SUMMA) NAL_SUM
                                    from(Select * from (    
                                            Select ds.*        -- ��� ����������� ������ ������ ����������� � ������� ����
                                            from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                                                where  ds.SERVICE_DOC<>0
                                                start with   ds.SHIFR_SCHET in 85   -- �����
                                                         and ds.SUB_SHIFR_SCHET in (0,2) -- 13%
                                                         and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                                         and ds.DATA_OP >= dTermBeg     -- ����������� ������� ����� ������ �������
                                                         and ds.DATA_OP <  dTermKor     -- �� ����� ��������, � ������� ����������� �������������
                                                connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                                         and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                                                         and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                         and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                         and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                                            ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor 
                                        ) group by NOM_VKL, NOM_IPS
                                          having sum(SUMMA)<>0
                                ) nl        
                                inner join F_NDFL_LOAD_NALPLAT np
                                    on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=nl.NOM_VKL and np.NOM_IPS=nl.NOM_IPS     
                                group by np.GF_PERSON   
                            ) group by GF_PERSON                                    
                        ) nal    
                          on nal.GF_PERSON=sgd.GF_PERSON 
                    left join
                       (Select np.GF_PERSON, 83 TIP, sum(ds.SUMMA) NAL_KOR83
                        from DV_SR_LSPV ds
                            inner join F_NDFL_LOAD_NALPLAT np
                                on np.KOD_NA=nKodNA and np.GOD=nGOD and np.SSYLKA_TIP=0 and np.NOM_VKL=ds.NOM_VKL and np.NOM_IPS=ds.NOM_IPS                                   
                            where ds.DATA_OP>=dTermBeg
                              and ds.DATA_OP< dTermEnd
                              and ds.SERVICE_DOC=0
                              and ds.SHIFR_SCHET=83  
                        group by np.GF_PERSON
                        ) kor
                          on kor.GF_PERSON=sgd.GF_PERSON   
                  ); -- where abs(DLT_NEG_NEDOPL)   >=0.01

               
/*                           
                -- ��������������� �������
                with q as (
                              -- ������ � �������� (������ ���������)
                              -- ���������� ����������, ��� �����������
                              -- ������ 
                              Select  sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                         -- ������ �� ����, � ������� ������������ �����
                                         inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                             where SHIFR_SCHET=85
                                                               and SUB_SHIFR_SCHET in (0,1)  -- ������
                                                               and DATA_OP>=dTermBeg  
                                                               and DATA_OP < dTermEnd ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                 where  ds.DATA_OP>=dTermBeg        -- � ������ ����
                                     and ds.DATA_OP < dTermEnd      -- �� ����� ��������� �������  
                                     and ds.SERVICE_DOC=0           -- ������� ��� ����������� �����������
                                     and sfl.NAL_REZIDENT=1         -- �� ������ 13%
                                     and sfl.PEN_SXEM<>7            -- �� ���
                                     and ( ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 ) -- ������ �� ����
                                          or ds.SHIFR_SCHET>1000 )                    -- ��������������� ����� �������  
                              -- ��������
                              UNION ALL
                              Select  sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                         -- ������ �� ����, � ������� ������������ �����
                                         inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                           where   SHIFR_SCHET=85
                                                               and SUB_SHIFR_SCHET in (2,3)  -- ��������
                                                               and DATA_OP>=dTermBeg  
                                                               and DATA_OP < dTermEnd 
                                                    ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                         inner join (Select distinct SSYLKA from VYPLACH_POSOB 
                                                        where TIP_VYPL=1030
                                                          and DATA_VYPL>=dTermBeg
                                                          and DATA_VYPL < dTermEnd
                                                          and NAL_REZIDENT=1  -- �� ������ 13%
                                                    ) rp on rp.SSYLKA=lspv.SSYLKA_FL  -- ���� ������� �� ������, �� ��� ���   
                                 where  ds.DATA_OP>=dTermBeg        -- � ������ ����
                                     and ds.DATA_OP < dTermEnd      -- �� ����� ��������� �������  
                                     and ds.SERVICE_DOC=0           -- ������� ��� ����������� �����������
                                     and (    ds.SHIFR_SCHET= 55    -- ��������
                                           or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������                                               
                               UNION ALL 
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               -- ������
                               Select GF_PERSON, SHIFR_SCHET, MINDATOP DATA_OP, SUMKORR SUMMA from (
                                            Select sfl.GF_PERSON, ds.SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                                     where SHIFR_SCHET=85 
                                                                       and SUB_SHIFR_SCHET in (0,1)  -- ������
                                                                       and DATA_OP>=dTermBeg  
                                                                       and DATA_OP < dTermEnd 
                                                                   ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                            where  sfl.NAL_REZIDENT=1                 -- �� ������ 13%        
                                                 and sfl.PEN_SXEM<>7  -- �� ���
                                             start with ( ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 ) --  ��� ������ �� ����
                                                         or ds.SHIFR_SCHET>1000 )  -- ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1          -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg       -- ����������� �������
                                                    -- ����������� ����� ���� ������� � �����, ���� ���������, ����� �� ������������ �������� ������?                              
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  sfl.GF_PERSON, ds.SHIFR_SCHET          
                                       )  where MINDATOP>=dTermBeg               -- ������������ ���������� ����
                                            and MINDATOP < dTermEnd               -- � ������� �������� �������       
                               -- ��������
                               UNION ALL
                               Select GF_PERSON, SHIFR_SCHET, MINDATOP DATA_OP, SUMKORR SUMMA from (
                                            Select sfl.GF_PERSON, ds.SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                                       where SHIFR_SCHET=85 
                                                                           and SUB_SHIFR_SCHET in (2,3)  -- ��������
                                                                           and DATA_OP>=dTermBeg  
                                                                           and DATA_OP < dTermEnd 
                                                                   ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                                        inner join (Select distinct SSYLKA from VYPLACH_POSOB 
                                                                        where TIP_VYPL=1030
                                                                          and DATA_VYPL>=dTermBeg
                                                                          and DATA_VYPL < dTermEnd
                                                                          and NAL_REZIDENT=1  -- �� ������ 13%
                                                                   ) rp on rp.SSYLKA=lspv.SSYLKA_FL  -- ���� ������� �� ������, �� ��� ���                                                                      
                                             start with (   ds.SHIFR_SCHET= 55 -- ��������
                                                         or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg       -- ����������� �������
                                                    -- ����������� ����� ���� ������� � �����, ���� ���������, ����� �� ������������ �������� ������?                              
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  sfl.GF_PERSON, ds.SHIFR_SCHET          
                                       )  where MINDATOP>=dTermBeg               -- ������������ ���������� ����
                                            and MINDATOP < dTermEnd               -- � ������� �������� �������       
                              UNION ALL 
                              -- �������� � ����������� ������
                               -- ���������� ����������, ��� �����������
                               Select vrp.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                     from DV_SR_LSPV ds
                                             inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                             inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                                                from VYPLACH_POSOB 
                                                                where TIP_VYPL=1010                -- �������� � ����������� ������
                                                                   and NAL_REZIDENT=1             -- �� ������ 13%      
                                                                   and DATA_VYPL>=dTermBeg    -- � ������ ����
                                                                   and DATA_VYPL < dTermEnd    -- �� ����� ��������� ������� 
                                                            ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                                     where (ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                                               or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                        and ds.SERVICE_DOC=0  -- ������� �� ����������������
                                        and ds.DATA_OP>=dTermBeg  
                                        and ds.DATA_OP < dTermEnd         
                 --          UNION
                               -- �������� � ����������� ������
                               -- ����������� � ����������������� � ������� �������
                 --            � � � � �   � � � � � � � � (���� ����� ��� ��� - ��� �������)
                 --                                                                      
                              )
            -- ��� ������                  
            Select sum(SGD_NAL) into fSIN from (                    
                Select    -- ������ ������ ��� ��������� ���������� 
                             -- ������ � ���������� ��� ������ �������
                             round( 0.13* case when doh.SUMGOD_DOH < nvl(vyc.SUMGOD_VYC,0 )  
                                                   then 0
                                                   else doh.SUMGOD_DOH - nvl(vyc.SUMGOD_VYC,0)
                                                end ) SGD_NAL        
                from (    Select GF_PERSON,  sum(SUMMA) SUMGOD_DOH from q   
                                      where  SHIFR_SCHET<1000    -- ������
                                      group by GF_PERSON
                        ) doh
                left join ( Select GF_PERSON, sum(SUMMA)  SUMGOD_VYC from  q 
                                      where SHIFR_SCHET>1000   --  ��� ������ 
                                      group by GF_PERSON
                        ) vyc  
                         on vyc.GF_PERSON=doh.GF_PERSON              
               );
*/                                
          when 30 then 
                nNalRez:=2;    
                -- ��� ��������� ������������
                -- ����� ��������� �����, �������� ���������� ��� ������� �������
                  
                -- ������ ����� ������������ ������,
                -- ����������� �� ������ 30%
                -- ������ ����� ����������� �� ������ 30%
                Select sum(NALOG_ISCHISL)  into  fSIN 
                    from (  -- ���������� ����������, ��� �����������
                            -- ������   (��������� �������� 1�� 2017 18-04-2017) 
                            Select nvl(sum(round(0.3*ds.SUMMA,0)),0) NALOG_ISCHISL 
                            from DV_SR_LSPV ds
                                 inner join DV_SR_LSPV n30 
                                        on n30.NOM_VKL=ds.NOM_VKL and n30.NOM_IPS=ds.NOM_IPS and n30.SHIFR_SCHET=85 and n30.SUB_SHIFR_SCHET=1
                                       and n30.DATA_OP=ds.DATA_OP and n30.SSYLKA_DOC=ds.SSYLKA_DOC and n30.SERVICE_DOC=0               
                                where ds.DATA_OP>=dTermBeg
                                  and ds.DATA_OP< dTermEnd
                                  and ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=60
                                  and ds.NOM_VKL<991
                            union all  
                            -- �������   (��������� �������� 1�� 2017 18-04-2017) 
                            Select nvl(sum(round(0.3*ds.SUMMA,0)),0) NALOG_ISCHISL                 
                            from DV_SR_LSPV ds
                                 inner join DV_SR_LSPV n30 
                                        on n30.NOM_VKL=ds.NOM_VKL and n30.NOM_IPS=ds.NOM_IPS and n30.SHIFR_SCHET=86 and n30.SUB_SHIFR_SCHET=1
                                       and n30.DATA_OP=ds.DATA_OP and n30.SSYLKA_DOC=ds.SSYLKA_DOC and n30.SERVICE_DOC=0                   
                                where ds.DATA_OP>=dTermBeg
                                  and ds.DATA_OP< dTermEnd
                                  and ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=62
                            union all  
                            -- ��������  (��������� ������� 1�� 2017 18-04-2017, ��������� ����� �������� ���������!) 
                            Select nvl(sum(round(0.3*ds.SUMMA,0)),0) NALOG_ISCHISL
                            from DV_SR_LSPV ds
                                 inner join DV_SR_LSPV n30 
                                        on n30.NOM_VKL=ds.NOM_VKL and n30.NOM_IPS=ds.NOM_IPS and n30.SHIFR_SCHET=85 and n30.SUB_SHIFR_SCHET=3
                                       and n30.DATA_OP=ds.DATA_OP and n30.SSYLKA_DOC=ds.SSYLKA_DOC and n30.SERVICE_DOC=0                   
                                where ds.DATA_OP>=dTermBeg
                                  and ds.DATA_OP< dTermEnd
                                  and ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=55   
                            -- �������� ��������� ������ � �������������
                            union all                     
                            -- ������      (��������� �������� 1�� 2017 18-04-2017, ������ ����, �� ��� ����� 30%==>13%, ��������� ����������) 
                            Select nvl(sum(round(0.3*dox.SUMMA,0)),0) NAL_ISCH
                            from
                               (Select * from (    
                                    Select ds.*        -- ��� ����������� ������ ������ ����������� � ������� ����
                                    from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                                        where  ds.SERVICE_DOC<>0
                                        start with   ds.SHIFR_SCHET= 60          -- ������
                                                 and ds.NOM_VKL<991              -- � ������ �� ����
                                                 and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                                 and ds.DATA_OP >= dTermBeg      -- ����������� ������� ����� ������ �������
                                                 and ds.DATA_OP <  dTermKor      -- �� ����� ��������, � ������� ����������� �������������
                                        connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                                 and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                                                 and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                 and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                 and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                                    ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor               
                                ) dox 
                                inner join DV_SR_LSPV n30 
                                          on n30.NOM_VKL=dox.NOM_VKL and n30.NOM_IPS=dox.NOM_IPS and n30.SHIFR_SCHET=85 and n30.SUB_SHIFR_SCHET=1
                                             and n30.DATA_OP=dox.DATA_OP and n30.SSYLKA_DOC=dox.SSYLKA_DOC and n30.SERVICE_DOC=dox.SERVICE_DOC                                           
                            union all                     
                            -- �������              (��������� ������� 1�� 2017 18-04-2017, ��������� ����� �������� ���������!) 
                            Select nvl(sum(dox.SUMMA),0) NALOG_ISCHISL
                            from
                               (Select * from (    
                                    Select ds.*        -- ��� ����������� ������� ������ ����������� � ������� ����
                                    from DV_SR_LSPV ds -- �.�. ��������� ������� ������ ����� �� �����  
                                        where  ds.SERVICE_DOC<>0
                                        start with   ds.SHIFR_SCHET= 62          -- �������
                                                 and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                                 and ds.DATA_OP >= dTermBeg      -- ����������� ������� ����� ������ �������
                                                 and ds.DATA_OP <  dTermKor      -- �� ����� ��������, � ������� ����������� �������������
                                        connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                                 and PRIOR ds.NOM_IPS=ds.NOM_IPS -- ������������� ����������
                                                 and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                 and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                 and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                                    ) where DATA_OP>=dTermBeg and DATA_OP<dTermKor               
                                ) dox 
                                inner join DV_SR_LSPV n30 
                                          on n30.NOM_VKL=dox.NOM_VKL and n30.NOM_IPS=dox.NOM_IPS and n30.SHIFR_SCHET=86 and n30.SUB_SHIFR_SCHET=1
                                             and n30.DATA_OP=dox.DATA_OP and n30.SSYLKA_DOC=dox.SSYLKA_DOC and n30.SERVICE_DOC=dox.SERVICE_DOC                                   
                            union all                     
                            -- ��������             (��������� ������� 1�� 2017 18-04-2017, ��������� ����� �������� ���������!) 
                            Select nvl(sum(dox.SUMMA),0) NAL_ISCH
                            from
                               (Select * from (    
                                    Select ds.*, min(DATA_OP) over(partition by ds.NOM_VKL, ds.NOM_IPS) MINDATOP
                                    from DV_SR_LSPV ds
                                        where  ds.SERVICE_DOC<>0
                                        start with   ds.SHIFR_SCHET= 55       -- ��������
                                                 and ds.SERVICE_DOC=-1        -- ��������� (�������� ����� � -1)
                                                 and ds.DATA_OP >= dTermBeg   -- ����������� ������� ����� ������ �������
                                        connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                 and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                 and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                 and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                 and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC   
                                    ) where MINDATOP>=dTermBeg                     -- ����������� ��������, ���������� � ������� ���� 
                                        and DATA_OP>=dTermBeg and DATA_OP<dTermEnd -- ����������� ������� � ������� �������             
                                ) dox 
                                inner join DV_SR_LSPV n30 
                                          on n30.NOM_VKL=dox.NOM_VKL and n30.NOM_IPS=dox.NOM_IPS and n30.SHIFR_SCHET=85 and n30.SUB_SHIFR_SCHET=3
                                             and n30.DATA_OP=dox.DATA_OP and n30.SSYLKA_DOC=dox.SSYLKA_DOC and n30.SERVICE_DOC=dox.SERVICE_DOC                                
                           );               
/* �������, �������������� �� 1 �� 2017
                with q as (-- ������ � �������� (���������)
                               Select sfl.GF_PERSON, ds.*
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                 where  ds.DATA_OP>=dTermBeg    -- � ������ ����
                                     and ds.DATA_OP < dTermEnd    -- �� ����� ��������� �������  
                                     and ( ds.SHIFR_SCHET= 55 -- ��������
                                              or ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 )) --  ��� ������ �� ����                             
                                     and sfl.NAL_REZIDENT=nNalRez         
                               UNION    -- �������� ������� � ���� �����������                                           
                               -- �������� � ����������� ������
                               Select vrp.GF_PERSON, ds.*
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                         inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                                            from VYPLACH_POSOB 
                                                            where TIP_VYPL=1010
                                                                and DATA_VYPL>=dTermBeg 
                                                                and DATA_VYPL < dTermEnd
                                                                and NAL_REZIDENT = nNalRez
                                                    ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                                 where ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                                    and ds.DATA_OP>=dTermBeg  
                                    and ds.DATA_OP < dTermEnd                                                               
                              )
                     -- ��� ������������         
                     -- ����� 30% � ����������� �� ����� ������������ � ������ �������         
                     Select sum(ISCH_NAL) into fSIN
                                       from( 
                                                 -- ������� ��� ����� ������� �����������  
                                                  Select GF_PERSON, DATA_OP, round( 0.30*SUMMA ) ISCH_NAL  from q   where SERVICE_DOC=0 and SHIFR_SCHET<1000
                                                  UNION ALL
                                                  -- ������� � �������������
                                                  Select osh.GF_PERSON, osh.DATA_OP,  round( 0.30*(osh.SUMMA+kor.SUMMA) ) ISCH_NAL  
                                                           from q OSH  
                                                           inner join q KOR on kor.NOM_VKL=osh.NOM_VKL and kor.NOM_IPS=osh.NOM_IPS and kor.SHIFR_SCHET=osh.SHIFR_SCHET and kor.SSYLKA_DOC=osh.SERVICE_DOC
                                                      where osh.SERVICE_DOC>0          
                                                         and kor.SERVICE_DOC=-1 
                                                         and osh.SHIFR_SCHET<1000
                                                );                     
*/         
          else 
                  return Null;    
                  
       end case;  
                          
       return fSIN;                             
                                     
   end SumIschislNal;    
   
   function SumUderzhNal( pSPRID in number ) return float as
   fSUN         float;
   dTermBeg date;
   dTermEnd date;
   nGod        number;
   nPeriod    number; 
   nNalRez   number;
   begin

          -- ������� ������� �������
       Select GOD, PERIOD into nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
       dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
       case nPeriod
           when 21 then dTermEnd := add_months(dTermBeg,3);         
           when 31 then dTermEnd := add_months(dTermBeg,6);        
           when 33 then dTermEnd := add_months(dTermBeg,9);        
           when 34 then dTermEnd := add_months(dTermBeg,12);      
           else  return Null;                
       end case;

                 -- ������ �������� �� ������ �� 1� ��������� 2016 ����   
                 -- ������ ���������� � ��� ����� ����������� ���������
                 -- ������ � �������� ������� �� ���� (���� SERVICE_DOC)
                 Select sum(SUMNAL) into fSUN from (
                             -- ������ � ��������
                             -- ���������� ����������, �� ����������������� ����� ��������� ������
                             Select  sum( ds.SUMMA ) SUMNAL
                                 from DV_SR_LSPV ds
                                 where  ds.DATA_OP>=dTermBeg        -- � ������ ����
                                     and ds.DATA_OP < dTermEnd        -- �� ����� ��������� �������  
                                     and ds.SERVICE_DOC=0              -- ������� ��� ����������� �����������
                                     and ds.SHIFR_SCHET=85  -- �����  � ������ � ��������  
                           UNION ALL
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               Select sum(SUMKORR) SUMNAL from (
                                            Select ds.NOM_VKL,ds.NOM_IPS, ds.SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds                 
                                         --  where ds.DATA_OP>dTermBeg -- ��������� �������� ������ � ������� �������� �������                                       
                                             start with ds.SHIFR_SCHET=85  -- �����  � ������ � �������� 
                                                    and ds.SERVICE_DOC=-1             -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg          -- ����������� �������                           
                                                    and ds.DATA_OP < dTermEnd         -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  ds.NOM_VKL,ds.NOM_IPS, ds.SHIFR_SCHET   
                                         --  ������������ ���� � ������� �������  
                                             having min(ds.DATA_OP)>=dTermBeg -- ���������� ����������� ��������, ��������� �� �������     
                                       )                
                          UNION ALL                                            
                              -- �������� � ����������� ������
                              Select sum(ds.SUMMA) SUMNAL
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                         inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                                            from VYPLACH_POSOB 
                                                            where TIP_VYPL=1010
                                                                and DATA_VYPL>=dTermBeg 
                                                                and DATA_VYPL < dTermEnd
                                                    ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                              where ds.SHIFR_SCHET=86 -- ����� �� �������� � ����������� ������
                                    and ds.DATA_OP >=dTermBeg  
                                    and ds.DATA_OP < dTermEnd                                                                            
                
                  );                             
       
   return fSUN; -- + SumVozvraNal(pSPRID);  + SumVozvraNal83( pSPRID );

   end SumUderzhNal;   

   function SumNeUderzhNal( pSPRID in number ) return float is
   vReportCursor  sys_refcursor;
   vErrInfo varchar2(4000);
   recNEDOPL float;
   sumNEDOPL float;
   nGag number;
   fGag float;
   tGag varchar2(255);
   begin
   
      Sverka_NesovpadNal( vReportCursor, vErrInfo, pSPRID );
      if vErrInfo is not Null then 
         return Null; 
         end if;
         
    sumNEDOPL:=0;
    loop
       fetch vReportCursor into nGag, nGag, fGag, fGag, recNEDOPL, tGag, tGag, tGag;
       Exit when vReportCursor%NOTFOUND;
          sumNEDOPL := sumNEDOPL + recNEDOPL;
       end loop;
       close vReportCursor;

    return sumNEDOPL;       
   
   end SumNeUderzhNal;


   -- ����� ������, ������������� ��������� �������
   -- ����������� ������ ���������� �������� (���� 83)
   function SumVozvraNal83( pSPRID in number ) return float as
   fSUM83   float;
   fSUMPV   float;
   dTermBeg date;
   dTermEnd date;
   nGod     number;
   nPeriod  number; 
   nNalRez  number;
   begin

          -- ������� ������� �������
       Select GOD, PERIOD into nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
       dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
       case nPeriod
           when 21 then dTermEnd := add_months(dTermBeg,3);         
           when 31 then dTermEnd := add_months(dTermBeg,6);        
           when 33 then dTermEnd := add_months(dTermBeg,9);        
           when 34 then dTermEnd := add_months(dTermBeg,12);      
           else  return Null;                
       end case;
       
   Select sum(SUMMA) into fSUM83 from DV_SR_LSPV 
     where SHIFR_SCHET=83 and DATA_OP>=dTermBeg and DATA_OP<dTermEnd;
   
   return nvl(fSUM83,0);
   
   end SumVozvraNal83;   
   
   
   -- ����� ������, ������������� ��������� �������
   -- ������� ������������ ���������� �����/����� ������ � ���������� ������
   -- ������������� ����������� ������ � �������� �����
   -- �� �������������� �����������
      
   function SumVozvraNalDoc( pSPRID in number ) return float as
   fSUM83   float;
   fSUMPV   float;
   dTermBeg date;
   dTermEnd date;
   nGod     number;
   nPeriod  number; 
   nNalRez  number;
   begin

          -- ������� ������� �������
       Select GOD, PERIOD into nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
       dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
       case nPeriod
           when 21 then dTermEnd := add_months(dTermBeg,3);         
           when 31 then dTermEnd := add_months(dTermBeg,6);        
           when 33 then dTermEnd := add_months(dTermBeg,9);        
           when 34 then dTermEnd := add_months(dTermBeg,12);      
           else  return Null;                
       end case;   
 
       -- ������ 25-10-2016  
       --   �������� ��� ��� 17-04-2017
       --   ������ ������ ����� ��������� ���� �� ������: ������ ���� - ����� ��������� �������� 
       --   ������������ ������ ������ ���� ������� �� ����� ����� �������� �������
       --   � ����� ��������� ���������� �����������, ��������� � ������� ������� 
       with ispr as (   
                Select q.*
                --       ,sum(SUMMA)   over(partition by NOM_VKL, NOM_IPS) CHK_SUM   -- ��������� �� ������
                --       ,min(DATA_OP) over(partition by NOM_VKL, NOM_IPS) MIN_DAT   -- ���� ��������������� ���������
                --       ,count(*)     over(partition by NOM_VKL, NOM_IPS) CHK_CNT   -- ����� �������: ��������� � �����������
                --       ,count(*)     over(partition by NOM_VKL, NOM_IPS order by DATA_OP rows unbounded preceding) CHK_ORD
                from(
                     Select ds.*, CONNECT_BY_ISLEAF ISLEAF 
                     from DV_SR_LSPV ds
                        start with ds.SHIFR_SCHET =85       -- ��������� �������
                                and ds.SUB_SHIFR_SCHET > 1  -- ������ ��������, ������ ���������
                                and ds.SERVICE_DOC= -1      -- ��������� (�������� � -1)
                                and ds.DATA_OP>=dTermBeg    -- ��������� ��������� ������ ������� ��� �����
                        connect by PRIOR ds.NOM_VKL=ds.NOM_VKL  
                               and PRIOR ds.NOM_IPS=ds.NOM_IPS
                               and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                               and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                               and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                    UNION ALL           
                     Select ds.*, CONNECT_BY_ISLEAF ISLEAF 
                     from DV_SR_LSPV ds
                        start with ds.SHIFR_SCHET =85       -- ��������� �������
                                and ds.SUB_SHIFR_SCHET <2  -- ������ ������
                                and ds.SERVICE_DOC= -1      -- ��������� (�������� � -1)
                                and ds.DATA_OP>=dTermBeg    -- ��������� ��������� ������ ������� ��� �����
                                and exists (
                                       -- �� ���� �� �������� � ��������� ������ ���� ������ �� ����� 83
                                       -- ��� ������� �� ������, � �������� ������
                                       Select * from DV_SR_LSPV vv
                                       where vv.NOM_VKL=ds.NOM_VKL and vv.NOM_IPS=ds.NOM_IPS and vv.SSYLKA_DOC=ds.SSYLKA_DOC
                                             and vv.SHIFR_SCHET=83 and vv.SERVICE_DOC=0
                                    )
                        connect by PRIOR ds.NOM_VKL=ds.NOM_VKL  
                               and PRIOR ds.NOM_IPS=ds.NOM_IPS
                               and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                               and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                               and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC                                
                    ) q  
              )
        Select -sum(SUMMA) into fSUMPV 
        from ispr                     -- �����, ������ ��� ����� ������� - ������������� �����, � � �������� �� ���� �������������
          where DATA_OP >= dTermBeg   -- �������� � ����� �������� �����������,
            and DATA_OP  < dTermEnd   -- ����������� ������ � ������� �������
            and ISLEAf = 0;           -- ������ �����������, ��� ��������� �����/ ��� ������������ ������ ������
            
              
   return nvl(fSUMPV,0);         
      
   end SumVozvraNalDoc;    
   
   -- ����� ������, ������������� ��������� �������
   -- �����
   
   function SumVozvraNal( pSPRID in number ) return float as
   fSUM83   float;
   fSUMPV   float;
   dTermBeg date;
   dTermEnd date;
   nGod     number;
   nPeriod  number; 
   nNalRez  number;
   begin

 /*    ������ 25-10-2016      */
 /*           18-04-2017      */
   
                    --fSUM83:= SumVozvraNal83(pSPRID);
   fSUMPV:= SumVozvraNalDoc(pSPRID);

   return fSUMPV;   -- � ���� 090 ������ ��, ��� ������� �� ��������(���������)    �� ����� + fSUM83;
   
   end SumVozvraNal;
   
   
/*
declare
TW sys_refcursor;
RC varchar2(1000);
begin
  dbms_output.enable(10000);  
  FXNDFL_UTIL.ZaPeriodPoDatam( TW, RC, 149565 );
  :CC := TW;
  dbms_output.put_line( nvl(RC,'��') );
END;
*/   
   procedure ZaPeriodPoDatam( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number, pKorKV in number default 0 ) as
   dTermBeg date;
   dTermEnd date;
   dTermKor date;
   nGod     number;
   nPeriod  number; 
   nNalRez  number;
   begin

          -- ������� ������� �������
       Select GOD, PERIOD into nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
       dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
       case nPeriod
           when 21 then dTermEnd := add_months(dTermBeg,3);         
           when 31 then dTermEnd := add_months(dTermBeg,6);        
           when 33 then dTermEnd := add_months(dTermBeg,9);        
           when 34 then dTermEnd := add_months(dTermBeg,12);      
           else pErrInfo :='������ ���������� ���������� �������.'; return;                
       end case;
       
       -- ��� �������������� �������
       -- pKorKV - ����� ��������� ����� ���������, � ������ ����� ������ ����������� � �������� ��������
       if pKorKV>0 then
          dTermKor := add_months(dTermEnd,3*pKorKV );  -- ��������� ���� ����� �����������
       else
          dTermKor := dTermEnd;
       end if;
   
       open pReportCursor for 
 
             with    -- ����� � ����� ���������� ������������
             qDoh as (   
                     -- ������, �������� � ��������
                     -- ��� �����������
                     Select  DATA_OP, sum(SUMMA) SUMDOH
                     from(
                              Select ds.DATA_OP, ds.SUMMA
                                     from DV_SR_LSPV ds                                   
                                     where  ds.DATA_OP >= dTermBeg        -- � ������ ����
                                        and ds.DATA_OP <  dTermEnd        -- �� ����� ��������� �������  
                                        and ds.SERVICE_DOC=0              -- ������� ��� ����������� �����������   
                                        and (    ds.SHIFR_SCHET= 55                      -- ��������
                                            or ( ds.SHIFR_SCHET= 60 and ds.NOM_VKL<991 ) -- ������ �� ����
                                            or   ds.SHIFR_SCHET= 62 )                    -- ��������
                          UNION ALL
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               -- ������
                               -- (��� ������ ����� ������ ���������� ��� ����, ������ ��� ������)
                               Select MINDATOP as DATA_OP, SUMKORR as SUMMA from (
                                            Select ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds                                           
                                             start with ds.SHIFR_SCHET=60          -- ������
                                                    and ds.NOM_VKL<991             --  �� �� ����� �������
                                                    and ds.SERVICE_DOC=-1          -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg       -- ����������� �������                          
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET      
                                       )  where MINDATOP >= dTermBeg              -- ������������ ���������� ����
                                            and MINDATOP <  dTermEnd              -- � ������� �������� �������    
                          UNION ALL                                            
                               -- ��������
                               Select MINDATOP as DATA_OP, sum(SUMKORR) as SUMMA 
                               from (
                                            Select -- ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                                   ds.DATA_OP DATKORR,
                                                   ds.SUMMA   SUMKORR,
                                                   min(ds.DATA_OP) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) MINDATOP
                                            from  DV_SR_LSPV ds                                    
                                             start with ds.SHIFR_SCHET=55          -- ��������
                                                    and ds.SERVICE_DOC=-1          -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg       -- ����������� �������                          
                                                --  and ds.DATA_OP < to_date('01.01.2017')      -- � ������� �������� ������� � �����                                               
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                         -- group by  ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET      
                                       )  where MINDATOP >= dTermBeg       -- ������������ ���������� ����
                                            and MINDATOP <  dTermEnd       -- � ������� �������� �������
                                            and DATKORR  <  dTermKor       -- ��������� �����������, ��������� ����� ��������� �������� �� ����� ��������� pKorKV
                                        group by MINDATOP                                                                             
                          ) group by DATA_OP    
                     ),
             qNal as (
                     -- ������ � ������ � ��������
                     -- ��� �����������
                     Select  DATA_OP, sum(SUMMA) SUMNAL
                     from(
                             Select ds.DATA_OP, ds.SUMMA 
                                 from DV_SR_LSPV ds
                                 where ds.DATA_OP >= dTermBeg  -- � ������ ����
                                   and ds.DATA_OP <  dTermEnd  -- �� ����� ��������� �������  
                                   and ds.SERVICE_DOC=0        -- ������� ��� ����������� �����������
                                   and ds.SHIFR_SCHET=85       -- ������ �� ������ ������ � ��������
                           UNION ALL
                               -- ������������ ������
                               -- ����������� � ����������������� � ������� �������
                               -- (������ �� ������ ����� ���� ������ ������, � ����� ������ ���� �����!)
                               Select MINDATOP as DATA_OP, SUMKORR as SUMMA from (
                                            Select  ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds 
                                        ---    
                                        --   ��������� �������� ������ � ������� �������� �������
                                        ---                                                   
                                             start with ds.SHIFR_SCHET=85      --  ������ �� ������ ������ 
                                                    and ds.SUB_SHIFR_SCHET <2  --  �� �� ����� �������
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP >= dTermBeg       -- ����������� �������                         
                                                    and ds.DATA_OP <  dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by   ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET         
                                       )  where MINDATOP >= dTermBeg               -- ������������ ���������� ����
                                            and MINDATOP <  dTermEnd              -- � ������� �������� �������      
                           UNION ALL
                               -- ������������ ��������
                               -- � ������ 2 ������ ������� ������������� ���������� ����� ������
                               -- �����������/�������� �� ��������� ������ ������� � ���� 090 ������� 1
                               Select DATA_OP, SUMMA 
                               from (
                                            Select  ds.DATA_OP, ds.SUMMA, CONNECT_BY_ISLEAF ISLEAF
                                            from  DV_SR_LSPV ds                                                   
                                             start with ds.SHIFR_SCHET=85      --  ������ �� ������ 
                                                    and ds.SUB_SHIFR_SCHET >1  --  �������� ����
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP >= dTermBeg       -- ��������� ����������� ������� � ������� �������� ������� � �����                         
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC        
                                    ) where DATA_OP >= dTermBeg    -- ��������� ������ ��������
                                        and DATA_OP <  dTermEnd    -- � ������� �������� ������� 
                                        and ISLEAF=1               -- �������������� ����� � ������� �������                                                      
                           UNION ALL                                      
                               -- �������� � ����������� ������
                               Select ds.DATA_OP, ds.SUMMA
                                  from DV_SR_LSPV ds          
                                  where ds.SHIFR_SCHET=86 -- ����� �� �������� � ����������� ������
                                      and ds.SERVICE_DOC=0  
                                      and ds.DATA_OP >= dTermBeg  
                                      and ds.DATA_OP <  dTermEnd    
                             ) group by DATA_OP     
                     )
             Select * from (        
                     Select doh.DATA_OP DATA_FACT_DOH, doh.DATA_OP DATA_UDERZH_NAL, nal.DATA_OP+1 SROK_PERECH_NAL, doh.SUMDOH  POLUCHDOH, nvl(nal.SUMNAL,0) UDERZHNAL
                             from  (Select * from qDoh) doh
                                  left join (Select * from qNal) nal  on nal.DATA_OP=doh.DATA_OP    
                     union            
                     Select nal.DATA_OP DATA_FACT_DOH, nal.DATA_OP DATA_UDERZH_NAL, nal.DATA_OP+1 SROK_PERECH_NAL, 0  POLUCHDOH, nal.SUMNAL UDERZHNAL
                             from  (Select * from qDoh) doh
                                  right join (Select * from qNal) nal  on nal.DATA_OP=doh.DATA_OP     
                             where doh.DATA_OP is Null ) 
           where  ( POLUCHDOH<>0 )
                 or  ( UDERZHNAL<>0  )                   
           order by DATA_FACT_DOH -- doh.DATA_OP                                       
        ;
   
        pErrInfo := Null; 
 
     exception
        when OTHERS then pErrInfo := SQLERRM;     
        
   end ZaPeriodPoDatam;
   
    -- ������������ ����������� � ���������� ���� �������
    procedure Sverka_NesovpadNal( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number ) as
    dTermBeg date;
    dTermEnd date;
    nGod        number;
    nPeriod    number; 
    nNalRez   number;
    begin

          -- ������� ������� �������
        Select GOD, PERIOD into nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
        dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
        case nPeriod
            when 21 then dTermEnd := to_date( '01.04.'||to_char(nGod),'dd.mm.yyyy' );         
            when 31 then dTermEnd := to_date( '01.07.'||to_char(nGod),'dd.mm.yyyy' );        
            when 33 then dTermEnd := to_date( '01.10.'||to_char(nGod),'dd.mm.yyyy' );        
            when 34 then dTermEnd := to_date( '01.01.'||to_char(nGod+1),'dd.mm.yyyy' );      
            else pErrInfo :='������ ���������� ���������� �������.'; return;                
        end case;
   
        open pReportCursor for 
        with  q13 as (
 /*     -- �� ��������� ����� (��� �� �������� � ��������)
        -- ������
        Select sfl.GF_PERSON, 60 SHIFR_SCHET, vp.DATA_VYPL DATA_OP, sum(vp.PENS) SUMMA
        from VYPLACH_PEN_BUF vp inner join SP_FIZ_LITS sfl on sfl.SSYLKA=vp.SSYLKA
        where vp.NOM_VKL<991 and SFL.NAL_REZIDENT=1  
        group by sfl.GF_PERSON, vp.DATA_VYPL
        union all
        -- ������        
        Select sfl.GF_PERSON, 1111 SHIFR_SCHET, vp.DATA_VYPL DATA_OP, sum(vp.LPN_SUM) SUMMA
        from VYPLACH_PEN_BUF vp inner join SP_FIZ_LITS sfl on sfl.SSYLKA=vp.SSYLKA
        where vp.NOM_VKL<991 and SFL.NAL_REZIDENT=1  
        group by sfl.GF_PERSON, vp.DATA_VYPL
        
        UNION ALL
               
*/      --
                              -- ������ � �������� (������ ���������)
                              -- ���������� ����������, ��� �����������
                              -- ������ 
                              Select  sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                         -- ������ �� ����, � ������� ������������ �����
                                         inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                             where SHIFR_SCHET=85
                                                               and SUB_SHIFR_SCHET in (0,1)  -- ������
                                                               and DATA_OP>=dTermBeg  
                                                               and DATA_OP < dTermEnd
                                                      ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                 where  ds.DATA_OP>=dTermBeg        -- � ������ ����
                                     and ds.DATA_OP < dTermEnd      -- �� ����� ��������� �������  
                                     and ds.SERVICE_DOC=0           -- ������� ��� ����������� �����������
                                     and sfl.NAL_REZIDENT=1         -- �� ������ 13%
                                     and sfl.PEN_SXEM<>7            -- �� ���
                                     and ( ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 ) -- ������ �� ����
                                          or ds.SHIFR_SCHET>1000 )                    -- ��������������� ����� �������  
                              -- ��������
                              UNION ALL
                              Select  sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                         -- ������ �� ����, � ������� ������������ �����
                                         inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                           where   SHIFR_SCHET=85
                                                               and SUB_SHIFR_SCHET in (2,3)  -- ��������
                                                               and DATA_OP>=dTermBeg  
                                                               and DATA_OP < dTermEnd 
                                                    ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                         inner join (Select distinct SSYLKA from VYPLACH_POSOB 
                                                        where TIP_VYPL=1030
                                                          and DATA_VYPL>=dTermBeg
                                                          and DATA_VYPL < dTermEnd
                                                          and NAL_REZIDENT=1  -- �� ������ 13%
                                                    ) rp on rp.SSYLKA=lspv.SSYLKA_FL  -- ���� ������� �� ������, �� ��� ���   
                                 where  ds.DATA_OP>=dTermBeg        -- � ������ ����
                                     and ds.DATA_OP < dTermEnd      -- �� ����� ��������� �������  
                                     and ds.SERVICE_DOC=0           -- ������� ��� ����������� �����������
                                     and ds.SHIFR_SCHET= 55    -- ��������
                                       --    or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������     �� �������� ������� �� ����  ???                                       
                               UNION ALL 
                               -- ������������ ������ � �������� 
                               -- ���������� � ��������� � ������� �������
                               -- ������
                               Select GF_PERSON, SHIFR_SCHET, MINDATOP DATA_OP, SUMKORR SUMMA from (
                                            Select sfl.GF_PERSON, ds.SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                                     where SHIFR_SCHET=85 
                                                                       and SUB_SHIFR_SCHET in (0,1)  -- ������
                                                                       and DATA_OP>=dTermBeg  
                                                                       and DATA_OP < dTermEnd 
                                                                   ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                            where  sfl.NAL_REZIDENT=1                 -- �� ������ 13%        
                                                 and sfl.PEN_SXEM<>7  -- �� ���
                                             start with ( ( ds.SHIFR_SCHET=60  and ds.NOM_VKL<991 ) --  ��� ������ �� ����
                                                       or (ds.SHIFR_SCHET>1000 and ds.NOM_VKL<991 ) )  -- ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1          -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg       -- ����������� �������
                                                    -- ����������� ����� ���� ������� � �����, ���� ���������, ����� �� ������������ �������� ������?                              
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  sfl.GF_PERSON, ds.SHIFR_SCHET          
                                       )  where MINDATOP>=dTermBeg               -- ������������ ���������� ����
                                            and MINDATOP < dTermEnd               -- � ������� �������� �������       
                               -- ��������
                               UNION ALL
                               Select GF_PERSON, SHIFR_SCHET, MINDATOP DATA_OP, SUMKORR SUMMA from (
                                            Select sfl.GF_PERSON, ds.SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                                       where SHIFR_SCHET=85 
                                                                           and SUB_SHIFR_SCHET in (2,3)  -- ��������
                                                                           and DATA_OP>=dTermBeg  
                                                                           and DATA_OP < dTermEnd 
                                                                   ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                                        inner join (Select distinct SSYLKA from VYPLACH_POSOB 
                                                                        where TIP_VYPL=1030
                                                                          and DATA_VYPL>=dTermBeg
                                                                          and DATA_VYPL < dTermEnd
                                                                          and NAL_REZIDENT=1  -- �� ������ 13%
                                                                   ) rp on rp.SSYLKA=lspv.SSYLKA_FL  -- ���� ������� �� ������, �� ��� ���                                                                      
                                             start with ds.SHIFR_SCHET= 55 -- ��������
                                                       --  or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������  �� �������� ������� �� ���� ???
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg       -- ����������� �������
                                                    -- ����������� ����� ���� ������� � �����, ���� ���������, ����� �� ������������ �������� ������?                              
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  sfl.GF_PERSON, ds.SHIFR_SCHET          
                                       )  where MINDATOP>=dTermBeg               -- ������������ ���������� ����
                                            and MINDATOP < dTermEnd               -- � ������� �������� �������       
                              UNION ALL 
                              -- �������� � ����������� ������
                               -- ���������� ����������, ��� �����������
                               Select vrp.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                     from DV_SR_LSPV ds
                                             inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                             inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                                                from VYPLACH_POSOB 
                                                                where TIP_VYPL=1010                -- �������� � ����������� ������
                                                                   and NAL_REZIDENT=1             -- �� ������ 13%      
                                                                   and DATA_VYPL>=dTermBeg    -- � ������ ����
                                                                   and DATA_VYPL < dTermEnd    -- �� ����� ��������� ������� 
                                                            ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                                     where (ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                                               or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                        and ds.SERVICE_DOC=0  -- ������� �� ����������������
                                        and ds.DATA_OP>=dTermBeg  
                                        and ds.DATA_OP < dTermEnd         
                  /*           UNION
                               -- �������� � ����������� ������
                               -- ����������� � ����������������� � ������� �������
                               � � � � �   � � � � � � � � (���� ����� ��� ��� - ��� �������)
                  */                                                                      
                              ),
       q30 as (-- ������ � �������� (���������)
               Select sfl.GF_PERSON, ds.*
                 from DV_SR_LSPV ds
                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                 where  ds.DATA_OP>=dTermBeg    -- � ������ ����
                     and ds.DATA_OP < dTermEnd    -- �� ����� ��������� �������  
                     and ( ds.SHIFR_SCHET= 55 -- ��������
                              or ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 )) --  ��� ������ �� ����                             
                     and sfl.NAL_REZIDENT=2        
               UNION    -- �������� ������� � ���� �����������                                           
               -- �������� � ����������� ������
               Select vrp.GF_PERSON, ds.*
                 from DV_SR_LSPV ds
                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                         inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                            from VYPLACH_POSOB 
                                            where TIP_VYPL=1010
                                                and DATA_VYPL>=dTermBeg 
                                                and DATA_VYPL < dTermEnd
                                                and NAL_REZIDENT = 2
                                    ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                 where ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                    and ds.DATA_OP>=dTermBeg  
                    and ds.DATA_OP < dTermEnd                                                               
              ) 
          -- ����������  
       Select res.*, ISCH_NAL-UDERZH_NAL NEDOPLATA,
              pe.Lastname, pe.Firstname, pe.Secondname 
       from(         
          Select 30 STAVKA, cn.GF_PERSON, cn.ISCH_NAL, bn.UDERZH_NAL  from (
                      Select GF_PERSON, sum(round( 0.30*SUMMA )) ISCH_NAL from q30 where SERVICE_DOC=0 and SHIFR_SCHET<1000
                          group by GF_PERSON          
                     )cn
                   left join (
                        Select  GF_PERSON, nvl(sum(SUMPOTIPU),0) UDERZH_NAL from ( 
                          Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                              inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                              inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                            where ds.SERVICE_DOC=0
                              and ds.SHIFR_SCHET=85 
                              and ds.SUB_SHIFR_SCHET=1
                              and ds.NOM_VKL<991
                              and ds.DATA_OP>=dTermBeg  
                              and ds.DATA_OP < dTermEnd 
                              and sfl.NAL_REZIDENT=2     
                          UNION ALL               
                          Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                              inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                              inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                            where ds.SERVICE_DOC=0
                              and ds.SHIFR_SCHET=85 
                              and ds.SUB_SHIFR_SCHET=3
                              and ds.DATA_OP>=dTermBeg  
                              and ds.DATA_OP < dTermEnd
                              and sfl.NAL_REZIDENT=2  
                          UNION ALL      
                          Select vrp.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                              inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                              inner join (Select SSYLKA, SSYLKA_DOC, GF_PERSON   
                                            from VYPLACH_POSOB 
                                            where TIP_VYPL=1010
                                              and DATA_VYPL>=dTermBeg 
                                              and DATA_VYPL < dTermEnd
                                              and NAL_REZIDENT = 2
                                          ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC                       
                            where ds.SERVICE_DOC=0
                             and ds.SHIFR_SCHET=86 
                             and ds.SUB_SHIFR_SCHET=1
                             and ds.DATA_OP>=dTermBeg  
                             and ds.DATA_OP < dTermEnd 
                        ) group by GF_PERSON  
                   ) bn on bn.GF_PERSON=cn.GF_PERSON           
               where cn.ISCH_NAL <> bn.UDERZH_NAL
         Union 
            -- ��� ������   
            Select 13 STAVKA, GF_PERSON, ISCH_NAL, UDERZH_NAL  from (
            --Select q.*, ISCH_NAL-UDERZH_NAL RAZN from (                                 
                Select  doh.GF_PERSON,  -- 149.611
                   -- ������ ������ ��� ��������� ���������� 
                             -- ������ � ���������� ��� ������ �������
                             round( 0.13* case when doh.SUMGOD_DOH < nvl(vyc.SUMGOD_VYC,0 )  
                                                   then 0
                                                   else doh.SUMGOD_DOH - nvl(vyc.SUMGOD_VYC,0)
                                                end ) ISCH_NAL, 
                        nvl(bn.UD_NAL,0) UDERZH_NAL                               
                from (    Select GF_PERSON,  sum(SUMMA) SUMGOD_DOH from q13  
                                      where  SHIFR_SCHET<1000    -- ������
                                      group by GF_PERSON
                        ) doh
                left join ( Select GF_PERSON, sum(SUMMA)  SUMGOD_VYC from  q13 
                                      where SHIFR_SCHET>1000   --  ��� ������ 
                                      group by GF_PERSON
                        ) vyc  
                         on vyc.GF_PERSON=doh.GF_PERSON     
                left join ( Select  GF_PERSON, nvl(sum(SUMPOTIPU),0) UD_NAL from (
                              -- ���������� ������
                              Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=85 
                                  and ds.SUB_SHIFR_SCHET=0
                                  and ds.NOM_VKL<991
                                  and ds.DATA_OP>=dTermBeg  
                                  and ds.DATA_OP < dTermEnd 
                                  and sfl.NAL_REZIDENT=1
                                       
/* ������ ��� �������, ��� �������� ��������/�������� � ������ �� � ����������� ��������
     -- ��������� ����� �� ������                             
        union all
        -- �����
        Select sfl.GF_PERSON, sum(vp.UDERGANO) SUMPOTIPU
        from VYPLACH_PEN_BUF vp inner join SP_FIZ_LITS sfl on sfl.SSYLKA=vp.SSYLKA
        where vp.NOM_VKL<991 and SFL.NAL_REZIDENT=1  
        group by sfl.GF_PERSON    
     --
*/                                  
                            UNION ALL         
                              -- ���������� ��������       
                              Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                  inner join (Select distinct SSYLKA from VYPLACH_POSOB 
                                                        where TIP_VYPL=1030
                                                          and DATA_VYPL>=dTermBeg
                                                          and DATA_VYPL < dTermEnd 
                                                          and NAL_REZIDENT=1  -- �� ������ 13%
                                              ) rp on rp.SSYLKA=lspv.SSYLKA_FL  -- ���� ������� �� ������, �� ��� ��� 
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=85 
                                  and ds.SUB_SHIFR_SCHET=2
                                  and ds.DATA_OP >= dTermBeg  
                                  and ds.DATA_OP <  dTermEnd 
                            UNION ALL   
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               Select sfl.GF_PERSON, kor.SUMKORR as SUMPOTIPU from (
                                            Select  ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds
                                            where  ds.SUB_SHIFR_SCHET in (0,2) -- ������ 13%                                                   
                                             start with ds.SHIFR_SCHET=85    --  ������ �� ������ ������ � ��������
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg       -- ����������� �������                         
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by   ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET         
                                       ) kor  
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=kor.NOM_VKL and lspv.NOM_IPS=kor.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL                                       
                                         where kor.MINDATOP>=dTermBeg               -- ������������ ���������� ����
                                           and kor.MINDATOP < dTermEnd              -- � ������� �������� �������   
                            UNION ALL
                              -- ������� � ���������� ����
                              Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                  left join DV_SR_LSPV vv 
                                         on vv.NOM_VKL=ds.NOM_VKL and vv.NOM_IPS=ds.NOM_IPS and vv.SSYLKA_DOC=ds.SSYLKA_DOC
                                            and vv.SHIFR_SCHET=85 and vv.SERVICE_DOC=-1
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=83 
                                  and ds.DATA_OP >= dTermBeg  
                                  and ds.DATA_OP <  dTermEnd  
                                  and vv.NOM_VKL is Null
                            UNION ALL      
                              -- ��������
                              Select vrp.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join (Select SSYLKA, SSYLKA_DOC, GF_PERSON   
                                                        from VYPLACH_POSOB 
                                                        where TIP_VYPL=1010
                                                            and DATA_VYPL>=dTermBeg 
                                                            and DATA_VYPL < dTermEnd
                                                            and NAL_REZIDENT = 1
                                              ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC                       
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=86 
                                  and ds.SUB_SHIFR_SCHET=0
                                  and ds.DATA_OP>=dTermBeg  
                                  and ds.DATA_OP < dTermEnd                     
                            ) group by GF_PERSON      
                        ) bn 
                         on bn.GF_PERSON=doh.GF_PERSON      
           ) where abs(ISCH_NAL - UDERZH_NAL)>0.01        
      ) res 
      left join gazfond.People pe on pe.fk_CONTRAGENT=res.GF_PERSON
      order by STAVKA, ISCH_NAL-UDERZH_NAL                                    
;            
        
    end Sverka_NesovpadNal;
   
-- ����� ��� �������� ���������
    procedure Sverka_NesovpadNal_v2( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number ) as
    dTermBeg date;
    dTermEnd date;
    nGod        number;
    nPeriod    number; 
    nNalRez   number;
    begin

          -- ������� ������� �������
        Select GOD, PERIOD into nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
        dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
        case nPeriod
            when 21 then dTermEnd := to_date( '01.04.'||to_char(nGod),'dd.mm.yyyy' );         
            when 31 then dTermEnd := to_date( '01.07.'||to_char(nGod),'dd.mm.yyyy' );        
            when 33 then dTermEnd := to_date( '01.10.'||to_char(nGod),'dd.mm.yyyy' );        
            when 34 then dTermEnd := to_date( '01.01.'||to_char(nGod+1),'dd.mm.yyyy' );      
            else pErrInfo :='������ ���������� ���������� �������.'; return;                
        end case;
   
        open pReportCursor for 
        with  q13 as (
 /*     -- �� ��������� ����� (��� �� �������� � ��������)
        -- ������
        Select sfl.GF_PERSON, 60 SHIFR_SCHET, vp.DATA_VYPL DATA_OP, sum(vp.PENS) SUMMA
        from VYPLACH_PEN_BUF vp inner join SP_FIZ_LITS sfl on sfl.SSYLKA=vp.SSYLKA
        where vp.NOM_VKL<991 and SFL.NAL_REZIDENT=1  
        group by sfl.GF_PERSON, vp.DATA_VYPL
        union all
        -- ������        
        Select sfl.GF_PERSON, 1111 SHIFR_SCHET, vp.DATA_VYPL DATA_OP, sum(vp.LPN_SUM) SUMMA
        from VYPLACH_PEN_BUF vp inner join SP_FIZ_LITS sfl on sfl.SSYLKA=vp.SSYLKA
        where vp.NOM_VKL<991 and SFL.NAL_REZIDENT=1  
        group by sfl.GF_PERSON, vp.DATA_VYPL
        
        UNION ALL
               
*/      --
                              -- ������ � �������� (������ ���������)
                              -- ���������� ����������, ��� �����������
                              
                              -- ������ 
                              Select  sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                         -- ��� ����������� ������
                                         left join 
                                             (Select * from DV_SR_LSPV
                                                 where SHIFR_SCHET=85
                                                   and SUB_SHIFR_SCHET=1 -- ������ ���� �� 30%
                                                   and DATA_OP >= dTermBeg  
                                                   and DATA_OP <  dTermEnd
                                             ) c85  
                                                 on ds.NOM_VKL=c85.NOM_VKL and ds.NOM_IPS=c85.NOM_IPS 
                                                and ds.DATA_OP=c85.DATA_OP and ds.SHIFR_SCHET=c85.SHIFR_SCHET   
                                                and ds.SSYLKA_DOC=c85.SSYLKA_DOC             
                                 where   ds.DATA_OP >=dTermBeg        -- � ������ ����
                                     and ds.DATA_OP < dTermEnd        -- �� ����� ��������� �������  
                                     and ds.SERVICE_DOC=0             -- ������� ��� ����������� �����������
                                     and ds.NOM_VKL<991               -- ������ �� �� ����� �������
                                     and (   ds.SHIFR_SCHET=60        -- ����������� ����� ������
                                          or ds.SHIFR_SCHET>1000 )    -- ��� ��������������� ����� �������  
                                     and c85.SUB_SHIFR_SCHET is Null  -- �� ������ 13% ��� ���������!    
                              -- ��������
                              UNION ALL
                              Select  sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                         -- ��� ����������� ������
                                         left join 
                                             (Select * from DV_SR_LSPV
                                                 where SHIFR_SCHET=85
                                                   and SUB_SHIFR_SCHET=3 -- ������ ���� �� 30%
                                                   and DATA_OP >= dTermBeg  
                                                   and DATA_OP <  dTermEnd
                                             ) c85  
                                                 on ds.NOM_VKL=c85.NOM_VKL and ds.NOM_IPS=c85.NOM_IPS 
                                                and ds.DATA_OP=c85.DATA_OP and ds.SHIFR_SCHET=c85.SHIFR_SCHET   
                                                and ds.SSYLKA_DOC=c85.SSYLKA_DOC
                                 where  ds.DATA_OP >=dTermBeg     -- � ������ ����
                                    and ds.DATA_OP < dTermEnd     -- �� ����� ��������� �������  
                                    and ds.SERVICE_DOC=0          -- ������� ��� ����������� �����������
                                    and (ds.SHIFR_SCHET= 55       -- ��������
                                         or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������  
                                    and c85.SUB_SHIFR_SCHET is Null -- �� ������ 13%
                                                                                      
                               UNION ALL 
                               -- ������������ ������ � �������� 
                               -- ���������� � ��������� � ������� �������
                               -- ������
                    -- ������������, ���� ������ ������ ������� ��� ����,
                    -- �.�. ��� ����������� ����� ����� ���� ������ ������ �� �������           
                               Select GF_PERSON, SHIFR_SCHET, MINDATOP DATA_OP, SUMKORR SUMMA from (
                                            Select sfl.GF_PERSON, ds.SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(ds.SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        -- ��� ����������� ������
                                                        left join 
                                                            (Select * from DV_SR_LSPV
                                                                where SHIFR_SCHET=85
                                                                  and SUB_SHIFR_SCHET=1 -- ������ ���� �� 30%
                                                                  and DATA_OP>=dTermBeg  
                                                                  and DATA_OP < dTermEnd
                                                            ) c85
                                                            on ds.NOM_VKL=c85.NOM_VKL and ds.NOM_IPS=c85.NOM_IPS 
                                                                and ds.DATA_OP=c85.DATA_OP and ds.SHIFR_SCHET=c85.SHIFR_SCHET   
                                                                and ds.SSYLKA_DOC=c85.SSYLKA_DOC
                                            where c85.SUB_SHIFR_SCHET is Null -- �� ������ 13%
                                             start with ds.NOM_VKL<991        -- ������ �� ����
                                                    and ( ds.SHIFR_SCHET=60 or ds.SHIFR_SCHET>1000 )  -- ����� ������ ��� ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP >=dTermBeg       -- ����������� �������
                                                    and ds.DATA_OP < dTermEnd       -- ��� ������ ������ � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  sfl.GF_PERSON, ds.SHIFR_SCHET          
                                       )  where MINDATOP>=dTermBeg               -- ������������ ���������� ����
                                            and MINDATOP < dTermEnd               -- � ������� �������� �������     
                    -- ����� ������ ������
                                              
                               -- ��������
                               UNION ALL
                               Select GF_PERSON, SHIFR_SCHET, MINDATOP DATA_OP, sum(SUMKORR) SUMMA from (
                                            Select sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA SUMKORR,
                                                   min(ds.DATA_OP) over(partition by sfl.GF_PERSON, ds.SHIFR_SCHET) MINDATOP
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        -- ��� ����������� ������
                                                        left join 
                                                            (Select * from DV_SR_LSPV
                                                                where SHIFR_SCHET=85
                                                                  and SUB_SHIFR_SCHET=3 -- ������ ���� �� 30%
                                                                  and DATA_OP >= dTermBeg  
                                                                  and DATA_OP <  dTermEnd
                                                            ) c85  
                                                                on ds.NOM_VKL=c85.NOM_VKL and ds.NOM_IPS=c85.NOM_IPS 
                                                               and ds.DATA_OP=c85.DATA_OP and ds.SHIFR_SCHET=c85.SHIFR_SCHET   
                                                               and ds.SSYLKA_DOC=c85.SSYLKA_DOC
                                             where c85.SUB_SHIFR_SCHET is Null    -- 13%                   
                                             start with (   ds.SHIFR_SCHET= 55    -- ��������
                                                         or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1         -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg      -- ����������� �������
                                                    and ds.DATA_OP < dTermEnd     -- � ������� �������� ������� � ����� ��� ��������                                                  
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                       )  where MINDATOP >= dTermBeg              -- ������������ ���������� ����
                                            and MINDATOP <  dTermEnd              -- � ������� �������� �������    
                                            and DATA_OP  >= dTermBeg              -- ��������� ����������� ������
                                            and DATA_OP  <  dTermEnd              -- �� ������� �������� ������
                                          group by GF_PERSON, SHIFR_SCHET, MINDATOP   
                              UNION ALL 
                              -- �������� � ����������� ������
                               -- ���������� ����������, ��� �����������
                               Select vrp.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                     from DV_SR_LSPV ds
                                             inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                             inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                                                from VYPLACH_POSOB 
                                                                where TIP_VYPL=1010                -- �������� � ����������� ������
                                                                   and NAL_REZIDENT=1             -- �� ������ 13%      
                                                                   and DATA_VYPL>=dTermBeg    -- � ������ ����
                                                                   and DATA_VYPL < dTermEnd    -- �� ����� ��������� ������� 
                                                            ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                                     where (ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                                               or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                        and ds.SERVICE_DOC=0  -- ������� �� ����������������
                                        and ds.DATA_OP>=dTermBeg  
                                        and ds.DATA_OP < dTermEnd         
                  /*           UNION
                               -- �������� � ����������� ������
                               -- ����������� � ����������������� � ������� �������
                               � � � � �   � � � � � � � � (���� ����� ��� ��� - ��� �������)
                  */                                                                      
                              ),
       q30 as (-- ������ � �������� (���������)
               Select sfl.GF_PERSON, ds.*
                 from DV_SR_LSPV ds
                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                         inner join (Select * from DV_SR_LSPV
                                         where SHIFR_SCHET=85
                                           and SUB_SHIFR_SCHET=1 -- ������ ���� �� 30%
                                           and DATA_OP >= dTermBeg  
                                           and DATA_OP <  dTermEnd
                                    ) c85  
                                         on ds.NOM_VKL=c85.NOM_VKL and ds.NOM_IPS=c85.NOM_IPS 
                                        and ds.DATA_OP=c85.DATA_OP and ds.SHIFR_SCHET=c85.SHIFR_SCHET   
                                        and ds.SSYLKA_DOC=c85.SSYLKA_DOC
                 where  ds.DATA_OP >= dTermBeg    -- � ������ ����
                     and ds.DATA_OP < dTermEnd    -- �� ����� ��������� �������  
                     and ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 --  ��� ������ �� ����
                     and ds.SERVICE_DOC=0          -- ������� ��� ����������� �����������
                     
               UNION ALL
                 Select sfl.GF_PERSON, ds.*
                 from DV_SR_LSPV ds
                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                         inner join (Select * from DV_SR_LSPV
                                         where SHIFR_SCHET=85
                                           and SUB_SHIFR_SCHET=3 -- �������� ���� �� 30%
                                           and DATA_OP >= dTermBeg  
                                           and DATA_OP <  dTermEnd
                                    ) c85  
                                         on ds.NOM_VKL=c85.NOM_VKL and ds.NOM_IPS=c85.NOM_IPS 
                                        and ds.DATA_OP=c85.DATA_OP and ds.SHIFR_SCHET=c85.SHIFR_SCHET   
                                        and ds.SSYLKA_DOC=c85.SSYLKA_DOC
                 where  ds.DATA_OP >= dTermBeg    -- � ������ ����
                     and ds.DATA_OP < dTermEnd    -- �� ����� ��������� �������  
                     and ds.SHIFR_SCHET=55 -- ��������   
                     and ds.SERVICE_DOC=0          -- ������� ��� ����������� �����������  
                     
UNION ALL 
                               -- ������������ ������ � �������� 
                               -- ���������� � ��������� � ������� �������
                               -- ������
                    -- ������������, ���� ������ ������ ������� ��� ����,
                    -- �.�. ��� ����������� ����� ����� ���� ������ ������ �� �������           
                               Select distinct GF_PERSON,
                                      NOM_VKL, NOM_IPS, SHIFR_SCHET, MINDATOP DATA_OP, SUMKORR SUMMA, SSYLKA_DOC, KOD_OPER, SUB_SHIFR_SCHET, SERVICE_DOC -- DS
                               from (
                                            Select sfl.GF_PERSON, ds.*, 
                                                min(ds.DATA_OP) over(partition by sfl.GF_PERSON, ds.SHIFR_SCHET) MINDATOP, 
                                                sum(ds.SUMMA)   over(partition by sfl.GF_PERSON, ds.SHIFR_SCHET) SUMKORR
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        -- ��� ����������� ������
                                                        inner join 
                                                            (Select * from DV_SR_LSPV
                                                                where SHIFR_SCHET=85
                                                                  and SUB_SHIFR_SCHET=1 -- ������ ���� �� 30%
                                                                  and DATA_OP>=dTermBeg  
                                                                  and DATA_OP < dTermEnd
                                                            ) c85
                                                            on ds.NOM_VKL=c85.NOM_VKL and ds.NOM_IPS=c85.NOM_IPS 
                                                                and ds.DATA_OP=c85.DATA_OP and ds.SHIFR_SCHET=c85.SHIFR_SCHET   
                                                                and ds.SSYLKA_DOC=c85.SSYLKA_DOC
                                             start with ds.NOM_VKL<991        -- ������ �� ����
                                                    and ( ds.SHIFR_SCHET=60 or ds.SHIFR_SCHET>1000 )  -- ����� ������ ��� ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1           -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP >=dTermBeg       -- ����������� �������
                                                    and ds.DATA_OP < dTermEnd       -- ��� ������ ������ � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                            -- group by  sfl.GF_PERSON, ds.SHIFR_SCHET          
                                       )  where MINDATOP>=dTermBeg               -- ������������ ���������� ����
                                            and MINDATOP < dTermEnd               -- � ������� �������� �������           
-- ��������
UNION ALL
                               Select distinct GF_PERSON,
                                      NOM_VKL, NOM_IPS, SHIFR_SCHET, MINDATOP DATA_OP, 
                                      sum(SUMMA) over(partition by GF_PERSON, SHIFR_SCHET, MINDATOP) SUMMA, 
                                      SSYLKA_DOC, KOD_OPER, SUB_SHIFR_SCHET, SERVICE_DOC -- DS 
                               from (
                                            Select sfl.GF_PERSON, ds.*,
                                                   min(ds.DATA_OP) over(partition by sfl.GF_PERSON, ds.SHIFR_SCHET) MINDATOP
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        -- ��� ����������� ������
                                                        inner join 
                                                            (Select * from DV_SR_LSPV
                                                                where SHIFR_SCHET=85
                                                                  and SUB_SHIFR_SCHET=3 -- ������ ���� �� 30%
                                                                  and DATA_OP >= dTermBeg  
                                                                  and DATA_OP <  dTermEnd
                                                            ) c85  
                                                                on ds.NOM_VKL=c85.NOM_VKL and ds.NOM_IPS=c85.NOM_IPS 
                                                               and ds.DATA_OP=c85.DATA_OP and ds.SHIFR_SCHET=c85.SHIFR_SCHET   
                                                               and ds.SSYLKA_DOC=c85.SSYLKA_DOC
                                             start with (   ds.SHIFR_SCHET= 55    -- ��������
                                                         or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1         -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg      -- ����������� �������
                                                    and ds.DATA_OP < dTermEnd     -- � ������� �������� ������� � ����� ��� ��������                                                  
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                       )  where MINDATOP >= dTermBeg              -- ������������ ���������� ����
                                            and MINDATOP <  dTermEnd              -- � ������� �������� �������    
                                            and DATA_OP  >= dTermBeg              -- ��������� ����������� ������
                                            and DATA_OP  <  dTermEnd              -- �� ������� �������� ������
                      
               UNION ALL                                         
               -- �������� � ����������� ������
               Select vrp.GF_PERSON, ds.*
                 from DV_SR_LSPV ds
                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                         inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                            from VYPLACH_POSOB 
                                            where TIP_VYPL=1010
                                                and DATA_VYPL>=dTermBeg 
                                                and DATA_VYPL < dTermEnd
                                                and NAL_REZIDENT = 2
                                    ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                 where ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                    and ds.DATA_OP>=dTermBeg  
                    and ds.DATA_OP < dTermEnd                                                               
              ) 
          -- ����������  
       Select res.*, ISCH_NAL-UDERZH_NAL NEDOPLATA,
              pe.Lastname, pe.Firstname, pe.Secondname 
       from(         
          Select 30 STAVKA, cn.GF_PERSON, cn.ISCH_NAL, bn.UDERZH_NAL  from (
                      Select GF_PERSON, sum(round( 0.30*SUMMA )) ISCH_NAL from q30 where SERVICE_DOC=0 and SHIFR_SCHET<1000
                          group by GF_PERSON          
                     )cn
                   left join (
                        Select  GF_PERSON, nvl(sum(SUMPOTIPU),0) UDERZH_NAL from ( 
                          Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                              inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                              inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                            where ds.SERVICE_DOC=0
                              and ds.SHIFR_SCHET=85 
                              and ds.SUB_SHIFR_SCHET=1
                              and ds.NOM_VKL<991
                              and ds.DATA_OP>=dTermBeg  
                              and ds.DATA_OP < dTermEnd 
                              and sfl.NAL_REZIDENT=2     
                        UNION ALL               
                        Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                              inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                              inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                            where ds.SERVICE_DOC=0
                              and ds.SHIFR_SCHET=85 
                              and ds.SUB_SHIFR_SCHET=3
                              and ds.DATA_OP>=dTermBeg  
                              and ds.DATA_OP < dTermEnd
                              and sfl.NAL_REZIDENT=2  
                        UNION ALL      
                        Select vrp.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                              inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                              inner join (Select SSYLKA, SSYLKA_DOC, GF_PERSON   
                                            from VYPLACH_POSOB 
                                            where TIP_VYPL=1010
                                              and DATA_VYPL>=dTermBeg 
                                              and DATA_VYPL < dTermEnd
                                              and NAL_REZIDENT = 2
                                          ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC                       
                            where ds.SERVICE_DOC=0
                             and ds.SHIFR_SCHET=86 
                             and ds.SUB_SHIFR_SCHET=1
                             and ds.DATA_OP>=dTermBeg  
                             and ds.DATA_OP < dTermEnd 
                        ) group by GF_PERSON  
                   ) bn on bn.GF_PERSON=cn.GF_PERSON           
               where cn.ISCH_NAL <> bn.UDERZH_NAL
         Union 
            -- ��� ������   
            Select 13 STAVKA, GF_PERSON, ISCH_NAL, UDERZH_NAL  from (
            --Select q.*, ISCH_NAL-UDERZH_NAL RAZN from (                                 
                Select  doh.GF_PERSON,  -- 149.611
                   -- ������ ������ ��� ��������� ���������� 
                             -- ������ � ���������� ��� ������ �������
                             round( 0.13* case when doh.SUMGOD_DOH < nvl(vyc.SUMGOD_VYC,0 )  
                                                   then 0
                                                   else doh.SUMGOD_DOH - nvl(vyc.SUMGOD_VYC,0)
                                                end ) ISCH_NAL, 
                        nvl(bn.UD_NAL,0) UDERZH_NAL                               
                from (    Select GF_PERSON,  sum(SUMMA) SUMGOD_DOH from q13  
                                      where  SHIFR_SCHET<1000    -- ������
                                      group by GF_PERSON
                        ) doh
                left join ( Select GF_PERSON, sum(SUMMA)  SUMGOD_VYC from  q13 
                                      where SHIFR_SCHET>1000   --  ��� ������ 
                                      group by GF_PERSON
                        ) vyc  
                         on vyc.GF_PERSON=doh.GF_PERSON     
                left join ( Select  GF_PERSON, nvl(sum(SUMPOTIPU),0) UD_NAL from (
                              -- ���������� ������
                              Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=85 
                                  and ds.SUB_SHIFR_SCHET=0
                                  and ds.NOM_VKL<991
                                  and ds.DATA_OP>=dTermBeg  
                                  and ds.DATA_OP < dTermEnd 
                                  and sfl.NAL_REZIDENT=1
                                       
/* ������ ��� �������, ��� �������� ��������/�������� � ������ �� � ����������� ��������
     -- ��������� ����� �� ������                             
        union all
        -- �����
        Select sfl.GF_PERSON, sum(vp.UDERGANO) SUMPOTIPU
        from VYPLACH_PEN_BUF vp inner join SP_FIZ_LITS sfl on sfl.SSYLKA=vp.SSYLKA
        where vp.NOM_VKL<991 and SFL.NAL_REZIDENT=1  
        group by sfl.GF_PERSON    
     --
*/                                  
                            UNION ALL         
                              -- ���������� ��������       
                              Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                  inner join (Select distinct SSYLKA from VYPLACH_POSOB 
                                                        where TIP_VYPL=1030
                                                          and DATA_VYPL>=dTermBeg
                                                          and DATA_VYPL < dTermEnd 
                                                          and NAL_REZIDENT=1  -- �� ������ 13%
                                              ) rp on rp.SSYLKA=lspv.SSYLKA_FL  -- ���� ������� �� ������, �� ��� ��� 
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=85 
                                  and ds.SUB_SHIFR_SCHET=2
                                  and ds.DATA_OP >= dTermBeg  
                                  and ds.DATA_OP <  dTermEnd 
                            UNION ALL   
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               Select sfl.GF_PERSON, kor.SUMKORR as SUMPOTIPU from (
                                            Select  ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds
                                            where  ds.SUB_SHIFR_SCHET in (0,2) -- ������ 13%                                                   
                                             start with ds.SHIFR_SCHET=85    --  ������ �� ������ ������ � ��������
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg       -- ����������� �������                         
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by   ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET         
                                       ) kor  
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=kor.NOM_VKL and lspv.NOM_IPS=kor.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL                                       
                                         where kor.MINDATOP>=dTermBeg               -- ������������ ���������� ����
                                           and kor.MINDATOP < dTermEnd              -- � ������� �������� �������   
                            UNION ALL
                              -- ������� � ���������� ����
                              Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=83 
                                  and ds.DATA_OP >= dTermBeg  
                                  and ds.DATA_OP <  dTermEnd                                                 
                            UNION ALL      
                              -- ��������
                              Select vrp.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join (Select SSYLKA, SSYLKA_DOC, GF_PERSON   
                                                        from VYPLACH_POSOB 
                                                        where TIP_VYPL=1010
                                                            and DATA_VYPL>=dTermBeg 
                                                            and DATA_VYPL < dTermEnd
                                                            and NAL_REZIDENT = 1
                                              ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC                       
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=86 
                                  and ds.SUB_SHIFR_SCHET=0
                                  and ds.DATA_OP>=dTermBeg  
                                  and ds.DATA_OP < dTermEnd                     
                            ) group by GF_PERSON      
                        ) bn 
                         on bn.GF_PERSON=doh.GF_PERSON      
           ) where abs(ISCH_NAL - UDERZH_NAL)>0.01        
      ) res 
      left join gazfond.People pe on pe.fk_CONTRAGENT=res.GF_PERSON
      order by STAVKA, ISCH_NAL-UDERZH_NAL                                    
;            
        
    end Sverka_NesovpadNal_v2;
/*
declare
TW sys_refcursor;
RC varchar2(1000);
begin
  dbms_output.enable(10000);  
  FXNDFL_UTIL.Sverka_KvOtchet( TW, RC, 149568 );
  :CC := TW;
  dbms_output.put_line( nvl(RC,'��') );
END;
*/  
   -- ������ ��� ������ ���� ������ �� ���������� ������ ��� ������ � ����������� �������
   procedure Sverka_KvOtchet( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number ) as
       dTermBeg date;
       dTermEnd date;
       nGod        number;
       nPeriod    number; 
       nNalRez   number;
   begin

          -- ������� ������� �������
       Select GOD, PERIOD into nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
       dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
       case nPeriod
           when 21 then dTermEnd := add_months(dTermBeg,3);         
           when 31 then dTermEnd := add_months(dTermBeg,6);        
           when 33 then dTermEnd := add_months(dTermBeg,9);        
           when 34 then dTermEnd := add_months(dTermBeg,12);      
           else pErrInfo :='������ ���������� ���������� �������.'; return;                
       end case;
   
    open pReportCursor for 
    With q as (     
        -- ������ � �������� ��� �����������
            Select org.*, kor.SUMNAL SUMKOR, nvl(org.SUMNAL,0)+nvl(kor.SUMNAL,0) SUMITG
            from ( 
                    Select case when SUB_SHIFR_SCHET<2 then '1��' else '3��' end TIP_VYPL,
                           case when mod(SUB_SHIFR_SCHET,2)=0 then '�13' else '�30' end STAVKA,
                           PEN_SXEM, SUMNAL
                    from (       
                            Select ds.SUB_SHIFR_SCHET, sfl.PEN_SXEM, sum( ds.SUMMA ) SUMNAL
                                from DV_SR_LSPV ds
                                    inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                    inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                where  ds.DATA_OP>=dTermBeg        -- � ������ ����
                                    and ds.DATA_OP < dTermEnd         -- �� ����� ��������� �������  
                                    and ds.SERVICE_DOC=0              -- ������� ��� ����������� �����������
                                    and ds.SHIFR_SCHET=85  -- �����  � ������ � �������� 
                                group by ds.SUB_SHIFR_SCHET, sfl.PEN_SXEM   
                                order by ds.SUB_SHIFR_SCHET, sfl.PEN_SXEM   
                         ) 
                    UNION     
                    -- �������� ��� �����������
                    Select '2��' TIP_VYPL,
                           case when mod(SUB_SHIFR_SCHET,2)=0 then '�13' else '�30' end STAVKA,
                           1 PEN_SXEM, SUMNAL
                    from(
                            Select ds.SUB_SHIFR_SCHET, sum(ds.SUMMA) SUMNAL
                             from DV_SR_LSPV ds
                                     inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                     inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                                        from VYPLACH_POSOB 
                                                        where TIP_VYPL=1010
                                                            and DATA_VYPL>=dTermBeg 
                                                            and DATA_VYPL < dTermEnd
                                                ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                            where ds.SHIFR_SCHET=86 -- ����� �� �������� � ����������� ������
                                and ds.DATA_OP>=dTermBeg  
                                and ds.DATA_OP < dTermEnd
                            group by  ds.SUB_SHIFR_SCHET      
                            order by  ds.SUB_SHIFR_SCHET                             
                         )  
                  ) org
               full join   
                  ( Select case when SUB_SHIFR_SCHET<2 then '1��' else '3��' end TIP_VYPL,
                           case when mod(SUB_SHIFR_SCHET,2)=0 then '�13' else '�30' end STAVKA,
                           PEN_SXEM, SUMNAL
                    from (   
                       -- ������                                   
                       Select SUB_SHIFR_SCHET, PEN_SXEM, sum(SUMMA) SUMNAL 
                       from (
                                    Select ds.NOM_VKL,ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, sfl.PEN_SXEM
                                           --, min(ds.DATA_OP) MINDATOP, sum(ds.SUMMA) SUMKORR
                                           , ds.DATA_OP 
                                           , min(ds.DATA_OP) over( partition by ds.NOM_VKL,ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) MINDATOP 
                                           ,ds.SUMMA
                                           , sum(ds.SUMMA) over( partition by ds.NOM_VKL,ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMKORR
                                    from  DV_SR_LSPV ds            
                                                inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL                                      
                                     start with ds.SHIFR_SCHET=85  -- �����  � ������ � �������� 
                                            and ds.SUB_SHIFR_SCHET < 2
                                            and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                            and ds.DATA_OP>=dTermBeg       -- ����������� �������                           
                                            and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                     connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC         
                               ) where DATA_OP>=dTermBeg     -- ��������� �������� ������ � ������� �������� �������            --   
                               group by SUB_SHIFR_SCHET, PEN_SXEM 
                       UNION ALL        
                       -- ��������                                   
                       Select SUB_SHIFR_SCHET, PEN_SXEM, sum(SUMMA) SUMNAL 
                       from (
                                    Select ds.NOM_VKL,ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, sfl.PEN_SXEM
                                           --, min(ds.DATA_OP) MINDATOP, sum(ds.SUMMA) SUMKORR
                                           , ds.DATA_OP 
                                           , min(ds.DATA_OP) over( partition by ds.NOM_VKL,ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) MINDATOP 
                                           ,ds.SUMMA
                                           , sum(ds.SUMMA) over( partition by ds.NOM_VKL,ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMKORR
                                    from  DV_SR_LSPV ds            
                                                inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL                                      
                                     start with ds.SHIFR_SCHET=85  -- �����  � ������ � �������� 
                                            and ds.SUB_SHIFR_SCHET > 1
                                            and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                            and ds.DATA_OP>=dTermBeg         -- ����������� �������                           
                                        --   and ds.DATA_OP < dTermEnd       -- � ������� �������� �������, ��� �����
                                     connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC         
                               ) where DATA_OP>= dTermBeg     -- ��������� �������� ������ � ������� �������� �������      
                                   and DATA_OP < dTermEnd   --   
                               group by SUB_SHIFR_SCHET, PEN_SXEM                               
                         )
                   ) kor
              on org.TIP_VYPL=kor.TIP_VYPL and org.STAVKA=kor.STAVKA and org.PEN_SXEM=kor.PEN_SXEM
              order by org.TIP_VYPL, org.STAVKA, org.PEN_SXEM
    )
    Select A.*, nvl(B.K13,0) K13, nvl(B.K30,0) K30 
    from
        (Select * from ( Select TIP_VYPL, PEN_SXEM, STAVKA, SUMITG from q )
           pivot( min(SUMITG) for STAVKA in ( '�13' as S13, '�30' as S30 ) ) 
         ) A
    full join 
         (Select * from ( Select TIP_VYPL, PEN_SXEM, STAVKA, SUMKOR from q )
           pivot( min(SUMKOR) for STAVKA in ( '�13' as K13, '�30' as K30 ) ) 
         ) B
       on B.TIP_VYPL=A.TIP_VYPL and B.PEN_SXEM=A.PEN_SXEM   
    order by A.TIP_VYPL, A.PEN_SXEM;
         
    pErrInfo := Null; 
 
    exception
        when OTHERS then pErrInfo := SQLERRM;            
   end Sverka_KvOtchet;   
   
/*
declare
TW sys_refcursor;
RC varchar2(1000);
begin
  dbms_output.enable(10000);  
  FXNDFL_UTIL.ZaPeriodPoDokum( TW, RC, 149565 );
  :CC := TW;
  dbms_output.put_line( nvl(RC,'��') );
END;
*/      
   procedure ZaPeriodPoDokum( pReportCursor out sys_refcursor, pErrInfo out varchar2, pSPRID in number ) as
   dTermBeg date;
   dTermEnd date;
   nGod        number;
   nPeriod    number; 
   nNalRez   number;
   begin

          -- ������� ������� �������
       Select GOD, PERIOD into nGod, nPeriod from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
       dTermBeg :=   to_date( '01.01.'||to_char(nGod),'dd.mm.yyyy' );
       case nPeriod
           when 21 then dTermEnd := add_months(dTermBeg,3);         
           when 31 then dTermEnd := add_months(dTermBeg,6);        
           when 33 then dTermEnd := add_months(dTermBeg,9);        
           when 34 then dTermEnd := add_months(dTermBeg,12);      
           else pErrInfo :='������ ���������� ���������� �������.'; return;                
       end case;
   
       open pReportCursor for 
       -- �� ������ �� ����������
       with 
             qDoh as (
                     -- ������ � ��������
                     -- ��� �����������
                     Select  SSYLKA_DOC, SERVICE_DOC, DATA_OP, sum(SUMMA) SUMDOH
                     from(
                              Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA
                                     from DV_SR_LSPV ds
                                     where  ds.DATA_OP>=dTermBeg         -- � ������ ����
                                         and ds.DATA_OP < dTermEnd        -- �� ����� ��������� �������  
                                         and ds.SERVICE_DOC=0              -- ������� ��� ����������� �����������   
                                         and  ( ds.SHIFR_SCHET= 55 -- ��������
                                                  or ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 )) --  ��� ������ �� ����
                              UNION ALL                    
                              -- ������������ ������ � �������� 
                              -- ����������� � ����������������� � ������� �������
                              Select SSYLKA_DOC, DOCF as SERVICE_DOC, DATA_OP, SUM_ISPRAV  SUMMA
                                  from (
                                            Select level as LVL, ds.* 
                                                     , first_value(SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)   DOCF
                                                     , last_value(SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)    DOCL       
                                                     , sum(SUMMA)   over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUM_ISPRAV                                            
                                            from  DV_SR_LSPV ds                                                    
                                             start with  ( ds.SHIFR_SCHET= 55 -- ��������
                                                              or ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 )) --  ��� ������ �� ����
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg        -- ����������� �������                          
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                     ) where SSYLKA_DOC=DOCL 
                                           and SSYLKA_DOC<>DOCF    
                                           and DATA_OP>=dTermBeg      -- ������������ ���������� ����                       
                                           and DATA_OP < dTermEnd       -- � ������� �������� �������                                                      
                 /*          UNION ALL
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               Select MINDATOP as DATA_OP, SUMKORR as SUMMA from (
                                            Select ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, ds.SSYLKA_DOC, ds.SERVICE_DOC , min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds                                                    
                                             start with  ( ds.SHIFR_SCHET= 55 -- ��������
                                                              or ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 )) --  ��� ������ �� ����
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg        -- ����������� �������                          
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET     
                                       )  where MINDATOP>=dTermBeg                -- ������������ ���������� ����
                                              and MINDATOP < dTermEnd              -- � ������� �������� �������    
                 */          UNION ALL                                      
                               -- �������� � ����������� ������
                               Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                         inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                                            from VYPLACH_POSOB 
                                                            where TIP_VYPL=1010
                                                    ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC and vrp.DATA_VYPL=ds.DATA_OP            
                                 where ds.SHIFR_SCHET=62 --  �������� � ����������� ������
                                    and ds.DATA_OP>=dTermBeg   
                                    and ds.DATA_OP < dTermEnd          
                                    and ds.SERVICE_DOC=0                                            
                          ) group by SSYLKA_DOC, SERVICE_DOC, DATA_OP    
                     ),
             qNal as (
                             -- ������ � ������ � ��������
                             -- ��� �����������
                             Select  SSYLKA_DOC, SERVICE_DOC, DATA_OP, sum(SUMMA) SUMNAL
                             from(
                                     Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA 
                                         from DV_SR_LSPV ds
                                         where  ds.DATA_OP>=dTermBeg         -- � ������ ����
                                             and ds.DATA_OP < dTermEnd         -- �� ����� ��������� �������  
                                             and ds.SERVICE_DOC=0              -- ������� ��� ����������� �����������
                                             and ds.SHIFR_SCHET=85    -- ������ �� ������ ������ � ��������
                              UNION ALL                    
                              -- ������������ ������ � �������� 
                              -- ����������� � ����������������� � ������� �������
                              Select SSYLKA_DOC, DOCF as SERVICE_DOC, DATA_OP, SUM_ISPRAV  SUMMA
                                  from (
                                            Select level as LVL, ds.* 
                                                     , first_value(SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)   DOCF
                                                     , last_value(SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)    DOCL       
                                                     , sum(SUMMA)   over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUM_ISPRAV                                            
                                            from  DV_SR_LSPV ds                                                    
                                             start with  ds.SHIFR_SCHET= 85  --  ������ �� ������ ������ � ��������
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg        -- ����������� �������                          
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                     ) where SSYLKA_DOC=DOCL 
                                           and SSYLKA_DOC<>DOCF    
                                           and DATA_OP>=dTermBeg      -- ������������ ���������� ����                       
                                           and DATA_OP < dTermEnd       -- � ������� �������� �������                                       
                 /*          UNION ALL
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               Select MINDATOP as DATA_OP, SUMKORR as SUMMA from (
                                            Select  ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds                                                
                                             start with ds.SHIFR_SCHET=85    --  ������ �� ������ ������ � ��������
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg        -- ����������� �������                         
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by   ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET         
                                       )  where MINDATOP>=dTermBeg                -- ������������ ���������� ����
                                              and MINDATOP < dTermEnd              -- � ������� �������� �������         
                 */          UNION ALL                                      
                               -- �������� � ����������� ������
                               Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA
                                  from DV_SR_LSPV ds          
                                  where ds.SHIFR_SCHET=86 -- ����� �� �������� � ����������� ������
                                      and ds.SERVICE_DOC=0  
                                      and ds.DATA_OP>=dTermBeg   
                                      and ds.DATA_OP < dTermEnd    
                             ) group by SSYLKA_DOC, SERVICE_DOC, DATA_OP     
                     )
             Select * from (        
                     Select doh.SSYLKA_DOC, doh.SERVICE_DOC, doh.DATA_OP DATA_FACT_DOH, doh.DATA_OP DATA_UDERZH_NAL, nal.DATA_OP+1 SROK_PERECH_NAL, doh.SUMDOH  POLUCHDOH, nvl(nal.SUMNAL,0) UDERZHNAL
                             from  (Select * from qDoh) doh
                                  left join (Select * from qNal) nal  on doh.SSYLKA_DOC=nal.SSYLKA_DOC and doh.SERVICE_DOC=nal.SERVICE_DOC and nal.DATA_OP=doh.DATA_OP    
                     union            
                     Select nal.SSYLKA_DOC, nal.SERVICE_DOC, nal.DATA_OP DATA_FACT_DOH, nal.DATA_OP DATA_UDERZH_NAL, nal.DATA_OP+1 SROK_PERECH_NAL, 0  POLUCHDOH, nal.SUMNAL UDERZHNAL
                             from  (Select * from qDoh) doh
                                  right join (Select * from qNal) nal  on doh.SSYLKA_DOC=nal.SSYLKA_DOC and doh.SERVICE_DOC=nal.SERVICE_DOC and  nal.DATA_OP=doh.DATA_OP     
                             where doh.DATA_OP is Null )                  
           order by DATA_FACT_DOH -- doh.DATA_OP                                       
        ;
       
       
        pErrInfo := Null; 
 
     exception
        when OTHERS then pErrInfo := SQLERRM;     
        
   end ZaPeriodPoDokum;
   
   procedure f6_ZagrSvedDoc( pSPRID in number ) as
   dTermBeg date;
   dTermEnd date;
   rSprDat    f6NDFL_LOAD_SPRAVKI% rowtype;
   begin
null;
/*
          -- ������� ������� �������
       Select * into rSprDat  from f6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
       dTermBeg :=   to_date( '01.01.'||to_char(rSprDat.GOD),'dd.mm.yyyy' );
       case rSprDat.PERIOD
           when 21 then dTermEnd := add_months(dTermBeg,3);         
           when 31 then dTermEnd := add_months(dTermBeg,6);        
           when 33 then dTermEnd := add_months(dTermBeg,9);        
           when 34 then dTermEnd := add_months(dTermBeg,12);      
           else return;                
       end case;
       
       Insert into f6NDFL_LOAD_SVED (
         KOD_NA, GOD, PERIOD, NOM_KORR, KOD_STAVKI, SSYLKA_DOC, SERVICE_DOC, 
         DATA_FACT_DOH, DATA_UDERZH_NAL, SROK_PERECH_NAL, 
         SUM_FACT_DOH, SUM_UDERZH_NAL --, SUM_PREDOST_VYCH, SUM_ISPOLZ_VYCH
       ) 
       Select rSprDat.KOD_NA, rSprDat.GOD ,rSprDat.PERIOD, rSprDat.NOM_KORR , 13, SSYLKA_DOC, SERVICE_DOC, 
                 DATA_OP, DATA_OP, DATA_OP+1, SUM_DOH, SUM_NAL 
       from (
                   Select SSYLKA_DOC, SERVICE_DOC, DATA_OP, sum(SUMMA) SUM_DOH, sum(DV_SUMMA) SUM_NAL
                   from (
                             -- ������ ����������, ��� �����������
                             Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA, nvl(dv.SUM85,0) DV_SUMMA
                             from DV_SR_LSPV ds
                                                 inner join (Select NOM_VKL, NOM_IPS, DATA_OP, sum( case when SHIFR_SCHET= 85 then SUMMA else 0 end ) SUM85
                                                                  from DV_SR_LSPV where (SHIFR_SCHET= 85 and SUB_SHIFR_SCHET=0) or (SHIFR_SCHET>1000)
                                                                  group by NOM_VKL, NOM_IPS, DATA_OP ) dv 
                                                     on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP                                                                       
                             where  ds.DATA_OP>=dTermBeg          -- � ������ ����
                                 and ds.DATA_OP < dTermEnd         -- �� ����� ��������� �������  
                                 and ds.SERVICE_DOC=0          -- ������� ��� ����������� �����������   
                                 and ds.SHIFR_SCHET=60          -- ������
                                 and ds.NOM_VKL<991               -- �� �� ����� �������
                             UNION ALL                    
                              -- ������������ ������, ����������� � ����������������� � ������� �������
                              Select SSYLKA_DOC, DOCF as SERVICE_DOC, DATA_OP, SUMDOH_ISPRAV  SUMMA, SUMNAL_ISPRAV DV_SUMMA
                                  from (
                                            Select level as LVL, ds.* 
                                                     , first_value(ds.SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)   DOCF
                                                     --, last_value(ds.SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)    DOCL      
                                                     , count(*) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET)   CNTT                                                      
                                                     , sum(ds.SUMMA)     over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMDOH_ISPRAV    
                                                     , sum(dv.SUM85) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMNAL_ISPRAV                  
                                            from  DV_SR_LSPV ds                 
                                                 inner join (Select NOM_VKL, NOM_IPS, DATA_OP, sum(case when SHIFR_SCHET= 85 then SUMMA else 0 end) SUM85
                                                                  from DV_SR_LSPV where (SHIFR_SCHET= 85 and SUB_SHIFR_SCHET=0) or (SHIFR_SCHET>1000)
                                                                  group by NOM_VKL, NOM_IPS, DATA_OP ) dv 
                                                     on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP                            
                                             start with ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 --  ������ �� �� ����� �������
                                                   -- and dv.SUB_SHIFR_SCHET=0    -- ����� 13%
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg        -- ����������� �������                          
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                     ) where CNTT=LVL --SSYLKA_DOC=DOCL 
                                           --and SSYLKA_DOC<>DOCF    
                                           and DATA_OP>=dTermBeg      -- ������������ ���������� ����                       
                                           and DATA_OP < dTermEnd       -- � ������� �������� �������          
                                            
                           -- �������� ����������, ��� �����������                                        
                           Union ALL     
                           Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA, dv.SUM85 DV_SUMMA
                             from DV_SR_LSPV ds
                                                 inner join (Select NOM_VKL, NOM_IPS, DATA_OP, sum( case when SHIFR_SCHET= 85 then SUMMA else 0 end ) SUM85
                                                                  from DV_SR_LSPV where (SHIFR_SCHET= 85 and SUB_SHIFR_SCHET=2) or (SHIFR_SCHET>1000)
                                                                  group by NOM_VKL, NOM_IPS, DATA_OP ) dv 
                                                     on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP  
                             where  ds.DATA_OP>=dTermBeg          -- � ������ ����
                                 and ds.DATA_OP < dTermEnd         -- �� ����� ��������� �������  
                                 and ds.SERVICE_DOC=0          -- ������� ��� ����������� �����������   
                                 and ds.SHIFR_SCHET= 55         -- ��������
                          --       and dv.SUB_SHIFR_SCHET=2    -- ����� 13%
                             
                             UNION ALL                    
                              -- ������������ ��������, ����������� � ����������������� � ������� �������
                              Select SSYLKA_DOC, DOCF as SERVICE_DOC, DATA_OP, SUMDOH_ISPRAV  SUMMA, SUMNAL_ISPRAV DV_SUMMA
                                  from (
                                            Select level as LVL, ds.* 
                                                     , first_value(ds.SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)   DOCF
                                                     , count(*) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET)   CNTT
                                                     , sum(ds.SUMMA)     over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMDOH_ISPRAV    
                                                     , sum(dv.SUM85) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMNAL_ISPRAV                  
                                            from  DV_SR_LSPV ds                 
                                                 inner join (Select NOM_VKL, NOM_IPS, DATA_OP, sum( case when SHIFR_SCHET= 85 then SUMMA else 0 end ) SUM85
                                                                  from DV_SR_LSPV where (SHIFR_SCHET= 85 and SUB_SHIFR_SCHET=2) or (SHIFR_SCHET>1000)
                                                                  group by NOM_VKL, NOM_IPS, DATA_OP ) dv 
                                                     on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP                                                                                 
                                             start with ds.SHIFR_SCHET=55          --  �������� 
                                              --      and dv.SUB_SHIFR_SCHET=2    -- ����� 13%
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg        -- ����������� �������                          
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                     ) where CNTT=LVL 
                                           and DATA_OP>=dTermBeg      -- ������������ ���������� ����                       
                                           and DATA_OP < dTermEnd       -- � ������� �������� �������                                  
                                 
                                 
                           Union ALL     
                           Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA, dv.SUM85 DV_SUMMA
                             from DV_SR_LSPV ds
                                                 inner join (Select NOM_VKL, NOM_IPS, DATA_OP, sum( case when SHIFR_SCHET= 86 then SUMMA else 0 end ) SUM85
                                                                  from DV_SR_LSPV where (SHIFR_SCHET= 86 and SUB_SHIFR_SCHET=0) or (SHIFR_SCHET>1000)
                                                                  group by NOM_VKL, NOM_IPS, DATA_OP ) dv 
                                                     on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP    
                             where  ds.DATA_OP>=dTermBeg          -- � ������ ����
                                 and ds.DATA_OP < dTermEnd         -- �� ����� ��������� �������  
                                 and ds.SERVICE_DOC=0          -- ������� ��� ����������� �����������   
                                 and ds.SHIFR_SCHET= 62         -- ��������
                         --        and dv.SUB_SHIFR_SCHET=0    -- ����� 13%                                 
                        ) group by SSYLKA_DOC, SERVICE_DOC, DATA_OP                            
                );
                
       Insert into f6NDFL_LOAD_SVED (
         KOD_NA, GOD, PERIOD, NOM_KORR, KOD_STAVKI, SSYLKA_DOC, SERVICE_DOC, 
         DATA_FACT_DOH, DATA_UDERZH_NAL, SROK_PERECH_NAL, 
         SUM_FACT_DOH, SUM_UDERZH_NAL, SUM_PREDOST_VYCH, SUM_ISPOLZ_VYCH
       ) 
       Select rSprDat.KOD_NA, rSprDat.GOD ,rSprDat.PERIOD, rSprDat.NOM_KORR , 30, SSYLKA_DOC, SERVICE_DOC, 
                 DATA_OP, DATA_OP, DATA_OP+1, SUM_DOH, SUM_NAL, 0, 0 
       from (
                   Select SSYLKA_DOC, SERVICE_DOC, DATA_OP, sum(SUMMA) SUM_DOH, sum(DV_SUMMA) SUM_NAL
                   from (
                             Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA, dv.SUMMA DV_SUMMA
                             from DV_SR_LSPV ds
                                     inner join (Select * from DV_SR_LSPV where SHIFR_SCHET= 85) dv on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP
                             where  ds.DATA_OP>=dTermBeg          -- � ������ ����
                                 and ds.DATA_OP < dTermEnd         -- �� ����� ��������� �������  
                                 and ds.SERVICE_DOC=0          -- ������� ��� ����������� �����������   
                                 and ds.SHIFR_SCHET=60          -- ������
                                 and ds.NOM_VKL<991               -- �� �� ����� �������
                                 and dv.SUB_SHIFR_SCHET=1    -- ����� 30%
                                 
                             UNION ALL                    
                              -- ������������ ������, ����������� � ����������������� � ������� �������
                              Select SSYLKA_DOC, DOCF as SERVICE_DOC, DATA_OP, SUMDOH_ISPRAV  SUMMA, SUMNAL_ISPRAV DV_SUMMA
                                  from (
                                            Select level as LVL, ds.* 
                                                     , first_value(ds.SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)   DOCF
                                                    --, last_value(ds.SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)    DOCL       
                                                     , count(*) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET)   CNTT                                                     
                                                     , sum(ds.SUMMA)     over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMDOH_ISPRAV    
                                                     , sum(dv.SUMMA) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMNAL_ISPRAV                  
                                            from  DV_SR_LSPV ds                 
                                                    inner join (Select * from DV_SR_LSPV where SHIFR_SCHET= 85) dv on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP                                    
                                             start with ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 --  ������ �� �� ����� �������
                                                    and dv.SUB_SHIFR_SCHET=1    -- ����� 30%
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg        -- ����������� �������                          
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                     ) where CNTT=LVL --SSYLKA_DOC=DOCL 
                                           --and SSYLKA_DOC<>DOCF    
                                           and DATA_OP>=dTermBeg      -- ������������ ���������� ����                       
                                           and DATA_OP < dTermEnd       -- � ������� �������� �������                                   
                                 
                           Union ALL     
                           Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA, dv.SUMMA DV_SUMMA
                             from DV_SR_LSPV ds
                                     inner join (Select * from DV_SR_LSPV where SHIFR_SCHET= 85) dv on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP
                             where  ds.DATA_OP>=dTermBeg          -- � ������ ����
                                 and ds.DATA_OP < dTermEnd         -- �� ����� ��������� �������  
                                 and ds.SERVICE_DOC=0          -- ������� ��� ����������� �����������   
                                 and ds.SHIFR_SCHET= 55         -- ��������
                                 and dv.SUB_SHIFR_SCHET=3    -- ����� 30%
                                 
                             UNION ALL                    
                              -- ������������ ��������, ����������� � ����������������� � ������� �������
                              Select SSYLKA_DOC, DOCF as SERVICE_DOC, DATA_OP, SUMDOH_ISPRAV  SUMMA, SUMNAL_ISPRAV DV_SUMMA
                                  from (
                                            Select level as LVL, ds.* 
                                                     , first_value(ds.SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)   DOCF
                                               --      , last_value(ds.SSYLKA_DOC) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET order by level)    DOCL      
                                                     , count(*) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET)   CNTT                                                      
                                                     , sum(ds.SUMMA) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMDOH_ISPRAV    
                                                     , sum(dv.SUMMA) over(partition by ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET) SUMNAL_ISPRAV                  
                                            from  DV_SR_LSPV ds                 
                                                    inner join (Select * from DV_SR_LSPV where SHIFR_SCHET= 85) dv on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP                                    
                                             start with ds.SHIFR_SCHET=55          --  �������� 
                                                    and dv.SUB_SHIFR_SCHET=3    -- ����� 30%
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=dTermBeg        -- ����������� �������                          
                                                    and ds.DATA_OP < dTermEnd       -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                     ) where CNTT=LVL --SSYLKA_DOC=DOCL 
                                           -- and SSYLKA_DOC<>DOCF    
                                           and DATA_OP>=dTermBeg      -- ������������ ���������� ����                       
                                           and DATA_OP < dTermEnd       -- � ������� �������� �������                                  
                                 
                           Union ALL     
                           Select ds.SSYLKA_DOC, ds.SERVICE_DOC, ds.DATA_OP, ds.SUMMA, dv.SUMMA DV_SUMMA
                             from DV_SR_LSPV ds
                                     inner join (Select * from DV_SR_LSPV where SHIFR_SCHET= 86) dv on ds.NOM_VKL=dv.NOM_VKL and ds.NOM_IPS=dv.NOM_IPS and ds.DATA_OP=dv.DATA_OP
                             where  ds.DATA_OP>=dTermBeg          -- � ������ ����
                                 and ds.DATA_OP < dTermEnd         -- �� ����� ��������� �������  
                                 and ds.SERVICE_DOC=0          -- ������� ��� ����������� �����������   
                                 and ds.SHIFR_SCHET= 62         -- ��������
                                 and dv.SUB_SHIFR_SCHET=1    -- ����� 30%                                       
                        ) group by SSYLKA_DOC, SERVICE_DOC, DATA_OP                                
                );

      Commit;  
 */      
   exception 
      when OTHERS then
            Rollback;
            Raise;    
   end f6_ZagrSvedDoc; 
   
-- ���������� ����������� ������ ��� 6���� �� �������� ������� �� ����
procedure ZagruzTabl_poLSPV( pErrInfo out varchar2, pSPRID in number ) is

  rSPR  F6NDFL_LOAD_SPRAVKI%rowtype;
  rSVED F6NDFL_LOAD_SVED%rowtype;
  cPoDatam sys_refcursor;

  fUderzhNalog   float;
  fNeUderzhNalog float;
  fVozvraNalog   float;
  fIschislNalog  float;
  fNachislDoh    float;
  fIspolzVych    float;
  nStavka       number;
  nKolNP        number;
  
  vErrPref varchar2(100);
  
begin
    -- �������� �� ����������
    if TestArhivBlok(pSPRID)<>0 then
       pErrInfo := '������� ��� �������� � �����. ������� ������ ��������.';
       return;
       end if;
       
    -- ��������� �����
    vErrPref := '������� ���������� �������.';
    Select * into rSPR from F6NDFL_LOAD_SPRAVKI where R_SPRID=pSPRID;
    
    -- ������ ���������� ����������
    vErrPref := '�������� ����������� �������.';
    Update F6NDFL_LOAD_SPRAVKI
       set KOL_FL_DOHOD=0
       where R_SPRID=pSPRID;
    Delete from F6NDFL_LOAD_SUMPOSTAVKE 
       where KOD_NA=rSPR.KOD_NA and GOD=rSPR.GOD and PERIOD=rSPR.PERIOD and NOM_KORR=rSPR.NOM_KORR and KOD_PODR=0;
    Delete from F6NDFL_LOAD_SVED 
       where KOD_NA=rSPR.KOD_NA and GOD=rSPR.GOD and PERIOD=rSPR.PERIOD and NOM_KORR=rSPR.NOM_KORR and KOD_PODR=0;
    Delete from F6NDFL_LOAD_SUMGOD 
       where KOD_NA=rSPR.KOD_NA and GOD=rSPR.GOD and PERIOD=rSPR.PERIOD and NOM_KORR=rSPR.NOM_KORR and KOD_PODR=0;
       
    -- ����� ������
    
    -- ���������� ����� ��� ������
    for i in 1..2 loop
       Case i
         when 1 then nStavka := 13;  Zapoln_Buf_NalogIschisl( pSPRID );
         when 2 then nStavka := 30;
       end case;  

        vErrPref := '������ ����������� ������� �� ������ '||to_char(nStavka);
          fIschislNalog :=SumIschislNal(pSPRID,nStavka);
        vErrPref := '������ �������, ���������� �� ������ '||to_char(nStavka);      
          fNachislDoh   :=SumNachislDoh(pSPRID,nStavka);                       -- ��������� 1 �� 2017 18-04-2017
        vErrPref := '������ ������� �� ������ '||to_char(nStavka);      
          fIspolzVych   :=SumIspolzVych(pSPRID,nStavka);

       vErrPref := '������ � ������ - ����� �� ������ '||to_char(nStavka);
       Insert into F6NDFL_LOAD_SUMPOSTAVKE (   
          KOD_NA, KOD_PODR, GOD, PERIOD, NOM_KORR, KOD_STAVKI, 
          NACHISL_DOH, NACH_DOH_DIV, VYCHET_PREDOST, VYCHET_ISPOLZ, 
          ISCHISL_NAL, ISCHISL_NAL_DIV, AVANS_PLAT)
       values( rSPR.KOD_NA, 0, rSPR.GOD, rSPR.PERIOD, rSPR.NOM_KORR, nStavka,
          fNachislDoh, 0, 0, fIspolzVych, fIschislNalog, 0, 0 );
       
       end loop;

    vErrPref := '����� ����� - ������ ����������� ������.';
      fUderzhNalog :=SumUderzhNal(pSPRID);                                     -- ��������� 1 �� 2017 18-04-2017
     vErrPref := '����� ����� - ������ �� ����������� ������.';
      fNeUderzhNalog := 0; --SumNeUderzhNal(pSPRID);                           -- �� ����, ������ ������, ����� 2-���� � ��������� 2  
    vErrPref := '����� ����� - ������ ������������� ������.';
      fVozvraNalog :=SumVozvraNal(pSPRID);                                     -- ��������� 1 �� 2017 18-04-2017            
    vErrPref := '����� ����� - ������ ����� ������������������.';
      nKolNP       :=KolichNP(pSPRID);      
    vErrPref := '����� ����� - ������.';
    Insert into FND.F6NDFL_LOAD_SUMGOD (
        KOD_NA, KOD_PODR, GOD, PERIOD, NOM_KORR, 
        KOL_FL_DOHOD, UDERZH_NAL, NE_UDERZH_NAL, VOZVRAT_NAL, KOL_FL_SOVPAD)
    values( rSPR.KOD_NA, 0, rSPR.GOD, rSPR.PERIOD, rSPR.NOM_KORR,
        nKolNP, fUderzhNalog, fNeUderzhNalog, fVozvraNalog, 0);
    
    vErrPref := '������ ����� ������������������.';
    Update F6NDFL_LOAD_SPRAVKI
       set KOL_FL_DOHOD=nvl((
                Select nvl(sum(KOL_FL_DOHOD),0)-nvl(sum(KOL_FL_SOVPAD),0) 
                    from FND.F6NDFL_LOAD_SUMGOD
                    where KOD_NA=rSPR.KOD_NA and GOD=rSPR.GOD and PERIOD=rSPR.PERIOD and NOM_KORR=rSPR.NOM_KORR)
                ,0)    
       where R_SPRID=pSPRID;
    
    vErrPref := '������� ������� �� �����.';
    ZaPeriodPoDatam( cPoDatam , pErrInfo, pSPRID );                            -- ��������� 1 �� 2017 18-04-2017    
    if pErrInfo is not Null then 
       Rollback;
       return;
       end if;
       
    loop
       Fetch cPoDatam into rSVED.DATA_FACT_DOH, rSVED.DATA_UDERZH_NAL, rSVED.SROK_PERECH_NAL, rSVED.SUM_FACT_DOH, rSVED.SUM_UDERZH_NAL; 
       Exit when cPoDatam%NOTFOUND;
       vErrPref := '������ ������� �� �����.';
       Insert into FND.F6NDFL_LOAD_SVED (
            KOD_NA, KOD_PODR, GOD, PERIOD, NOM_KORR, 
            DATA_FACT_DOH, DATA_UDERZH_NAL, SROK_PERECH_NAL, SUM_FACT_DOH, SUM_UDERZH_NAL)
       Values( rSPR.KOD_NA, 0, rSPR.GOD, rSPR.PERIOD, rSPR.NOM_KORR,   
            rSVED.DATA_FACT_DOH, rSVED.DATA_UDERZH_NAL, rSVED.SROK_PERECH_NAL, rSVED.SUM_FACT_DOH, rSVED.SUM_UDERZH_NAL); 
       end loop;
    
    Close cPoDatam;            
       
    pErrInfo := Null;
    Commit; 
 
exception
    when OTHERS then 
        pErrInfo := vErrPref||' '||SQLERRM;  
        Rollback;
end ZagruzTabl_poLSPV;   


function TestArhivBlok( pSPRID in number ) return number is
nXMLID number;
begin

   Select min(R_XMLID) into nXMLID from F6NDFL_ARH_SPRAVKI where ID=pSPRID; 
   
   if nvl(nXMLID,0) = 0 then return 0; end if;
   return 1;
                 
end TestArhivBlok;


procedure PROVERKA_OKRUGLENIYA_NALOGA as
fNEOKRUG float;
fOKRUGL  float;
fUDERZH  float;
fNEDOPL  float;
begin
--  ��� ��������� ������ ��� ���������� ������� ��������
--  �������� �� 2� �������
--  �� ������ 13%
with  q13 as (
                              -- ������ � �������� (������ ���������)
                              -- ���������� ����������, ��� �����������
                              -- ������ 
                              Select  sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                         -- ������ �� ����, � ������� ������������ �����
                                         inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                             where SHIFR_SCHET=85
                                                               and SUB_SHIFR_SCHET in (0,1)  -- ������
                                                               and DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                                                               and DATA_OP < to_date('01.07.2016','dd.mm.yyyy') 
                                                      ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                 where  ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')         -- � ������ ����
                                     and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')       -- �� ����� ��������� �������  
                                     and ds.SERVICE_DOC=0           -- ������� ��� ����������� �����������
                                     and sfl.NAL_REZIDENT=1         -- �� ������ 13%
                                     and sfl.PEN_SXEM<>7            -- �� ���
                                     and ( ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 ) -- ������ �� ����
                                          or ds.SHIFR_SCHET>1000 )                    -- ��������������� ����� �������  
                              -- ��������
                              UNION ALL
                              Select  sfl.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                 from DV_SR_LSPV ds
                                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL 
                                         -- ������ �� ����, � ������� ������������ �����
                                         inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                           where   SHIFR_SCHET=85
                                                               and SUB_SHIFR_SCHET in (2,3)  -- ��������
                                                               and DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                                                               and DATA_OP < to_date('01.07.2016','dd.mm.yyyy')  
                                                    ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                         inner join (Select distinct SSYLKA from VYPLACH_POSOB 
                                                        where TIP_VYPL=1030
                                                          and DATA_VYPL>=to_date('01.01.2016','dd.mm.yyyy') 
                                                          and DATA_VYPL < to_date('01.07.2016','dd.mm.yyyy') 
                                                          and NAL_REZIDENT=1  -- �� ������ 13%
                                                    ) rp on rp.SSYLKA=lspv.SSYLKA_FL  -- ���� ������� �� ������, �� ��� ���   
                                 where  ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')         -- � ������ ����
                                     and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')       -- �� ����� ��������� �������  
                                     and ds.SERVICE_DOC=0           -- ������� ��� ����������� �����������
                                     and (    ds.SHIFR_SCHET= 55    -- ��������
                                           or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������                                               
                               UNION ALL 
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               -- ������
                               Select GF_PERSON, SHIFR_SCHET, MINDATOP DATA_OP, SUMKORR SUMMA from (
                                            Select sfl.GF_PERSON, ds.SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                                     where SHIFR_SCHET=85 
                                                                       and SUB_SHIFR_SCHET in (0,1)  -- ������
                                                                       and DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                                                                       and DATA_OP < to_date('01.07.2016','dd.mm.yyyy')  
                                                                   ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                            where  sfl.NAL_REZIDENT=1                 -- �� ������ 13%        
                                                 and sfl.PEN_SXEM<>7  -- �� ���
                                             start with ( ( ds.SHIFR_SCHET=60  and ds.NOM_VKL<991 ) --  ��� ������ �� ����
                                                       or (ds.SHIFR_SCHET>1000 and ds.NOM_VKL<991 ) )  -- ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1          -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')        -- ����������� �������
                                                    -- ����������� ����� ���� ������� � �����, ���� ���������, ����� �� ������������ �������� ������?                              
                                                    and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')        -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  sfl.GF_PERSON, ds.SHIFR_SCHET          
                                       )  where MINDATOP>=to_date('01.01.2016','dd.mm.yyyy')                -- ������������ ���������� ����
                                            and MINDATOP < to_date('01.07.2016','dd.mm.yyyy')                -- � ������� �������� �������       
                               -- ��������
                               UNION ALL
                               Select GF_PERSON, SHIFR_SCHET, MINDATOP DATA_OP, SUMKORR SUMMA from (
                                            Select sfl.GF_PERSON, ds.SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds            
                                                        inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS     
                                                        inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                                        inner join (Select distinct NOM_VKL, NOM_IPS from DV_SR_LSPV
                                                                       where SHIFR_SCHET=85 
                                                                           and SUB_SHIFR_SCHET in (2,3)  -- ��������
                                                                           and DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                                                                           and DATA_OP < to_date('01.07.2016','dd.mm.yyyy')  
                                                                   ) c85  on lspv.NOM_VKL=c85.NOM_VKL and lspv.NOM_IPS=c85.NOM_IPS 
                                                        inner join (Select distinct SSYLKA from VYPLACH_POSOB 
                                                                        where TIP_VYPL=1030
                                                                          and DATA_VYPL>=to_date('01.01.2016','dd.mm.yyyy') 
                                                                          and DATA_VYPL < to_date('01.07.2016','dd.mm.yyyy') 
                                                                          and NAL_REZIDENT=1  -- �� ������ 13%
                                                                   ) rp on rp.SSYLKA=lspv.SSYLKA_FL  -- ���� ������� �� ������, �� ��� ���                                                                      
                                             start with (   ds.SHIFR_SCHET= 55 -- ��������
                                                         or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')        -- ����������� �������
                                                    -- ����������� ����� ���� ������� � �����, ���� ���������, ����� �� ������������ �������� ������?                              
                                                    and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')        -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by  sfl.GF_PERSON, ds.SHIFR_SCHET          
                                       )  where MINDATOP>=to_date('01.01.2016','dd.mm.yyyy')                -- ������������ ���������� ����
                                            and MINDATOP < to_date('01.07.2016','dd.mm.yyyy')                -- � ������� �������� �������       
                              UNION ALL 
                              -- �������� � ����������� ������
                               -- ���������� ����������, ��� �����������
                               Select vrp.GF_PERSON, ds.SHIFR_SCHET, ds.DATA_OP, ds.SUMMA
                                     from DV_SR_LSPV ds
                                             inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                             inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                                                from VYPLACH_POSOB 
                                                                where TIP_VYPL=1010                -- �������� � ����������� ������
                                                                   and NAL_REZIDENT=1             -- �� ������ 13%      
                                                                   and DATA_VYPL>=to_date('01.01.2016','dd.mm.yyyy')     -- � ������ ����
                                                                   and DATA_VYPL < to_date('01.07.2016','dd.mm.yyyy')     -- �� ����� ��������� ������� 
                                                            ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                                     where (ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                                               or ds.SHIFR_SCHET>1000 ) -- ��������������� ����� �������
                                        and ds.SERVICE_DOC=0  -- ������� �� ����������������
                                        and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                                        and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')          
                  /*           UNION
                               -- �������� � ����������� ������
                               -- ����������� � ����������������� � ������� �������
                               � � � � �   � � � � � � � � (���� ����� ��� ��� - ��� �������)
                    */                                                                      
                              ),
       q30 as (-- ������ � �������� (���������)
               Select sfl.GF_PERSON, ds.*
                 from DV_SR_LSPV ds
                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS                                 
                         inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                 where  ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')     -- � ������ ����
                     and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')     -- �� ����� ��������� �������  
                     and ( ds.SHIFR_SCHET= 55 -- ��������
                              or ( ds.SHIFR_SCHET=60 and ds.NOM_VKL<991 )) --  ��� ������ �� ����                             
                     and sfl.NAL_REZIDENT=2        
               UNION    -- �������� ������� � ���� �����������                                           
               -- �������� � ����������� ������
               Select vrp.GF_PERSON, ds.*
                 from DV_SR_LSPV ds
                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                         inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, GF_PERSON, NAL_REZIDENT   
                                            from VYPLACH_POSOB 
                                            where TIP_VYPL=1010
                                                and DATA_VYPL>=to_date('01.01.2016','dd.mm.yyyy')  
                                                and DATA_VYPL < to_date('01.07.2016','dd.mm.yyyy') 
                                                and NAL_REZIDENT = 2
                                    ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC              
                 where ds.SHIFR_SCHET=62 -- �������� � ����������� ������
                    and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                    and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')                                                                
              ) 
          -- ����������  
       --Select res.*, ISCH_NAL-UDERZH_NAL NEDOPLATA from(
       Select res.*, ISCHISL-UDERZH NEDOPL  
          into fNEOKRUG, fOKRUGL, fUDERZH, fNEDOPL
       from(         
        /*  Select 30 STAVKA, cn.GF_PERSON, cn.ISCH_NAL, bn.UDERZH_NAL  from (
                      Select GF_PERSON, sum(round( 0.30*SUMMA )) ISCH_NAL from q30 where SERVICE_DOC=0 and SHIFR_SCHET<1000
                          group by GF_PERSON          
                     )cn
                   left join (
                        Select  GF_PERSON, nvl(sum(SUMPOTIPU),0) UDERZH_NAL from ( 
                          Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                              inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                              inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                            where ds.SERVICE_DOC=0
                              and ds.SHIFR_SCHET=85 
                              and ds.SUB_SHIFR_SCHET=1
                              and ds.NOM_VKL<991
                              and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                              and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')  
                              and sfl.NAL_REZIDENT=2     
                          UNION ALL               
                          Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                              inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                              inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                            where ds.SERVICE_DOC=0
                              and ds.SHIFR_SCHET=85 
                              and ds.SUB_SHIFR_SCHET=3
                              and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                              and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy') 
                              and sfl.NAL_REZIDENT=2  
                          UNION ALL      
                          Select vrp.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                              inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                              inner join (Select SSYLKA, SSYLKA_DOC, GF_PERSON   
                                            from VYPLACH_POSOB 
                                            where TIP_VYPL=1010
                                              and DATA_VYPL>=to_date('01.01.2016','dd.mm.yyyy')  
                                              and DATA_VYPL < to_date('01.07.2016','dd.mm.yyyy') 
                                              and NAL_REZIDENT = 2
                                          ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC                       
                            where ds.SERVICE_DOC=0
                             and ds.SHIFR_SCHET=86 
                             and ds.SUB_SHIFR_SCHET=1
                             and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                             and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')  
                        ) group by GF_PERSON  
                   ) bn on bn.GF_PERSON=cn.GF_PERSON           
               where cn.ISCH_NAL <> bn.UDERZH_NAL 
         Union */
            -- ��� ������   
            --Select 13 STAVKA, GF_PERSON, NEORUGL_NAL, ISCH_NAL, UDERZH_NAL  from (
            Select sum(NEORUGL_NAL) NEOKRUGL, sum(ISCH_NAL) ISCHISL, sum(UDERZH_NAL) UDERZH  from (
            --Select q.*, ISCH_NAL-UDERZH_NAL RAZN from (                                 
                Select  doh.GF_PERSON,  -- 149.611
                   -- ������ ������ ��� ��������� ���������� 
                             -- ������ � ���������� ��� ������ �������
                             0.13* case when doh.SUMGOD_DOH < nvl(vyc.SUMGOD_VYC,0 )  
                                                   then 0
                                                   else doh.SUMGOD_DOH - nvl(vyc.SUMGOD_VYC,0)
                                                end NEORUGL_NAL,
                             round( 0.13* case when doh.SUMGOD_DOH < nvl(vyc.SUMGOD_VYC,0 )  
                                                   then 0
                                                   else doh.SUMGOD_DOH - nvl(vyc.SUMGOD_VYC,0)
                                                end ) ISCH_NAL, 
                        nvl(bn.UD_NAL,0) UDERZH_NAL                               
                from (    Select GF_PERSON,  sum(SUMMA) SUMGOD_DOH from q13  
                                      where  SHIFR_SCHET<1000    -- ������
                                      group by GF_PERSON
                        ) doh
                left join ( Select GF_PERSON, sum(SUMMA)  SUMGOD_VYC from  q13 
                                      where SHIFR_SCHET>1000   --  ��� ������ 
                                      group by GF_PERSON
                        ) vyc  
                         on vyc.GF_PERSON=doh.GF_PERSON     
                left join ( Select  GF_PERSON, nvl(sum(SUMPOTIPU),0) UD_NAL from (
                              -- ���������� ������
                              Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=85 
                                  and ds.SUB_SHIFR_SCHET=0
                                  and ds.NOM_VKL<991
                                  and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                                  and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')  
                                  and sfl.NAL_REZIDENT=1     
                            UNION ALL         
                              -- ���������� ��������       
                              Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                  inner join (Select distinct SSYLKA from VYPLACH_POSOB 
                                                        where TIP_VYPL=1030
                                                          and DATA_VYPL>=to_date('01.01.2016','dd.mm.yyyy') 
                                                          and DATA_VYPL < to_date('01.07.2016','dd.mm.yyyy')  
                                                          and NAL_REZIDENT=1  -- �� ������ 13%
                                              ) rp on rp.SSYLKA=lspv.SSYLKA_FL  -- ���� ������� �� ������, �� ��� ��� 
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=85 
                                  and ds.SUB_SHIFR_SCHET=2
                                  and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                                  and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')  
                            UNION ALL   
                               -- ������������ ������ � �������� 
                               -- ����������� � ����������������� � ������� �������
                               Select sfl.GF_PERSON, kor.SUMKORR as SUMPOTIPU from (
                                            Select  ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET, min(ds.DATA_OP) MINDATOP, sum(SUMMA) SUMKORR
                                            from  DV_SR_LSPV ds
                                            where  ds.SUB_SHIFR_SCHET in (0,2) -- ������ 13%                                                   
                                             start with ds.SHIFR_SCHET=85    --  ������ �� ������ ������ � ��������
                                                    and ds.SERVICE_DOC=-1            -- ��������� (�������� ����� � -1)
                                                    and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')        -- ����������� �������                         
                                                    and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')        -- � ������� �������� �������
                                             connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                                        and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                                        and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                                        and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                                        and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC 
                                             group by   ds.NOM_VKL, ds.NOM_IPS, ds.SHIFR_SCHET, ds.SUB_SHIFR_SCHET         
                                       ) kor  
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=kor.NOM_VKL and lspv.NOM_IPS=kor.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL                                       
                                         where kor.MINDATOP>=to_date('01.01.2016','dd.mm.yyyy')                -- ������������ ���������� ����
                                           and kor.MINDATOP < to_date('01.07.2016','dd.mm.yyyy')               -- � ������� �������� �������   
                            UNION ALL
                              -- ������� � ���������� ����
                              Select sfl.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join SP_FIZ_LITS sfl on sfl.SSYLKA=lspv.SSYLKA_FL
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=83 
                                  and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                                  and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')                                                  
                            UNION ALL      
                              -- ��������
                              Select vrp.GF_PERSON, ds.SUMMA SUMPOTIPU from DV_SR_LSPV ds
                                  inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                                  inner join (Select SSYLKA, SSYLKA_DOC, GF_PERSON   
                                                        from VYPLACH_POSOB 
                                                        where TIP_VYPL=1010
                                                            and DATA_VYPL>=to_date('01.01.2016','dd.mm.yyyy')  
                                                            and DATA_VYPL < to_date('01.07.2016','dd.mm.yyyy') 
                                                            and NAL_REZIDENT = 1
                                              ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC                       
                                where ds.SERVICE_DOC=0
                                  and ds.SHIFR_SCHET=86 
                                  and ds.SUB_SHIFR_SCHET=0
                                  and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')   
                                  and ds.DATA_OP < to_date('01.07.2016','dd.mm.yyyy')                      
                            ) group by GF_PERSON      
                        ) bn 
                         on bn.GF_PERSON=doh.GF_PERSON      
           )        
      ) res                                   
;            
 end PROVERKA_OKRUGLENIYA_NALOGA;
 
 
 procedure SAVE_QUERY as
 
 -- � � � � � � �
 -- ============================================================== --
 --  � DV_SR_LSPV                                                  --
 --  ���� SERVICE_DOC                                              --
 --  = 0  - ����� � �������� ����������                            --
 --  > 0  - ������ �� SSYLKA_DOC ������ � ���������� �����         --
 --         NOM_VKL, NOM_IPS, SHIFR_SCHET, SUB_SHIFR_SCHET �� ��   --
 --  = -1 - ���������, ��������� � ������� SERVICE_DOC-SSYLKA_DOC  --
 -- ============================================================== -- 
 
 -- ���������� ������ �� ����� � ���������� ������������ ����
 cursor C1 is
         Select * from (   
                             Select ds.DATA_OP, 
                                    ds.SHIFR_SCHET,
                                    ds.SUMMA 
                                 from DV_SR_LSPV ds
                                 where  ds.DATA_OP>=to_date( '01.01.2016','dd.mm.yyyy' )    -- � ������ ����
                                    and ds.DATA_OP <to_date( '01.10.2016','dd.mm.yyyy' )    -- �� ����� ��������� �������  
                                    and ds.SHIFR_SCHET in (85,86)                           -- ������ �� ������ ������ � ��������         
                                    and  ds.SERVICE_DOC=0                                   -- ��� �����������, ���������� ���������
                       )  
         pivot(  sum(SUMMA) as UDNAL for SHIFR_SCHET in ( 85 UCH, 86 POS ) )
         order by DATA_OP;
         
  -- ���������� ����� �������, ������� ����� �� ����������� � ���������� ���       
  cursor C2 is       
    with ispr as (   
                Select q.*,
                       sum(SUMMA)   over(partition by NOM_VKL, NOM_IPS) CHK_SUM,   -- ��������� �� ������
                       min(DATA_OP) over(partition by NOM_VKL, NOM_IPS) MIN_DAT,   -- ���� ��������������� ���������
                       count(*)     over(partition by NOM_VKL, NOM_IPS) CHK_CNT,   -- ����� �������: ��������� � �����������
                       count(*)     over(partition by NOM_VKL, NOM_IPS order by DATA_OP rows unbounded preceding) CHK_ORD
                from(
                     Select ds.* from DV_SR_LSPV ds
                        start with ds.SHIFR_SCHET in (85,86)      -- ��������� �������
                                and ds.SERVICE_DOC= -1            -- ��������� (�������� � -1)
                                and ds.DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')  -- ��������� ��������� ������ 
                                and ds.DATA_OP <to_date('01.10.2016','dd.mm.yyyy')  -- ��������� �������
                        connect by PRIOR ds.NOM_VKL=ds.NOM_VKL  
                               and PRIOR ds.NOM_IPS=ds.NOM_IPS
                               and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                               and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                               and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC  
                    ) q  
              )
        Select sum(SUMMA) from ispr  
          where MIN_DAT<to_date('01.01.2016','dd.mm.yyyy')   
            and DATA_OP>=to_date('01.01.2016','dd.mm.yyyy');        
  

  -- ��������
  -- ��� ����� ��������� -1 � ������-���     
  cursor C3 is           
    Select * from DV_SR_LSPV
    where DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')
    and SERVICE_DOC = 0 
    and (SSYLKA_DOC, SHIFR_SCHET, NOM_IPS, NOM_VKL) 
         in (Select distinct SERVICE_DOC, SHIFR_SCHET, NOM_IPS, NOM_VKL
                  from DV_SR_LSPV
                  where DATA_OP>=to_date('01.01.2016','dd.mm.yyyy')
                    and SERVICE_DOC >0
            );             
 
 begin
   Open C1;
   Close C1;
 end;


/*
-- ��������� ��� ����������� ������� 
--   �� ��������
--   �  ��������������

Select rowid, t.*  from f2NDFL_ARH_SPRAVKI t where R_XMLID=160;
-- ARH_ADR
-- ARH_ITOGI
-- ARH_MES
-- ARH_UVED
-- ARH_VYCH

INSERT INTO FND.F2NDFL_ARH_ADR (
   R_SPRID, KOD_STR, ADR_INO, PINDEX, KOD_REG, RAYON, 
   GOROD, PUNKT, ULITSA, DOM, KOR, KV  ) 
Select trg.ID, arh.KOD_STR, arh.ADR_INO, arh.PINDEX, arh.KOD_REG, arh.RAYON, 
       arh.GOROD, arh.PUNKT, arh.ULITSA, arh.DOM, arh.KOR, arh.KV 
from f2NDFL_ARH_ADR arh
 inner join f2NDFL_ARH_SPRAVKI src on src.ID=arh.R_SPRID 
 inner join f2NDFL_ARH_SPRAVKI trg on trg.NOM_SPR=src.NOM_SPR and trg.R_XMLID=160;
 
Select rowid, arh.* from  f2NDFL_ARH_ADR arh where R_SPRID in (Select ID from f2NDFL_ARH_SPRAVKI t where R_XMLID=160); 

-- �����
Select arh.*
from f2NDFL_ARH_UVED arh
 inner join f2NDFL_ARH_SPRAVKI src on src.ID=arh.R_SPRID 
 inner join f2NDFL_ARH_SPRAVKI trg on trg.NOM_SPR=src.NOM_SPR and trg.R_XMLID=160; 
 
-- ����� 
Select arh.*
from f2NDFL_ARH_VYCH arh
 inner join f2NDFL_ARH_SPRAVKI src on src.ID=arh.R_SPRID 
 inner join f2NDFL_ARH_SPRAVKI trg on trg.NOM_SPR=src.NOM_SPR and trg.R_XMLID=160; 


INSERT INTO FND.F2NDFL_ARH_ITOGI (
   R_SPRID, KOD_STAVKI, SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, 
   SUM_OBL_NU, SUM_NAL_PER, DOLG_NA, VZYSK_IFNS) 
Select trg.ID, arh.KOD_STAVKI, arh.SGD_SUM, arh.SUM_OBL, arh.SUM_OBL_NI, arh.SUM_FIZ_AVANS, 
       arh.SUM_OBL_NU, arh.SUM_NAL_PER, arh.DOLG_NA, arh.VZYSK_IFNS
from f2NDFL_ARH_ITOGI arh
 inner join f2NDFL_ARH_SPRAVKI src on src.ID=arh.R_SPRID 
 inner join f2NDFL_ARH_SPRAVKI trg on trg.NOM_SPR=src.NOM_SPR and trg.R_XMLID=160;
 
Select arh.* from  f2NDFL_ARH_ITOGI arh where R_SPRID in (Select ID from f2NDFL_ARH_SPRAVKI t where R_XMLID=160);  
 
INSERT INTO FND.F2NDFL_ARH_MES (
   R_SPRID, KOD_STAVKI, MES, DOH_KOD_GNI, DOH_SUM, VYCH_KOD_GNI, VYCH_SUM) 
Select trg.ID, arh.KOD_STAVKI, arh.MES, arh.DOH_KOD_GNI, arh.DOH_SUM, arh.VYCH_KOD_GNI, arh.VYCH_SUM
from f2NDFL_ARH_MES arh
 inner join f2NDFL_ARH_SPRAVKI src on src.ID=arh.R_SPRID 
 inner join f2NDFL_ARH_SPRAVKI trg on trg.NOM_SPR=src.NOM_SPR and trg.R_XMLID=160; 
 
Select arh.* from  f2NDFL_ARH_MES arh where R_SPRID in (Select ID from f2NDFL_ARH_SPRAVKI t where R_XMLID=160);  
 
 


*/

 -- ��������� ������ ������������������
 -- �����   ������ 
 -- ������  ���
procedure Load_Pensionery_bez_Storno as

dTermBeg date;
dTermEnd date;

cursor cPBS is 
    Select sfl.SSYLKA, ifl.INN, sfl.NAL_REZIDENT, sfl.GRAZHDAN, sfl.FAMILIYA, sfl.IMYA, sfl.OTCHESTVO, 
           sfl.DATA_ROGD, sfl.DOC_TIP, trim(sfl.DOC_SER1||' '||sfl.DOC_SER2||' '||sfl.DOC_NOM) SER_NOM_DOC       
    from SP_FIZ_LITS sfl
        inner join SP_LSPV lspv on lspv.SSYLKA_FL=sfl.SSYLKA
        left join SP_INN_FIZ_LITS ifl on ifl.SSYLKA=sfl.SSYLKA
    where (lspv.NOM_VKL, lspv.NOM_IPS) 
       in (Select ds.NOM_VKL, ds.NOM_IPS
            from DV_SR_LSPV ds                                   
            where  ds.DATA_OP >= dTermBeg
               and ds.DATA_OP <  dTermEnd
               and ds.SHIFR_SCHET=60  -- ������
               and ds.NOM_VKL < 991   -- ����� ������ �� ������ �������
            group by ds.NOM_VKL, ds.NOM_IPS   
            having min(ds.SERVICE_DOC)=0 and max(ds.SERVICE_DOC)=0 ); -- ��� ���������

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 1; -- ������
    
    Open cPBS;
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
        Insert into F2NDFL_LOAD_SPRAVKI (
            KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, DATA_DOK, NOM_SPR, KVARTAL, 
            PRIZNAK, INN_FL, INN_INO, STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, 
            DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC, STORNO_FLAG, STORNO_DOXPRAV) 
        values( gl_KODNA,
                gl_GOD,
                aPBS(i).SSYLKA,
                gl_TIPDOX,
                gl_NOMKOR,
                Null     /* DATA_DOK */,
                Null     /* NOM_SPR */,
                4        /* KVARTAL */,  -- ��� 2-���� ������ �� ���
                1        /* PRIZNAK */,  -- ������� 2 ������ �������
                aPBS(i).INN,
                Null     /* INN_INO */,
                aPBS(i).NAL_REZIDENT,
                aPBS(i).GRAZHDAN,
                aPBS(i).FAMILIYA,
                aPBS(i).IMYA,
                aPBS(i).OTCHESTVO,
                aPBS(i).DATA_ROGD,
                aPBS(i).DOC_TIP,
                aPBS(i).SER_NOM_DOC,
                0 /* STORNO_FLAG */,
                0 /* STORNO_DOXPRAV */  ); 
        end loop;
    Close cPBS;
    Commit;
    
end Load_Pensionery_bez_Storno;


 -- ��������� ������ ������������������
 -- �����   ������ 
 -- ������  ����
procedure Load_Pensionery_so_Storno as

dTermBeg date;
dTermEnd date;

cursor cPBS is 
    Select sfl.SSYLKA, ifl.INN, sfl.NAL_REZIDENT, sfl.GRAZHDAN, sfl.FAMILIYA, sfl.IMYA, sfl.OTCHESTVO, 
           sfl.DATA_ROGD, sfl.DOC_TIP, trim(sfl.DOC_SER1||' '||sfl.DOC_SER2||' '||sfl.DOC_NOM) SER_NOM_DOC,
           sum(ds.SUMMA) STORNO_DOXPRAV       
    from SP_FIZ_LITS sfl
                    inner join SP_LSPV lspv on lspv.SSYLKA_FL=sfl.SSYLKA
                    inner join DV_SR_LSPV ds on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                    left join SP_INN_FIZ_LITS ifl on ifl.SSYLKA=sfl.SSYLKA                                    
                where  ds.SERVICE_DOC<>0
                start with   ds.SHIFR_SCHET= 60      -- ������
                         and ds.NOM_VKL<991          -- � ������ �� ����
                         and ds.SERVICE_DOC=-1       -- ��������� (�������� ����� � -1)
                         and ds.DATA_OP >= dTermBeg  -- ����������� ������� � ���� ����
                         and ds.DATA_OP <  dTermEnd
                connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                         and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                         and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                         and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                         and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC                    
 group by sfl.SSYLKA, ifl.INN, sfl.NAL_REZIDENT, sfl.GRAZHDAN, sfl.FAMILIYA, sfl.IMYA, sfl.OTCHESTVO, sfl.DATA_ROGD, sfl.DOC_TIP, sfl.DOC_SER1||' '||sfl.DOC_SER2||' '||sfl.DOC_NOM
 having  min(ds.DATA_OP) >= dTermBeg; -- ���������� �������, ������������� ��������� � ���� ����

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 1; -- ������
    
    Open cPBS;
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
        Insert into F2NDFL_LOAD_SPRAVKI (
            KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, DATA_DOK, NOM_SPR, KVARTAL, 
            PRIZNAK, INN_FL, INN_INO, STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, 
            DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC, STORNO_FLAG, STORNO_DOXPRAV) 
        values( gl_KODNA,
                gl_GOD,
                aPBS(i).SSYLKA,
                gl_TIPDOX,
                gl_NOMKOR,
                Null     /* DATA_DOK */,
                Null     /* NOM_SPR */,
                4        /* KVARTAL */,
                1        /* PRIZNAK */,
                aPBS(i).INN,
                Null     /* INN_INO */,
                aPBS(i).NAL_REZIDENT,
                aPBS(i).GRAZHDAN,
                aPBS(i).FAMILIYA,
                aPBS(i).IMYA,
                aPBS(i).OTCHESTVO,
                aPBS(i).DATA_ROGD,
                aPBS(i).DOC_TIP,
                aPBS(i).SER_NOM_DOC,
                1 /* STORNO_FLAG */,
                aPBS(i).STORNO_DOXPRAV ); 
        end loop;
    Close cPBS;
    Commit;
    
end Load_Pensionery_so_Storno;


 -- ��������� ������ ������������������
 -- �����   ��������
 -- ������  ���
procedure Load_Vykupnye_bez_Pravok as

dTermBeg date;
dTermEnd date;

cursor cPBS is 
    select sfl.ssylka,
           ifl.inn,
           sfl.nal_rezident,
           sfl.grazhdan,
           sfl.familiya,
           sfl.imya,
           sfl.otchestvo,
           sfl.data_rogd,
           sfl.doc_tip,
           trim(sfl.doc_ser1 || ' ' || sfl.doc_ser2 || ' ' || sfl.doc_nom) ser_nom_doc
    from   sp_fiz_lits sfl
     inner join sp_lspv lspv
      on   lspv.ssylka_fl = sfl.ssylka
     left  join sp_inn_fiz_lits ifl
      on   ifl.ssylka = sfl.ssylka
    where  (lspv.nom_vkl, lspv.nom_ips) in
           (select ds.nom_vkl,
                   ds.nom_ips
            from   dv_sr_lspv ds
            where  ds.data_op >= dtermbeg
            and    ds.data_op < dtermend
            and    ds.shifr_schet = 55 -- ��������
            group  by ds.nom_vkl,
                      ds.nom_ips
            having min(ds.service_doc) = 0 and max(ds.service_doc) = 0); -- ��� ���������

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 3; -- ��������
    
    Open cPBS;
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
        Insert into F2NDFL_LOAD_SPRAVKI (
            KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, DATA_DOK, NOM_SPR, KVARTAL, 
            PRIZNAK, INN_FL, INN_INO, STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, 
            DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC, STORNO_FLAG, STORNO_DOXPRAV) 
        values( gl_KODNA,
                gl_GOD,
                aPBS(i).SSYLKA,
                gl_TIPDOX,
                gl_NOMKOR,
                Null     /* DATA_DOK */,
                Null     /* NOM_SPR */,
                4        /* KVARTAL */,  -- ��� 2-���� ������ �� ���
                1        /* PRIZNAK */,  -- ������� 2 ������ �������
                aPBS(i).INN,
                Null     /* INN_INO */,
                aPBS(i).NAL_REZIDENT,
                aPBS(i).GRAZHDAN,
                aPBS(i).FAMILIYA,
                aPBS(i).IMYA,
                aPBS(i).OTCHESTVO,
                aPBS(i).DATA_ROGD,
                aPBS(i).DOC_TIP,
                aPBS(i).SER_NOM_DOC,
                0 /* STORNO_FLAG */,
                0 /* STORNO_DOXPRAV */  ); 
        end loop;
    Close cPBS;
    Commit;
    
end Load_Vykupnye_bez_Pravok;

 -- ��������� ������ ������������������
 -- �����   ��������
 -- ������  ����
procedure Load_Vykupnye_s_Ipravlen as

dTermBeg date;
dTermEnd date;

cursor cPBS is 
    Select sfl.SSYLKA, ifl.INN, sfl.NAL_REZIDENT, sfl.GRAZHDAN, sfl.FAMILIYA, sfl.IMYA, sfl.OTCHESTVO, 
           sfl.DATA_ROGD, sfl.DOC_TIP, trim(sfl.DOC_SER1||' '||sfl.DOC_SER2||' '||sfl.DOC_NOM) SER_NOM_DOC,
           sum(ds.SUMMA) STORNO_DOXPRAV       
    from SP_FIZ_LITS sfl
                    inner join SP_LSPV lspv on lspv.SSYLKA_FL=sfl.SSYLKA
                    inner join DV_SR_LSPV ds on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS
                    left join SP_INN_FIZ_LITS ifl on ifl.SSYLKA=sfl.SSYLKA                                    
                where  ds.SERVICE_DOC<>0
                start with   ds.SHIFR_SCHET= 55      -- ������
                         and ds.SERVICE_DOC=-1       -- ��������� (�������� ����� � -1)
                         and ds.DATA_OP >= dTermBeg  -- ����������� ������� � ���� ����
                         and ds.DATA_OP <  dTermEnd
                connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                         and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                         and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                         and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                         and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC                    
 group by sfl.SSYLKA, ifl.INN, sfl.NAL_REZIDENT, sfl.GRAZHDAN, sfl.FAMILIYA, sfl.IMYA, sfl.OTCHESTVO, sfl.DATA_ROGD, sfl.DOC_TIP, sfl.DOC_SER1||' '||sfl.DOC_SER2||' '||sfl.DOC_NOM
 having  min(ds.DATA_OP) >= dTermBeg; -- ���������� �������, ������������� ��������� � ���� ����

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 3; -- ��������
    
    Open cPBS;
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
        Insert into F2NDFL_LOAD_SPRAVKI (
            KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, DATA_DOK, NOM_SPR, KVARTAL, 
            PRIZNAK, INN_FL, INN_INO, STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, 
            DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC, STORNO_FLAG, STORNO_DOXPRAV) 
        values( gl_KODNA,
                gl_GOD,
                aPBS(i).SSYLKA,
                gl_TIPDOX,
                gl_NOMKOR,
                Null     /* DATA_DOK */,
                Null     /* NOM_SPR */,
                4        /* KVARTAL */,
                1        /* PRIZNAK */,
                aPBS(i).INN,
                Null     /* INN_INO */,
                aPBS(i).NAL_REZIDENT,
                aPBS(i).GRAZHDAN,
                aPBS(i).FAMILIYA,
                aPBS(i).IMYA,
                aPBS(i).OTCHESTVO,
                aPBS(i).DATA_ROGD,
                aPBS(i).DOC_TIP,
                aPBS(i).SER_NOM_DOC,
                1 /* STORNO_FLAG */,
                aPBS(i).STORNO_DOXPRAV ); 
        end loop;
    Close cPBS;
    Commit;
    
end Load_Vykupnye_s_Ipravlen; 

 -- ��������� ������ ������������������
 -- �����   �������
 -- ������  ���
procedure Load_Posobiya_bez_Pravok as

dTermBeg date;
dTermEnd date;

cursor cPBS is 
        select psb.ssylka,
               nvl(nvl(ca.inn, ifl.inn), sr.inn_fl) inn,
               psb.nal_rezident,
               ic.citizenship grazhdan,
               pe.lastname familiya,
               pe.firstname imya,
               pe.secondname otchestvo,
               pe.birthdate data_rogd,
               ic.fk_idcard_type doc_tip,
               trim(ic.series || ' ' || ic.nbr) ser_nom_doc
        from   (select vrp.ssylka,
                       vrp.ssylka_poluch,
                       vrp.gf_person,
                       vrp.nal_rezident
                from   sp_lspv lspv
                 inner join dv_sr_lspv ds
                  on   ds.nom_vkl = lspv.nom_vkl
                  and  ds.nom_ips = lspv.nom_ips
                 inner join (select data_vypl,
                                    ssylka,
                                    ssylka_doc,
                                    nom_vipl,
                                    ssylka_poluch,
                                    gf_person,
                                    nal_rezident
                             from   vyplach_posob
                             where  tip_vypl = 1010
                             and    nom_vipl = 1
                             and    data_vypl >= dtermbeg
                             and    data_vypl < dtermend) vrp
                  on   vrp.ssylka = lspv.ssylka_fl
                  and  vrp.ssylka_doc = ds.ssylka_doc
                where  ds.data_op >= dtermbeg
                and    ds.data_op < dtermend
                and    ds.shifr_schet = 62 -- �������� � ����������� �����  
                group  by vrp.ssylka,
                          vrp.ssylka_poluch,
                          vrp.gf_person,
                          vrp.nal_rezident
                having min(ds.service_doc) = 0 and max(ds.service_doc) = 0 -- ��� ���������                            
                ) psb
        left   join gazfond.people pe
        on     pe.fk_contragent = psb.gf_person
        left   join gazfond.idcards ic
        on     ic.id = pe.fk_idcard
        left   join gazfond.contragents ca
        on     ca.id = psb.gf_person
        left   join sp_inn_fiz_lits ifl
        on     ifl.ssylka = psb.ssylka_poluch
        left   join sp_ritual_pos sr
        on     sr.ssylka = psb.ssylka;

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 2; -- �������
    
    Open cPBS;
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
        Insert into F2NDFL_LOAD_SPRAVKI (
            KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, DATA_DOK, NOM_SPR, KVARTAL, 
            PRIZNAK, INN_FL, INN_INO, STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, 
            DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC, STORNO_FLAG, STORNO_DOXPRAV) 
        values( gl_KODNA,
                gl_GOD,
                aPBS(i).SSYLKA,
                gl_TIPDOX,
                gl_NOMKOR,
                Null     /* DATA_DOK */,
                Null     /* NOM_SPR */,
                4        /* KVARTAL */,  -- ��� 2-���� ������ �� ���
                1        /* PRIZNAK */,  -- ������� 2 ������ �������
                aPBS(i).INN,
                Null     /* INN_INO */,
                aPBS(i).NAL_REZIDENT,
                aPBS(i).GRAZHDAN,
                aPBS(i).FAMILIYA,
                aPBS(i).IMYA,
                aPBS(i).OTCHESTVO,
                aPBS(i).DATA_ROGD,
                aPBS(i).DOC_TIP,
                aPBS(i).SER_NOM_DOC,
                0 /* STORNO_FLAG */,
                0 /* STORNO_DOXPRAV */  ); 
        end loop;
    Close cPBS;
    Commit;
    
  end Load_Posobiya_bez_Pravok; 


 -- ��������� ������ ������������������
 -- �����   �������
 -- ������  ����
procedure Load_Posobiya_s_Ipravlen as

dTermBeg date;
dTermEnd date;

cursor cPBS is 
         Select psb.SSYLKA, nvl(nvl(ca.INN, ifl.INN),sr.INN_FL) INN, psb.NAL_REZIDENT, ic.CITIZENSHIP GRAZHDAN, 
                pe.Lastname FAMILIYA, pe.Firstname IMYA, pe.Secondname OTCHESTVO, pe.Birthdate DATA_ROGD, 
                ic.FK_IDCARD_TYPE DOC_TIP, trim(ic.SERIES||' '||ic.NBR) SER_NOM_DOC, psb.SUMPOS                       
            from 
                (Select vrp.SSYLKA, vrp.SSYLKA_POLUCH, vrp.GF_PERSON, vrp.NAL_REZIDENT, sum(ds.SUMMA) SUMPOS
                    from SP_LSPV lspv 
                        inner join DV_SR_LSPV ds on ds.NOM_VKL=lspv.NOM_VKL and ds.NOM_IPS=lspv.NOM_IPS 
                        inner join (Select DATA_VYPL, SSYLKA, SSYLKA_DOC, NOM_VIPL, SSYLKA_POLUCH, GF_PERSON, NAL_REZIDENT   
                                        from VYPLACH_POSOB 
                                        where TIP_VYPL=1010
                                          and NOM_VIPL=1   
                                          and DATA_VYPL >= to_date('01.01.2016') 
                                          and DATA_VYPL  < to_date('01.01.2017')
                                   ) vrp on vrp.SSYLKA=lspv.SSYLKA_FL and vrp.SSYLKA_DOC=ds.SSYLKA_DOC   
                    where  ds.DATA_OP >= to_date('01.01.2016')
                       and ds.DATA_OP <  to_date('01.01.2017')
                       and ds.SHIFR_SCHET=62  -- �������� � ����������� �����  
                    group by vrp.SSYLKA, vrp.SSYLKA_POLUCH, vrp.GF_PERSON, vrp.NAL_REZIDENT  
                    having min(ds.SERVICE_DOC)<>0 or max(ds.SERVICE_DOC)<>0                             
                ) psb
                left join gazfond.People pe on pe.FK_CONTRAGENT=psb.GF_PERSON  
                left join gazfond.IDCards ic on ic.ID=pe.FK_IDCARD     
                left join gazfond.Contragents ca on ca.ID=psb.GF_PERSON  
                left join SP_INN_FIZ_LITS ifl on ifl.SSYLKA=psb.SSYLKA_POLUCH                         
                left join SP_RITUAL_POS sr on sr.SSYLKA=psb.SSYLKA;

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 2; -- �������
    
    Open cPBS;
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
        Insert into F2NDFL_LOAD_SPRAVKI (
            KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, DATA_DOK, NOM_SPR, KVARTAL, 
            PRIZNAK, INN_FL, INN_INO, STATUS_NP, GRAZHD, FAMILIYA, IMYA, OTCHESTVO, 
            DATA_ROZHD, KOD_UD_LICHN, SER_NOM_DOC, STORNO_FLAG, STORNO_DOXPRAV) 
        values( gl_KODNA,
                gl_GOD,
                aPBS(i).SSYLKA,
                gl_TIPDOX,
                gl_NOMKOR,
                Null     /* DATA_DOK */,
                Null     /* NOM_SPR */,
                4        /* KVARTAL */,  -- ��� 2-���� ������ �� ���
                1        /* PRIZNAK */,  -- ������� 2 ������ �������
                aPBS(i).INN,
                Null     /* INN_INO */,
                aPBS(i).NAL_REZIDENT,
                aPBS(i).GRAZHDAN,
                aPBS(i).FAMILIYA,
                aPBS(i).IMYA,
                aPBS(i).OTCHESTVO,
                aPBS(i).DATA_ROGD,
                aPBS(i).DOC_TIP,
                aPBS(i).SER_NOM_DOC,
                1 /* STORNO_FLAG */,
                aPBS(i).SUMPOS /* STORNO_DOXPRAV */  ); 
        end loop;
    Close cPBS;
    Commit;
    
  end Load_Posobiya_s_Ipravlen; 
  
-- �������� ������� �� �������
-- ������ ��� �����������
procedure Load_MesDoh_Pensia_bezIspr as
dTermBeg date;
dTermEnd date;

cursor cPBS( pNPStatus in number ) is 
        Select ls.SSYLKA, extract(MONTH from ds.DATA_OP) MES, sum(ds.SUMMA) DOH_SUM
        from DV_SR_LSPV ds
          inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
          inner join f2NDFL_LOAD_SPRAVKI ls on ls.SSYLKA=sp.SSYLKA_FL
        where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=gl_TIPDOX and ls.NOM_KORR=gl_NOMKOR and ls.STORNO_FLAG=0 and ls.STATUS_NP=pNPStatus
          and ds.DATA_OP>=dTermBeg and ds.DATA_OP<dTermEnd and ds.SHIFR_SCHET=60
        group by ls.SSYLKA, extract(MONTH from ds.DATA_OP)
        order by ls.SSYLKA, extract(MONTH from ds.DATA_OP);

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 1; -- ������
    
    Open cPBS( 1 );  -- ���������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    1240               /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    13                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
    
    Open cPBS( 2 );  -- �����������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    1240               /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    30                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
        
    Commit;

end Load_MesDoh_Pensia_bezIspr;

-- �������� ������� �� �������
-- ������ � �������������
procedure Load_MesDoh_Pensia_sIspravl as
dTermBeg date;
dTermEnd date;

cursor cPBS( pNPStatus in number ) is 
        Select ls.SSYLKA, extract(MONTH from ds.DATA_OP) MES, sum(ds.SUMMA) DOH_SUM
            from DV_SR_LSPV ds 
                 inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                 inner join F2NDFL_LOAD_SPRAVKI ls on lspv.SSYLKA_FL=ls.SSYLKA 
            where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=gl_TIPDOX and ls.NOM_KORR=gl_NOMKOR and ls.STORNO_FLAG<>0 and ls.STATUS_NP=pNPStatus     
              and ds.DATA_OP>=dTermBeg and ds.DATA_OP<dTermEnd and ds.SHIFR_SCHET=60 and ds.SERVICE_DOC=0
        group by ls.SSYLKA, extract(MONTH from ds.DATA_OP)        
        order by ls.SSYLKA, extract(MONTH from ds.DATA_OP);

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

nNonZeroSTORNO number;

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 1; -- ������
    
    -- �������� �� ������� ���� ������������������ �������� ������
    Select count(*) into nNonZeroSTORNO
    from(
         Select dvsr.SSYLKA_FL
            from( Select lspv.SSYLKA_FL, ds.*
                    from DV_SR_LSPV ds 
                    inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                        start with   ds.SHIFR_SCHET= 60      -- ������
                                 and ds.SERVICE_DOC=-1       -- ��������� (�������� ����� � -1)
                                 and ds.DATA_OP >= dTermBeg  -- ����������� ������� � ���� ����
                                 and ds.DATA_OP <  dTermEnd
                        connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                 and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                 and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                 and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                 and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC
                 ) dvsr                
                inner join F2NDFL_LOAD_SPRAVKI ls on dvsr.SSYLKA_FL=ls.SSYLKA    
            where ls.KOD_NA=1 and ls.GOD=2016 and ls.TIP_DOX=1 and ls.NOM_KORR=0 and ls.STORNO_FLAG<>0
            group by dvsr.SSYLKA_FL   
            having sum(dvsr.SUMMA)<>0
        );  
        
    if nNonZeroSTORNO<>0 then
       Raise_Application_Error( 
             -200001,
            '������: ��� �������� ������� ����������� �� ������� ���������� '||to_char(nNonZeroSTORNO)||
            ' ��������� ���� �� ��������� ������.' );
       end if;      
    
    Open cPBS( 1 );  -- ���������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    1240               /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    13                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
    
    Open cPBS( 2 );  -- �����������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    1240               /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    30                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
        
    Commit;

end Load_MesDoh_Pensia_sIspravl;

-- �������� ������� �� �������
-- ������� ��� �����������
procedure Load_MesDoh_Posob_bezIspr as
dTermBeg date;
dTermEnd date;

cursor cPBS( pNPStatus in number ) is 
        select ls.ssylka,
               extract(month from ds.data_op) mes,
               ds.sub_shifr_schet,
               sum(ds.summa) doh_sum
        from   dv_sr_lspv ds
         inner  join sp_lspv sp
          on   sp.nom_vkl = ds.nom_vkl
          and  sp.nom_ips = ds.nom_ips
         inner  join f2ndfl_load_spravki ls
          on   ls.ssylka = sp.ssylka_fl
        where  ls.kod_na = gl_kodna
        and    ls.god = gl_god
        and    ls.tip_dox = gl_tipdox
        and    ls.nom_korr = gl_nomkor
        and    ls.storno_flag = 0
        and    ls.status_np = pnpstatus
        and    ds.data_op >= dtermbeg
        and    ds.data_op < dtermend
        and    ds.shifr_schet = 62
        group  by ls.ssylka,
                  extract(month from ds.data_op),
                  ds.sub_shifr_schet
        order  by ls.ssylka,
                  extract(month from ds.data_op),
                  ds.sub_shifr_schet;

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 2; -- �������
    
    Open cPBS( 1 );  -- ���������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    1240               /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    13                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
    
    Open cPBS( 2 );  -- �����������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    1240               /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    30                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
        
    Commit;

end Load_MesDoh_Posob_bezIspr;


-- �������� ������� �� �������
-- ������� ��� �����������
procedure Load_MesDoh_Posob_sIspravl as
dTermBeg date;
dTermEnd date;
nCorrQnt number;
begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 2; -- �������
    
    -- ��������, ���� �� �������� ����������� � �������� �������
    Select count(*) into nCorrQnt
        from DV_SR_LSPV ds   
        where ds.SHIFR_SCHET=62 and ds.DATA_OP>=dTermBeg and ds.DATA_OP<dTermEnd 
          and ( ds.SUMMA<0 or ds.SERVICE_DOC<>0 );

    if nCorrQnt>0 then
        Raise_Application_Error( 
             -200001,
            '������: �������� ������� �� ������������ ������ ������� ��� �� ����������. '||chr(10)||chr(13)||
            '� �������� ������� ������� ������� '||to_char(nCorrQnt)||' � ���������� �����������.' );    
        end if;

end Load_MesDoh_Posob_sIspravl;


-- �������� ������� �� �������
-- �������� ��� �����������
procedure Load_MesDoh_Vykup_bezIspr as
dTermBeg date;
dTermEnd date;

cursor cPBS( pNPStatus in number ) is 
        select ls.ssylka,
               extract(month from ds.data_op) mes,
               ds.sub_shifr_schet,
               sum(ds.summa) doh_sum
        from   dv_sr_lspv ds
         inner join sp_lspv sp
          on   sp.nom_vkl = ds.nom_vkl
          and  sp.nom_ips = ds.nom_ips
         inner join f2ndfl_load_spravki ls
          on   ls.ssylka = sp.ssylka_fl
        where  ls.kod_na = gl_kodna
        and    ls.god = gl_god
        and    ls.tip_dox = gl_tipdox
        and    ls.nom_korr = gl_nomkor
        and    ls.storno_flag = 0
        and    ls.status_np = pnpstatus
        and    ds.data_op >= dtermbeg
        and    ds.data_op < dtermend
        and    ds.shifr_schet = 55
        group  by ls.ssylka,
                  extract(month from ds.data_op),
                  ds.sub_shifr_schet
        order  by ls.ssylka,
                  extract(month from ds.data_op),
                  ds.sub_shifr_schet;

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 3; -- ��������
    
    Open cPBS( 1 );  -- ���������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    case aPBS(i).SUB_SHIFR_SCHET
                        when 0 then 1215
                        when 1 then 1220
                        else Null
                    end                /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    13                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
    
    Open cPBS( 2 );  -- �����������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    case aPBS(i).SUB_SHIFR_SCHET
                        when 0 then 1215
                        when 1 then 1220
                        else Null
                    end                /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    30                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
        
    Commit;

end Load_MesDoh_Vykup_bezIspr;

-- �������� � �������������
procedure Load_MesDoh_Vykup_sIspravl as
dTermBeg date;
dTermEnd date;

cursor cPBS( pNPStatus in number ) is 
        Select * 
        from(   -- ����� ��� �����������
                Select ls.SSYLKA, extract(MONTH from ds.DATA_OP) MES, ds.SUB_SHIFR_SCHET, sum(ds.SUMMA) DOH_SUM
                    from DV_SR_LSPV ds 
                         inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                         inner join F2NDFL_LOAD_SPRAVKI ls on lspv.SSYLKA_FL=ls.SSYLKA 
                    where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=gl_TIPDOX and ls.NOM_KORR=gl_NOMKOR and ls.STORNO_FLAG<>0 and ls.STATUS_NP=pNPStatus    
                        and ds.SHIFR_SCHET= 55      -- ��������
                        and ds.DATA_OP >= dTermBeg  
                        and ds.DATA_OP <  dTermEnd
                        and ds.SERVICE_DOC=0        -- ��� �����������
                group by ls.SSYLKA, extract(MONTH from ds.DATA_OP), ds.SUB_SHIFR_SCHET        
            UNION
                -- ����� ������������
                Select dvsr.*
                from( Select SSYLKA_FL SSYLKA, extract(MONTH from PERVDATA) MES, SUB_SHIFR_SCHET, sum(NOVSUM) DOH_SUM 
                      from( 
                            Select lspv.SSYLKA_FL, ds.SUB_SHIFR_SCHET, sum(SUMMA) NOVSUM, min(ds.DATA_OP) PERVDATA
                                from DV_SR_LSPV ds 
                                inner join SP_LSPV lspv on lspv.NOM_VKL=ds.NOM_VKL and lspv.NOM_IPS=ds.NOM_IPS 
                                    start with   ds.SHIFR_SCHET= 55      -- ��������
                                             and ds.SERVICE_DOC=-1       -- ��������� (�������� ����� � -1)
                                             and ds.DATA_OP >= dTermBeg  -- ����������� ������� � ���� ����
                                             and ds.DATA_OP <  dTermEnd
                                    connect by   PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                                             and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                                             and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                                             and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                                             and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC
                                group by lspv.SSYLKA_FL, ds.SUB_SHIFR_SCHET
                          ) group by SSYLKA_FL, SUB_SHIFR_SCHET, extract(MONTH from PERVDATA)              
                     ) dvsr                
                    inner join F2NDFL_LOAD_SPRAVKI ls on dvsr.SSYLKA=ls.SSYLKA    
                where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=gl_TIPDOX and ls.NOM_KORR=gl_NOMKOR and ls.STORNO_FLAG<>0 and ls.STATUS_NP=pNPStatus               
        ) where DOH_SUM<>0
          order by SSYLKA, MES, SUB_SHIFR_SCHET;

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 3; -- ��������
    
    Open cPBS( 1 );  -- ���������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    case aPBS(i).SUB_SHIFR_SCHET
                        when 0 then 1215
                        when 1 then 1220
                        else Null
                    end                /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    13                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
    
    Open cPBS( 2 );  -- �����������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into FND.F2NDFL_LOAD_MES (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, DOH_KOD_GNI, 
                DOH_SUM, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI, FL_TRUE) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    aPBS(i).MES,
                    case aPBS(i).SUB_SHIFR_SCHET
                        when 0 then 1215
                        when 1 then 1220
                        else Null
                    end                /* DOH_KOD_GNI  */,
                    aPBS(i).DOH_SUM,
                    0                  /* VYCH_KOD_GNI */,
                    Null               /* VYCH_SUM     */,
                    30                 /*KOD_STAVKI    */,
                    0                  /* FL_TRUE      */ );        
        end loop;
    Close cPBS;
        
    Commit;

end Load_MesDoh_Vykup_sIspravl;
  

-- �������� ������� ��� ����������� � ���������� - ����������
procedure Load_Vychety as

dTermBeg date;
dTermEnd date;

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 1; -- ������

    Insert into F2NDFL_LOAD_VYCH 
          ( KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI) 
    Select ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, ls.NOM_KORR, 
           extract(MONTH from ds.DATA_OP), ds.SHIFR_SCHET, sum(ds.SUMMA), 13
    from F2NDFL_LOAD_SPRAVKI ls
         inner join SP_LSPV sp on sp.SSYLKA_FL=ls.SSYLKA
         inner join DV_SR_LSPV ds on ds.NOM_VKL=sp.NOM_VKL and ds.NOM_IPS=sp.NOM_IPS
    where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=gl_TIPDOX and ls.NOM_KORR=gl_NOMKOR
      and ls.STATUS_NP=1          -- ���������
      and ds.SHIFR_SCHET>1000     -- ������
      and ds.DATA_OP >= dTermBeg  -- �� ���
      and ds.DATA_OP <  dTermEnd
    group by ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, ls.NOM_KORR, extract(MONTH from ds.DATA_OP), ds.SHIFR_SCHET;
    
    gl_TIPDOX := 3; -- ��������

    Insert into F2NDFL_LOAD_VYCH 
          ( KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, MES, VYCH_KOD_GNI, VYCH_SUM, KOD_STAVKI) 
    Select ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, ls.NOM_KORR, 
           extract(MONTH from ds.DATA_OP), ds.SHIFR_SCHET, sum(ds.SUMMA), 13
    from F2NDFL_LOAD_SPRAVKI ls
         inner join SP_LSPV sp on sp.SSYLKA_FL=ls.SSYLKA
         inner join DV_SR_LSPV ds on ds.NOM_VKL=sp.NOM_VKL and ds.NOM_IPS=sp.NOM_IPS
    where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=gl_TIPDOX and ls.NOM_KORR=gl_NOMKOR
      and ls.STATUS_NP=1          -- ���������
      and ds.SHIFR_SCHET>1000     -- ������
      and ds.DATA_OP >= dTermBeg  -- �� ���
      and ds.DATA_OP <  dTermEnd
    group by ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, ls.NOM_KORR, extract(MONTH from ds.DATA_OP), ds.SHIFR_SCHET;    
    
    Commit;
    
end Load_Vychety;


-- �������� ������ �� �������
-- ������ 13 � 30%
-- ������ ���: ��� ����������� � � �������������
procedure Load_Itogi_Pensia as

dTermBeg date;
dTermEnd date;

cursor cPBS( pNPStatus in number, pKodStavki in number ) is 
    Select ls.SSYLKA, nvl(doh.SGD_SUM,0) SGD_DOH, nvl(vyc.SGD_SUM,0) SGD_VYCH, nvl(nal.SGD_SUM,0) SGD_NAL, 
           nvl(doh.SGD_SUM30,0) SGD_NI30, 
           nvl(doh.SGD_SUM,0) - LEAST(nvl(doh.SGD_SUM,0),nvl(vyc.SGD_SUM,0)) SGD_OB13,
           round( 0.13*(nvl(doh.SGD_SUM,0) - LEAST(nvl(doh.SGD_SUM,0),nvl(vyc.SGD_SUM,0))), 0 ) SGD_NI13
    from f2NDFL_LOAD_SPRAVKI ls
        left join( 
            Select SSYLKA, sum(DOH_SUM) SGD_SUM, sum(round(0.3*DOH_SUM,0)) SGD_SUM30
                from f2NDFL_LOAD_MES 
                where KOD_NA=gl_KODNA and GOD=gl_GOD and TIP_DOX=gl_TIPDOX and NOM_KORR=gl_NOMKOR and KOD_STAVKI=pKodStavki
                group by SSYLKA
        ) doh on ls.SSYLKA=doh.SSYLKA
        left join (
            Select SSYLKA, sum(VYCH_SUM) SGD_SUM
                from f2NDFL_LOAD_VYCH
                where KOD_NA=gl_KODNA and GOD=gl_GOD and TIP_DOX=gl_TIPDOX and NOM_KORR=gl_NOMKOR and KOD_STAVKI=pKodStavki
                group by SSYLKA 
        ) vyc on  ls.SSYLKA=vyc.SSYLKA 
        left join( 
            Select SSYLKA_FL, sum(SGD_SUMPRED) SGD_SUM from (
                    Select sp.SSYLKA_FL, sum(SUMMA) SGD_SUMPRED  
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where ds.DATA_OP >= dTermBeg 
                          and ds.DATA_OP <  dTermEnd 
                          and ds.SHIFR_SCHET=85 
                          and ds.SUB_SHIFR_SCHET=(pNPStatus-1) -- ��� ������: 0-���������, 1-����������� 
                          and ds.SERVICE_DOC=0                 -- ���� <>0, �� ��� ������ ���������� ������� ����� ��� ������
                        group by sp.SSYLKA_FL
                union all  -- ����������� ������ ������� ������ ���������� ��������  
                    Select sp.SSYLKA_FL, sum(SUMMA) SGD_SUMPRED 
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where ds.DATA_OP >= dTermBeg
                          and ds.DATA_OP <  dTermEnd 
                          and ds.SHIFR_SCHET=83 
                          and ds.SERVICE_DOC=0       
                        group by sp.SSYLKA_FL 
                union all  -- ����������� ������, ��������� � 2016 ����, �� ���� ��������� � 2017   
                    Select sp.SSYLKA_FL, -sum(SUMMA) SGD_SUMPRED 
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where gl_GOD=2016 -- ��������� ������ ��� 2016 ����
                          and ds.DATA_OP = to_date('01.01.2017') 
                          and ds.SHIFR_SCHET=83 
                        group by sp.SSYLKA_FL 
            ) group by SSYLKA_FL               
        ) nal on ls.SSYLKA=nal.SSYLKA_FL
    where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=gl_TIPDOX and ls.NOM_KORR=gl_NOMKOR and ls.STATUS_NP=pNPStatus;

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 1; -- ������
    
    -- ����������� � ��������� � ���������� ������ ���� �� �����
    -- ������� ����� �������� ��� � � �������������
    -- �� ��� ��������� ������� ��������� �� ������� ��� ���������� � ������������
    
    Open cPBS( 1, 13 );  -- ���������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into F2NDFL_LOAD_ITOGI (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, 
                SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, SUM_OBL_NU, 
                SUM_NAL_PER, DOLG_NA, VZYSK_IFNS) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    13               /* KOD_STAVKI */,
                    aPBS(i).SGD_DOH  /* SGD_SUM */,
                    aPBS(i).SGD_OB13 /* SUM_OBL */,
                    aPBS(i).SGD_NI13 /* SUM_OBL_NI */,
                    0                /* SUM_FIZ_AVANS */,
                    aPBS(i).SGD_NAL  /* SUM_OBL_NU */,
                    aPBS(i).SGD_NAL  /* SUM_NAL_PER */,
                    GREATEST( aPBS(i).SGD_NAL -aPBS(i).SGD_NI13, 0 ) /* DOLG_NA */,
                    GREATEST( aPBS(i).SGD_NI13-aPBS(i).SGD_NAL,  0 ) /* VZYSK_IFNS */ );                                   
        end loop;
    Close cPBS;  
    
    
    Open cPBS( 2, 30 );  -- �����������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into F2NDFL_LOAD_ITOGI (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, 
                SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, SUM_OBL_NU, 
                SUM_NAL_PER, DOLG_NA, VZYSK_IFNS) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    30                /* KOD_STAVKI */,
                    aPBS(i).SGD_DOH   /* SGD_SUM */,
                    aPBS(i).SGD_DOH   /* SUM_OBL */,
                    aPBS(i).SGD_NI30  /* SUM_OBL_NI */,
                    0                 /* SUM_FIZ_AVANS */,
                    aPBS(i).SGD_NAL   /* SUM_OBL_NU */,
                    aPBS(i).SGD_NAL   /* SUM_NAL_PER */,
                    GREATEST( aPBS(i).SGD_NAL -aPBS(i).SGD_NI30, 0 ) /* DOLG_NA */,
                    GREATEST( aPBS(i).SGD_NI30-aPBS(i).SGD_NAL,  0 ) /* VZYSK_IFNS */ );                                   
        end loop;
    Close cPBS;   
    
    Commit;
    
end Load_Itogi_Pensia;  


-- �������� ������ �� �������� �� ������ 13% � 30%
-- ��� �����������
procedure Load_Itogi_Posob_bezIspr as

dTermBeg date;
dTermEnd date;

-- �������� ��� ����������� ������ ������
cursor cPBS( pNPStatus in number, pKodStavki in number ) is 
    Select ls.SSYLKA, nvl(doh.SGD_SUM,0) SGD_DOH, nvl(vyc.SGD_SUM,0) SGD_VYCH, nvl(nal.SGD_SUM,0) SGD_NAL, 
           nvl(doh.SGD_SUM30,0) SGD_NI30, 
           nvl(doh.SGD_SUM,0) - LEAST(nvl(doh.SGD_SUM,0),nvl(vyc.SGD_SUM,0)) SGD_OB13,
           round( 0.13*(nvl(doh.SGD_SUM,0) - LEAST(nvl(doh.SGD_SUM,0),nvl(vyc.SGD_SUM,0))), 0 ) SGD_NI13 
    from f2NDFL_LOAD_SPRAVKI ls
        left join(  
            Select SSYLKA, sum(DOH_SUM) SGD_SUM, sum(round(0.3*DOH_SUM,0)) SGD_SUM30
                from f2NDFL_LOAD_MES 
                where KOD_NA=gl_KODNA and GOD=gl_GOD and TIP_DOX=gl_TIPDOX and NOM_KORR=gl_NOMKOR and KOD_STAVKI=pKodStavki
                group by SSYLKA
            ) doh on ls.SSYLKA=doh.SSYLKA
        left join (
            Select SSYLKA, sum(VYCH_SUM) SGD_SUM
                from f2NDFL_LOAD_VYCH
                where KOD_NA=gl_KODNA and GOD=gl_GOD and TIP_DOX=gl_TIPDOX and NOM_KORR=gl_NOMKOR and KOD_STAVKI=pKodStavki
                group by SSYLKA 
            ) vyc on  ls.SSYLKA=vyc.SSYLKA 
        left join( 
            Select sp.SSYLKA_FL, sum(SUMMA) SGD_SUM -- SGD_SUMPRED  
                from DV_SR_LSPV ds 
                     inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                where ds.DATA_OP >= dTermBeg 
                  and ds.DATA_OP <  dTermEnd 
                  and ds.SHIFR_SCHET=86 
                  and ds.SUB_SHIFR_SCHET=(pNPStatus-1) -- ��� �������: 0-���������, 1-����������� 
                  and ds.SERVICE_DOC=0                 -- ��� ������ ��� ����������� STORNO_FLAG=0
                group by sp.SSYLKA_FL             
            ) nal on ls.SSYLKA=nal.SSYLKA_FL    
    where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=gl_TIPDOX and ls.NOM_KORR=gl_NOMKOR and STORNO_FLAG=0 and ls.STATUS_NP=pNPStatus;

type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 2; -- �������
    
    -- ����������� � ��������� � ���������� ������ ���� �� �����
    -- ������� ����� �������� ��� � � �������������
    -- �� ��� ��������� ������� ��������� �� ������� ��� ���������� � ������������
    
    Open cPBS( 1, 13 );  -- ���������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into F2NDFL_LOAD_ITOGI (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, 
                SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, SUM_OBL_NU, 
                SUM_NAL_PER, DOLG_NA, VZYSK_IFNS) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    13               /* KOD_STAVKI */,
                    aPBS(i).SGD_DOH  /* SGD_SUM */,
                    aPBS(i).SGD_OB13 /* SUM_OBL */,
                    aPBS(i).SGD_NI13 /* SUM_OBL_NI */,
                    0                /* SUM_FIZ_AVANS */,
                    aPBS(i).SGD_NAL  /* SUM_OBL_NU */,
                    aPBS(i).SGD_NAL  /* SUM_NAL_PER */,
                    GREATEST( aPBS(i).SGD_NAL -aPBS(i).SGD_NI13, 0 ) /* DOLG_NA */,
                    GREATEST( aPBS(i).SGD_NI13-aPBS(i).SGD_NAL,  0 ) /* VZYSK_IFNS */ );                                 
        end loop;
    Close cPBS;  
    
    
    Open cPBS( 2, 30 );  -- �����������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into F2NDFL_LOAD_ITOGI (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, 
                SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, SUM_OBL_NU, 
                SUM_NAL_PER, DOLG_NA, VZYSK_IFNS) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    30                /* KOD_STAVKI */,
                    aPBS(i).SGD_DOH   /* SGD_SUM */,
                    aPBS(i).SGD_DOH   /* SUM_OBL */,
                    aPBS(i).SGD_NI30  /* SUM_OBL_NI */,
                    0                 /* SUM_FIZ_AVANS */,
                    aPBS(i).SGD_NAL   /* SUM_OBL_NU */,
                    aPBS(i).SGD_NAL   /* SUM_NAL_PER */,
                    GREATEST( aPBS(i).SGD_NAL -aPBS(i).SGD_NI30, 0 ) /* DOLG_NA */,
                    GREATEST( aPBS(i).SGD_NI30-aPBS(i).SGD_NAL,  0 ) /* VZYSK_IFNS */ );                                    
        end loop;
    Close cPBS;   
    
    Commit;
    
end Load_Itogi_Posob_bezIspr; 


-- �������� ������ �� �������� �� ������ 13% � 30%
-- ��� �����������
procedure Load_Itogi_Vykup_bezIspr as

dTermBeg date;
dTermEnd date;

-- �������� ��� ����������� ������ ������
cursor cPBS( pNPStatus in number, pKodStavki in number ) is 
  select ls.ssylka,
         nvl(doh.sgd_sum, 0) sgd_doh,
         nvl(vyc.sgd_sum, 0) sgd_vych,
         nvl(nal.sgd_sum, 0) sgd_nal,
         nvl(doh.sgd_sum30, 0) sgd_ni30,
         nvl(doh.sgd_sum, 0) -
         least(nvl(doh.sgd_sum, 0), nvl(vyc.sgd_sum, 0)) sgd_ob13,
         round(0.13 * (nvl(doh.sgd_sum, 0) -
               least(nvl(doh.sgd_sum, 0), nvl(vyc.sgd_sum, 0))),
               0) sgd_ni13
  from   f2ndfl_load_spravki ls
   left  join (select ssylka,
                      sum(doh_sum) sgd_sum,
                      sum(round(0.3 * doh_sum, 0)) sgd_sum30
               from   f2ndfl_load_mes
               where  kod_na = gl_kodna
               and    god = gl_god
               and    tip_dox = gl_tipdox
               and    nom_korr = gl_nomkor
               and    kod_stavki = pkodstavki
               group  by ssylka) doh
    on   ls.ssylka = doh.ssylka
   left  join (select ssylka,
                      sum(vych_sum) sgd_sum
               from   f2ndfl_load_vych
               where  kod_na = gl_kodna
               and    god = gl_god
               and    tip_dox = gl_tipdox
               and    nom_korr = gl_nomkor
               and    kod_stavki = pkodstavki
               group  by ssylka) vyc
    on   ls.ssylka = vyc.ssylka
   left  join (select ssylka_fl,
                      sum(sgd_sumpred) sgd_sum
               from   (select sp.ssylka_fl,
                              sum(summa) sgd_sumpred
                       from   dv_sr_lspv ds
                        inner join sp_lspv sp
                         on   sp.nom_vkl = ds.nom_vkl
                         and  sp.nom_ips = ds.nom_ips
                       where  ds.data_op >= dtermbeg
                       and    ds.data_op < dtermend
                       and    ds.shifr_schet = 85
                       and    ds.sub_shifr_schet = (pnpstatus + 1) -- ��� ��������: 2-���������, 3-����������� 
                       and    ds.service_doc = 0 -- ��� ������� ��� ����������� STORNO_FLAG=0
                       group  by sp.ssylka_fl)
               group  by ssylka_fl) nal
    on   ls.ssylka = nal.ssylka_fl
  where  ls.kod_na = gl_kodna
  and    ls.god = gl_god
  and    ls.tip_dox = gl_tipdox
  and    ls.nom_korr = gl_nomkor
  and    storno_flag = 0
  and    ls.status_np = pnpstatus;


type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 3; -- ��������
    
    -- ����������� � ��������� � ���������� ������ ���� �� �����
    -- ������� ����� �������� ��� � � �������������
    -- �� ��� ��������� ������� ��������� �� ������� ��� ���������� � ������������
    
    Open cPBS( 1, 13 );  -- ���������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into F2NDFL_LOAD_ITOGI (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, 
                SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, SUM_OBL_NU, 
                SUM_NAL_PER, DOLG_NA, VZYSK_IFNS) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    13               /* KOD_STAVKI */,
                    aPBS(i).SGD_DOH  /* SGD_SUM */,
                    aPBS(i).SGD_OB13 /* SUM_OBL */,
                    aPBS(i).SGD_NI13 /* SUM_OBL_NI */,
                    0                /* SUM_FIZ_AVANS */,
                    aPBS(i).SGD_NAL  /* SUM_OBL_NU */,
                    aPBS(i).SGD_NAL  /* SUM_NAL_PER */,
                    GREATEST( aPBS(i).SGD_NAL -aPBS(i).SGD_NI13, 0 ) /* DOLG_NA */,
                    GREATEST( aPBS(i).SGD_NI13-aPBS(i).SGD_NAL,  0 ) /* VZYSK_IFNS */ );                                 
        end loop;
    Close cPBS;  
    
    
    Open cPBS( 2, 30 );  -- �����������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into F2NDFL_LOAD_ITOGI (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, 
                SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, SUM_OBL_NU, 
                SUM_NAL_PER, DOLG_NA, VZYSK_IFNS) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    30                /* KOD_STAVKI */,
                    aPBS(i).SGD_DOH   /* SGD_SUM */,
                    aPBS(i).SGD_DOH   /* SUM_OBL */,
                    aPBS(i).SGD_NI30  /* SUM_OBL_NI */,
                    0                 /* SUM_FIZ_AVANS */,
                    aPBS(i).SGD_NAL   /* SUM_OBL_NU */,
                    aPBS(i).SGD_NAL   /* SUM_NAL_PER */,
                    GREATEST( aPBS(i).SGD_NAL -aPBS(i).SGD_NI30, 0 ) /* DOLG_NA */,
                    GREATEST( aPBS(i).SGD_NI30-aPBS(i).SGD_NAL,  0 ) /* VZYSK_IFNS */ );                                    
        end loop;
    Close cPBS;   
    
    Commit;
    
end Load_Itogi_Vykup_bezIspr;   

-- �������� ������ �� �������� �� ������ 13% � 30%
-- � �������������
procedure Load_Itogi_Vykup_sIspravl as

dTermBeg date;
dTermEnd date;

-- �������� � ������������� ������ ������
cursor cPBS( pNPStatus in number, pKodStavki in number ) is 
Select ls.SSYLKA, nvl(doh.SGD_SUM,0) SGD_DOH, nvl(vyc.SGD_SUM,0) SGD_VYCH, nvl(nal.SGD_SUM,0) SGD_NAL, 
           nvl(doh.SGD_SUM30,0) SGD_NI30, 
           nvl(doh.SGD_SUM,0) - LEAST(nvl(doh.SGD_SUM,0),nvl(vyc.SGD_SUM,0)) SGD_OB13,
           round( 0.13*(nvl(doh.SGD_SUM,0) - LEAST(nvl(doh.SGD_SUM,0),nvl(vyc.SGD_SUM,0))), 0 ) SGD_NI13
    from f2NDFL_LOAD_SPRAVKI ls
        left join(  
            Select SSYLKA, sum(DOH_SUM) SGD_SUM, sum(round(0.3*DOH_SUM,0)) SGD_SUM30
                from f2NDFL_LOAD_MES 
                where KOD_NA=gl_KODNA and GOD=gl_GOD and TIP_DOX=gl_TIPDOX and NOM_KORR=gl_NOMKOR and KOD_STAVKI=pKodStavki
                group by SSYLKA
            ) doh on ls.SSYLKA=doh.SSYLKA
        left join (
            Select SSYLKA, sum(VYCH_SUM) SGD_SUM
                from f2NDFL_LOAD_VYCH
                where KOD_NA=gl_KODNA and GOD=gl_GOD and TIP_DOX=gl_TIPDOX and NOM_KORR=gl_NOMKOR and KOD_STAVKI=pKodStavki
                group by SSYLKA 
            ) vyc on  ls.SSYLKA=vyc.SSYLKA 
        left join( 
            Select SSYLKA_FL, sum(SGD_SUMPRED) SGD_SUM from (
                    -- �������������� �����
                    Select sp.SSYLKA_FL, sum(SUMMA) SGD_SUMPRED  
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where ds.DATA_OP >= dTermBeg 
                          and ds.DATA_OP <  dTermEnd 
                          and ds.SHIFR_SCHET=85 
                          and ds.SUB_SHIFR_SCHET=(pNPStatus+1) -- ��� ��������: 2-���������, 3-����������� 
                          and ds.SERVICE_DOC=0                 -- ��� ������ ��� ����������� 
                        group by sp.SSYLKA_FL
                    -- �����������
                    union all
                    Select sp.SSYLKA_FL, sum(SUMMA) SGD_SUMPRED  
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where ds.SHIFR_SCHET=85 
                          and ds.SUB_SHIFR_SCHET=(pNPStatus+1) -- ��� ��������: 2-���������, 3-����������� 
                          and ds.SERVICE_DOC<>0                -- ��� ������ � ������������� STORNO_FLAG=1
                        start with ds.SERVICE_DOC=-1
                          and ds.DATA_OP >= dTermBeg 
                        connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                               and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                               and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                               and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                               and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC                         
                        group by sp.SSYLKA_FL
                        having min(ds.DATA_OP) >= dTermBeg                         
                ) group by SSYLKA_FL               
            ) nal on ls.SSYLKA=nal.SSYLKA_FL        
    where ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and ls.TIP_DOX=gl_TIPDOX and ls.NOM_KORR=gl_NOMKOR and STORNO_FLAG=1 and ls.STATUS_NP=pNPStatus;


type tPBS is table of cPBS%rowtype;
aPBS tPBS; 

begin

    CheckGlobals;
    dTermBeg  := gl_DATAS;
    dTermEnd  := gl_DATADO;
    gl_TIPDOX := 3; -- ��������
    
    -- ����������� � ��������� � ���������� ������ ���� �� �����
    -- ������� ����� �������� ��� � � �������������
    -- �� ��� ��������� ������� ��������� �� ������� ��� ���������� � ������������
    
    Open cPBS( 1, 13 );  -- ���������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into F2NDFL_LOAD_ITOGI (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, 
                SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, SUM_OBL_NU, 
                SUM_NAL_PER, DOLG_NA, VZYSK_IFNS) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    13               /* KOD_STAVKI */,
                    aPBS(i).SGD_DOH  /* SGD_SUM */,
                    aPBS(i).SGD_OB13 /* SUM_OBL */,
                    aPBS(i).SGD_NI13 /* SUM_OBL_NI */,
                    0                /* SUM_FIZ_AVANS */,
                    aPBS(i).SGD_NAL  /* SUM_OBL_NU */,
                    aPBS(i).SGD_NAL  /* SUM_NAL_PER */,
                    GREATEST( aPBS(i).SGD_NAL -aPBS(i).SGD_NI13, 0 ) /* DOLG_NA */,
                    GREATEST( aPBS(i).SGD_NI13-aPBS(i).SGD_NAL,  0 ) /* VZYSK_IFNS */ );                                 
        end loop;
    Close cPBS;  
    
    
    Open cPBS( 2, 30 );  -- �����������
    Loop
        Fetch cPBS bulk collect into aPBS limit 1000;
        Exit when aPBS.COUNT=0;
         
        forall i in 1 .. aPBS.COUNT
            Insert into F2NDFL_LOAD_ITOGI (
                KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, KOD_STAVKI, 
                SGD_SUM, SUM_OBL, SUM_OBL_NI, SUM_FIZ_AVANS, SUM_OBL_NU, 
                SUM_NAL_PER, DOLG_NA, VZYSK_IFNS) 
            values( gl_KODNA,
                    gl_GOD,
                    aPBS(i).SSYLKA,
                    gl_TIPDOX,
                    gl_NOMKOR,
                    30                /* KOD_STAVKI */,
                    aPBS(i).SGD_DOH   /* SGD_SUM */,
                    aPBS(i).SGD_DOH   /* SUM_OBL */,
                    aPBS(i).SGD_NI30  /* SUM_OBL_NI */,
                    0                 /* SUM_FIZ_AVANS */,
                    aPBS(i).SGD_NAL   /* SUM_OBL_NU */,
                    aPBS(i).SGD_NAL   /* SUM_NAL_PER */,
                    GREATEST( aPBS(i).SGD_NAL -aPBS(i).SGD_NI30, 0 ) /* DOLG_NA */,
                    GREATEST( aPBS(i).SGD_NI30-aPBS(i).SGD_NAL,  0 ) /* VZYSK_IFNS */ );                                    
        end loop;
    Close cPBS;   
    
    Commit;
    
end Load_Itogi_Vykup_sIspravl;  

-- �������� ������
procedure Load_Itogi_Obnovit( pKODNA in number, pGOD in number, pSSYLKA in number, pTIPDOX in number, pNOMKOR in number ) as
nStatusNP number;
nKodStavki number;
fGodDoh float;
fGodDohOblag float;
fGodIschNal30 float;
fGodIschNal float;
fGodVych float;
fGodUdNal float;

dTermBeg date;
dTermEnd date;
begin

    Select STATUS_NP into nStatusNP
        from f2NDFL_LOAD_SPRAVKI 
        where KOD_NA=pKODNA and GOD=pGOD and SSYLKA=pSSYLKA and TIP_DOX=pTIPDOX and NOM_KORR=pNOMKOR;
        
    Case nStatusNP
      when 1 then  nKodStavki:=13;
      when 2 then  nKodStavki:=30;
      else Raise_Application_Error( -20001, '������ ����������������� �� ���������.');
    end case;  

    Select sum(DOH_SUM), sum(round(0.3*DOH_SUM,0)) into fGodDoh, fGodIschNal30
        from f2NDFL_LOAD_MES 
        where KOD_NA=pKODNA and GOD=pGOD and SSYLKA=pSSYLKA and TIP_DOX=pTIPDOX and NOM_KORR=pNOMKOR and KOD_STAVKI=nKodStavki;
        
    if fGodDoh is Null then    
       Raise_Application_Error( -20001, '�� ������� ������ �� ������� ���� � ������ �����������������.'); 
       end if;    
    
    Select sum(VYCH_SUM) into fGodVych
        from f2NDFL_LOAD_VYCH
        where KOD_NA=pKODNA and GOD=pGOD and SSYLKA=pSSYLKA and TIP_DOX=pTIPDOX and NOM_KORR=pNOMKOR and KOD_STAVKI=nKodStavki;  
        
    -- ���������� �����
    dTermBeg := to_date( '01.01.'||trim(to_char(pGOD  ,'0000')), 'dd.mm.yyyy');
    dTermEnd := to_date( '01.01.'||trim(to_char(pGOD+1,'0000')), 'dd.mm.yyyy');
    
    Case pTIPDOX 
        when 1 then
            Select sum(SGD_SUMPRED) into fGodUdNal
            from(
                Select sp.SSYLKA_FL, sum(SUMMA) SGD_SUMPRED  
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where sp.SSYLKA_FL=pSSYLKA
                          and ds.DATA_OP >= dTermBeg 
                          and ds.DATA_OP <  dTermEnd 
                          and ds.SHIFR_SCHET=85 
                          and ds.SUB_SHIFR_SCHET=(nStatusNP-1) -- ��� ������: 0-���������, 1-����������� 
                          and ds.SERVICE_DOC=0                 -- ���� <>0, �� ��� ������ ���������� ������� ����� ��� ������
                        group by sp.SSYLKA_FL
                union all  -- ����������� ������ ������� ������ ���������� ��������  
                    Select sp.SSYLKA_FL, sum(SUMMA) SGD_SUMPRED 
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where sp.SSYLKA_FL=pSSYLKA
                          and ds.DATA_OP >= dTermBeg
                          and ds.DATA_OP <  dTermEnd 
                          and ds.SHIFR_SCHET=83 
                          and ds.SERVICE_DOC=0       
                        group by sp.SSYLKA_FL 
                union all  -- ����������� ������, ��������� � 2016 ����, �� ���� ��������� � 2017   
                    Select sp.SSYLKA_FL, -sum(SUMMA) SGD_SUMPRED 
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where pGOD=2016 -- ��������� ������ ��� 2016 ����
                          and sp.SSYLKA_FL=pSSYLKA
                          and ds.DATA_OP = to_date('01.01.2017') 
                          and ds.SHIFR_SCHET=83 
                        group by sp.SSYLKA_FL
                );            
        when 2 then
            Select sum(SUMMA) into fGodUdNal
                from DV_SR_LSPV ds 
                     inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                where sp.SSYLKA_FL=pSSYLKA
                  and ds.DATA_OP >= dTermBeg 
                  and ds.DATA_OP <  dTermEnd 
                  and ds.SHIFR_SCHET=86 
                  and ds.SUB_SHIFR_SCHET=(nStatusNP-1) -- ��� �������: 0-���������, 1-����������� 
                  and ds.SERVICE_DOC=0;                -- ��� ������ ��� ����������� STORNO_FLAG=0        
        when 3 then
            Select sum(SGD_SUMPRED) into fGodUdNal
            from(        
                    Select sp.SSYLKA_FL, sum(SUMMA) SGD_SUMPRED  
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where sp.SSYLKA_FL=pSSYLKA
                          and ds.DATA_OP >= dTermBeg 
                          and ds.DATA_OP <  dTermEnd 
                          and ds.SHIFR_SCHET=85 
                          and ds.SUB_SHIFR_SCHET=(nStatusNP+1) -- ��� ��������: 2-���������, 3-����������� 
                          and ds.SERVICE_DOC=0                 -- ��� ������ ��� ����������� 
                        group by sp.SSYLKA_FL
                    -- �����������
                    union all
                    Select sp.SSYLKA_FL, sum(SUMMA) SGD_SUMPRED  
                        from DV_SR_LSPV ds 
                             inner join SP_LSPV sp on sp.NOM_VKL=ds.NOM_VKL and sp.NOM_IPS=ds.NOM_IPS
                        where sp.SSYLKA_FL=pSSYLKA
                          and ds.SHIFR_SCHET=85 
                          and ds.SUB_SHIFR_SCHET=(nStatusNP+1) -- ��� ��������: 2-���������, 3-����������� 
                          and ds.SERVICE_DOC<>0                -- ��� ������ � ������������� STORNO_FLAG=1
                        start with ds.SERVICE_DOC=-1
                          and ds.DATA_OP >= dTermBeg 
                        connect by PRIOR ds.NOM_VKL=ds.NOM_VKL   -- ����� �� ������� ����������� ��
                               and PRIOR ds.NOM_IPS=ds.NOM_IPS    -- ������������� ����������
                               and PRIOR ds.SHIFR_SCHET=ds.SHIFR_SCHET
                               and PRIOR ds.SUB_SHIFR_SCHET=ds.SUB_SHIFR_SCHET
                               and PRIOR ds.SSYLKA_DOC=ds.SERVICE_DOC                         
                        group by sp.SSYLKA_FL
                        having min(ds.DATA_OP) >= dTermBeg    
                );           
        else Raise_Application_Error( -20001, '��������� ��� ������ �� ������������� �������� �� ����������� ��������.');
    end case;    

        
    fGodVych      := nvl(fGodVych,0);   
    fGodUdNal     := nvl(fGodUdNal,0);
    case nStatusNP
        when 1 then
            fGodDohOblag  := fGodDoh - LEAST(fGodDoh,fGodVych);
            fGodIschNal   := round( 0.13*fGodDohOblag, 0 );
        else
            fGodDohOblag  := fGodDoh;
            fGodIschNal   := fGodIschNal30;          
    end case;        

    Update F2NDFL_LOAD_ITOGI 
        set 
            SGD_SUM       = fGodDoh, 
            SUM_OBL       = fGodDohOblag, 
            SUM_OBL_NI    = fGodIschNal, 
            SUM_FIZ_AVANS = 0, 
            SUM_OBL_NU    = fGodUdNal, 
            SUM_NAL_PER   = fGodUdNal, 
            DOLG_NA       = GREATEST( round(fGodUdNal-fGodIschNal,0) , 0 ), 
            VZYSK_IFNS    = GREATEST( round(fGodIschNal-fGodUdNal,0) , 0 )
        where KOD_NA=pKODNA and GOD=pGOD and SSYLKA=pSSYLKA and TIP_DOX=pTIPDOX and NOM_KORR=pNOMKOR and KOD_STAVKI=nKodStavki;               
          

end Load_Itogi_Obnovit;

-- ������ ����� ��������� ��������� ������
-- ������ ������� ����� �������������� ����������� � ������� ������� �������
-- (����� ��������������� ��������� ���������� InitGlobals)
procedure Load_Adresa_INO as
begin

    CheckGlobals;
    
    Insert into f2NDFL_LOAD_ADR (
       KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, TIP_ADR, ADR_FULL, 
       PINDEX,  STR_NAM, REG_NAM, REG_SKR, RON_NAM, RON_SKR, 
       GOR_NAM, GOR_SKR, PUN_NAM, PUN_SKR, ULI_NAM, ULI_SKR, 
       DOM_TXT, KOR_TXT, KV_TXT, 
       STR_KOD, REG_GNK, RON_GNK, GOR_GNK, PUN_GNK, ULI_GNK,  
       F2_KODSTR, 
       F2_KODREG, F2_INDEX, F2_RAYON, F2_GOROD, F2_PUNKT, 
       F2_ULITSA, F2_DOM, F2_KOR, F2_KV, BNA_NOMSPR )
    Select ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, ls.NOM_KORR, ga.TIP_ADR, ga.ADR_FND, 
           ga.PINDEX,  ga.STR_NAM, ga.REG_NAM, ga.REG_SKR, ga.RON_NAM, ga.RON_SKR, 
           ga.GOR_NAM, ga.GOR_SKR, ga.PUN_NAM, ga.PUN_SKR, ga.ULI_NAM, ga.ULI_SKR, 
           ga.TXT_DOM, ga.TXT_KOR, ga.TXT_KV,
           ga.STR_KOD, ga.REG_GNK, ga.RON_GNK, ga.GOR_GNK, ga.PUN_GNK, ga.ULI_GNK,
           trim(to_char(ga.STR_KOD,'000')) F2_KODSTR,
           Null F2_KODREG, Null F2_INDEX, Null F2_RAYON, Null F2_GOROD, Null F2_PUNKT,
           Null F2_ULITSA, Null F2_DOM, Null F2_KOR, Null F2_KV, ls.NOM_SPR
    from GNI_ADR_SOOTV ga 
         inner join f2NDFL_LOAD_SPRAVKI ls on ls.SSYLKA=ga.SSYLKA and ls.TIP_DOX=ga.TIP_DOX and ls.NOM_SPR=ga.SPRNOM
    where ga.STR_KOD<>643  and ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD;    
  
    Commit;

Exception
    when OTHERS then
        Rollback;
        Raise;    
  
end Load_Adresa_INO; 

procedure Load_Adresa_vRF as
begin

    CheckGlobals;
    
        Insert into f2NDFL_LOAD_ADR (
           KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, TIP_ADR, 
           ADR_FULL, PINDEX, STR_NAM, 
           REG_NAM, REG_SKR, RON_NAM, 
           RON_SKR, GOR_NAM, GOR_SKR, 
           PUN_NAM, PUN_SKR, ULI_NAM, 
           ULI_SKR, DOM_TXT, KOR_TXT, 
           KV_TXT, STR_KOD, REG_GNK, 
           RON_GNK, GOR_GNK, PUN_GNK, 
           ULI_GNK,  
           F2_KODSTR, F2_KODREG, F2_INDEX, 
           F2_RAYON, F2_GOROD, F2_PUNKT, 
           F2_ULITSA, F2_DOM, F2_KOR, 
           F2_KV, BNA_NOMSPR )    
        Select ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, ls.NOM_KORR, ga.TIP_ADR, ga.ADR_FND, 
               ga.PINDEX,  ga.STR_NAM, ga.REG_NAM, ga.REG_SKR, ga.RON_NAM, ga.RON_SKR, 
               ga.GOR_NAM, ga.GOR_SKR, ga.PUN_NAM, ga.PUN_SKR, ga.ULI_NAM, ga.ULI_SKR, 
               ga.TXT_DOM, ga.TXT_KOR, ga.TXT_KV,
               ga.STR_KOD, ga.REG_GNK, ga.RON_GNK, ga.GOR_GNK, ga.PUN_GNK, ga.ULI_GNK,
               trim(to_char(ga.STR_KOD,'000')) F2_KODSTR,
               substr(ga.REG_GNK,1,2) F2_KODREG, ga.PINDEX F2_INDEX, ga.RON_NAM||' '||ga.RON_SKR F2_RAYON, 
               ga.GOR_NAM||' '||ga.GOR_SKR F2_GOROD, ga.PUN_NAM||' '||ga.PUN_SKR F2_PUNKT,
               ga.ULI_NAM||' '||ga.ULI_SKR F2_ULITSA, ga.TXT_DOM F2_DOM, ga.TXT_KOR F2_KOR, ga.TXT_KV F2_KV, ls.NOM_SPR
        from GNI_ADR_SOOTV ga 
             inner join f2NDFL_LOAD_SPRAVKI ls on ls.SSYLKA=ga.SSYLKA and ls.TIP_DOX=ga.TIP_DOX and ls.NOM_SPR=ga.SPRNOM
        where ga.STR_KOD=643 and ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD 
          and (not regexp_like( ga.ULI_GNK, '\d{17}' )) and (not regexp_like( ga.PUN_GNK, '\d{13}' ));    
          
        Insert into f2NDFL_LOAD_ADR (
           KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, TIP_ADR, 
           ADR_FULL, PINDEX, STR_NAM, 
           REG_NAM, REG_SKR, RON_NAM, 
           RON_SKR, GOR_NAM, GOR_SKR, 
           PUN_NAM, PUN_SKR, ULI_NAM, 
           ULI_SKR, DOM_TXT, KOR_TXT, 
           KV_TXT, STR_KOD, REG_GNK, 
           RON_GNK, GOR_GNK, PUN_GNK, 
           ULI_GNK,  
           F2_KODSTR, F2_KODREG, F2_INDEX, 
           F2_RAYON, F2_GOROD, F2_PUNKT, 
           F2_ULITSA, F2_DOM, F2_KOR, 
           F2_KV, BNA_NOMSPR )
        Select ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, ls.NOM_KORR, ga.TIP_ADR, ga.ADR_FND, 
               ga.PINDEX,  ga.STR_NAM, ga.REG_NAM, ga.REG_SKR, ga.RON_NAM, ga.RON_SKR, 
               ga.GOR_NAM, ga.GOR_SKR, ga.PUN_NAM, ga.PUN_SKR, ga.ULI_NAM, ga.ULI_SKR, 
               ga.TXT_DOM, ga.TXT_KOR, ga.TXT_KV,
               ga.STR_KOD, 
               substr(ga.PUN_GNK,1,2)||'00000000000' REG_GNK, 
               substr(ga.PUN_GNK,1,5)||'00000000'    RON_GNK, 
               substr(ga.PUN_GNK,1,8)||'00000'       GOR_GNK, 
               ga.PUN_GNK, ga.ULI_GNK,
               trim(to_char(ga.STR_KOD,'000')) F2_KODSTR,
               substr(ga.PUN_GNK,1,2) F2_KODREG, ga.PINDEX F2_INDEX, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.PUN_GNK,1,5)||'00000000' and ga.PUN_GNK not like '__000%'   ) F2_RAYON, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.PUN_GNK,1,8)||'00000'    and ga.PUN_GNK not like '_____000%') F2_GOROD, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=ga.PUN_GNK and KLCODE not like '%000__')  F2_PUNKT,
               ga.ULI_NAM||' '||ga.ULI_SKR F2_ULITSA, 
               ga.TXT_DOM F2_DOM, ga.TXT_KOR F2_KOR, ga.TXT_KV F2_KV, ls.NOM_SPR
        from GNI_ADR_SOOTV ga 
             inner join f2NDFL_LOAD_SPRAVKI ls on ls.SSYLKA=ga.SSYLKA and ls.TIP_DOX=ga.TIP_DOX and ls.NOM_SPR=ga.SPRNOM
        where ga.STR_KOD=643 and ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and regexp_like( ga.PUN_GNK, '\d{13}' ) and not regexp_like( ga.ULI_GNK, '\d{17}' );        
        
        Insert into f2NDFL_LOAD_ADR (
           KOD_NA, GOD, SSYLKA, TIP_DOX, NOM_KORR, TIP_ADR, 
           ADR_FULL, PINDEX, STR_NAM, 
           REG_NAM, REG_SKR, RON_NAM, 
           RON_SKR, GOR_NAM, GOR_SKR, 
           PUN_NAM, PUN_SKR, ULI_NAM, 
           ULI_SKR, DOM_TXT, KOR_TXT, 
           KV_TXT, STR_KOD, REG_GNK, 
           RON_GNK, GOR_GNK, PUN_GNK, 
           ULI_GNK,  
           F2_KODSTR, F2_KODREG, F2_INDEX, 
           F2_RAYON, F2_GOROD, F2_PUNKT, 
           F2_ULITSA, F2_DOM, F2_KOR, 
           F2_KV, BNA_NOMSPR )
        Select ls.KOD_NA, ls.GOD, ls.SSYLKA, ls.TIP_DOX, ls.NOM_KORR, ga.TIP_ADR, ga.ADR_FND, 
               ga.PINDEX,  ga.STR_NAM, ga.REG_NAM, ga.REG_SKR, ga.RON_NAM, ga.RON_SKR, 
               ga.GOR_NAM, ga.GOR_SKR, ga.PUN_NAM, ga.PUN_SKR, ga.ULI_NAM, ga.ULI_SKR, 
               ga.TXT_DOM, ga.TXT_KOR, ga.TXT_KV,
               ga.STR_KOD, 
               substr(ga.ULI_GNK,1, 2)||'00000000000' REG_GNK, 
               substr(ga.ULI_GNK,1, 5)||'00000000'    RON_GNK, 
               substr(ga.ULI_GNK,1, 8)||'00000'       GOR_GNK, 
               substr(ga.ULI_GNK,1,11)||'00'          PUN_GNK, 
               ga.ULI_GNK,
               trim(to_char(ga.STR_KOD,'000')) F2_KODSTR,
               substr(ga.ULI_GNK,1,2) F2_KODREG, ga.PINDEX F2_INDEX, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.ULI_GNK,1, 5)||'00000000' and ga.ULI_GNK not like '__000%'   )     F2_RAYON, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.ULI_GNK,1, 8)||'00000'    and ga.ULI_GNK not like '_____000%')     F2_GOROD, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.ULI_GNK,1,11)||'00'       and ga.ULI_GNK not like '________000%')  F2_PUNKT,
               (Select NAZV||' '||SOCR from GNI_STREET where KLCODE=ga.ULI_GNK and ga.ULI_GNK not like '%0000__') F2_ULITSA, 
               ga.TXT_DOM F2_DOM, ga.TXT_KOR F2_KOR, ga.TXT_KV F2_KV, ls.NOM_SPR
        from GNI_ADR_SOOTV ga 
             inner join f2NDFL_LOAD_SPRAVKI ls on ls.SSYLKA=ga.SSYLKA and ls.TIP_DOX=ga.TIP_DOX and ls.NOM_SPR=ga.SPRNOM
        where ga.STR_KOD=643 and ls.KOD_NA=gl_KODNA and ls.GOD=gl_GOD and regexp_like( ga.ULI_GNK, '\d{17}' );            
          
    Commit;      
    
Exception
    when OTHERS then
        Rollback;
        Raise;        
    
end Load_Adresa_vRF;  

procedure Kopir_Adresa_vRF_izSOOTV( pPachka in number, pGod in number ) as
begin

        Delete from fnd.f2NDFL_ARH_ADR
          where R_SPRID in (Select sp.ID from fnd.f2NDFL_ARH_SPRAVKI sp 
                                inner join fnd.GNI_ADR_SOOTV ga on ga.SPRNOM=sp.NOM_SPR
                                where ga.FL_ULIS=pGod and sp.KOD_NA=1 and sp.GOD=pGod
                                  and sp.R_XMLID = pPachka);  

        Insert into fnd.f2NDFL_ARH_ADR( R_SPRID, KOD_STR, ADR_INO,  PINDEX, KOD_REG, RAYON, GOROD, PUNKT, ULITSA,  DOM, KOR, KV )  
        Select ls.R_SPRID, trim(to_char(ga.STR_KOD,'000')) F2_KODSTR, ga.ADR_FND, ga.PINDEX, substr(ga.REG_GNK,1,2) F2_KODREG, 
               ga.RON_NAM||' '||ga.RON_SKR F2_RAYON, ga.GOR_NAM||' '||ga.GOR_SKR F2_GOROD, ga.PUN_NAM||' '||ga.PUN_SKR F2_PUNKT, 
               ga.ULI_NAM||' '||ga.ULI_SKR F2_ULITSA, ga.TXT_DOM F2_DOM, ga.TXT_KOR F2_KOR, ga.TXT_KV F2_KV
        from fnd.GNI_ADR_SOOTV ga 
             inner join fnd.f2NDFL_LOAD_SPRAVKI ls on ls.SSYLKA=ga.SSYLKA and ls.TIP_DOX=ga.TIP_DOX and ls.NOM_SPR=ga.SPRNOM
        where ga.STR_KOD=643 and ls.KOD_NA=1 and ls.GOD=pGOD and ga.FL_ULIS=pGOD  
          and (not regexp_like( ga.ULI_GNK, '\d{17}' )) and (not regexp_like( ga.PUN_GNK, '\d{13}' ));    
          
        Insert into fnd.f2NDFL_ARH_ADR( R_SPRID, KOD_STR, ADR_INO,  PINDEX, KOD_REG, RAYON, GOROD, PUNKT, ULITSA,  DOM, KOR, KV ) 
        Select ls.R_SPRID, trim(to_char(ga.STR_KOD,'000')) F2_KODSTR, ga.ADR_FND, ga.PINDEX, substr(ga.PUN_GNK,1,2) F2_KODREG,
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.PUN_GNK,1,5)||'00000000' and ga.PUN_GNK not like '__000%'   ) F2_RAYON, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.PUN_GNK,1,8)||'00000'    and ga.PUN_GNK not like '_____000%') F2_GOROD, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=ga.PUN_GNK and KLCODE not like '%000__')  F2_PUNKT,
               ga.ULI_NAM||' '||ga.ULI_SKR F2_ULITSA, ga.TXT_DOM, ga.TXT_KOR, ga.TXT_KV
        from fnd.GNI_ADR_SOOTV ga 
             inner join fnd.f2NDFL_LOAD_SPRAVKI ls on ls.SSYLKA=ga.SSYLKA and ls.TIP_DOX=ga.TIP_DOX and ls.NOM_SPR=ga.SPRNOM
        where ga.STR_KOD=643 and ga.FL_ULIS=pGOD 
          and ls.KOD_NA=1 and ls.GOD=pGOD and regexp_like( ga.PUN_GNK, '\d{13}' ) and not regexp_like( ga.ULI_GNK, '\d{17}' );        
        
        Insert into fnd.f2NDFL_ARH_ADR( R_SPRID, KOD_STR, ADR_INO,  PINDEX, KOD_REG, RAYON, GOROD, PUNKT, ULITSA,  DOM, KOR, KV ) 
        Select ls.R_SPRID, trim(to_char(ga.STR_KOD,'000')) F2_KODSTR, ga.ADR_FND, ga.PINDEX, substr(ga.PUN_GNK,1,2) F2_KODREG,
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.ULI_GNK,1, 5)||'00000000' and ga.ULI_GNK not like '__000%'   )     F2_RAYON, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.ULI_GNK,1, 8)||'00000'    and ga.ULI_GNK not like '_____000%')     F2_GOROD, 
               (Select NAZV||' '||SOCR from GNI_KLADR where KLCODE=substr(ga.ULI_GNK,1,11)||'00'       and ga.ULI_GNK not like '________000%')  F2_PUNKT,
--               (Select NAZV||' '||SOCR from GNI_STREET where KLCODE=ga.ULI_GNK and ga.ULI_GNK not like '%0000__') F2_ULITSA, 
               (select txt from ( Select NAZV||' '||SOCR as txt, row_number() OVER (PARTITION BY substr(ga.ULI_GNK,1,16) ORDER BY ga.ULI_GNK DESC) as rm
                 from GNI_STREET where KLCODE like substr(ga.ULI_GNK,1,16)||'%'   and ga.ULI_GNK not like '%0000__') where rm = 1  and ga.ULI_GNK not like '%0000__') F2_ULITSA, 
               ga.TXT_DOM, ga.TXT_KOR, ga.TXT_KV
        from fnd.GNI_ADR_SOOTV ga 
             inner join fnd.f2NDFL_LOAD_SPRAVKI ls on ls.SSYLKA=ga.SSYLKA and ls.TIP_DOX=ga.TIP_DOX and ls.NOM_SPR=ga.SPRNOM
        where ga.STR_KOD=643 and ga.FL_ULIS=pGOD
          and ls.KOD_NA=1 and ls.GOD=pGOD and regexp_like( ga.ULI_GNK, '\d{17}' );            
          
    Commit;      
    
Exception
    when OTHERS then
        Rollback;
        Raise;        
    
end Kopir_Adresa_vRF_izSOOTV;  


procedure Parse_xml_izBuh(
  x_err_info out varchar2,
  p_spr_id   in  number,
  p_xml_info in  varchar2,
  p_kod_podr in  number default 1
) is
  --
  l_err_info varchar2(32767);
  --
  e_no_corr_spr exception;
  --
  l_spr_row f6ndfl_load_spravki%rowtype;
  --
  type sved_tbl_type is table of F6NDFL_LOAD_SVED%rowtype;
  type po_stavke_tbl_type is table of F6NDFL_LOAD_SUMPOSTAVKE%rowtype;
  --
  cursor l_docs_cur(p_xml xmltype) is
    select t.doc_num ,
           to_date(t.doc_date, 'dd.mm.yyyy') doc_date,
           t.period  ,
           t.god     ,
           t.code_gni,
           t.nom_korr,
           t.po_mestu,
           t.doc_body
    from   xmltable('/����/��������' passing(p_xml)
             columns
               doc_num  varchar2(20) path '@���',
               doc_date varchar2(20) path '@�������',
               period   number       path '@������',
               god      number       path '@��������',
               code_gni varchar2(20) path '@�����',
               nom_korr number       path '@�������',
               po_mestu number       path '@�������',
               doc_body xmltype      path '/'
           ) t;
  --
  --
  --
  procedure plog(p_msg varchar2, p_eof boolean default true) is
  begin
    return;
    if p_eof then
      dbms_output.put_line(p_msg);
    else
      dbms_output.put(p_msg);
    end if;
  end plog;
  --
  --
  --
  procedure fix_exception(
    p_err_msg varchar2 default null
  ) is
  begin
    if l_err_info is null then
      l_err_info := p_err_msg || chr(10) || 
            dbms_utility.format_error_stack || chr(10) || 
            dbms_utility.format_error_backtrace || chr(10) || 
            dbms_utility.format_call_stack;
    end if;
  end fix_exception;
  --
  --
  --
  procedure init_spravka(
    p_spr_id  in  number,
    p_spr_row in out nocopy f6ndfl_load_spravki%rowtype
  ) is
  begin
    select *
    into   p_spr_row
    from   f6ndfl_load_spravki s
    where  1=1
    and    s.r_sprid = p_spr_id;
    --
    plog('Init spravka ID = ' || p_spr_row.r_sprid);
    --
  exception
    when no_data_found then
      fix_exception('������: �� ������� �������. SPR_ID = ' || p_spr_id);
      raise;
    when others then
      fix_exception('Crash init_spravka, spr_id = ' || p_spr_id);
      raise;
  end init_spravka;
  
  --
  --
  --
  procedure purge_tables(
    p_spr_row in out nocopy f6ndfl_load_spravki%rowtype
  ) is
    procedure show_results(p_table_name varchar2) is
    begin
      plog(p_table_name || ': delete ' || sql%rowcount || ' row(s).');
    end show_results;
  begin
    --
    delete from F6NDFL_LOAD_SVED s
    where  1=1
    and    s.kod_na   = p_spr_row.kod_na  
    and    s.kod_podr = p_kod_podr
    and    s.god      = p_spr_row.god     
    and    s.period   = p_spr_row.period  
    and    s.nom_korr = p_spr_row.nom_korr;
    show_results('F6NDFL_LOAD_SVED');
    --
    delete from F6NDFL_LOAD_SUMPOSTAVKE s
    where  1=1
    and    s.kod_na   = p_spr_row.kod_na  
    and    s.kod_podr = p_kod_podr
    and    s.god      = p_spr_row.god     
    and    s.period   = p_spr_row.period  
    and    s.nom_korr = p_spr_row.nom_korr;
    show_results('F6NDFL_LOAD_SUMPOSTAVKE');
    --
    delete from f6ndfl_load_sumgod s
    where  1=1
    and    s.kod_na   = p_spr_row.kod_na  
    and    s.kod_podr = p_kod_podr
    and    s.god      = p_spr_row.god     
    and    s.period   = p_spr_row.period  
    and    s.nom_korr = p_spr_row.nom_korr;
    show_results('f6ndfl_load_sumgod');
    --
  exception
    when others then
      fix_exception('Crash purge_tables.');
      raise;
  end purge_tables;
  
  --
  --
  --
  procedure insert_sumgod(p_sumgod_row in out nocopy f6ndfl_load_sumgod%rowtype) is
  begin
    plog('Run proc insert_sumgod');
    insert into f6ndfl_load_sumgod(
      kod_na                     ,
      kod_podr                   ,
      god                        ,
      period                     ,
      nom_korr                   ,
      kol_fl_dohod               ,
      uderzh_nal                 ,
      ne_uderzh_nal              ,
      vozvrat_nal                ,
      kol_fl_sovpad
    ) values (
      p_sumgod_row.kod_na        ,
      p_sumgod_row.kod_podr      ,
      p_sumgod_row.god           ,
      p_sumgod_row.period        ,
      p_sumgod_row.nom_korr      ,
      p_sumgod_row.kol_fl_dohod  ,
      p_sumgod_row.uderzh_nal    ,
      p_sumgod_row.ne_uderzh_nal ,
      p_sumgod_row.vozvrat_nal   ,
      p_sumgod_row.kol_fl_sovpad
     );
    --
  exception
    when others then
      fix_exception('Crash insert_sumgod.');
      raise;
  end insert_sumgod;
  
  --
  --
  --
  procedure insert_po_stavke(p_po_stavke_tbl in out nocopy po_stavke_tbl_type) is
  begin
    forall i in 1..p_po_stavke_tbl.count
      insert into F6NDFL_LOAD_SUMPOSTAVKE(
        KOD_NA,
        KOD_PODR,
        GOD,
        PERIOD,
        NOM_KORR,
        KOD_STAVKI,
        NACHISL_DOH,
        NACH_DOH_DIV,
        VYCHET_PREDOST,
        VYCHET_ISPOLZ,
        ISCHISL_NAL,
        ISCHISL_NAL_DIV,
        AVANS_PLAT
      ) values (
        p_po_stavke_tbl(i).KOD_NA,
        p_po_stavke_tbl(i).KOD_PODR,
        p_po_stavke_tbl(i).GOD,
        p_po_stavke_tbl(i).PERIOD,
        p_po_stavke_tbl(i).NOM_KORR,
        p_po_stavke_tbl(i).KOD_STAVKI,
        p_po_stavke_tbl(i).NACHISL_DOH,
        p_po_stavke_tbl(i).NACH_DOH_DIV,
        p_po_stavke_tbl(i).VYCHET_PREDOST,
        p_po_stavke_tbl(i).VYCHET_ISPOLZ,
        p_po_stavke_tbl(i).ISCHISL_NAL,
        p_po_stavke_tbl(i).ISCHISL_NAL_DIV,
        p_po_stavke_tbl(i).AVANS_PLAT
      );
    plog('Run proc insert_po_stavke. Inserted ' || sql%rowcount || ' rows.');
    --
  exception
    when others then
      fix_exception('Crash insert_po_stavke.');
      raise;
  end insert_po_stavke;
  
  --
  --
  --
  procedure insert_sved(p_sved_tbl in out nocopy sved_tbl_type) is
  begin
    forall i in 1..p_sved_tbl.count
      insert into F6NDFL_LOAD_SVED(
        KOD_NA,
        KOD_PODR,
        GOD,
        PERIOD,
        NOM_KORR,
        DATA_FACT_DOH,
        DATA_UDERZH_NAL,
        SROK_PERECH_NAL,
        SUM_FACT_DOH,
        SUM_UDERZH_NAL
      ) values (
        p_sved_tbl(i).KOD_NA,
        p_sved_tbl(i).KOD_PODR,
        p_sved_tbl(i).GOD,
        p_sved_tbl(i).PERIOD,
        p_sved_tbl(i).NOM_KORR,
        p_sved_tbl(i).DATA_FACT_DOH,
        p_sved_tbl(i).DATA_UDERZH_NAL,
        p_sved_tbl(i).SROK_PERECH_NAL,
        p_sved_tbl(i).SUM_FACT_DOH,
        p_sved_tbl(i).SUM_UDERZH_NAL
      );
    --
    plog('Run proc insert_sved. Inserted ' || sql%rowcount || ' rows.');
    --
  exception
    when others then
      fix_exception('Crash insert_sved.');
      raise;
  end insert_sved;
  
  --
  --
  --
  procedure parse_po_stavke(
    p_spr_row in out nocopy f6ndfl_load_spravki%rowtype,
    p_xml     in out nocopy xmltype
  ) is
    --
    l_po_stavke_row fnd.F6NDFL_LOAD_SUMPOSTAVKE%rowtype;
    l_po_stavke_tbl po_stavke_tbl_type;
    --
    cursor l_ps_cur is
      select t.kod_stavki          ,
             nvl(t.nachisl_doh,     0) nachisl_doh,
             nvl(t.nach_doh_div,    0) nach_doh_div,
             nvl(t.vychet_ispolz,   0) vychet_ispolz,
             nvl(t.ischisl_nal,     0) ischisl_nal,
             nvl(t.ischisl_nal_div, 0) ischisl_nal_div,
             nvl(t.avans_plat,      0) avans_plat
      from   xmltable('/����������/���������' passing(p_xml)
             columns
               kod_stavki      number path '@������',
               nachisl_doh     number path '@���������',
               nach_doh_div    number path '@������������',
               vychet_ispolz   number path '@��������',
               ischisl_nal     number path '@���������',
               ischisl_nal_div number path '@������������',
               avans_plat      number path '@���������'
             ) t;
    --
  begin
    --
    l_po_stavke_tbl := po_stavke_tbl_type();
    --
    l_po_stavke_row.nom_korr := p_spr_row.nom_korr;
    l_po_stavke_row.period   := p_spr_row.period  ;
    l_po_stavke_row.god      := p_spr_row.god     ;
    l_po_stavke_row.kod_na   := p_spr_row.kod_na  ;
    l_po_stavke_row.kod_podr := p_kod_podr;
    --
    for ps in l_ps_cur loop
      --
      l_po_stavke_row.kod_stavki       := ps.kod_stavki      ;
      l_po_stavke_row.nachisl_doh      := ps.nachisl_doh     ;
      l_po_stavke_row.nach_doh_div     := ps.nach_doh_div    ;
      l_po_stavke_row.vychet_predost   := 0;
      l_po_stavke_row.vychet_ispolz    := ps.vychet_ispolz   ;
      l_po_stavke_row.ischisl_nal      := ps.ischisl_nal     ;
      l_po_stavke_row.ischisl_nal_div  := ps.ischisl_nal_div ;
      l_po_stavke_row.avans_plat       := ps.avans_plat      ;
      --
      l_po_stavke_tbl.extend;
      l_po_stavke_tbl(l_po_stavke_tbl.last) := l_po_stavke_row;
    end loop;
    --
    insert_po_stavke(l_po_stavke_tbl);
    --
  exception
    when others then
      fix_exception('Crash parse_po_stavke.');
      raise;
  end parse_po_stavke;
  
  --
  --
  --
  procedure parse_sved(
    p_spr_row in out nocopy f6ndfl_load_spravki%rowtype,
    p_xml     in out nocopy xmltype
  ) is
    --
    l_sved_row F6NDFL_LOAD_SVED%rowtype;
    l_sved_tbl sved_tbl_type;
    --
    cursor l_sved_cur is
      select to_date(t.data_fact_doh  , 'dd.mm.yyyy') data_fact_doh  ,
             to_date(t.data_uderzh_nal, 'dd.mm.yyyy') data_uderzh_nal,
             to_date(t.srok_perech_nal, 'dd.mm.yyyy') srok_perech_nal,
             t.sum_fact_doh     ,
             t.sum_uderzh_nal
      from   xmltable('/������/�������' passing(p_xml)
               columns
                 data_fact_doh   varchar2(10) path '@�����������',
                 data_uderzh_nal varchar2(10) path '@������������',
                 srok_perech_nal varchar2(10) path '@������������',
                 sum_fact_doh    number path '@���������',
                 sum_uderzh_nal  number path '@��������'
             ) t;
    --
  begin
    --
    l_sved_tbl := sved_tbl_type();
    --
    l_sved_row.nom_korr := p_spr_row.nom_korr;
    l_sved_row.period   := p_spr_row.period  ;
    l_sved_row.god      := p_spr_row.god     ;
    l_sved_row.kod_na   := p_spr_row.kod_na  ;
    l_sved_row.kod_podr := p_kod_podr        ;
    --
    for sv in l_sved_cur loop
      --
      l_sved_row.data_fact_doh   := sv.data_fact_doh   ;
      l_sved_row.data_uderzh_nal := sv.data_uderzh_nal ;
      l_sved_row.srok_perech_nal := sv.srok_perech_nal ;
      l_sved_row.sum_fact_doh    := sv.sum_fact_doh    ;
      l_sved_row.sum_uderzh_nal  := sv.sum_uderzh_nal  ;
      --
      l_sved_tbl.extend;
      l_sved_tbl(l_sved_tbl.last) := l_sved_row;
      --
    end loop;
    --
    insert_sved(l_sved_tbl);
    --
  exception
    when others then
      fix_exception('Crash parse_sved.');
      raise;
  end parse_sved;
  
  --
  --
  --
  procedure parse_doc_body(
    p_spr_row in out nocopy f6ndfl_load_spravki%rowtype,
    p_xml     in out nocopy xmltype
  ) is
    --
    l_sumgod_row F6NDFL_LOAD_SUMGOD%rowtype;
    --
    cursor l_body_cur is
      select t.kol_fl_dohod ,
             t.uderzh_nal   ,
             t.ne_uderzh_nal,
             t.vozvrat_nal  ,
             t.po_stavke_xml,
             t.sved_xml
      from   xmltable('/��������/����6' passing(p_xml)
               columns
                 kol_fl_dohod  number path '����������/@����������',
                 uderzh_nal    number path '����������/@����������',
                 ne_uderzh_nal number path '����������/@������������',
                 vozvrat_nal   number path '����������/@����������',
                 po_stavke_xml xmltype path '����������',
                 sved_xml      xmltype path '������'
             ) t;
  begin
    l_sumgod_row.nom_korr := p_spr_row.nom_korr;
    l_sumgod_row.period   := p_spr_row.period  ;
    l_sumgod_row.god      := p_spr_row.god     ;
    l_sumgod_row.kod_na   := p_spr_row.kod_na  ;
    l_sumgod_row.kod_podr := p_kod_podr;
    --
    for b in l_body_cur loop
      --
      l_sumgod_row.kol_fl_dohod  := b.kol_fl_dohod ;
      l_sumgod_row.uderzh_nal    := b.uderzh_nal   ;
      l_sumgod_row.ne_uderzh_nal := b.ne_uderzh_nal;
      l_sumgod_row.vozvrat_nal   := b.vozvrat_nal  ;
      --
      insert_sumgod(l_sumgod_row);
      --
      parse_po_stavke(p_spr_row, b.po_stavke_xml);
      --
      parse_sved(p_spr_row, b.sved_xml);
      --
      exit; --������������ ������ ������ ��������!
      --
    end loop;
    --
  exception
    when others then
      fix_exception('Crash parse_doc_body.');
      raise;
  end parse_doc_body;
  --
begin
  --
  init_spravka(
    p_spr_id  => p_spr_id,
    p_spr_row => l_spr_row
  );
  --
  purge_tables(l_spr_row);
  --
  for s in l_docs_cur(xmltype(p_xml_info)) loop
    --
    if s.god <> l_spr_row.god or s.period <> l_spr_row.period then
      fix_exception(
        '������ XML (' || s.god || ', ' || s.period || ') �� ������������� ������ ������� ID ' || p_spr_id || ' (' || l_spr_row.god || ', ' || l_spr_row.period || ')'
      );
      --
      raise no_data_found;
    end if;
    --
    parse_doc_body(l_spr_row, s.doc_body);
    --
    exit;
    --
  end loop;
  --
exception
  when others then
    fix_exception('Crash f6ndfl_xml_parse');
    x_err_info := l_err_info;
end Parse_xml_izBuh;

-- �������� �������������� ������� �� ������ ������������ �� ���� � ������ ��    
  procedure Kopir_SprF2_dlya_KORR( pNOMSPRAV in varchar2, pGod in number) is 
    iCount number(3) := 0;
    sr f2NDFL_ARH_SPRAVKI%rowtype;
    s_id_new f2NDFL_ARH_SPRAVKI.Id%type;
  begin
  
    for sr in (
                select s.* from fnd.f2ndfl_arh_spravki s 
--                inner join fnd.SP_FIZ_LITS f on f.SSYLKA= pSSYLKA  
--                inner join fnd.f2ndfl_arh_nomspr n 
--                    on 
--                      n.kod_NA   = s.kod_NA and
--                      n.nom_spr  = s.nom_spr and 
--                      n.god      = s.god and 
--                      n.god      = pGod and 
--                      n.fk_CONTRAGENT = f.GF_PERSON   
                where 
                      s.NOM_SPR  = pNOMSPRAV
                  and s.GOD      = pGod   
                  and s.nom_korr = (select max(s1.nom_korr) from fnd.f2ndfl_arh_spravki s1 
                                        where s1.god = pGod and s1.nom_spr = s.nom_spr )
      ) loop
      
      -- �������� ������ � ������� ��� � ��������� ������������� 
      -- ���, �����, ����� � ���������� ����� ��� ��� ����?
      --select s.* into sr from fnd.f2ndfl_arh_spravki s where s.id = sr.id;
      
      -- �������� ����� ������������� � fnd.f2ndfl_arh_spravki 
      insert into fnd.f2ndfl_arh_spravki(
        r_xmlid,
        kod_na,
        data_dok,
        nom_spr,
        god,
        nom_korr,
        kvartal,
        priznak_s,
        inn_fl,
        inn_ino,
        status_np,
        grazhd,
        familiya,
        imya,
        otchestvo,
        data_rozhd,
        kod_ud_lichn,
        ser_nom_doc
      ) values (
        null /*sr.R_XMLID ����� ����� �����*/,
        sr.kod_na,
        trunc(sysdate) /* sr.DATA_DOK */,
        sr.nom_spr,
        sr.god,
        sr.nom_korr + 1,
        sr.kvartal,
        sr.priznak_s,
        sr.inn_fl,
        sr.inn_ino,
        sr.status_np,
        sr.grazhd,
        sr.familiya,
        sr.imya,
        sr.otchestvo,
        sr.data_rozhd,
        sr.kod_ud_lichn,
        sr.ser_nom_doc
      ) returning id into s_id_new;

      -- �������� ������ �� ���������� ������ ������� ��� ������������� � �������� �������
        insert into fnd.f2ndfl_arh_itogi(
                r_sprid,kod_stavki,sgd_sum,sum_obl,sum_obl_ni,
                sum_fiz_avans,sum_obl_nu,sum_nal_per,dolg_na,vzysk_ifns)
        select  s_id_new, i.kod_stavki, i.sgd_sum, i.sum_obl, i.sum_obl_ni, 
                i.sum_fiz_avans, i.sum_obl_nu, i.sum_nal_per, i.dolg_na, i.vzysk_ifns 
            from fnd.f2ndfl_arh_itogi i 
            where i.r_sprid = sr.id;
      
      -- �������� ������ �� sr.DATA_DOK ������� ��� ������������� � ������ �� ������� 
        insert into fnd.f2ndfl_arh_mes(
                r_sprid,kod_stavki,mes,doh_kod_gni,doh_sum,vych_kod_gni,vych_sum)
        select  s_id_new, m.kod_stavki, m.mes, m.doh_kod_gni, m.doh_sum, m.vych_kod_gni, m.vych_sum 
            from fnd.f2ndfl_arh_mes m 
            where m.r_sprid = sr.id;
      
      -- �������� ������ �� sr.DATA_DOK ������� ��� ������������� � ����������� 
        insert into fnd.f2ndfl_arh_uved(
                r_sprid,kod_stavki,schet_kratn,nomer_uved,data_uved,ifns_kod,uved_tip_vych)
        select  s_id_new, u.kod_stavki, u.schet_kratn, u.nomer_uved, u.data_uved, u.ifns_kod, u.uved_tip_vych 
            from fnd.f2ndfl_arh_uved u 
            where u.r_sprid = sr.id;

      -- �������� ������ �� sr.DATA_DOK ������� ��� ������������� � ������ f2ndfl_arh_vych 
        insert into fnd.f2ndfl_arh_vych(
                r_sprid,kod_stavki,vych_kod_gni,vych_sum_predost,vych_sum_ispolz)
        select  s_id_new, v.kod_stavki, v.vych_kod_gni, v.vych_sum_predost, v.vych_sum_ispolz 
            from fnd.f2ndfl_arh_vych v 
            where v.r_sprid = sr.id;      

      -- �������� ������ �� ������� ������� ��� ������������� � �������� �������
        insert into fnd.f2ndfl_arh_adr(
                r_sprid,kod_str,adr_ino,pindex,kod_reg,rayon,gorod,punkt,ulitsa,dom,kor,kv)
        select  s_id_new, a.kod_str, a.adr_ino, a.pindex, a.kod_reg, a.rayon, a.gorod, a.punkt, a.ulitsa, a.dom, a.kor, a.kv 
            from fnd.f2ndfl_arh_adr a 
            where a.r_sprid = sr.id;
      
    end loop;
    
  end Kopir_SprF2_dlya_KORR;

END FXNDFL_UTIL;
/