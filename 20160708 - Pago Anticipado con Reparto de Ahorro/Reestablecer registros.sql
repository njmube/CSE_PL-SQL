DELETE FROM ATET_SB_SAVINGS_TRANSACTIONS WHERE ATTRIBUTE7 = 'REPARTO DE AHORRO';
DELETE FROM ATET_SB_SAVINGS_TRANSACTIONS WHERE ELEMENT_NAME = 'INTERES GANADO';
DELETE FROM ATET_SB_MEMBERS_ACCOUNTS WHERE ACCOUNT_DESCRIPTION = 'INTERES GANADO'; 



COMMIT;


SELECT LOAN_ID,
       MEMBER_ID,
       MEMBER_ACCOUNT_ID,
       ENTRY_VALUE,
       TO_CHAR(CREATION_DATE, 'DD/MM/RRRR') CREATION_DATE
  FROM ATET_SB_LOANS_TRANSACTIONS
 WHERE ATTRIBUTE7 = 'REPARTO DE AHORRO';
 
 
DECLARE

    CURSOR DETAILS IS
        SELECT LOAN_ID,
               MEMBER_ACCOUNT_ID,
               ENTRY_VALUE,
               TO_CHAR(CREATION_DATE, 'DD/MM/RRRR') CREATION_DATE
          FROM ATET_SB_LOANS_TRANSACTIONS
         WHERE ATTRIBUTE7 = 'REPARTO DE AHORRO';
    
BEGIN


    FOR detail IN DETAILS LOOP
    
        UPDATE ATET_SB_LOANS ASL
           SET ASL.LOAN_STATUS_FLAG = 'ACTIVE',
               ASL.LOAN_BALANCE = ASL.LOAN_BALANCE + detail.ENTRY_VALUE
         WHERE LOAN_ID = detail.LOAN_ID;
         
        UPDATE ATET_SB_MEMBERS_ACCOUNTS ASMA
           SET ASMA.CREDIT_BALANCE = ASMA.CREDIT_BALANCE - detail.ENTRY_VALUE,
               ASMA.FINAL_BALANCE = ASMA.FINAL_BALANCE + detail.ENTRY_VALUE
         WHERE LOAN_ID = detail.LOAN_ID
           AND MEMBER_ACCOUNT_ID = detail.MEMBER_ACCOUNT_ID;
           
        UPDATE ATET_SB_PAYMENTS_SCHEDULE ASPS
           SET ATTRIBUTE6 = NULL,
               STATUS_FLAG = 'PENDING',
               PAYED_AMOUNT = NULL,
               PAYED_CAPITAL = NULL,
               PAYED_INTEREST = NULL,
               PAYED_INTEREST_LATE = NULL,
               OWED_AMOUNT = NULL,
               OWED_CAPITAL = NULL,
               OWED_INTEREST = NULL,
               OWED_INTEREST_LATE = NULL
         WHERE 1 = 1
           AND ASPS.LOAN_ID = detail.LOAN_ID
           AND TO_CHAR(LAST_UPDATE_DATE, 'DD/MM/RRRR') = detail.CREATION_DATE;
    
    END LOOP;    

    DELETE FROM ATET_SB_LOANS_TRANSACTIONS
     WHERE ATTRIBUTE7 = 'REPARTO DE AHORRO';
     
    COMMIT;

END;


UPDATE ATET_SB_MEMBERS_ACCOUNTS
   SET DEBIT_BALANCE = 0,
       FINAL_BALANCE = CREDIT_BALANCE
 WHERE 1 = 1
   AND MEMBER_ID IN (1131, 1132, 1133, 1135, 1136, 1111, 1113, 1126, 1128, 1130)
   AND ACCOUNT_DESCRIPTION = 'D071_CAJA DE AHORRO';
   
COMMIT;

DECLARE
    
    BALANCE NUMBER;

    CURSOR DETAILS IS
    SELECT ASMA.LOAN_ID,
           ASMA.MEMBER_ACCOUNT_ID
      FROM ATET_SB_MEMBERS_ACCOUNTS ASMA
     WHERE MEMBER_ID IN (1131, 1132, 1133, 1135, 1136, 1111, 1113, 1126, 1128, 1130)
       AND ACCOUNT_DESCRIPTION = 'D072_PRESTAMO CAJA DE AHORRO';

BEGIN
    FOR detail IN DETAILS LOOP
    
        SELECT SUM(PAYED_AMOUNT)
          INTO BALANCE
          FROM ATET_SB_PAYMENTS_SCHEDULE
         WHERE LOAN_ID = detail.LOAN_ID
           AND STATUS_FLAG IN ('PAYED', 'PARTIAL');
           
        UPDATE ATET_SB_MEMBERS_ACCOUNTS 
          SET CREDIT_BALANCE = BALANCE,
              FINAL_BALANCE = DEBIT_BALANCE - BALANCE
          WHERE LOAN_ID = detail.LOAN_ID
            AND MEMBER_ACCOUNT_ID = detail.MEMBER_ACCOUNT_ID;
    
    END LOOP;
END;


COMMIT;