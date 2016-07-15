            SELECT ASM.MEMBER_ID,
                   ASM.PERSON_ID,
                   ASM.EMPLOYEE_NUMBER,
                   ASM.EMPLOYEE_FULL_NAME,
                   ASMA1.MEMBER_ACCOUNT_ID  AS SAVING_MEMBER_ACCOUNT_ID,
                   ASMA1.FINAL_BALANCE      AS SAVING_FINAL_BALANCE,
                   ASMA2.MEMBER_ACCOUNT_ID  AS INTEREST_MEMBER_ACCOUNT_ID,
                   ASMA2.FINAL_BALANCE       AS INTEREST_FINAL_BALANCE,
                   ASL.LOAN_ID,
                   ASL.LOAN_NUMBER,
                   ASMA3.FINAL_BALANCE,
                   SUM(ASPS.PAYMENT_AMOUNT) PAYMENTS_BALANCE,
                   ASL.LOAN_BALANCE
              FROM ATET_SB_MEMBERS          ASM,
                   ATET_SB_MEMBERS_ACCOUNTS ASMA1,
                   ATET_SB_MEMBERS_ACCOUNTS ASMA2,
                   ATET_SB_MEMBERS_ACCOUNTS ASMA3,
                   ATET_SB_LOANS            ASL,
                   ATET_SB_PAYMENTS_SCHEDULE ASPS
             WHERE 1 = 1
               AND ASL.MEMBER_ID = ASM.MEMBER_ID
               AND ASM.MEMBER_ID = ASMA1.MEMBER_ID
               AND ASMA1.ACCOUNT_DESCRIPTION = 'D071_CAJA DE AHORRO'
               AND ASMA1.FINAL_BALANCE > 0
               AND ASM.MEMBER_ID = ASMA2.MEMBER_ID
               AND ASMA2.ACCOUNT_DESCRIPTION = 'INTERES GANADO'
               AND ASM.MEMBER_ID = ASMA3.MEMBER_ID
               AND ASMA3.ACCOUNT_DESCRIPTION LIKE 'D072%'
               AND ASMA3.LOAN_ID = ASL.LOAN_ID
               AND ASMA2.FINAL_BALANCE > 0
               AND ASL.LOAN_ID = ASPS.LOAN_ID
               AND ASPS.STATUS_FLAG = 'PENDING'
               AND ASM.SAVING_BANK_ID = ATET_SAVINGS_BANK_PKG.GET_SAVING_BANK_ID
--               AND ASM.MEMBER_ID IN (1131, 1132, 1133, 1135, 1136, 1111, 1113, 1126, 1128, 1130)
             GROUP BY ASM.MEMBER_ID,
                       ASM.PERSON_ID,
                       ASM.EMPLOYEE_NUMBER,
                       ASM.EMPLOYEE_FULL_NAME,
                       ASMA1.MEMBER_ACCOUNT_ID,
                       ASMA1.FINAL_BALANCE,
                       ASMA2.MEMBER_ACCOUNT_ID,
                       ASMA2.FINAL_BALANCE,
                       ASL.LOAN_ID,
                       ASL.LOAN_NUMBER,
                       ASMA3.FINAL_BALANCE,
                       ASL.LOAN_BALANCE;
               
               
               ATET_SB_SAVINGS_TRANSACTIONS
               ATET_SB_LOANS_TRANSACTIONS
               ATET_SB_MEMBERS_ACCOUNTS
               ATET_SB_PAYMENTS_SCHEDULE
                 
                 
    SELECT *
      FROM (SELECT ASM.MEMBER_ID,
                   ASM.PERSON_ID,
                   ASM.EMPLOYEE_NUMBER,
                   ASM.EMPLOYEE_FULL_NAME,
                   ASMA1.MEMBER_ACCOUNT_ID  AS SAVING_MEMBER_ACCOUNT_ID,
                   ASMA1.FINAL_BALANCE      AS SAVING_FINAL_BALANCE,
                   ASMA2.MEMBER_ACCOUNT_ID  AS INTEREST_MEMBER_ACCOUNT_ID,
                   ASMA2.FINAL_BALANCE       AS INTEREST_FINAL_BALANCE,
                   ASL.LOAN_ID,
                   ASL.LOAN_NUMBER,
                   ASMA3.FINAL_BALANCE,
                   SUM( NVL(ASPS.OWED_AMOUNT, ASPS.PAYMENT_AMOUNT) ) PAYMENTS_BALANCE,
                   ASL.LOAN_BALANCE
              FROM ATET_SB_MEMBERS          ASM,
                   ATET_SB_MEMBERS_ACCOUNTS ASMA1,
                   ATET_SB_MEMBERS_ACCOUNTS ASMA2,
                   ATET_SB_MEMBERS_ACCOUNTS ASMA3,
                   ATET_SB_LOANS            ASL,
                   ATET_SB_PAYMENTS_SCHEDULE ASPS
             WHERE 1 = 1
               AND ASL.MEMBER_ID = ASM.MEMBER_ID
               AND ASM.MEMBER_ID = ASMA1.MEMBER_ID
               AND ASMA1.ACCOUNT_DESCRIPTION = 'D071_CAJA DE AHORRO'
               AND ASMA1.FINAL_BALANCE > 0
               AND ASM.MEMBER_ID = ASMA2.MEMBER_ID
               AND ASMA2.ACCOUNT_DESCRIPTION = 'INTERES GANADO'
               AND ASM.MEMBER_ID = ASMA3.MEMBER_ID
               AND ASMA3.ACCOUNT_DESCRIPTION LIKE 'D072%'
               AND ASMA3.LOAN_ID = ASL.LOAN_ID
               AND ASMA2.FINAL_BALANCE > 0
               AND ASL.LOAN_ID = ASPS.LOAN_ID
               AND ASL.LOAN_STATUS_FLAG = 'ACTIVE'
               AND ASPS.STATUS_FLAG IN ('PENDING', 'SKIP', 'PARTIAL')
               AND ASM.SAVING_BANK_ID = ATET_SAVINGS_BANK_PKG.GET_SAVING_BANK_ID
--               AND ASM.MEMBER_ID IN (1131, 1132, 1133, 1135, 1136, 1111, 1113, 1126, 1128, 1130)
             GROUP BY ASM.MEMBER_ID,
                       ASM.PERSON_ID,
                       ASM.EMPLOYEE_NUMBER,
                       ASM.EMPLOYEE_FULL_NAME,
                       ASMA1.MEMBER_ACCOUNT_ID,
                       ASMA1.FINAL_BALANCE,
                       ASMA2.MEMBER_ACCOUNT_ID,
                       ASMA2.FINAL_BALANCE,
                       ASL.LOAN_ID,
                       ASL.LOAN_NUMBER,
                       ASMA3.FINAL_BALANCE,
                       ASL.LOAN_BALANCE) D
         WHERE 1 = 1 
           AND (FINAL_BALANCE <> PAYMENTS_BALANCE 
             OR FINAL_BALANCE <> LOAN_BALANCE
             OR PAYMENTS_BALANCE <> LOAN_BALANCE);
                 
             
             
             
             SELECT ASM.MEMBER_ID,
                   ASM.PERSON_ID,
                   ASM.EMPLOYEE_NUMBER,
                   ASM.EMPLOYEE_FULL_NAME,
--                   ASMA1.MEMBER_ACCOUNT_ID      AS SAVING_MEMBER_ACCOUNT_ID,
                   ASMA1.FINAL_BALANCE          AS SAVING_FINAL_BALANCE,
--                   ASMA1.CODE_COMBINATION_ID    AS SAVING_CODE_COMBINATION_ID,
--                   ASMA2.MEMBER_ACCOUNT_ID      AS INTEREST_MEMBER_ACCOUNT_ID,
                   ASMA2.FINAL_BALANCE          AS INTEREST_FINAL_BALANCE,
--                   ASMA2.CODE_COMBINATION_ID    AS INTEREST_CODE_COMBINATION_ID,
--                   ASL.LOAN_ID,
--                   ASMA3.CODE_COMBINATION_ID    AS LOAN_CODE_COMBINATION_ID,
--                   ASL.LOAN_NUMBER,
                   ASL.LOAN_BALANCE
              FROM ATET_SB_MEMBERS          ASM,
                   ATET_SB_MEMBERS_ACCOUNTS ASMA1,
                   ATET_SB_MEMBERS_ACCOUNTS ASMA2,
                   ATET_SB_MEMBERS_ACCOUNTS ASMA3,
                   ATET_SB_LOANS            ASL,
                   ATET_SAVINGS_BANK        ASB
             WHERE 1 = 1
               AND ASL.MEMBER_ID = ASM.MEMBER_ID
               AND ASM.MEMBER_ID = ASMA1.MEMBER_ID
               AND ASMA1.ACCOUNT_DESCRIPTION = 'D071_CAJA DE AHORRO'
               AND ASMA1.FINAL_BALANCE > 0
               AND ASM.MEMBER_ID = ASMA2.MEMBER_ID
               AND ASMA2.ACCOUNT_DESCRIPTION = 'INTERES GANADO'
               AND ASMA2.FINAL_BALANCE > 0
               AND ASM.MEMBER_ID = ASMA3.MEMBER_ID
               AND ASMA3.ACCOUNT_DESCRIPTION = 'D072_PRESTAMO CAJA DE AHORRO'
               AND ASMA3.LOAN_ID = ASL.LOAN_ID
               AND ASL.LOAN_STATUS_FLAG = 'ACTIVE'
               AND ASL.LOAN_BALANCE > 0
               AND ASM.SAVING_BANK_ID = ASB.SAVING_BANK_ID
               AND ASB.YEAR = :P_YEAR;