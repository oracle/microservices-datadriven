// Copyright (c) 2026, Oracle and/or its affiliates.

package com.example.common.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.autoconfigure.security.servlet.EndpointRequest;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication.Type;
import org.springframework.context.annotation.Bean;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@AutoConfiguration
@ConditionalOnClass(SecurityFilterChain.class)
@ConditionalOnWebApplication(type = Type.SERVLET)
public class CloudBankSecurityAutoConfiguration {

    private static final String READ_SCOPE = "SCOPE_cloudbank.read";
    private static final String WRITE_SCOPE = "SCOPE_cloudbank.write";
    private static final String ADMIN_SCOPE = "SCOPE_cloudbank.admin";
    private static final String TRANSFER_SCOPE = "SCOPE_cloudbank.transfer";
    private static final String INTERNAL_SCOPE = "SCOPE_cloudbank.internal";
    private static final String TEST_SCOPE = "SCOPE_cloudbank.test";

    /**
     * Shared CloudBank HTTP security policy.
     *
     * @param http Spring Security HTTP configuration.
     * @param securityEnabled enables OAuth2 resource server authorization.
     * @param requireInternalToken protects internal service callback endpoints.
     * @return configured security filter chain.
     * @throws Exception when the filter chain cannot be built.
     */
    @Bean
    @ConditionalOnMissingBean(SecurityFilterChain.class)
    public SecurityFilterChain cloudBankSecurityFilterChain(HttpSecurity http,
            @Value("${cloudbank.security.enabled:false}") boolean securityEnabled,
            @Value("${cloudbank.security.require-internal-token:false}") boolean requireInternalToken)
            throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        if (!securityEnabled) {
            http.authorizeHttpRequests(authorize -> authorize.anyRequest().permitAll());
            return http.build();
        }

        http
            .authorizeHttpRequests(authorize -> {
                authorize
                    .requestMatchers(EndpointRequest.to("health", "info", "prometheus")).permitAll()
                    .requestMatchers("/error", "/error/**").permitAll();

                if (requireInternalToken) {
                    authorizeInternalEndpoints(authorize, INTERNAL_SCOPE);
                } else {
                    permitInternalEndpoints(authorize);
                }

                authorize
                    .requestMatchers(HttpMethod.GET, "/api/v1/accounts").hasAuthority(READ_SCOPE)
                    .requestMatchers(HttpMethod.GET, "/api/v1/account/**").hasAuthority(READ_SCOPE)
                    .requestMatchers(HttpMethod.POST, "/api/v1/account").hasAuthority(WRITE_SCOPE)
                    .requestMatchers(HttpMethod.DELETE, "/api/v1/account/**").hasAuthority(ADMIN_SCOPE)
                    .requestMatchers(HttpMethod.GET, "/api/v1/customer/**").hasAuthority(READ_SCOPE)
                    .requestMatchers(HttpMethod.GET, "/api/v1/customer").hasAuthority(READ_SCOPE)
                    .requestMatchers(HttpMethod.POST, "/api/v1/customer").hasAuthority(WRITE_SCOPE)
                    .requestMatchers(HttpMethod.POST, "/api/v1/customer/applyLoan/**").hasAuthority(WRITE_SCOPE)
                    .requestMatchers(HttpMethod.PUT, "/api/v1/customer/**").hasAuthority(WRITE_SCOPE)
                    .requestMatchers(HttpMethod.DELETE, "/api/v1/customer/**").hasAuthority(ADMIN_SCOPE)
                    .requestMatchers(HttpMethod.GET, "/api/v1/creditscore").hasAuthority(READ_SCOPE)
                    .requestMatchers(HttpMethod.GET, "/hello").hasAuthority(READ_SCOPE)
                    .requestMatchers(HttpMethod.POST, "/transfer").hasAuthority(TRANSFER_SCOPE)
                    .requestMatchers(HttpMethod.POST, "/api/v1/testrunner/**").hasAuthority(TEST_SCOPE)
                    .anyRequest().authenticated();
            })
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()));

        return http.build();
    }

    private static void authorizeInternalEndpoints(
            org.springframework.security.config.annotation.web.configurers.AuthorizeHttpRequestsConfigurer<
                    HttpSecurity>.AuthorizationManagerRequestMatcherRegistry authorize,
            String scope) {
        authorize
            .requestMatchers(HttpMethod.POST, "/api/v1/account/journal").hasAuthority(scope)
            .requestMatchers(HttpMethod.POST, "/api/v1/account/journal/*/clear").hasAuthority(scope)
            .requestMatchers("/deposit", "/deposit/**", "/withdraw", "/withdraw/**").hasAuthority(scope)
            .requestMatchers(HttpMethod.POST, "/confirm", "/cancel", "/processconfirm", "/processcancel")
            .hasAuthority(scope);
    }

    private static void permitInternalEndpoints(
            org.springframework.security.config.annotation.web.configurers.AuthorizeHttpRequestsConfigurer<
                    HttpSecurity>.AuthorizationManagerRequestMatcherRegistry authorize) {
        authorize
            .requestMatchers(HttpMethod.POST, "/api/v1/account/journal").permitAll()
            .requestMatchers(HttpMethod.POST, "/api/v1/account/journal/*/clear").permitAll()
            .requestMatchers("/deposit", "/deposit/**", "/withdraw", "/withdraw/**").permitAll()
            .requestMatchers(HttpMethod.POST, "/confirm", "/cancel", "/processconfirm", "/processcancel")
            .permitAll();
    }
}
