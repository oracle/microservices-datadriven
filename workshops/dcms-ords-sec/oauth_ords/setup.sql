CREATE USER "ORDSTEST" IDENTIFIED BY "H2VG_nTTD_dxqzsoHL3CLJ";
GRANT "CONNECT" TO "ORDSTEST";
GRANT "RESOURCE" TO "ORDSTEST";
ALTER USER "ORDSTEST" QUOTA UNLIMITED ON DATA; 

BEGIN
    ORDS.enable_schema(
         p_enabled             => TRUE
        ,p_schema              => 'ORDSTEST'
        ,p_url_mapping_type    => 'BASE_PATH'
        ,p_url_mapping_pattern => 'ordstest'
        ,p_auto_rest_auth      => FALSE
    );  
    COMMIT;
END;
/

CREATE TABLE ORDSTEST.EMP (
    EMPNO    NUMBER(4,0)
    ,ENAME    VARCHAR2(10 BYTE)
    ,JOB      VARCHAR2(9 BYTE)
    ,MGR      NUMBER(4,0)
    ,HIREDATE DATE
    ,SAL      NUMBER(7,2)
    ,COMM     NUMBER(7,2)
    ,DEPTNO   NUMBER(2,0) 
    ,CONSTRAINT PK_EMP PRIMARY KEY (EMPNO)
);

INSERT into ORDSTEST.EMP 
VALUES (7369,'SMITH','CLERK',7902,to_date('17-DEC-80','DD-MON-RR'),800,null,20);
    
INSERT into ORDSTEST.EMP 
VALUES (7499,'ALLEN','SALESMAN',7698,to_date('20-FEB-81','DD-MON-RR'),1600,300,30);
    
INSERT into ORDSTEST.EMP 
VALUES (7521,'WARD','SALESMAN',7698,to_date('22-FEB-81','DD-MON-RR'),1250,500,30);
    
INSERT into ORDSTEST.EMP 
VALUES (7566,'JONES','MANAGER',7839,to_date('02-APR-81','DD-MON-RR'),2975,null,20);
COMMIT;