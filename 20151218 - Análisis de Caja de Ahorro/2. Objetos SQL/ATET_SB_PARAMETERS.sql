CREATE TABLE ATET_SB_PARAMETERS
(
    PARAMETER_ID                     NUMBER NOT NULL,
    SAVING_BANK_ID                   NUMBER NOT NULL,
    PARAMETER_CODE                   VARCHAR2(50),
    PARAMETER_DESCRIPTION            VARCHAR2(250),
    PARAMETER_VALUE                  VARCHAR2(50),
    EFFECTIVE_START_DATE             DATE,
    EFFECTIVE_END_DATE               DATE,
    ATTRIBUTE1                       NUMBER,
    ATTRIBUTE2                       NUMBER,
    ATTRIBUTE3                       NUMBER,
    ATTRIBUTE4                       NUMBER,
    ATTRIBUTE5                       NUMBER,
    ATTRIBUTE6                       VARCHAR2(250),
    ATTRIBUTE7                       VARCHAR2(250),
    ATTRIBUTE8                       VARCHAR2(250),
    ATTRIBUTE9                       VARCHAR2(250),
    ATTRIBUTE10                      VARCHAR2(250),
    ATTRIBUTE11                      VARCHAR2(250),
    ATTRIBUTE12                      VARCHAR2(250),
    ATTRIBUTE13                      VARCHAR2(250),
	ATTRIBUTE14                      VARCHAR2(250),
	ATTRIBUTE15                      VARCHAR2(250),
	CREATION_DATE                    DATE,
	CREATED_BY                       NUMBER,
	LAST_UPDATE_DATE                 DATE,
	LAST_UPDATED_BY                  NUMBER
);


ALTER TABLE ATET_SB_PARAMETERS
	ADD CONSTRAINT UQ_ATET_PARAMETERS UNIQUE (PARAMETER_ID)
 USING INDEX ;
 
 
ALTER TABLE ATET_SB_PARAMETERS
    ADD CONSTRAINT FK_ATET_PARAMETERS 
        FOREIGN KEY (SAVING_BANK_ID)
        REFERENCES ATET_SAVINGS_BANK(SAVING_BANK_ID); 

 

CREATE SEQUENCE ATET_SB_PARAMETERS_SEQ
  START WITH 1
  NOCYCLE
  NOCACHE
  NOORDER;
  
  
CREATE OR REPLACE TRIGGER ATET_SB_PARAMETERS_TGR
BEFORE INSERT
   ON ATET_SB_PARAMETERS
   FOR EACH ROW
DECLARE

   var_next_id  NUMBER;

BEGIN

    SELECT ATET_SB_PARAMETERS_SEQ.NEXTVAL
      INTO var_next_id
      FROM dual;        
      
    :NEW.PARAMETER_ID := var_next_id;

END;