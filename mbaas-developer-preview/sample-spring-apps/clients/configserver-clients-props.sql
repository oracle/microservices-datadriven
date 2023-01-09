INSERT INTO CONFIGSERVER.PROPERTIES(APPLICATION, PROFILE, LABEL, PROP_KEY, "VALUE")
VALUES ('clients', 'kube', 'latest', 'clients.customer.url', 'http://customer:8080');

INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE)
VALUES ('clients', 'kube', 'latest', 'clients.fraud.url', 'http://fraud:8081');

INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE)
VALUES ('clients', 'kube', 'latest', 'clients.notification.url', 'http://notification:8088');

COMMIT;
