WHENEVER SQLERROR EXIT

------------------------------
prompt Connect as &user_name at &sid
conn &user_name/&user_psw@&sid
------------------------------

set termout on
ACCEPT YN CHAR PROMPT 'Drop objects? (Y/N): '
set termout off
BEGIN
  IF NVL(UPPER('&yn'), 'N') <> 'Y' THEN
    RAISE_APPLICATION_ERROR(-20000, 'Don''t do it!');
  END IF;
END;
/
set termout on


WHENEVER SQLERROR CONTINUE

prompt
prompt Drop packages...
rem |--------------------------------------------------------------------------|
rem |                         Drop packages                                    |
rem |--------------------------------------------------------------------------|
BEGIN
  FOR c IN (SELECT object_name
              FROM user_objects
             WHERE object_type = 'PACKAGE'
               AND object_name IN ('LOGGER_API'
                                  )
           )
  LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP PACKAGE ' || c.object_name;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE (c.object_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

prompt
prompt Drop views...
rem |--------------------------------------------------------------------------|
rem |                         Drop views                                       |
rem |--------------------------------------------------------------------------|
BEGIN
  FOR c IN (SELECT object_name
              FROM user_objects o
             WHERE object_type = 'VIEW'
               AND o.object_name IN ('LOGGER_LOG_5_MIN'
                                    )
           )
  LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP VIEW ' || c.object_name;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE (c.object_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

prompt
prompt Drop tables...
rem |--------------------------------------------------------------------------|
rem |                          Drop tables                                     |
rem |--------------------------------------------------------------------------|
DECLARE
  failure_count_var   PLS_INTEGER := 0;
  previous_count_var  PLS_INTEGER := 0;
BEGIN
  LOOP
    FOR c IN (SELECT object_name
                FROM user_objects
               WHERE object_type = 'TABLE'
                 AND object_name IN ('LOGGER_LOG', 'LOGGER_TIMER_CFG'
                                    )
             )
    LOOP
      BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE ' || c.object_name || ' CASCADE CONSTRAINTS PURGE';
      EXCEPTION
        WHEN OTHERS THEN
          failure_count_var := failure_count_var + 1;
      END;
    END LOOP;
    IF failure_count_var >= 0 THEN
      IF failure_count_var = previous_count_var THEN
        EXIT;
      ELSE
        previous_count_var := failure_count_var;
        failure_count_var := 0;
      END IF;
    END IF;
  END LOOP;
END;
/

prompt
prompt Drop contexts...
rem |--------------------------------------------------------------------------|
rem |                          Drop contexts                                   |
rem |--------------------------------------------------------------------------|
DECLARE
  obj_not_exisis EXCEPTION;
  PRAGMA EXCEPTION_INIT(obj_not_exisis, -04043);
BEGIN
  EXECUTE IMMEDIATE 'DROP CONTEXT ctx_logger';
EXCEPTION
  WHEN obj_not_exisis THEN
    NULL;
  WHEN OTHERS THEN
    RAISE;
END;
/
