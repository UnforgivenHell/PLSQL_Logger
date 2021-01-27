WHENEVER SQLERROR EXIT

prompt Connecting as sys at &sid
conn sys@&sid as sysdba

set termout on
ACCEPT YN CHAR PROMPT 'Create users &user_name? (Y/N): '
set termout off
BEGIN
  IF NVL(UPPER('&yn'), 'N') <> 'Y' THEN
    RAISE_APPLICATION_ERROR(-20000, 'Don''t do it!');
  END IF;
END;
/
set termout on

WHENEVER SQLERROR CONTINUE


-------------------------------------------------

CREATE USER &user_name
  IDENTIFIED BY &user_psw
  PROFILE "DEFAULT"
  DEFAULT TABLESPACE &data_tbs 
  TEMPORARY TABLESPACE &temp_tbs 
  ACCOUNT UNLOCK
  QUOTA UNLIMITED ON &data_tbs
  QUOTA UNLIMITED ON &index_tbs
/

GRANT CREATE SESSION, CREATE PROCEDURE, CREATE TRIGGER, CREATE TABLE, CREATE VIEW
   TO &user_name;

GRANT SELECT ON v_$session TO &user_name;

GRANT CREATE ANY CONTEXT, DROP ANY CONTEXT
   TO &user_name;

GRANT DEBUG CONNECT SESSION TO &user_name;

spool off;

exit;