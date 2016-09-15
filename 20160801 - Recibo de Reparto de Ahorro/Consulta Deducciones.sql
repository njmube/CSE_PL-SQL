SELECT ASMA.MEMBER_ID,
       ASMA.MEMBER_ACCOUNT_ID,
       ASMA.LOAN_ID,
       ASMA.ACCOUNT_DESCRIPTION,
       SUM(ASLT.CREDIT_AMOUNT)      AS  CREDIT_AMOUNT
  FROM ATET_SB_MEMBERS_ACCOUNTS     ASMA,
       ATET_SB_LOANS_TRANSACTIONS   ASLT
 WHERE 1 = 1
   AND ASMA.MEMBER_ID = :P_MEMBER_ID
   AND ASMA.MEMBER_ACCOUNT_ID = ASLT.MEMBER_ACCOUNT_ID
   AND ASMA.MEMBER_ID = ASLT.MEMBER_ID
   AND ASMA.ACCOUNT_DESCRIPTION IN ('D072_PRESTAMO CAJA DE AHORRO')
   AND ASLT.ATTRIBUTE7 = 'REPARTO DE AHORRO'
 GROUP BY ASMA.MEMBER_ID,
          ASMA.MEMBER_ACCOUNT_ID,
          ASMA.LOAN_ID,
          ASMA.ACCOUNT_DESCRIPTION
 ORDER BY ASMA.ACCOUNT_DESCRIPTION