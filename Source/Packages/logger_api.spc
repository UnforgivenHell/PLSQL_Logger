CREATE OR REPLACE PACKAGE logger_api AS
  /**
    * <b>Author</b>  : Sergey Lavrov <br>
    * <b>Created</b> : 01.21.2021 9:39:36 <br>
    * <b>Purpose</b> : Package for working with logging <a href="https://github.com/unforgivenHell/PLSQL_Logger">PLSQL_Logger</a>
  */
  
  -- =======================================================
  /** Type describing the parameter: key (string) - value (string)
    * @param  name   The name of parameter
    * @param  value  String value
  */
  TYPE param_type IS RECORD (
    name               VARCHAR2 (255 CHAR),
    value              VARCHAR2 (4000 CHAR)
  );
  /** Type describes an indexed array of parameters PARAM_TYPE
  */
  TYPE param_tab IS TABLE OF param_type INDEX BY BINARY_INTEGER;
  /** Type describing the timer parameter:
    * @param  start_time   Timer start date in date format TIMESTAMP
    * @param  method_name  Name of the method
    * @param  params       List of parameters. Then PARAM_TAB type is used
    * @param  guid         Unique identifier GUID, used for generating SYS_GUID
  */
  TYPE timer_type IS RECORD (
    start_time         TIMESTAMP,
    scope_name         VARCHAR2 (100 CHAR),
    params             param_tab,
    guid               VARCHAR2 (100 CHAR)
  );
  /** Type describes an indexed array of parameters timer_type
  */
  TYPE timer_tab IS TABLE OF timer_type INDEX BY VARCHAR2 (100 CHAR);
  
  -- =======================================================
  /** Getting package version
    * @return  Package version
  */
  FUNCTION version RETURN VARCHAR2;
  
  -- =======================================================
  /** Getting name of the logging level by identifyer
    * @param  level_id_in  ID of the logging level
    * @return  Name of the current logging level
  */
  FUNCTION get_level_name_by_id (
    level_id_in              IN VARCHAR2
  ) RETURN VARCHAR2;
  /** Getting the name of current logging level
    * @return  Name of the current logging level
  */
  FUNCTION get_level_name RETURN VARCHAR2;
  /** Setting the global logging level
    * @param  level_id_in  ID of the logging level
  */
  PROCEDURE set_global_level (
    level_id_in              IN NUMBER
  );
  /** Setting the session logging level
    * @param  level_id_in  ID of the logging level
  */
  PROCEDURE set_session_level (
    level_id_in              IN NUMBER
  );
  
  -- =======================================================
  /** Converting a number to string
    * @param  value_in  Число которое необходимо преобразовать в строку
    * @return  String with the conversion result
  */
  FUNCTION tochar (
    value_in                 IN NUMBER
  ) RETURN VARCHAR2;
  /** Converting a date to string
    * @param  value_in  Дата которую необходимо преобразовать в строку
    * @return  String with the conversion result
  */
  FUNCTION tochar (
    value_in                 IN DATE
  ) RETURN VARCHAR2;
  /** Converting a boolean variable to string
    * @param  value_in  Булевая переменная которую необходимо преобразовать в строку
    * @return  String with the conversion result
  */
  FUNCTION tochar(
    value_in                 IN BOOLEAN
  ) RETURN VARCHAR2;
  /** Converting a TIMESTAMP to string
    * @param  value_in  TIMESTAMP который необходимо преобразовать в строку
    * @return  String with the conversion result
  */
  FUNCTION tochar (
    value_in                 IN TIMESTAMP
  )  RETURN VARCHAR2;
  
  -- =======================================================
  /** Adding a string variable to array
    * @param  params_io       Array of parameters
    * @param  param_name_in   Наименование параметра
    * @param  param_value_in  String value of the parameteer
  */
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN VARCHAR2
  );
  /** Adding a number variable to array
    * @param  params_io       Array of parameters
    * @param  param_name_in   Name of the parameter
    * @param  param_value_in  Number value of the parameteer
  */
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN NUMBER
  );
  /** Adding a date variable to array
    * @param  params_io       Array of parameters
    * @param  param_name_in   Name of the parameter
    * @param  param_value_in  Date value of the parameteer
  */
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN DATE
  );
  /** Adding a boolean variable to array
    * @param  params_io       Array of parameters
    * @param  param_name_in   Name of the parameter
    * @param  param_value_in  Boolean value of the parameteer
  */
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN BOOLEAN
  );
  /** Adding a timestamp variable to array
    * @param  params_io       Array of parameters
    * @param  param_name_in   Name of the parameter
    * @param  param_value_in  Timestamp value of the parameteer
  */
  PROCEDURE append_param (
    params_io                IN OUT NOCOPY param_tab,
    param_name_in            IN VARCHAR2,
    param_value_in           IN TIMESTAMP
  );
  
  -- =======================================================
  /** Converting an array of parameters to clob
    * @param  params_in  Array of parameters
    * @return  CLOB with an array of parameters
  */
  FUNCTION convert_param_to_clob (
    params_in                IN param_tab
  ) RETURN CLOB;
  /** Converting an array of parameters to xml
    * @param  params_in  Array of parameters
    * @return  XMLTYPE with an array of parameters
  */
  FUNCTION convert_param_to_xml (
    params_in                IN param_tab
  ) RETURN XMLTYPE;
  
  -- =======================================================
  /** Adding a log with the type FATAL
    * @param  scope_name_in  Name of the scope
    * @param  text_in        The text of the message
  */
  PROCEDURE log_fatal (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  );
  /** Adding a log with the type ERROR
    * @param  scope_name_in  Name of the scope
    * @param  text_in        The text of the message
  */
  PROCEDURE log_error (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  );
  /** Adding a log with the type WARNING
    * @param  scope_name_in  Name of the scope
    * @param  text_in        The text of the message
  */
  PROCEDURE log_warning (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  );
  /** Adding a log with the type INFO
    * @param  scope_name_in  Name of the scope
    * @param  text_in        The text of the message
  */
  PROCEDURE log_info (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  );
  /** Adding a log with the type DEBUG
    * @param  scope_name_in  Name of the scope
    * @param  text_in        The text of the message
  */
  PROCEDURE log_debug (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  );
  /** Adding a log with the type TRACE
    * @param  scope_name_in  Name of the scope
    * @param  text_in        The text of the message
  */
  PROCEDURE log_trace (
    scope_name_in            IN VARCHAR2,
    text_in                  IN VARCHAR2
  );
  
  -- =======================================================
  /** Starting the timer
    * @param  scope_name_in  Name of the scope
    * @param  timer_out      The resulting parameters of the timer
  */
  PROCEDURE timer_start (
    scope_name_in            IN VARCHAR2,
    timer_out                OUT timer_type
  );
  /** Finalizing the timer
    * @param  timer_in  Data with timer parameters
  */
  PROCEDURE timer_stop (
    timer_in                 IN timer_type
  );
  
  -- =======================================================
  /** Getting the DISABLE logging level ID
    * @return ID of the DISABLE logging level
  */
  FUNCTION get_level_disable_id RETURN NUMBER;
  /** Getting the FATAL logging level ID
    * @return ID of the FATAL logging level
  */
  FUNCTION get_level_fatal_id RETURN NUMBER;
  /** Getting the ERROR logging level ID
    * @return ID of the ERROR logging level
  */
  FUNCTION get_level_error_id RETURN NUMBER;
  /** Getting the WARNING logging level ID
    * @return ID of the WARNING logging level
  */
  FUNCTION get_level_warning_id RETURN NUMBER;
  /** Getting the INFO logging level ID
    * @return ID of the INFO logging level
  */
  FUNCTION get_level_info_id RETURN NUMBER;
  /** Getting the DEBUG logging level ID
    * @return ID of the DEBUG logging level
  */
  FUNCTION get_level_debug_id RETURN NUMBER;
  /** Getting the TRACE logging level ID
    * @return ID of the TRACE logging level
  */
  FUNCTION get_level_trace_id RETURN NUMBER;
  /** Getting the TIMER logging level ID
    * @return ID of the TIMER logging level
  */
  FUNCTION get_level_timer_id RETURN NUMBER;
END logger_api;
/
