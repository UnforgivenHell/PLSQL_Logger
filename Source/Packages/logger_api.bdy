CREATE OR REPLACE PACKAGE BODY logger_api AS

  gc_line_feed               CONSTANT VARCHAR2(1) := chr(10);
  -- Constraints date format
  gc_format_date             CONSTANT VARCHAR2(255) := 'DD.MM.YYYY';
  gc_format_date_time        CONSTANT VARCHAR2(255) := gc_format_date || ' HH24:MI:SS';
  gc_format_timestamp        CONSTANT VARCHAR2(255) := gc_format_date_time || ':FF';

  -- =======================================================
  -- Constraints of the id loggging levels
  gc_level_disable_id        CONSTANT PLS_INTEGER := 0; -- disable
  gc_level_fatal_id          CONSTANT PLS_INTEGER := 1; -- fatal
  gc_level_error_id          CONSTANT PLS_INTEGER := 2; -- fatal, error
  gc_level_warning_id        CONSTANT PLS_INTEGER := 3; -- fatal, error, warning
  gc_level_info_id           CONSTANT PLS_INTEGER := 4; -- fatal, error, warning, info
  gc_level_debug_id          CONSTANT PLS_INTEGER := 5; -- fatal, error, warning, info, debug
  gc_level_trace_id          CONSTANT PLS_INTEGER := 6; -- fatal, error, warning, info, debug, trace
  gc_level_timer_id          CONSTANT PLS_INTEGER := 7; -- timer

  -- Global variables with session parameters
  gv_session_sid              INTEGER;
  gv_session_serial           INTEGER;
  gv_session_machine          VARCHAR2(64);
  gv_session_osuser           VARCHAR2(64);

  gv_session_level_id         NUMBER;

  -- Getting package version
  FUNCTION version RETURN VARCHAR2 AS
  BEGIN
    --| Version  | Date       | Author           | Description
    --|----------|------------|------------------|--------------------------
    --| 01.01.01 | 21.01.2021 | Sergey Lavrov    | Created
    RETURN '01.01.01';
  END version;

  -- =======================================================
  -- Check the logging level ID
  PROCEDURE check_level_id (
    level_id_in             IN NUMBER
  ) AS
  BEGIN
    IF level_id_in IS NULL THEN
      raise_application_error (-20001, 'The logging level ID cannot be empty');
    ELSIF level_id_in NOT IN (gc_level_disable_id, gc_level_fatal_id, gc_level_error_id, gc_level_warning_id,
                              gc_level_info_id, gc_level_debug_id, gc_level_trace_id, gc_level_timer_id
                             )
    THEN
      raise_application_error (-20001, 'Incorrect input logging level id');
    END IF;
  END check_level_id;
  -- Setting the global logging level
  PROCEDURE set_global_level (
    level_id_in              IN NUMBER
  ) AS
  BEGIN
    check_level_id (
      level_id_in => level_id_in
    );
    -- Setting context with global logging level
    dbms_session.set_context (
      namespace => 'CTX_LOGGER',
      attribute => 'LEVEL',
      value     => level_id_in
    );
  END set_global_level;
  -- Setting the session logging level
  PROCEDURE set_session_level (
    level_id_in              IN NUMBER
  ) AS
  BEGIN
    check_level_id (
      level_id_in => level_id_in
    );
    -- If disabled session logging level then set null
    gv_session_level_id := CASE level_id_in
                             WHEN gc_level_disable_id THEN NULL
                             ELSE level_id_in
                           END;
  END set_session_level;
  -- Setting the default logging level
  FUNCTION set_default_logging_level RETURN NUMBER AS
    v_ret                    NUMBER;
  BEGIN
    -- If then debug flag is set then set the DEBUG level, otherwise FATAL
    $IF $$debug $THEN
      v_ret := gc_level_debug_id;
    $ELSE
      v_ret := gc_level_fatal_id;
    $END
    set_global_level (
      level_id_in => v_ret
    );
    RETURN v_ret;
  END set_default_logging_level;
  -- Getting name of the logging level by identifyer
  FUNCTION get_level_name_by_id (
    level_id_in              IN VARCHAR2
  ) RETURN VARCHAR2 AS
    v_name_list SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('OFF', 'FATAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG', 'TRACE', 'TIMER');
  BEGIN
    RETURN v_name_list (level_id_in + 1);
  END get_level_name_by_id;
  -- Getting the logging level
  FUNCTION get_level RETURN NUMBER AS
  BEGIN
    RETURN coalesce ( gv_session_level_id, sys_context ('CTX_LOGGER', 'LEVEL'), set_default_logging_level );
  END get_level;
  -- Getting the name of current logging level
  FUNCTION get_level_name RETURN VARCHAR2 AS
  BEGIN
    RETURN get_level_name_by_id (level_id_in => get_level);
  END get_level_name;

  -- =======================================================
  -- Converting a number to string
  FUNCTION tochar (
    value_in                 IN NUMBER
  ) RETURN VARCHAR2 AS
    lc_abs_values      CONSTANT NUMBER := abs(value_in);
  BEGIN
    RETURN CASE
             WHEN lc_abs_values < 1 THEN CASE WHEN value_in < 0 THEN '-' ELSE '' END || '0' || to_char(lc_abs_values)
             ELSE to_char(value_in)
           END;
  END tochar;
  -- Converting a date to string
  FUNCTION tochar (
    value_in                 IN DATE
  ) RETURN VARCHAR2 AS
  BEGIN
    RETURN CASE
             WHEN value_in = trunc(value_in) THEN to_char(value_in, gc_format_date)
             ELSE to_char(value_in, gc_format_date_time)
           END;
  END tochar;
  -- Converting a boolean variable to string
  FUNCTION tochar (
    value_in                 IN BOOLEAN
  ) RETURN VARCHAR2 AS
  BEGIN
    RETURN CASE value_in WHEN TRUE THEN 'TRUE' WHEN FALSE THEN 'FALSE' ELSE 'NULL' END;
  END tochar;
  -- Converting a TIMESTAMP to string
  FUNCTION tochar (
    value_in                 IN TIMESTAMP
  ) RETURN VARCHAR2 AS
  BEGIN
    RETURN to_char(value_in, gc_format_timestamp);
  END tochar;

  -- =======================================================
  -- Adding a string variable to array
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN VARCHAR2
  ) AS
    v_param            param_type;
  BEGIN
    v_param.name  := param_name_in;
    v_param.value := param_value_in;
    params_io(params_io.count + 1) := v_param;
  END append_param;
  -- Adding a number variable to array
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN NUMBER
  ) AS
  BEGIN
    append_param (params_io      => params_io,
                  param_name_in  => param_name_in,
                  param_value_in => tochar (value_in => param_value_in)
                 );
  END append_param;
  -- Adding a date variable to array
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN DATE
  ) AS
  BEGIN
    append_param (params_io      => params_io,
                  param_name_in  => param_name_in,
                  param_value_in => tochar (value_in => param_value_in)
                 );
  END append_param;
  -- Adding a boolean variable to array
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN BOOLEAN
  ) AS
  BEGIN
    append_param (params_io      => params_io,
                  param_name_in  => param_name_in,
                  param_value_in => tochar (value_in => param_value_in)
                 );
  END append_param;
  -- Adding a timestamp variable to array
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN TIMESTAMP
  ) AS
  BEGIN
    append_param (params_io      => params_io,
                  param_name_in  => param_name_in,
                  param_value_in => tochar (value_in => param_value_in)
                 );
  END append_param;

  -- =======================================================
  -- Converting an array of parameters to clob
  FUNCTION convert_param_to_clob (
    params_in                IN param_tab
  ) RETURN CLOB AS
    v_ret              CLOB;
    v_count            NUMBER;
  BEGIN
    IF params_in IS NOT NULL THEN
      v_count := params_in.count;
      FOR c IN 1 .. v_count LOOP
        IF c = 1 THEN
          dbms_lob.createtemporary (lob_loc => v_ret,
                                    cache   => FALSE
                                   );
        END IF;
        dbms_lob.append(v_ret, params_in(c).name || ': ' || params_in(c).value || CASE WHEN c != v_count THEN gc_line_feed ELSE '' END);
      END LOOP;
    END IF;

    RETURN v_ret;
  END convert_param_to_clob;
  -- Converting an array of parameters to xml
  FUNCTION convert_param_to_xml (
    params_in                IN param_tab
  ) RETURN XMLTYPE AS
    v_ret              XMLTYPE;
    v_domdoc           DBMS_XMLDOM.DOMDOCUMENT;
    v_root_node        DBMS_XMLDOM.DOMNODE;
    v_params_node      DBMS_XMLDOM.DOMNODE;
    v_param_element    DBMS_XMLDOM.DOMELEMENT;
    v_param_node       DBMS_XMLDOM.DOMNODE;
  BEGIN
    -- Creating new XML document
    v_domdoc := dbms_xmldom.newdomdocument;

    -- Creating root element
    v_root_node   := dbms_xmldom.makenode (v_domdoc);
    v_params_node := dbms_xmldom.appendchild (v_root_node, dbms_xmldom.makeNode (dbms_xmldom.createelement (v_domdoc, 'params')));

    FOR c IN (SELECT name, value
                FROM TABLE (params_in)
             )
    LOOP
      -- Adding parameters
      v_param_element := dbms_xmldom.createelement( v_domdoc, 'param');
      dbms_xmldom.setattribute (v_param_element, 'name', c.name);
      v_param_node := dbms_xmldom.appendchild (v_params_node, dbms_xmldom.makeNode(v_param_element));

      dbms_xmldom.setattribute (v_param_element, 'value', c.value);
      v_param_node := dbms_xmldom.appendchild (v_params_node, dbms_xmldom.makeNode(v_param_element));
    END LOOP;

    v_ret := dbms_xmldom.getXmlType (v_domdoc);
    dbms_xmldom.freeDocument (v_domdoc);

    RETURN v_ret;
  END convert_param_to_xml;
  -- =======================================================
  -- Check that the timer is enable for method
  FUNCTION timer_enabled (
    scope_name_in           IN VARCHAR2
  ) RETURN BOOLEAN RESULT_CACHE AS
    v_res              logger_timer_cfg.status%TYPE;
  BEGIN
    SELECT nvl(max(c.status), 0) INTO v_res
      FROM logger_timer_cfg c
     WHERE c.scope_name = scope_name_in;
    RETURN ( v_res = 1 );
  END timer_enabled;
  -- Check that this logging level is enabled
  FUNCTION level_log_enabled (
    log_level_in             IN NUMBER
  ) RETURN BOOLEAN AS
    v_ret              BOOLEAN := FALSE;
  BEGIN
    IF log_level_in <= get_level THEN
      v_ret := TRUE;
    END IF;
    RETURN v_ret;
  END level_log_enabled;
  -- Saving log to table
  PROCEDURE ins_log (
    log_level_id_in          IN NUMBER,
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2 DEFAULT NULL,
    params_in                IN XMLTYPE DEFAULT NULL,
    oper_duration_in         IN INTERVAL DAY TO SECOND DEFAULT NULL
  ) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_call_stack       VARCHAR2(4000 CHAR);
  BEGIN
    -- If this is a timer or an acceptable logging level then save the information
    IF log_level_id_in = get_level_timer_id OR level_log_enabled(log_level_in => log_level_id_in) THEN
      -- If logging level DEBUG, TIMER или FATAL, then save CALL STACK (maximum 3900 characters)
      IF log_level_id_in IN (get_level_debug_id, get_level_fatal_id) THEN
        v_call_stack := substr(dbms_utility.format_call_stack, 1 , 3900);
      END IF;

      INSERT INTO logger_log (log_level_id, scope_name, error_text, sid, serial#, osuser, machine, call_stack, params, oper_duration)
      VALUES (log_level_id_in, scope_name_in, text_in, gv_session_sid, gv_session_serial, gv_session_osuser, gv_session_machine, v_call_stack, params_in, oper_duration_in);
      COMMIT;
    END IF;
  END ins_log;
  -- Adding a log with the type FATAL
  PROCEDURE log_fatal (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  ) AS
  BEGIN
    ins_log (
      log_level_id_in => gc_level_fatal_id,
      scope_name_in   => scope_name_in,
      text_in         => text_in
    );
  END log_fatal;
  -- Adding a log with the type ERROR
  PROCEDURE log_error (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  ) AS
  BEGIN
    ins_log (
      log_level_id_in => gc_level_error_id,
      scope_name_in   => scope_name_in,
      text_in         => text_in
    );
  END log_error;
  -- Adding a log with the type WARNING
  PROCEDURE log_warning (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  ) AS
  BEGIN
    ins_log (
      log_level_id_in => gc_level_warning_id,
      scope_name_in   => scope_name_in,
      text_in         => text_in
    );
  END log_warning;
  -- Adding a log with the type INFO
  PROCEDURE log_info (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  ) AS
  BEGIN
    ins_log (
      log_level_id_in => gc_level_info_id,
      scope_name_in   => scope_name_in,
      text_in         => text_in
    );
  END log_info;
  -- Adding a log with the type DEBUG
  PROCEDURE log_debug (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  ) AS
  BEGIN
    ins_log (
      log_level_id_in => gc_level_debug_id,
      scope_name_in   => scope_name_in,
      text_in         => text_in
    );
  END log_debug;
  -- Adding a log with the type TRACE
  PROCEDURE log_trace (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  ) AS
  BEGIN
    ins_log (
      log_level_id_in => gc_level_trace_id,
      scope_name_in   => scope_name_in,
      text_in         => text_in
    );
  END log_trace;

  -- =======================================================
  -- Starting the timer
  PROCEDURE timer_start (
    scope_name_in            IN VARCHAR2,
    timer_out                OUT timer_type
  ) AS
  BEGIN
    -- Chech whether the timer is enabled for the method or not
    IF timer_enabled (scope_name_in => scope_name_in) THEN
      timer_out.start_time := systimestamp;
      timer_out.scope_name := scope_name_in;
      timer_out.guid       := SYS_GUID();
      ins_log (
        log_level_id_in => gc_level_timer_id,
        scope_name_in   => timer_out.scope_name,
        text_in         => 'START: ' || timer_out.guid
      );
    END IF;
  END timer_start;
  -- Finalizing the timer
  PROCEDURE timer_stop (
    timer_in                 IN timer_type
  ) AS
    v_timer_stop       TIMESTAMP := systimestamp;
  BEGIN
    IF timer_in.scope_name IS NOT NULL THEN
      ins_log (
        log_level_id_in  => gc_level_timer_id,
        scope_name_in    => timer_in.scope_name,
        text_in          => 'STOP: ' || timer_in.guid,
        params_in        => convert_param_to_xml (params_in => timer_in.params),
        oper_duration_in => v_timer_stop - timer_in.start_time
      );
    END IF;
  END timer_stop;

  -- =======================================================
  -- Getting the DISABLE logging level ID
  FUNCTION get_level_disable_id RETURN NUMBER AS
  BEGIN
    RETURN logger_api.gc_level_disable_id;
  END get_level_disable_id;
  -- Getting the FATAL logging level ID
  FUNCTION get_level_fatal_id RETURN NUMBER AS
  BEGIN
    RETURN logger_api.gc_level_fatal_id;
  END get_level_fatal_id;
  -- Getting the ERROR logging level ID
  FUNCTION get_level_error_id RETURN NUMBER AS
  BEGIN
    RETURN logger_api.gc_level_error_id;
  END get_level_error_id;
  -- Getting the WARNING logging level ID
  FUNCTION get_level_warning_id RETURN NUMBER AS
  BEGIN
    RETURN logger_api.gc_level_warning_id;
  END get_level_warning_id;
  -- Getting the INFO logging level ID
  FUNCTION get_level_info_id RETURN NUMBER AS
  BEGIN
    RETURN logger_api.gc_level_info_id;
  END get_level_info_id;
  -- Getting the DEBUG logging level ID
  FUNCTION get_level_debug_id RETURN NUMBER AS
  BEGIN
    RETURN logger_api.gc_level_debug_id;
  END get_level_debug_id;
  -- Getting the TRACE logging level ID
  FUNCTION get_level_trace_id RETURN NUMBER AS
  BEGIN
    RETURN logger_api.gc_level_trace_id;
  END get_level_trace_id;
  -- Getting the TIMER logging level ID
  FUNCTION get_level_timer_id RETURN NUMBER AS
  BEGIN
    RETURN logger_api.gc_level_timer_id;
  END get_level_timer_id;

BEGIN
  -- Initiakizing variables that do not change in the session
  SELECT t.sid, t.serial#, t.machine, t.osuser
    INTO gv_session_sid, gv_session_serial, gv_session_machine, gv_session_osuser
    FROM v$session t
   WHERE audsid = sys_context ('USERENV', 'SESSIONID');
END logger_api;
/
