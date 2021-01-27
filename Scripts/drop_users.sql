WHENEVER SQLERROR EXIT

prompt Connecting as sys at &sid
conn sys@&sid as sysdba

ACCEPT YN CHAR PROMPT 'Drop users &user_name? (Y/N): '

set termout off
BEGIN
  IF NVL(UPPER('&yn'), 'N') <> 'Y' THEN
    RAISE_APPLICATION_ERROR(-20000, 'Don''t delete user!');
  END IF;
END;
/

set termout on

@Scripts/drop_objects.sql

DROP USER &user_name CASCADE
/

spool off;

exit;