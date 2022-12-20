-- Copyright (c) 2022, Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

INSERT INTO CONFIGSERVER.PROPERTIES(APPLICATION, PROFILE, LABEL, PROP_KEY, "VALUE")
VALUES ('notification', 'kube', 'latest', 'spring.datasource.url', 'jdbc:oracle:thin:@<DATABASE SERVICE>?TNS_ADMIN=/oracle/tnsadmin');

INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE)
VALUES ('notification', 'kube', 'latest', 'spring.datasource.driver-class-name', 'oracle.jdbc.OracleDriver');

COMMIT;