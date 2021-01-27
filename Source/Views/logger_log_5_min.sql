create or replace view logger_log_5_min as
select l.log_date,
       logger_api.get_level_name_by_id(level_id_in => l.log_level_id) AS log_level_name,
       l.scope_name,
       l.error_text,
       l.sid,
       l.serial#,
       l.machine,
       l.call_stack,
       CASE l.log_level_id
         WHEN logger_api.get_level_timer_id THEN l.params.getStringVal()
         ELSE ''
       END AS str_params,
       l.params AS xml_params,
       l.oper_duration
  from logger_log l
 where log_date > systimestamp - INTERVAL '5' MINUTE
ORDER BY  l.log_date DESC;
/
