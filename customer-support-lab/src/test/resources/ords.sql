-- Enable ORDS AutoREST support for the application
-- The ticket_dv JSON Relational Duality View is exposed for REST access.

begin
   ords.enable_schema(
      p_enabled             => true,
      p_schema              => 'TESTUSER',
      p_url_mapping_type    => 'BASE_PATH',
      p_url_mapping_pattern => 'support',
      p_auto_rest_auth      => false
   );
commit;
end;
/

begin
   ords.enable_object(
      p_enabled      => true,
      p_schema       => 'TESTUSER',
      p_object       => 'TICKET_DV',
      p_object_type  => 'VIEW',
      p_object_alias => 'ticket'
   );
commit;
end;
/