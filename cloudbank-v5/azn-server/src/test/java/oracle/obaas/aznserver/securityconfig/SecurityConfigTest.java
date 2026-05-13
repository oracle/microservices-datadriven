// Copyright (c) 2026, Oracle and/or its affiliates.

package oracle.obaas.aznserver.securityconfig;

import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;

import static org.assertj.core.api.Assertions.assertThat;

class SecurityConfigTest {

    @Test
    void defaultClientUsesCloudBankClientAndScopes() {
        SecurityConfig securityConfig = new SecurityConfig();
        RegisteredClientRepository repository = securityConfig.localRegisteredClientRepository(
                new BCryptPasswordEncoder(), "cloudbank-client", "TestClientSecret123!",
                "http://127.0.0.1:8080/login/oauth2/code/cloudbank-client",
                "openid,cloudbank.read,cloudbank.transfer,cloudbank.internal,cloudbank.test,azn.users.admin");

        RegisteredClient client = repository.findByClientId("cloudbank-client");

        assertThat(client).isNotNull();
        assertThat(client.getScopes()).contains(
                "openid",
                "cloudbank.read",
                "cloudbank.transfer",
                "cloudbank.internal",
                "cloudbank.test",
                "azn.users.admin");
    }
}
