CREATE OR REPLACE PROCEDURE PAC_CFDI_NOMINA_PRC(
            P_ERRBUF    OUT NOCOPY  VARCHAR2,
            P_RETCODE   OUT NOCOPY  VARCHAR2,
            P_COMPANY_ID            VARCHAR2,
            P_PERIOD_TYPE           VARCHAR2,
            P_PAYROLL_ID            NUMBER,
            P_CONSOLIDATION_ID      NUMBER,
            P_YEAR                  NUMBER,
            P_MONTH                 NUMBER,
            P_PERIOD_NAME           VARCHAR,
            P_RUN_TYPE_ID           NUMBER)
IS
    var_path            VARCHAR2(250) := 'CFDI_NOMINA';
    var_file_name       VARCHAR2(250);
    var_payroll_name    VARCHAR2(200);
    var_file            UTL_FILE.FILE_TYPE;
    var_consolidation_name  VARCHAR2(250);
    var_run_type_name       VARCHAR2(250);
    var_sequence_name   VARCHAR2(250);
    
    var_date_exp        VARCHAR2(50);
    var_reg_seq         NUMBER(10);
    var_user_id         NUMBER := FND_GLOBAL.USER_ID;
    var_validate        NUMBER;
    
    MIN_WAGE            NUMBER;
    
    V_REQUEST_ID         NUMBER;
    WAITING              BOOLEAN;
    PHASE                VARCHAR2 (80 BYTE);
    STATUS               VARCHAR2 (80 BYTE);
    DEV_PHASE            VARCHAR2 (80 BYTE);
    DEV_STATUS           VARCHAR2 (80 BYTE);
    V_MESSAGE            VARCHAR2 (4000 BYTE);
            
    CURSOR  DETAIL_LIST IS
         SELECT DISTINCT 
                PPF.PAYROLL_NAME,
                (CASE
                    WHEN FLV1.LOOKUP_CODE = '02' THEN 'CS'
                    WHEN FLV1.LOOKUP_CODE = '08' THEN 'POGA'
                    WHEN FLV1.LOOKUP_CODE = '11' THEN 'PAC'
                 END)                                                                           AS  SERFOL,
                UPPER(OI.ORG_INFORMATION2)                                                      AS  RFCEMI,
                UPPER(FLV1.MEANING)                                                             AS  NOMEMI,
                UPPER(LA.ADDRESS_LINE_1)                                                        AS  CALEMI,
                UPPER(LA.ADDRESS_LINE_2)                                                        AS  COLEMI,
                UPPER(LA.TOWN_OR_CITY)                                                          AS  MUNEMI,
                UPPER(FLV2.MEANING)                                                             AS  ESTEMI,
                LA.POSTAL_CODE                                                                  AS  CODEMI,
                UPPER(FT1.NLS_TERRITORY)                                                        AS  PAIEMI,
                REPLACE(PAPF.PER_INFORMATION2, '-', '')                                         AS  RFCREC,
                UPPER(PAPF.LAST_NAME        || ' ' || 
                      PAPF.PER_INFORMATION1 || ' ' || 
                      PAPF.FIRST_NAME       || ' ' || 
                      PAPF.MIDDLE_NAMES)                                                        AS  NOMREC,
                (SELECT UPPER(NVL(FT2.NLS_TERRITORY, 'MEXICO'))
                   FROM PER_ADDRESSES    PA,
                        FND_TERRITORIES  FT2
                  WHERE PA.PERSON_ID = PAPF.PERSON_ID
                    AND FT2.TERRITORY_CODE = PA.COUNTRY)                                        AS  PAIREC,
                NVL(PAPF.EMAIL_ADDRESS, 'NULL')                                                 AS  MAIL,
                SUM(NVL(APPS.PAC_CFDI_FUNCTIONS_PKG.GET_SUBTBR(PAA.ASSIGNMENT_ACTION_ID), '0')) AS  SUBTBR,     
                SUM(NVL(APPS.PAC_CFDI_FUNCTIONS_PKG.GET_ISRRET(PAA.ASSIGNMENT_ACTION_ID), '0')) AS  ISRRET,
                SUM(NVL(APPS.PAC_CFDI_FUNCTIONS_PKG.GET_MONDET(PAA.ASSIGNMENT_ACTION_ID), '0')) AS  MONDET,  
                PAPF.EMPLOYEE_NUMBER                                                            AS  NOM_NUMEMP,
                PAPF.NATIONAL_IDENTIFIER                                                        AS  NOM_CURP,
                (CASE
                    WHEN PCS.CONSOLIDATION_SET_NAME LIKE '%NORMAL%' THEN
                        CASE 
                            WHEN P_PERIOD_TYPE = 'Week' OR P_PERIOD_TYPE = 'Semana' THEN
                                 PTP.END_DATE + 4
                            ELSE
                                 PTP.END_DATE
                        END
                    ELSE
                        PTP.END_DATE
                 END)                                                                           AS  NOM_FECPAG,       
                (CASE
                    WHEN PCS.CONSOLIDATION_SET_NAME LIKE '%NORMAL%' THEN
                        PTP.START_DATE 
                    ELSE 
                        PTP.END_DATE
                 END)                                                                           AS  NOM_FECINI,
                PTP.END_DATE                                                                    AS  NOM_FECFIN,
                TO_CHAR(REPLACE(REPLACE(PAPF.PER_INFORMATION3, ' ', ''),'-',''), '00000000000') AS  NOM_NUMSEG,   
                MAX(NVL(APPS.PAC_CFDI_FUNCTIONS_PKG.GET_DIAPAG(PAA.ASSIGNMENT_ACTION_ID), '0')) AS  NOM_DIAPAG,
                HOUV.NAME                                                                       AS  NOM_DEPTO,
                HAPD.NAME                                                                       AS  NOM_PUESTO, 
                (CASE
                    WHEN PPF.PAYROLL_NAME LIKE '%SEM%' THEN
                         'SEMANAL'
                    WHEN PPF.PAYROLL_NAME LIKE '%QUIN%' THEN
                         'QUINCENAL'
                    ELSE
                         ''
                 END)                                                                           AS  NOM_FORPAG,
                PTP.PERIOD_NUM                                                                  AS  NOM_NUMERONOM,
                APPS.PAC_HR_PAY_PKG.GET_EMPLOYER_REGISTRATION(PAAF.ASSIGNMENT_ID)               AS  NOM_REGPAT,
                MAX(NVL(APPS.PAC_RESULT_VALUES_PKG.GET_OTHER_VALUE(PAA.ASSIGNMENT_ACTION_ID,
                                                          'Integrated Daily Wage',
                                                          'Pay Value'), '0'))                   AS  NOM_SDI,
                MAX(NVL(APPS.PAC_RESULT_VALUES_PKG.GET_EARNING_VALUE(PAA.ASSIGNMENT_ACTION_ID,
                                                            'P001_SUELDO NORMAL',
                                                            'Sueldo Diario'), '0'))             AS  NOM_SALBASE, 
                PPF.ATTRIBUTE1                                                                  AS  NOM_CVENOM,  
                MAX(NVL(APPS.PAC_CFDI_FUNCTIONS_PKG.GET_FAHOACUM(PAA.ASSIGNMENT_ACTION_ID,
                                                        PPA.DATE_EARNED,
                                                        PAA.TAX_UNIT_ID), '0'))                  AS  NOM_FAHOACUM,
                SUM(NVL(APPS.PAC_CFDI_FUNCTIONS_PKG.GET_PER_TOTGRA(PAA.ASSIGNMENT_ACTION_ID), '0'))  AS  NOM_PER_TOTGRA,
                SUM(NVL(APPS.PAC_CFDI_FUNCTIONS_PKG.GET_PER_TOTEXE(PAA.ASSIGNMENT_ACTION_ID), '0'))  AS  NOM_PER_TOTEXE,  
                APPS.PAC_CFDI_FUNCTIONS_PKG.GET_NOM_DESCRI(PPA.PAYROLL_ACTION_ID)               AS  NOM_DESCRI,  
                 NVL((SELECT DISTINCT 
                             (CASE WHEN PAPF.EMPLOYEE_NUMBER = 13 OR PAPF.EMPLOYEE_NUMBER = 24 THEN
                                    'TRANSFERENCIA ELECTRONICA'
                                   WHEN POPM.ORG_PAYMENT_METHOD_NAME LIKE '%EFECTIVO%' THEN
                                    'EFECTIVO'
                                   WHEN (POPM.ORG_PAYMENT_METHOD_NAME LIKE '%BANCOMER%'
                                      OR POPM.ORG_PAYMENT_METHOD_NAME LIKE '%BANORTE%'
                                      OR POPM.ORG_PAYMENT_METHOD_NAME LIKE '%HSBC%'
                                      OR POPM.ORG_PAYMENT_METHOD_NAME LIKE '%INVERLAT%') THEN
                                    'TRANSFERENCIA ELECTRONICA'
                                   
                              END)
                        FROM PER_ALL_ASSIGNMENTS_F          PAA,
                             PAY_PERSONAL_PAYMENT_METHODS_F PPPM,
                             PAY_ORG_PAYMENT_METHODS_F      POPM,
                             PAY_PAYMENT_TYPES_V            PPTV
                        WHERE PPPM.ASSIGNMENT_ID = PAAF.ASSIGNMENT_ID
                          AND PPPM.ORG_PAYMENT_METHOD_ID = POPM.ORG_PAYMENT_METHOD_ID
                          AND PPTV.PAYMENT_TYPE_ID = POPM.PAYMENT_TYPE_ID
                          AND PPTV.TERRITORY_CODE = 'MX'
                          AND (POPM.ORG_PAYMENT_METHOD_NAME NOT LIKE '%DESPENSA%'
                          AND POPM.ORG_PAYMENT_METHOD_NAME NOT LIKE '%EFECTIVALE%'
                          AND POPM.ORG_PAYMENT_METHOD_NAME NOT LIKE '%PENSIONES%')
                          AND ROWNUM = 1
                            ), 'EFECTIVO')                                                      AS  METPAG,
                PPF.PAYROLL_ID,
                PAAF.ASSIGNMENT_ID,
                PPA.PAYROLL_ACTION_ID,
--                PAA.ASSIGNMENT_ACTION_ID,
--                PAA.TAX_UNIT_ID,
                PPA.DATE_EARNED,
--                PPA.ELEMENT_SET_ID,
                PPA.CONSOLIDATION_SET_ID,
                PPA.EFFECTIVE_DATE,
                PTP.END_DATE
              FROM 
                   FND_LOOKUP_VALUES            FLV1,
                   HR_ALL_ORGANIZATION_UNITS    AOU,
                   HR_LOCATIONS_ALL             LA,
                   HR_ORGANIZATION_INFORMATION  OI,
                   FND_TERRITORIES              FT1,
                   FND_LOOKUP_VALUES            FLV2,
                   PAY_PAYROLLS_F               PPF,
                   PAY_PAYROLL_ACTIONS          PPA,
                   PER_TIME_PERIODS             PTP,
                   PER_ALL_ASSIGNMENTS_F        PAAF,
                   PAY_ASSIGNMENT_ACTIONS       PAA,
                   PER_ALL_PEOPLE_F             PAPF,
                   PAY_RUN_TYPES_X              PRTX,
                   HR_ORGANIZATION_UNITS_V      HOUV,
                   HR_ALL_POSITIONS_D           HAPD,
                   PAY_CONSOLIDATION_SETS       PCS
             WHERE 1 = 1
               AND FLV1.LOOKUP_TYPE = 'NOMINAS POR EMPLEADOR LEGAL'
               AND FLV1.LOOKUP_CODE = P_COMPANY_ID
               AND FLV1.LANGUAGE = USERENV('LANG')
               AND AOU.NAME = FLV1.MEANING
               AND LA.LOCATION_ID = AOU.LOCATION_ID
               AND AOU.ORGANIZATION_ID = OI.ORGANIZATION_ID
               AND OI.ORG_INFORMATION_CONTEXT = 'MX_TAX_REGISTRATION'
               AND LA.COUNTRY = FT1.TERRITORY_CODE
               AND FLV2.LOOKUP_CODE = LA.REGION_1
               AND FLV2.LOOKUP_TYPE = 'MX_STATE'
               AND FLV2.LANGUAGE = USERENV('LANG')
               AND SUBSTR(PPF.PAYROLL_NAME,1,2) = FLV1.LOOKUP_CODE
               AND APPS.PAC_HR_PAY_PKG.GET_PERIOD_TYPE(PPF.PAYROLL_NAME) = NVL(P_PERIOD_TYPE, APPS.PAC_HR_PAY_PKG.GET_PERIOD_TYPE(PPF.PAYROLL_NAME))
               AND PPF.PAYROLL_ID = NVL(P_PAYROLL_ID, PPF.PAYROLL_ID) 
               AND PPF.PAYROLL_ID = PPA.PAYROLL_ID
               AND PPA.CONSOLIDATION_SET_ID  = NVL(P_CONSOLIDATION_ID, PPA.CONSOLIDATION_SET_ID)
               AND PTP.PAYROLL_ID = PPF.PAYROLL_ID
               AND (EXTRACT(YEAR FROM PTP.END_DATE) = P_YEAR 
                AND EXTRACT(MONTH FROM PTP.END_DATE) = P_MONTH)
               AND PTP.PERIOD_NAME = NVL(P_PERIOD_NAME, PTP.PERIOD_NAME)
--               AND PAA.RUN_TYPE_ID = NVL(P_RUN_TYPE_ID, PAA.RUN_TYPE_ID)
               AND PPA.EFFECTIVE_DATE BETWEEN PTP.START_DATE AND PTP.END_DATE
               AND PTP.TIME_PERIOD_ID = PPA.TIME_PERIOD_ID   
               AND PAAF.PAYROLL_ID = PPF.PAYROLL_ID
               AND PAPF.PERSON_ID = PAAF.PERSON_ID
               AND PPA.CONSOLIDATION_SET_ID = PCS.CONSOLIDATION_SET_ID
               AND PAA.PAYROLL_ACTION_ID = PPA.PAYROLL_ACTION_ID 
               AND PAA.ASSIGNMENT_ID = PAAF.ASSIGNMENT_ID
               AND PRTX.RUN_TYPE_ID = PAA.RUN_TYPE_ID
               AND PAAF.ORGANIZATION_ID = NVL(HOUV.ORGANIZATION_ID, PAAF.ORGANIZATION_ID) 
               AND PAAF.POSITION_ID = NVL(HAPD.POSITION_ID, PAAF.POSITION_ID)
               AND PPF.PAYROLL_NAME NOT IN ('02_SEM - GRBE', '02_QUIN - EVENTUAL')
               AND PPA.EFFECTIVE_DATE BETWEEN PAAF.EFFECTIVE_START_DATE AND PAAF.EFFECTIVE_END_DATE
               AND PPA.EFFECTIVE_DATE BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
               AND PPA.EFFECTIVE_DATE BETWEEN HAPD.EFFECTIVE_START_DATE AND HAPD.EFFECTIVE_END_DATE
               AND PPA.EFFECTIVE_DATE BETWEEN PRTX.EFFECTIVE_START_DATE AND PRTX.EFFECTIVE_END_DATE
               AND PPA.EFFECTIVE_DATE BETWEEN PPF.EFFECTIVE_START_DATE AND PPF.EFFECTIVE_END_DATE
             GROUP BY PPF.PAYROLL_NAME,
                      FLV1.LOOKUP_CODE,
                      OI.ORG_INFORMATION2,
                      FLV1.MEANING,
                      LA.ADDRESS_LINE_1,
                      LA.ADDRESS_LINE_2,
                      LA.TOWN_OR_CITY,
                      FLV2.MEANING,
                      LA.POSTAL_CODE,
                      FT1.NLS_TERRITORY,
                      PAPF.PER_INFORMATION2,
                      PAPF.LAST_NAME, 
                      PAPF.PER_INFORMATION1, 
                      PAPF.FIRST_NAME, 
                      PAPF.MIDDLE_NAMES,
                      PAPF.PERSON_ID,
                      PAPF.EMAIL_ADDRESS,
                      PAPF.EMPLOYEE_NUMBER,
                      PAPF.NATIONAL_IDENTIFIER,
                      PCS.CONSOLIDATION_SET_NAME,
                      PTP.END_DATE,
                      PTP.START_DATE,
                      PAPF.PER_INFORMATION3,
                      HOUV.NAME,
                      HAPD.NAME,
                      PTP.PERIOD_NUM,
                      PAAF.ASSIGNMENT_ID,
                      PPF.ATTRIBUTE1,
                      PPA.PAYROLL_ACTION_ID,
                      PPF.PAYROLL_ID,
                      PAAF.ASSIGNMENT_ID,
                      PPA.PAYROLL_ACTION_ID,
                      PPA.DATE_EARNED,
                      PPA.CONSOLIDATION_SET_ID,
                      PPA.EFFECTIVE_DATE,
                      PTP.END_DATE
             ORDER BY PPF.PAYROLL_NAME,
                      PAPF.EMPLOYEE_NUMBER;
                      



                                   
     TYPE   DETAILS IS TABLE OF DETAIL_LIST%ROWTYPE INDEX BY PLS_INTEGER;
     
     DETAIL DETAILS;
     
BEGIN
    
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN
    
        SELECT REPLACE(PCS.CONSOLIDATION_SET_NAME, ' ', '_')
          INTO var_consolidation_name
          FROM PAYBV_CONSOLIDATION_SET PCS
         WHERE PCS.CONSOLIDATION_SET_ID = P_CONSOLIDATION_ID;
         
    
        var_file_name := 'CFDI_NOMINA_';
        
        IF P_COMPANY_ID = '02' THEN 
            var_file_name := var_file_name || 'CS_';
        ELSIF P_COMPANY_ID = '08' THEN 
            var_file_name := var_file_name || 'POGA_';
        ELSIF P_COMPANY_ID = '11' THEN 
            var_file_name := var_file_name || 'PAC_';
        END IF;
        
        var_file_name := var_file_name || REPLACE(NVL(P_PERIOD_NAME,P_MONTH || '_' || P_YEAR), ' ', '_') || '_';
        var_file_name := var_file_name || REPLACE(var_consolidation_name, '�', 'O');
        var_sequence_name := SUBSTR(REPLACE(REPLACE(var_file_name, 'NOMINA', ''), '_', ''), 0, 30);       
        var_file_name := var_file_name || '.txt';
        
    EXCEPTION WHEN OTHERS THEN        
        dbms_output.put_line('**Error al preparar el archivo CFDI de N�mina. ' || SQLERRM);
        FND_FILE.PUT_LINE(FND_FILE.LOG, '**Error al preparar el archivo CFDI de N�mina. ' || SQLERRM); 
    END;
    
    SELECT COUNT(CFDI.FILE_NAME)
      INTO var_validate
      FROM PAC_CFDI_NOMINA_TB  CFDI
     WHERE 1 = 1
       AND CFDI.FILE_NAME = var_file_name;
    
    IF var_validate = 0 THEN
    
        INSERT
          INTO PAC_CFDI_NOMINA_TB (USER_ID,
                                   FILE_NAME,
                                   SEQUENCE_NAME,
                                   CREATION_DATE)
                           VALUES (var_user_id,
                                   var_file_name,
                                   var_sequence_name,
                                   SYSDATE);
    
        --Eliminaci�n y creaci�n del Archivo.
        BEGIN
        
            var_file := UTL_FILE.FOPEN(var_path, var_file_name, 'A', 30000);
            UTL_FILE.FREMOVE(var_path, var_file_name);
        
        EXCEPTION
            WHEN UTL_FILE.INVALID_OPERATION THEN
                var_file := UTL_FILE.FOPEN(var_path, var_file_name, 'A', 30000); 
            WHEN OTHERS THEN
                dbms_output.put_line('**Error al Limpiar el Archivo.. ' || SQLERRM);
                FND_FILE.PUT_LINE(FND_FILE.LOG, '**Error al Limpiar el Archivo.. ' || SQLERRM);
        END;
        
        var_file := UTL_FILE.FOPEN(var_path, var_file_name, 'A', 30000);
        
        --Creaci�n de la secuencia
        BEGIN

            EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || var_sequence_name || ' ' ||
                          'START WITH 1 ' ||
                          'INCREMENT BY 1 ' ||
                          'NOCACHE ' ||
                          'NOCYCLE';
                          
        EXCEPTION WHEN OTHERS THEN
            dbms_output.put_line('**Error al Crear la Secuencia ' || var_sequence_name || '. ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '**Error al Crear la Secuencia ' || var_sequence_name || '. ' || SQLERRM);
        END;
        
        
        --Impresi�n de Parametros.
        BEGIN
        
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parametros de Ejecucion. ');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_COMPANY_ID : '       || P_COMPANY_ID);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_PERIOD_TYPE : '      || P_PERIOD_TYPE);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_PAYROLL_ID : '       || P_PAYROLL_ID);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_CONSOLIDATION_ID : ' || P_CONSOLIDATION_ID);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_YEAR : '             || P_YEAR);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_MONTH : '            || P_MONTH);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_PERIOD_NAME : '      || P_PERIOD_NAME);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'P_SEQUENCE_NAME : '    || var_sequence_name);
            
            dbms_output.put_line('Parametros de Ejecucion. ');
            dbms_output.put_line('P_COMPANY_ID : '       || P_COMPANY_ID);
            dbms_output.put_line('P_PERIOD_TYPE : '      || P_PERIOD_TYPE);
            dbms_output.put_line('P_PAYROLL_ID : '       || P_PAYROLL_ID);
            dbms_output.put_line('P_CONSOLIDATION_ID : ' || P_CONSOLIDATION_ID);
            dbms_output.put_line('P_YEAR : '             || P_YEAR);
            dbms_output.put_line('P_MONTH : '            || P_MONTH);
            dbms_output.put_line('P_PERIOD_NAME : '      || P_PERIOD_NAME);
        
        END;
        
        --Inicio del Procesamiento del Cursor
        dbms_output.put_line('Creando el Archivo. . .');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Creando el Archivo. . .');
        
        --Recorrido del Cursor de Empleados.
        BEGIN
        
            var_date_exp := TO_CHAR(SYSDATE, 'RRRR-MM-DD') || 'T' || TO_CHAR(SYSDATE, 'HH24:MI:SS');
            
            OPEN DETAIL_LIST;
            
            LOOP
            
                FETCH DETAIL_LIST BULK COLLECT INTO DETAIL LIMIT 500;
                
                EXIT WHEN DETAIL.COUNT = 0;
                
                FOR rowIndex IN 1 .. DETAIL.COUNT
                LOOP
                
                    MIN_WAGE := 0;
                    MIN_WAGE := PAY_MX_UTILITY.GET_MIN_WAGE(P_CTX_DATE_EARNED => DETAIL(rowIndex).DATE_EARNED,
                                                            P_TAX_BASIS => 'NONE',
                                                            P_ECON_ZONE => 'A');
            
                    --Consulta de la Secuencia
                    BEGIN
                        EXECUTE 
                        IMMEDIATE   'SELECT ' || var_sequence_name || '.NEXTVAL FROM DUAL' INTO var_reg_seq;
                    EXCEPTION WHEN OTHERS THEN
                        dbms_output.put_line('**Error al Consultar la Secuencia ' || var_sequence_name || '. ' || SQLERRM);
                        FND_FILE.PUT_LINE(FND_FILE.LOG, '**Error al Consultar la Secuencia ' || var_sequence_name || '. ' || SQLERRM);
                    END;       
                    
                
                    UTL_FILE.PUT_LINE(var_file, 'NOMINA');
                    UTL_FILE.PUT_LINE(var_file, 'NOMDOC  RECIBO NOMINA');
                    UTL_FILE.PUT_LINE(var_file, 'TIPDOC  2');    
                    UTL_FILE.PUT_LINE(var_file, 'SERFOL  ' || DETAIL(rowIndex).SERFOL);
                    UTL_FILE.PUT_LINE(var_file, 'NUMFOL ' || TO_CHAR(var_reg_seq,'0000'));
                    UTL_FILE.PUT_LINE(var_file, 'FECEXP  ' || var_date_exp);
                    UTL_FILE.PUT_LINE(var_file, 'RFCEMI  ' || DETAIL(rowIndex).RFCEMI);
                    UTL_FILE.PUT_LINE(var_file, 'NOMEMI  ' || DETAIL(rowIndex).NOMEMI);
                    UTL_FILE.PUT_LINE(var_file, 'CALEMI  ' || DETAIL(rowIndex).CALEMI);
                    UTL_FILE.PUT_LINE(var_file, 'COLEMI  ' || DETAIL(rowIndex).COLEMI);
                    UTL_FILE.PUT_LINE(var_file, 'MUNEMI  ' || DETAIL(rowIndex).MUNEMI);
                    UTL_FILE.PUT_LINE(var_file, 'ESTEMI  ' || DETAIL(rowIndex).ESTEMI);
                    UTL_FILE.PUT_LINE(var_file, 'CODEMI  ' || DETAIL(rowIndex).CODEMI);
                    UTL_FILE.PUT_LINE(var_file, 'PAIEMI  ' || DETAIL(rowIndex).PAIEMI);
                    UTL_FILE.PUT_LINE(var_file, 'RFCREC  ' || DETAIL(rowIndex).RFCREC);
                    UTL_FILE.PUT_LINE(var_file, 'NOMREC  ' || DETAIL(rowIndex).NOMREC);
                    UTL_FILE.PUT_LINE(var_file, 'PAIREC  ' || NVL(DETAIL(rowIndex).PAIREC, 'MEXICO'));
                    IF DETAIL(rowIndex).MAIL <> 'NULL'  AND DETAIL(rowIndex).MAIL <> 'trabajadores@elcalvario.com.mx'THEN
                        UTL_FILE.PUT_LINE(var_file, 'MAIL    ' || DETAIL(rowIndex).MAIL);
                    END IF;
                    UTL_FILE.PUT_LINE(var_file, 'FORPAG  PAGO EN UNA SOLA EXCIBICION');
                    UTL_FILE.PUT_LINE(var_file, 'METPAG  ' || DETAIL(rowIndex).METPAG);
                    UTL_FILE.PUT_LINE(var_file, 'LUGEXP  TEHUACAN'); 
                    UTL_FILE.PUT_LINE(var_file, 'SUBTBR  ' || TO_CHAR(DETAIL(rowIndex).SUBTBR, '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'ISRRET  ' || TO_CHAR(DETAIL(rowIndex).ISRRET, '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'MONDET  ' || TO_CHAR(DETAIL(rowIndex).MONDET, '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'TOTPAG  ' || TO_CHAR((DETAIL(rowIndex).SUBTBR - (DETAIL(rowIndex).ISRRET + DETAIL(rowIndex).MONDET)), '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'NOM_NUMEMP  ' || DETAIL(rowIndex).NOM_NUMEMP);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_CURP    ' || DETAIL(rowIndex).NOM_CURP);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_TIPREG  2');
                    UTL_FILE.PUT_LINE(var_file, 'NOM_FECPAG  ' || TO_CHAR(DETAIL(rowIndex).NOM_FECPAG, 'YYYY-MM-DD'));
                    UTL_FILE.PUT_LINE(var_file, 'NOM_FECINI  ' || TO_CHAR(DETAIL(rowIndex).NOM_FECINI, 'YYYY-MM-DD'));
                    UTL_FILE.PUT_LINE(var_file, 'NOM_FECFIN  ' || TO_CHAR(DETAIL(rowIndex).NOM_FECFIN, 'YYYY-MM-DD'));
                    UTL_FILE.PUT_LINE(var_file, 'NOM_NUMSEG ' || DETAIL(rowIndex).NOM_NUMSEG);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_DIAPAG  ' || DETAIL(rowIndex).NOM_DIAPAG);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_DEPTO   ' || DETAIL(rowIndex).NOM_DEPTO);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_PUESTO  ' || DETAIL(rowIndex).NOM_PUESTO);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_FORPAG  ' || DETAIL(rowIndex).NOM_FORPAG);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_NUMERONOM  ' || DETAIL(rowIndex).NOM_NUMERONOM);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_REGPAT  ' || DETAIL(rowIndex).NOM_REGPAT);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_SALBASE ' || TO_CHAR(DETAIL(rowIndex).NOM_SALBASE, '9999990D99'));
                    
                    IF DETAIL(rowIndex).NOM_SDI >= (MIN_WAGE * 25) THEN
                        UTL_FILE.PUT_LINE(var_file, 'NOM_SDI     ' || TO_CHAR((MIN_WAGE * 25), '9999990D99'));
                    ELSE
                        UTL_FILE.PUT_LINE(var_file, 'NOM_SDI     ' || TO_CHAR(DETAIL(rowIndex).NOM_SDI, '9999990D99'));
                    END IF;
                    
                    UTL_FILE.PUT_LINE(var_file, 'NOM_TIPSAL  MIXTO');
                    UTL_FILE.PUT_LINE(var_file, 'NOM_CVENOM  ' || DETAIL(rowIndex).NOM_CVENOM);
                    UTL_FILE.PUT_LINE(var_file, 'NOM_FAHOACUM    ' || TO_CHAR(DETAIL(rowIndex).NOM_FAHOACUM, '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'NOM_PER_TOTGRA  ' || TO_CHAR(DETAIL(rowIndex).NOM_PER_TOTGRA, '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'NOM_PER_TOTEXE  ' || TO_CHAR(DETAIL(rowIndex).NOM_PER_TOTEXE, '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'NOM_DED_TOTGRA  ' || TO_CHAR(0, '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'NOM_DED_TOTEXE  ' || TO_CHAR((DETAIL(rowIndex).MONDET + DETAIL(rowIndex).ISRRET), '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'CANTID  1');
                    UTL_FILE.PUT_LINE(var_file, 'DESCRI  PAGO DE NOMINA');
                    UTL_FILE.PUT_LINE(var_file, 'NOM_DESCRI  ' || DETAIL(rowIndex).NOM_DESCRI);
                    UTL_FILE.PUT_LINE(var_file, 'UNIDAD  SERVICIO');
                    UTL_FILE.PUT_LINE(var_file, 'PBRUDE  ' || TO_CHAR(DETAIL(rowIndex).SUBTBR, '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'IMPBRU  ' || TO_CHAR(DETAIL(rowIndex).SUBTBR, '9999990D99'));
                    UTL_FILE.PUT_LINE(var_file, 'R');
                
                    DECLARE 
                    
                        CURSOR  DETAIL_ASSIGNMENT_ACTION (P_ASSIGNMENT_ID       NUMBER,
                                                          P_PAYROLL_ACTION_ID   NUMBER) IS
                                 SELECT DISTINCT PAA.ASSIGNMENT_ACTION_ID
                                   FROM PAY_ASSIGNMENT_ACTIONS PAA
                                  WHERE 1 = 1
                                    AND PAA.ASSIGNMENT_ID = P_ASSIGNMENT_ID
                                    AND PAA.PAYROLL_ACTION_ID = P_PAYROLL_ACTION_ID; 
                    
                        CURSOR  DETAIL_PERCEPCION (P_ASSIGNMENT_ACTION_ID   NUMBER) IS
                                                              SELECT NOM_PER_TIP,
                                        NOM_PER_CVE,
                                        NOM_PER_DESCRI,
                                        NOM_PER_IMPGRA,
                                        NOM_PER_IMPEXE    
                                   FROM(SELECT 
                                            NOM_PER_TIP,
                                            NOM_PER_CVE,
                                            NOM_PER_DESCRI,
                                            SUM(NOM_PER_IMPGRA) AS  NOM_PER_IMPGRA,
                                            SUM(NOM_PER_IMPEXE) AS  NOM_PER_IMPEXE 
                                          FROM (SELECT 
                                                    NVL((SELECT DISTINCT
                                                                DESCRIPTION
                                                           FROM FND_LOOKUP_VALUES
                                                          WHERE (LOOKUP_TYPE = 'XXCALV_CFDI_SAT_EARNING_CODES'
                                                             OR  LOOKUP_TYPE = 'XXCALV_CFDI_SAT_DEDUCTION_CODE')
                                                            AND MEANING LIKE PETF.ELEMENT_NAME
                                                            AND LANGUAGE = 'ESA'), '016')       AS  NOM_PER_TIP,
                                                    NVL((SELECT DISTINCT
                                                                TAG
                                                           FROM FND_LOOKUP_VALUES
                                                          WHERE (LOOKUP_TYPE = 'XXCALV_CFDI_SAT_EARNING_CODES'
                                                             OR  LOOKUP_TYPE = 'XXCALV_CFDI_SAT_DEDUCTION_CODE')
                                                            AND MEANING LIKE PETF.ELEMENT_NAME
                                                            AND LANGUAGE = 'ESA'), '000')      AS  NOM_PER_CVE,
                                                    (CASE 
                                                        WHEN PETF.ELEMENT_NAME = 'Profit Sharing' THEN
                                                            'REPARTO DE UTILIDADES'
                                                        WHEN PETF.ELEMENT_NAME LIKE 'P0%' THEN
                                                            REPLACE(SUBSTR(PETF.ELEMENT_NAME, 6, LENGTH(PETF.ELEMENT_NAME)), '_', ' ')
                                                        WHEN PETF.ELEMENT_NAME LIKE 'A0%' THEN
                                                            REPLACE(SUBSTR(PETF.ELEMENT_NAME, 6, LENGTH(PETF.ELEMENT_NAME)), '_', ' ')
                                                        ELSE
                                                            REPLACE(UPPER(PETF.ELEMENT_NAME), '_', ' ')
                                                     END)                                       AS  NOM_PER_DESCRI,
                                                    (CASE
                                                        WHEN PIVF.NAME = 'ISR Subject' THEN
                                                            SUM(PRRV.RESULT_VALUE)
                                                        ELSE 0
                                                     END)                                       AS  NOM_PER_IMPGRA,
                                                     (CASE
                                                        WHEN PIVF.NAME = 'ISR Exempt' THEN
                                                            SUM(PRRV.RESULT_VALUE)
                                                        ELSE 0
                                                     END)                                       AS  NOM_PER_IMPEXE
                                                  FROM PAY_RUN_RESULTS              PRR,
                                                       PAY_ELEMENT_TYPES_F          PETF,
                                                       PAY_RUN_RESULT_VALUES        PRRV,
                                                       PAY_INPUT_VALUES_F           PIVF,
                                                       PAY_ELEMENT_CLASSIFICATIONS  PEC
                                                 WHERE PRR.ASSIGNMENT_ACTION_ID = P_ASSIGNMENT_ACTION_ID
                                                   AND PETF.ELEMENT_TYPE_ID = PRR.ELEMENT_TYPE_ID
                                                   AND PRRV.RUN_RESULT_ID = PRR.RUN_RESULT_ID
                                                   AND PIVF.INPUT_VALUE_ID = PRRV.INPUT_VALUE_ID
                                                   AND PEC.CLASSIFICATION_ID = PETF.CLASSIFICATION_ID
                                                   AND (PEC.CLASSIFICATION_NAME IN ('Earnings', 
                                                                                    'Supplemental Earnings', 
                                                                                    'Amends', 
                                                                                    'Imputed Earnings') 
                                                          OR PETF.ELEMENT_NAME  IN (SELECT MEANING
                                                                                      FROM FND_LOOKUP_VALUES 
                                                                                     WHERE LOOKUP_TYPE = 'XX_PERCEPCIONES_INFORMATIVAS'
                                                                                       AND LANGUAGE = USERENV('LANG')))
                                                   AND PIVF.UOM = 'M'
                                                   AND (PIVF.NAME = 'ISR Subject' OR PIVF.NAME = 'ISR Exempt')
                                                   AND SYSDATE BETWEEN PETF.EFFECTIVE_START_DATE AND PETF.EFFECTIVE_END_DATE
                                                   AND SYSDATE BETWEEN PIVF.EFFECTIVE_START_DATE AND PIVF.EFFECTIVE_END_DATE 
                                                 GROUP BY PETF.ELEMENT_NAME,
                                                          PETF.REPORTING_NAME,
                                                          PETF.ELEMENT_INFORMATION11,
                                                          PIVF.NAME
                                                UNION
                                                SELECT 
                                                    NVL((SELECT DISTINCT
                                                                DESCRIPTION
                                                           FROM FND_LOOKUP_VALUES
                                                          WHERE (LOOKUP_TYPE = 'XXCALV_CFDI_SAT_EARNING_CODES'
                                                             OR  LOOKUP_TYPE = 'XXCALV_CFDI_SAT_DEDUCTION_CODE')
                                                            AND MEANING LIKE PETF.ELEMENT_NAME
                                                            AND LANGUAGE = 'ESA'), '016')       AS  NOM_PER_TIP,
                                                    NVL((SELECT DISTINCT
                                                                TAG
                                                           FROM FND_LOOKUP_VALUES
                                                          WHERE (LOOKUP_TYPE = 'XXCALV_CFDI_SAT_EARNING_CODES'
                                                             OR  LOOKUP_TYPE = 'XXCALV_CFDI_SAT_DEDUCTION_CODE')
                                                            AND MEANING LIKE PETF.ELEMENT_NAME
                                                            AND LANGUAGE = 'ESA'), '000')      AS  NOM_PER_CVE,
                                                    (CASE
                                                        WHEN PETF.ELEMENT_NAME = 'Profit Sharing' THEN
                                                            'REPARTO DE UTILIDADES' 
                                                        WHEN PETF.ELEMENT_NAME LIKE 'P0%' THEN
                                                            REPLACE(SUBSTR(PETF.ELEMENT_NAME, 6, LENGTH(PETF.ELEMENT_NAME)), '_', ' ')
                                                        WHEN PETF.ELEMENT_NAME LIKE 'A0%' THEN
                                                            REPLACE(SUBSTR(PETF.ELEMENT_NAME, 6, LENGTH(PETF.ELEMENT_NAME)), '_', ' ')
                                                        ELSE
                                                            REPLACE(UPPER(PETF.ELEMENT_NAME), '_', ' ')
                                                     END)                                       AS  NOM_PER_DESCRI,
                                                     0                                          AS  NOM_PER_IMPGRA,
                                                     SUM(PRRV.RESULT_VALUE)                     AS  NOM_PER_IMPEXE
                                                  FROM PAY_RUN_RESULTS              PRR,
                                                       PAY_ELEMENT_TYPES_F          PETF,
                                                       PAY_RUN_RESULT_VALUES        PRRV,
                                                       PAY_INPUT_VALUES_F           PIVF,
                                                       PAY_ELEMENT_CLASSIFICATIONS  PEC
                                                 WHERE PRR.ASSIGNMENT_ACTION_ID = P_ASSIGNMENT_ACTION_ID
                                                   AND PETF.ELEMENT_TYPE_ID = PRR.ELEMENT_TYPE_ID
                                                   AND PRRV.RUN_RESULT_ID = PRR.RUN_RESULT_ID
                                                   AND PIVF.INPUT_VALUE_ID = PRRV.INPUT_VALUE_ID
                                                   AND PEC.CLASSIFICATION_ID = PETF.CLASSIFICATION_ID
                                                   AND PETF.ELEMENT_NAME  IN ('FINAN_TRABAJO_RET',
                                                                              'P080_FONDO AHORRO TR ACUM',
                                                                              'P017_PRIMA DE ANTIGUEDAD',
                                                                              'P032_SUBSIDIO_PARA_EMPLEO',
                                                                              'P047_ISPT ANUAL A FAVOR')
                                                   AND PIVF.UOM = 'M'
                                                   AND PIVF.NAME = 'Pay Value'
                                                   AND SYSDATE BETWEEN PETF.EFFECTIVE_START_DATE AND PETF.EFFECTIVE_END_DATE
                                                   AND SYSDATE BETWEEN PIVF.EFFECTIVE_START_DATE AND PIVF.EFFECTIVE_END_DATE
                                                 GROUP BY PETF.ELEMENT_NAME,
                                                          PETF.REPORTING_NAME,
                                                          PETF.ELEMENT_INFORMATION11,
                                                          PIVF.NAME
                                               ) GROUP BY NOM_PER_TIP,
                                                          NOM_PER_CVE,
                                                          NOM_PER_DESCRI)
                                  WHERE 1 = 1
                                    AND (   NOM_PER_IMPGRA <> 0
                                         OR NOM_PER_IMPEXE <> 0)
                                  ORDER BY NOM_PER_CVE;
                                                              
                        CURSOR  DETAIL_DEDUCCION (P_ASSIGNMENT_ACTION_ID NUMBER) IS
                                 SELECT NOM_DED_TIP,
                                        NOM_DED_CVE,
                                        NOM_DED_DESCRI,
                                        NOM_DED_IMPGRA,
                                        NOM_DED_IMPEXE
                                   FROM(SELECT 
                                                NVL((SELECT DISTINCT
                                                            DESCRIPTION
                                                       FROM FND_LOOKUP_VALUES
                                                      WHERE (LOOKUP_TYPE = 'XXCALV_CFDI_SAT_EARNING_CODES'
                                                         OR  LOOKUP_TYPE = 'XXCALV_CFDI_SAT_DEDUCTION_CODE')
                                                        AND MEANING LIKE PETF.ELEMENT_NAME
                                                        AND LANGUAGE = 'ESA'), '004')       AS  NOM_DED_TIP,
                                                NVL((SELECT DISTINCT
                                                            TAG
                                                       FROM FND_LOOKUP_VALUES
                                                      WHERE (LOOKUP_TYPE = 'XXCALV_CFDI_SAT_EARNING_CODES'
                                                         OR  LOOKUP_TYPE = 'XXCALV_CFDI_SAT_DEDUCTION_CODE')
                                                        AND MEANING LIKE PETF.ELEMENT_NAME
                                                        AND LANGUAGE = 'ESA'), '000')      AS  NOM_DED_CVE,
                                               SUBSTR(PETF.ELEMENT_NAME,
                                                      6,
                                                      LENGTH(PETF.ELEMENT_NAME))AS  NOM_DED_DESCRI,
                                               0                                AS  NOM_DED_IMPGRA,
                                               PRRV.RESULT_VALUE                AS  NOM_DED_IMPEXE  
                                          FROM PAY_RUN_RESULTS              PRR,
                                               PAY_ELEMENT_TYPES_F          PETF,
                                               PAY_RUN_RESULT_VALUES        PRRV,
                                               PAY_INPUT_VALUES_F           PIVF,
                                               PAY_ELEMENT_CLASSIFICATIONS  PEC
                                         WHERE PRR.ASSIGNMENT_ACTION_ID = P_ASSIGNMENT_ACTION_ID
                                           AND PETF.ELEMENT_TYPE_ID = PRR.ELEMENT_TYPE_ID
                                           AND PRRV.RUN_RESULT_ID = PRR.RUN_RESULT_ID
                                           AND PIVF.INPUT_VALUE_ID = PRRV.INPUT_VALUE_ID
                                           AND PEC.CLASSIFICATION_ID = PETF.CLASSIFICATION_ID
                                           AND (PEC.CLASSIFICATION_NAME IN ('Voluntary Deductions', 
                                                                            'Involuntary Deductions') 
                                                   OR PETF.ELEMENT_NAME IN (SELECT MEANING
                                                                              FROM FND_LOOKUP_VALUES 
                                                                             WHERE LOOKUP_TYPE = 'XX_DEDUCCIONES_INFORMATIVAS'
                                                                               AND LANGUAGE = USERENV('LANG')))
                                           AND PIVF.UOM = 'M'
                                           AND PIVF.NAME = 'Pay Value'
                                           AND SYSDATE BETWEEN PETF.EFFECTIVE_START_DATE AND PETF.EFFECTIVE_END_DATE
                                           AND SYSDATE BETWEEN PIVF.EFFECTIVE_START_DATE AND PIVF.EFFECTIVE_END_DATE)
                                   WHERE 1 = 1
                                     AND (   NOM_DED_IMPGRA <> 0
                                          OR NOM_DED_IMPEXE <> 0)
                                   ORDER BY NOM_DED_DESCRI;
                    
                        isPERCEP    BOOLEAN;
                        isDEDUC     BOOLEAN;
                        
                        
                    BEGIN
                    
                        isPERCEP := FALSE;
                        isDEDUC  := FALSE;
                    
                        FOR ASSIGN IN DETAIL_ASSIGNMENT_ACTION (DETAIL(rowIndex).ASSIGNMENT_ID, DETAIL(rowIndex).PAYROLL_ACTION_ID) LOOP       
                            FOR PERCEP IN DETAIL_PERCEPCION (ASSIGN.ASSIGNMENT_ACTION_ID) LOOP
                                IF isPERCEP = FALSE THEN
                                    UTL_FILE.PUT_LINE(var_file, 'INIPER');
                                    isPERCEP := TRUE;
                                END IF;
                            
                                UTL_FILE.PUT_LINE(var_file, '');
                                UTL_FILE.PUT_LINE(var_file, 'NOM_PER_TIP     ' || PERCEP.NOM_PER_TIP);
                                UTL_FILE.PUT_LINE(var_file, 'NOM_PER_CVE     ' || PERCEP.NOM_PER_CVE);
                                UTL_FILE.PUT_LINE(var_file, 'NOM_PER_DESCRI  ' || REPLACE(PERCEP.NOM_PER_DESCRI, '_', ' '));
                                UTL_FILE.PUT_LINE(var_file, 'NOM_PER_IMPGRA  ' || TO_CHAR(PERCEP.NOM_PER_IMPGRA, '9999990D99'));
                                UTL_FILE.PUT_LINE(var_file, 'NOM_PER_IMPEXE  ' || TO_CHAR(PERCEP.NOM_PER_IMPEXE, '9999990D99'));
                            
                            END LOOP;
                        END LOOP;
                                
                        IF isPERCEP = TRUE THEN
                            UTL_FILE.PUT_LINE(var_file, '');
                            UTL_FILE.PUT_LINE(var_file, 'FINPER');
                        END IF;                        
                           
                        
                        
                        FOR ASSIGN IN DETAIL_ASSIGNMENT_ACTION (DETAIL(rowIndex).ASSIGNMENT_ID, DETAIL(rowIndex).PAYROLL_ACTION_ID) LOOP                            
                            FOR DEDUC IN DETAIL_DEDUCCION (ASSIGN.ASSIGNMENT_ACTION_ID) LOOP
                            
                                IF isDEDUC = FALSE THEN
                                    UTL_FILE.PUT_LINE(var_file, 'INIDED');
                                    isDEDUC := TRUE;   
                                END IF;
                            
                                UTL_FILE.PUT_LINE(var_file, '');
                                UTL_FILE.PUT_LINE(var_file, 'NOM_DED_TIP     ' || DEDUC.NOM_DED_TIP);
                                UTL_FILE.PUT_LINE(var_file, 'NOM_DED_CVE     ' || DEDUC.NOM_DED_CVE);
                                UTL_FILE.PUT_LINE(var_file, 'NOM_DED_DESCRI  ' || REPLACE(DEDUC.NOM_DED_DESCRI, '_', ' '));
                                UTL_FILE.PUT_LINE(var_file, 'NOM_DED_IMPGRA  ' || TO_CHAR(DEDUC.NOM_DED_IMPGRA, '9999990D99'));
                                UTL_FILE.PUT_LINE(var_file, 'NOM_DED_IMPEXE  ' || TO_CHAR(DEDUC.NOM_DED_IMPEXE, '9999990D99'));
                                
                            END LOOP;
                        END LOOP;                       
                                
                        IF isDEDUC = TRUE THEN
                            UTL_FILE.PUT_LINE(var_file, '');
                            UTL_FILE.PUT_LINE(var_file, 'FINDED');
                        END IF;
                            
                        
                        
                        UTL_FILE.PUT_LINE(var_file, '');
                        
                        dbms_output.put_line(TO_CHAR(var_reg_seq,'00000') || ' - ' || DETAIL(rowIndex).NOMREC);
                        FND_FILE.PUT_LINE(FND_FILE.LOG, TO_CHAR(var_reg_seq,'00000') || ' - ' || DETAIL(rowIndex).NOMREC);
                        
                    EXCEPTION WHEN OTHERS THEN
                        dbms_output.put_line('**Error al Crear los Registros de Percepciones y Deducciones. ' || SQLERRM);
                        FND_FILE.PUT_LINE(FND_FILE.LOG, '**Error al Crear los Registros de Percepciones y Deducciones. ' || SQLERRM);
                    END;
            
                END LOOP;
                
            END LOOP;
            
            CLOSE DETAIL_LIST;
                    
        
        EXCEPTION WHEN OTHERS THEN
            dbms_output.put_line('**Error al Recorrer el Cursor DETAIL_LIST. ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '**Error al Recorrer el Cursor DETAIL_LIST. ' || SQLERRM);
        END;
        
        --Finalizacion del Procedimiento.
        dbms_output.put_line('Archivo creado!');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Archivo creado!');
        
        --Eliminaci�n de la secuencia
        BEGIN
        
            EXECUTE IMMEDIATE 'DROP SEQUENCE ' || var_sequence_name;
                          
        EXCEPTION WHEN OTHERS THEN
            dbms_output.put_line('**Error al Borrar la Secuencia ' || var_sequence_name || '. ' || SQLERRM);
            FND_FILE.PUT_LINE(FND_FILE.LOG, '**Error al Borrar la Secuencia ' || var_sequence_name || '. ' || SQLERRM);
        END;
            
    ELSE
        P_RETCODE := 1;
        P_ERRBUF := 'EL ARCHIVO ' || var_file_name || ' YA HA SIDO GENERADO ANTERIORMENTE.';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('**Error al Ejecutar el Procedure PAC_CFDI_NOMINA_PRC. ' || SQLERRM);
    FND_FILE.PUT_LINE(FND_FILE.LOG, '**Error al Ejecutar el Procedure PAC_CFDI_NOMINA_PRC. ' || SQLERRM);
END;
/
