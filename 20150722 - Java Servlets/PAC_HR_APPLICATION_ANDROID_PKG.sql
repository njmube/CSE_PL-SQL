CREATE OR REPLACE PACKAGE PAC_HR_APPLICATION_ANDROID_PKG
IS

    FUNCTION GET_EMPLOYEE_NAME(P_EMPLOYEE_NUMBER  NUMBER)
             RETURN VARCHAR2;
             
    FUNCTION GET_DEPARTMENT(P_EMPLOYEE_NUMBER  NUMBER)
             RETURN VARCHAR2;
             
    FUNCTION GET_JOB(P_EMPLOYEE_NUMBER  NUMBER)
             RETURN VARCHAR2;
             
    FUNCTION GET_PICTURE(P_EMPLOYEE_NUMBER  NUMBER)
             RETURN BLOB;         

END PAC_HR_APPLICATION_ANDROID_PKG;