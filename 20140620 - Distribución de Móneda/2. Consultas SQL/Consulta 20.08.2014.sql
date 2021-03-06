SELECT 
    SUM(VALUE)
FROM(

    SELECT DISTINCT
           PAPF.PERSON_ID,
           PAPF.EMPLOYEE_NUMBER,
           PPPV.VALUE
      FROM PER_ALL_PEOPLE_F         PAPF,
           PER_ALL_ASSIGNMENTS_F    PAAF,
           PAY_PAYROLLS_F           PPF,
           PAY_PAYROLL_ACTIONS      PPA,
           PAY_ASSIGNMENT_ACTIONS   PAA,
           PAY_PRE_PAYMENTS_V       PPPV
     WHERE PAPF.PERSON_ID = PAAF.PERSON_ID
       AND PAAF.PAYROLL_ID = PPF.PAYROLL_ID
       AND PPA.PAYROLL_ID = PPF.PAYROLL_ID
       AND PPA.ACTION_TYPE IN ('U', 'P')
       AND PAA.ASSIGNMENT_ID = PAAF.ASSIGNMENT_ID
       AND PAA.PAYROLL_ACTION_ID = PPA.PAYROLL_ACTION_ID
       AND PPPV.ASSIGNMENT_ACTION_ID = PAA.ASSIGNMENT_ACTION_ID
       AND PPPV.ORG_PAYMENT_METHOD_NAME LIKE '%EFECTIVO'
       
       AND SUBSTR(PPF.PAYROLL_NAME, 1, 2) = :P_COMPANY_ID
       AND PAC_HR_PAY_PKG.GET_PERIOD_TYPE(PPF.PAYROLL_NAME) = NVL(:P_PERIOD_TYPE, PAC_HR_PAY_PKG.GET_PERIOD_TYPE(PPF.PAYROLL_NAME))
       AND PPF.PAYROLL_ID = NVL(:P_PAYROLL_ID, PPF.PAYROLL_ID)
       AND PPA.CONSOLIDATION_SET_ID = NVL(:P_CONSOLIDATION_SET_ID, PPA.CONSOLIDATION_SET_ID)
       AND PAAF.ORGANIZATION_ID = NVL(:P_ORGANIZATION_ID, PAAF.ORGANIZATION_ID)
       AND (PPA.START_DATE >= :P_START_DATE AND PPA.EFFECTIVE_DATE <= :P_END_DATE)
       
      )

       
           
          