WHENEVER SQLERROR EXIT

------------------------------
prompt Connect as &user_name at &sid
conn &user_name/&user_psw@&sid
------------------------------

set termout on
ACCEPT YN CHAR PROMPT 'Create objects? (Y/N): '
set termout off
BEGIN
  IF NVL(UPPER('&yn'), 'N') <> 'Y' THEN
    RAISE_APPLICATION_ERROR(-20000, 'Don''t do it!');
  END IF;
END;
/
set termout on

WHENEVER SQLERROR CONTINUE

ALTER SESSION SET PLSQL_CCFLAGS = 'debug:&debug'
/

@Source/Tables/_list.sql
@Source/Packages/_list.sql
@Source/Views/_list.sql
@Source/Contexts/_list.sql