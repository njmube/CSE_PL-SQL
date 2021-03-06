SELECT DISTINCT
       EMP.EMPLOYEE_NUMBER      "Numero de Empleado",
       EMP.FULL_NAME            "Nombre de Empleado",
       EMP.USER_PERSON_TYPE     "Tipo Persona",
       EMP.NAME                 "Departamento",
       CON.FULL_NAME            "Nombre de Contacto",
       PPT.USER_PERSON_TYPE     "Tipo Contacto"
  FROM (SELECT EMP.PERSON_ID,
               EMP.EMPLOYEE_NUMBER,
               EMP.FULL_NAME,
               PPT.USER_PERSON_TYPE,
               HOU.NAME
          FROM PER_PEOPLE_F             EMP,
               PER_PERSON_TYPES         PPT,
               PER_ASSIGNMENTS_F        PAF,
               HR_ORGANIZATION_UNITS    HOU
         WHERE 1 = 1 
           AND PAF.PERSON_ID = EMP.PERSON_ID
           AND EMP.PERSON_TYPE_ID = PPT.PERSON_TYPE_ID
           AND HOU.ORGANIZATION_ID = PAF.ORGANIZATION_ID
           AND PPT.SYSTEM_PERSON_TYPE = 'EMP'
           AND SYSDATE BETWEEN EMP.EFFECTIVE_START_DATE AND EMP.EFFECTIVE_END_DATE
           AND SYSDATE BETWEEN PAF.EFFECTIVE_START_DATE AND PAF.EFFECTIVE_END_DATE
        ) EMP
  LEFT JOIN PER_CONTACT_RELATIONSHIPS   PCR
         ON PCR.PERSON_ID = EMP.PERSON_ID
  LEFT JOIN PER_PEOPLE_F                CON
         ON PCR.CONTACT_PERSON_ID = CON.PERSON_ID
  LEFT JOIN PER_PERSON_TYPES    PPT
         ON CON.PERSON_TYPE_ID = PPT.PERSON_TYPE_ID
        AND PPT.USER_PERSON_TYPE IN ('Contacto', 'Contact')
 WHERE 1 = 1 
 ORDER BY TO_NUMBER(EMP.EMPLOYEE_NUMBER)