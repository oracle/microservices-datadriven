// Copyright (c) 2023, 2026, Oracle and/or its affiliates.

package oracle.obaas.aznserver.securityconfig;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.util.UUID;

import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.autoconfigure.security.servlet.EndpointRequest;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.security.access.expression.method.DefaultMethodSecurityExpressionHandler;
import org.springframework.security.access.expression.method.MethodSecurityExpressionHandler;
import org.springframework.security.access.hierarchicalroles.RoleHierarchy;
import org.springframework.security.access.hierarchicalroles.RoleHierarchyImpl;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.core.ClientAuthenticationMethod;
import org.springframework.security.oauth2.core.oidc.OidcScopes;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.authorization.client.InMemoryRegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.config.annotation.web.configuration.OAuth2AuthorizationServerConfiguration;
import org.springframework.security.oauth2.server.authorization.config.annotation.web.configurers.OAuth2AuthorizationServerConfigurer;
import org.springframework.security.oauth2.server.authorization.settings.AuthorizationServerSettings;
import org.springframework.security.oauth2.server.authorization.settings.ClientSettings;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.LoginUrlAuthenticationEntryPoint;
import org.springframework.security.web.util.matcher.MediaTypeRequestMatcher;
import org.springframework.util.StringUtils;

@Configuration
@EnableWebSecurity(debug = false)
@EnableMethodSecurity
@Slf4j
public class SecurityConfig {

    public static final String ROLE_HIERARCHY = "ROLE_ADMIN > ROLE_USER\n"
            + "ROLE_ADMIN > ROLE_CONFIG_EDITOR\n"
            + "ROLE_CONFIG_EDITOR > ROLE_USER";

    /**
     * Configure a role hierarchy such that ADMIN "includes"/implies USER.
     * 
     * @return the hierarchy.
     */

    @Bean
    public RoleHierarchy roleHierarchy() {
        return RoleHierarchyImpl.fromHierarchy(ROLE_HIERARCHY);
    }

    /**
     * Configure method security to use the role hierarchy.
     * 
     * @param roleHierarchy injected by Spring.
     * @return The MethodSecurityExpressionHandler.
     */
    @Bean
    public MethodSecurityExpressionHandler methodSecurityExpressionHandler(RoleHierarchy roleHierarchy) {
        DefaultMethodSecurityExpressionHandler expressionHandler = new DefaultMethodSecurityExpressionHandler();
        expressionHandler.setRoleHierarchy(roleHierarchy);
        return expressionHandler;
    }
    
    /**
     * Authorization Server endpoints use their own filter chain so OAuth protocol
     * handling does not inherit API-specific stateless settings.
     *
     * @param http HttpSecurity injected by Spring.
     * @return the SecurityFilterChain.
     * @throws Exception if unable to create the chain.
     */
    @Bean
    @Order(1)
    public SecurityFilterChain authorizationServerSecurityFilterChain(HttpSecurity http)
            throws Exception {
        log.debug("In authorizationServerSecurityFilterChain");
        OAuth2AuthorizationServerConfigurer authorizationServerConfigurer =
                OAuth2AuthorizationServerConfigurer.authorizationServer();

        http
            .securityMatcher(authorizationServerConfigurer.getEndpointsMatcher())
            .with(authorizationServerConfigurer, authorizationServer ->
                authorizationServer.oidc(Customizer.withDefaults()))
            .authorizeHttpRequests((authorize) -> authorize
                .requestMatchers("/.well-known/**", "/oauth2/jwks").permitAll()
                .anyRequest().authenticated())
            .csrf((csrf) -> csrf.ignoringRequestMatchers(authorizationServerConfigurer.getEndpointsMatcher()))
            .exceptionHandling((exceptions) -> exceptions.defaultAuthenticationEntryPointFor(
                new LoginUrlAuthenticationEntryPoint("/login"),
                new MediaTypeRequestMatcher(MediaType.TEXT_HTML)));
        return http.build();
    }

    /** Create a SecurityFilterChain to allow anonymous access to actuator endpoints.
     * @param http HttpSecurity injected by Spring. 
     * @return the SecurityFilterChain.
     * @throws Exception if unable to create the chain.
     */
    @Bean
    @Order(2)
    public SecurityFilterChain actuatorSecurityFilterChain(HttpSecurity http)
        throws Exception {
        log.debug("In actuatorSecurityFilterChain");
        http
            .securityMatcher(EndpointRequest.toAnyEndpoint())
            .authorizeHttpRequests((authorize) -> authorize
                .requestMatchers(EndpointRequest.to("health", "info")).permitAll()
                .anyRequest().hasRole("ACTUATOR"))
            .httpBasic(Customizer.withDefaults());
        return http.build();
    }

    /**
     * Create a SecurityFilterChain for the user-management API.
     * @param http HttpSecurity injected by Spring. 
     * @param userDetailsService the JPA-backed user details service.
     * @return the SecurityFilterChain.
     * @throws Exception if unable to create the chain.
     */
    @Bean
    @Order(3)
    public SecurityFilterChain apiSecurityFilterChain(HttpSecurity http, UserDetailsService userDetailsService)
            throws Exception {
        log.debug("In apiSecurityFilterChain");
        http
            .securityMatcher("/user/api/**", "/error/**")
            .authorizeHttpRequests((authorize) -> authorize
                .requestMatchers("/error/**").permitAll()
                .requestMatchers("/user/api/v1/ping").permitAll()
                .requestMatchers("/user/api/v1/forgot").permitAll()
                .anyRequest().authenticated()
            )
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .httpBasic(Customizer.withDefaults())
            .userDetailsService(userDetailsService);
        // The user-management API is stateless and does not use browser sessions or cookies.
        http.csrf(csrf -> csrf.disable());
        return http.build();
    }

    /**
     * Create the fallback browser login chain used by authorization-code flows.
     * @param http HttpSecurity injected by Spring.
     * @return the SecurityFilterChain.
     * @throws Exception if unable to create the chain.
     */
    @Bean
    @Order(4)
    public SecurityFilterChain defaultSecurityFilterChain(HttpSecurity http)
            throws Exception {
        log.debug("In defaultSecurityFilterChain");
        http
            .authorizeHttpRequests((authorize) -> authorize.anyRequest().authenticated())
            .formLogin(Customizer.withDefaults())
            .httpBasic(Customizer.withDefaults());
        return http.build();
    }

    /**
     * Create an Authentication Provider for our UserDetailsService.
     * @param userDetailsService the JPA-backed user details service.
     * @param passwordEncoder password encoder for stored password hashes.
     * @return the AuthenticationProvider.
     */
    @Bean
    public DaoAuthenticationProvider authenticationProvider(UserDetailsService userDetailsService,
            PasswordEncoder passwordEncoder) {
        DaoAuthenticationProvider auth = new DaoAuthenticationProvider(userDetailsService);
        auth.setPasswordEncoder(passwordEncoder);
        return auth;
    }

    /**
     * Create an opt-in local client for test and developer-only contexts.
     *
     * Production deployments should configure registered clients explicitly using
     * Spring Boot's authorization-server client properties.
     *
     * @param passwordEncoder password encoder for the client secret.
     * @param clientSecret configured client secret.
     * @return a local RegisteredClientRepository.
     */
    @Bean
    @ConditionalOnMissingBean
    @ConditionalOnProperty(prefix = "azn.authorization-server.default-client", name = "enabled",
            havingValue = "true")
    public RegisteredClientRepository localRegisteredClientRepository(PasswordEncoder passwordEncoder,
            @Value("${azn.authorization-server.default-client.secret:}") String clientSecret) {
        if (!StringUtils.hasText(clientSecret)) {
            throw new IllegalStateException("azn.authorization-server.default-client.secret must be set when "
                    + "azn.authorization-server.default-client.enabled=true");
        }
        RegisteredClient registeredClient = RegisteredClient.withId(UUID.randomUUID().toString())
                .clientId("azn-local-client")
                .clientSecret(passwordEncoder.encode(clientSecret))
                .clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_BASIC)
                .authorizationGrantType(AuthorizationGrantType.CLIENT_CREDENTIALS)
                .authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
                .authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN)
                .redirectUri("http://127.0.0.1:8080/login/oauth2/code/azn-local-client")
                .scope(OidcScopes.OPENID)
                .scope("user.read")
                .clientSettings(ClientSettings.builder().requireProofKey(true).build())
                .build();
        return new InMemoryRegisteredClientRepository(registeredClient);
    }

    /**
     * Create an instance of AuthorizationServerSettings to configure Spring Authorization Server.
     * @return the AuthorizationServerSettings
     */
    @Bean
    public AuthorizationServerSettings authorizationServerSettings() {
        return AuthorizationServerSettings.builder().build();
    }

    /**
     * Provide process-local signing keys for development and tests.
     *
     * Production deployments should replace this bean with persistent key material
     * so tokens remain verifiable across restarts and rolling deploys.
     *
     * @return the JWK source.
     */
    @Bean
    @ConditionalOnMissingBean
    public JWKSource<SecurityContext> jwkSource() {
        log.warn("Using process-local generated RSA signing keys. Configure a persistent JWKSource bean for "
                + "production so issued tokens remain verifiable across restarts and rolling deploys.");
        RSAKey rsaKey = generateRsa();
        JWKSet jwkSet = new JWKSet(rsaKey);
        return (jwkSelector, securityContext) -> jwkSelector.select(jwkSet);
    }

    @Bean
    @ConditionalOnMissingBean
    public JwtDecoder jwtDecoder(JWKSource<SecurityContext> jwkSource) {
        return OAuth2AuthorizationServerConfiguration.jwtDecoder(jwkSource);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    private static RSAKey generateRsa() {
        KeyPair keyPair = generateRsaKeyPair();
        RSAPublicKey publicKey = (RSAPublicKey) keyPair.getPublic();
        RSAPrivateKey privateKey = (RSAPrivateKey) keyPair.getPrivate();
        return new RSAKey.Builder(publicKey)
                .privateKey(privateKey)
                .keyID(UUID.randomUUID().toString())
                .build();
    }

    private static KeyPair generateRsaKeyPair() {
        try {
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(3072);
            return keyPairGenerator.generateKeyPair();
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to generate authorization server RSA key", exception);
        }
    }

}
