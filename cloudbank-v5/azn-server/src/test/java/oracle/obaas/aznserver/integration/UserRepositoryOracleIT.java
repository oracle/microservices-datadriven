// Copyright (c) 2026, Oracle and/or its affiliates.

package oracle.obaas.aznserver.integration;

import oracle.obaas.aznserver.model.User;
import oracle.obaas.aznserver.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@TestPropertySource(properties = "azn.authorization-server.default-client.enabled=true")
class UserRepositoryOracleIT extends OracleIntegrationTestSupport {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private UserRepository userRepository;

    @DynamicPropertySource
    static void oracleProperties(DynamicPropertyRegistry registry) {
        configureOracleProperties(registry);
    }

    @Test
    void liquibaseCreatesUsersTableAndStartupUsers() {
        String currentUser = jdbcTemplate.queryForObject(
                "select sys_context('USERENV', 'CURRENT_USER') from dual", String.class);
        String proxyUser = jdbcTemplate.queryForObject(
                "select sys_context('USERENV', 'PROXY_USER') from dual", String.class);
        Integer userCount = jdbcTemplate.queryForObject("select count(*) from USERS", Integer.class);

        assertThat(currentUser).isEqualTo("USER_REPO");
        assertThat(proxyUser).isNull();
        assertThat(userCount).isNotNull();
        assertStoredBcryptPassword("obaas-user", BOOTSTRAP_PASSWORD);
        assertStoredBcryptPassword("obaas-config", BOOTSTRAP_PASSWORD);
        assertThat(userRepository.findByUsername("obaas-admin"))
                .hasValueSatisfying(user -> {
                    assertThat(user.getRoles()).isEqualTo("ROLE_ADMIN,ROLE_CONFIG_EDITOR,ROLE_USER");
                    assertThat(user.getPassword()).isNotEqualTo(BOOTSTRAP_PASSWORD).startsWith("$2");
                    assertThat(passwordEncoder.matches(BOOTSTRAP_PASSWORD, user.getPassword())).isTrue();
                });
    }

    @Test
    void repositoryPersistsAndFindsUsersCaseInsensitively() {
        User saved = userRepository.saveAndFlush(new User(
                "CaseUser",
                passwordEncoder.encode("StrongPass123!"),
                "ROLE_USER",
                "caseuser@example.com"));

        assertThat(saved.getUserId()).isNotNull();
        assertThat(userRepository.findByUsernameIgnoreCase("caseuser"))
                .hasValueSatisfying(user -> assertThat(user.getEmail()).isEqualTo("caseuser@example.com"));
        assertThat(userRepository.findUsersByUsernameStartsWithIgnoreCase("case")).hasSize(1);
        assertThat(userRepository.findByEmailIgnoreCase("CASEUSER@example.com")).isPresent();
    }

    private void assertStoredBcryptPassword(String username, String cleartextPassword) {
        assertThat(userRepository.findByUsername(username))
                .hasValueSatisfying(user -> {
                    assertThat(user.getPassword()).isNotEqualTo(cleartextPassword).startsWith("$2");
                    assertThat(passwordEncoder.matches(cleartextPassword, user.getPassword())).isTrue();
                });
    }
}
