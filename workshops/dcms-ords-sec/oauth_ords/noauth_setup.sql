BEGIN
      ORDS.CREATE_SERVICE(
         P_MODULE_NAME    => 'examples.employees' 
        ,P_BASE_PATH      => '/examples/employees/'
        ,P_PATTERN        =>  '.' 
        ,P_ITEMS_PER_PAGE => 7
        ,P_SOURCE         =>  'SELECT * FROM EMP ORDER BY EMPNO DESC'
      );
      COMMIT;
    EXCEPTION WHEN DUP_VAL_ON_INDEX THEN 
      DBMS_OUTPUT.PUT_LINE('Service already exists');
    END;
    /

SELECT id, name, uri_prefix
      FROM user_ords_modules
     ORDER BY name;

SELECT id, module_id, uri_template
      FROM user_ords_templates
     ORDER BY module_id;

SELECT id, template_id, source_type, method, source
      FROM user_ords_handlers
     ORDER BY id;