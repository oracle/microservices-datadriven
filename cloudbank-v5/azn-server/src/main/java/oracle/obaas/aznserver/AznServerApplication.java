// Copyright (c) 2023, 2026, Oracle and/or its affiliates.

package oracle.obaas.aznserver;

import java.util.Optional;

import lombok.extern.slf4j.Slf4j;
import oracle.obaas.aznserver.model.User;
import oracle.obaas.aznserver.repository.UserRepository;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

@Slf4j
@SpringBootApplication
@EnableDiscoveryClient
public class AznServerApplication {

    private static final String OBAAS_ADMIN = "obaas-admin";
    private static final String OBAAS_USER = "obaas-user";
    private static final String OBAAS_CONFIG = "obaas-config";

    public static void main(String[] args) {
        SpringApplication.run(AznServerApplication.class, args);
    }

    @Bean
    @ConditionalOnProperty(prefix = "azn.bootstrap-users", name = "enabled", havingValue = "true",
            matchIfMissing = true)
    ApplicationRunner userStoreInitializer(UserRepository users, PasswordEncoder passwordEncoder,
            @Value("${azn.bootstrap-users.admin-password:}") String adminPassword,
            @Value("${azn.bootstrap-users.user-password:}") String userPassword) {
        return args -> initUserStore(users, passwordEncoder, adminPassword, userPassword);
    }

    /**
     * Initialize the user store with our required admin users and roles. If the
     * users already
     * exits the users will not be created. The following users are created:
     * obaas-admin, obaas-config and obaas-user
     * 
     * The initial passwords come from external configuration.
     * 
     * @param users The user repository.
     * @param encoder The password encoder for initial password hashes.
     * @param adminPassword The initial admin password.
     * @param userPassword The initial user/config-editor password.
     */
    public static void initUserStore(UserRepository users, PasswordEncoder encoder,
            String adminPassword, String userPassword) {
        log.debug("ENTER initUserStore");

        String obaasAdminPwd = adminPassword;
        String obaasUserPwd = userPassword;
        String obaasConfigPwd = obaasUserPwd;

        // Check for obaas-user, if not existent create the user
        if (users.findByUsername(OBAAS_USER).isEmpty()) {
            log.debug("Creating user obaas-user");

            obaasUserPwd = bootstrapPassword("azn.bootstrap-users.user-password", obaasUserPwd);

            users.saveAndFlush(new User(OBAAS_USER, encoder.encode(obaasUserPwd),
                    "ROLE_USER"));
        }

        // Check for obaas-admin, if not existent create the user
        Optional<User> adminUser = users.findByUsername(OBAAS_ADMIN);
        if (adminUser.isEmpty()) {
            log.debug("Creating user obaas-admin");

            obaasAdminPwd = bootstrapPassword("azn.bootstrap-users.admin-password", obaasAdminPwd);

            users.saveAndFlush(new User(OBAAS_ADMIN, encoder.encode(obaasAdminPwd),
                    "ROLE_ADMIN,ROLE_CONFIG_EDITOR,ROLE_USER"));
        }

        // Check for obaas-config, if not existent create the user with the same pwd as
        // obaas-user
        if (users.findByUsernameIgnoreCase(OBAAS_CONFIG).isEmpty()) {
            log.debug("Creating user obaas-config");

            obaasConfigPwd = bootstrapPassword("azn.bootstrap-users.user-password", obaasConfigPwd);

            users.saveAndFlush(new User(OBAAS_CONFIG, encoder.encode(obaasConfigPwd),
                    "ROLE_CONFIG_EDITOR,ROLE_USER"));
        }
    }

    private static String bootstrapPassword(String propertyName, String configuredPassword) {
        if (StringUtils.isNotBlank(configuredPassword)) {
            return configuredPassword;
        }
        throw new IllegalStateException(propertyName + " must be set when azn.bootstrap-users.enabled=true");
    }

}
