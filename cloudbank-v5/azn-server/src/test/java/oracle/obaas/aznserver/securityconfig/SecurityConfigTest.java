// Copyright (c) 2026, Oracle and/or its affiliates.

package oracle.obaas.aznserver.securityconfig;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.Base64;

import com.nimbusds.jose.jwk.JWKMatcher;
import com.nimbusds.jose.jwk.JWKSelector;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;

import static org.assertj.core.api.Assertions.assertThat;

class SecurityConfigTest {

    @TempDir
    private Path tempDir;

    @Test
    void defaultClientUsesCloudBankClientAndScopes() {
        SecurityConfig securityConfig = new SecurityConfig();
        RegisteredClientRepository repository = securityConfig.localRegisteredClientRepository(
                new BCryptPasswordEncoder(), "cloudbank-client", "TestClientSecret123!",
                "http://127.0.0.1:8080/login/oauth2/code/cloudbank-client",
                "openid,cloudbank.read,cloudbank.transfer",
                "cloudbank-service-client", "ServiceClientSecret123!", "cloudbank.internal",
                "cloudbank-test-client", "TestOnlyClientSecret123!", "cloudbank.test",
                "cloudbank-admin-client", "AdminClientSecret123!", "cloudbank.admin");

        RegisteredClient client = repository.findByClientId("cloudbank-client");
        RegisteredClient serviceClient = repository.findByClientId("cloudbank-service-client");
        RegisteredClient testClient = repository.findByClientId("cloudbank-test-client");
        RegisteredClient adminClient = repository.findByClientId("cloudbank-admin-client");

        assertThat(client).isNotNull();
        assertThat(client.getScopes()).contains(
                "openid",
                "cloudbank.read",
                "cloudbank.transfer");
        assertThat(client.getScopes()).doesNotContain(
                "cloudbank.admin",
                "cloudbank.internal",
                "cloudbank.test",
                "azn.users.admin");
        assertThat(serviceClient).isNotNull();
        assertThat(serviceClient.getScopes()).containsExactlyInAnyOrder("cloudbank.internal");
        assertThat(testClient).isNotNull();
        assertThat(testClient.getScopes()).containsExactlyInAnyOrder("cloudbank.test");
        assertThat(adminClient).isNotNull();
        assertThat(adminClient.getScopes()).containsExactlyInAnyOrder("cloudbank.admin");
    }

    @Test
    void persistentJwkSourceLoadsMountedPemKeys() throws Exception {
        SecurityConfig securityConfig = new SecurityConfig();
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        KeyPair keyPair = generator.generateKeyPair();
        Path privateKey = tempDir.resolve("private.pem");
        Path publicKey = tempDir.resolve("public.pem");

        Files.writeString(privateKey, pem("PRIVATE KEY", keyPair.getPrivate().getEncoded()),
                StandardCharsets.UTF_8);
        Files.writeString(publicKey, pem("PUBLIC KEY", keyPair.getPublic().getEncoded()),
                StandardCharsets.UTF_8);

        JWKSelector selector = new JWKSelector(new JWKMatcher.Builder()
                .keyID("test-key")
                .build());

        assertThat(securityConfig.persistentJwkSource(privateKey.toString(), publicKey.toString(), "test-key")
                .get(selector, null))
                .hasSize(1);
    }

    private static String pem(String type, byte[] encoded) {
        return "-----BEGIN " + type + "-----\n"
                + Base64.getMimeEncoder(64, "\n".getBytes(StandardCharsets.UTF_8)).encodeToString(encoded)
                + "\n-----END " + type + "-----\n";
    }
}
