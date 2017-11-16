CREATE TABLE DV_SR_LSPV_TAX_DIFF_BUF(
  GF_PERSON             NUMBER, 
  LASTNAME              VARCHAR2(100) NOT NULL ENABLE, 
  FIRSTNAME             VARCHAR2(100), 
  SECONDNAME            VARCHAR2(100), 
  SSYLKA_FL             NUMBER(10,0), 
  NOM_VKL               NUMBER(10,0)  NOT NULL ENABLE, 
  NOM_IPS               NUMBER(10,0)  NOT NULL ENABLE, 
  PEN_SCHEME            VARCHAR2(3), 
  REVENUE_SHIFR_SCHET   NUMBER, 
  TAX_SHIFR_SCHET       VARCHAR2(81), 
  REVENUE               NUMBER, 
  BENEFIT               NUMBER, 
  TAX                   NUMBER, 
  TAX_RETAINED          NUMBER, 
  TAX_CALC              NUMBER, 
  TAX_DIFF              NUMBER, 
  MARK                  VARCHAR2(5)
)
/
