// Copyright (c) 2026, Oracle and/or its affiliates.

package com.example.common.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "cloudbank.security.service-token")
public class CloudBankServiceTokenProperties {

    private boolean enabled;
    private String tokenUri;
    private String clientId = "cloudbank-client";
    private String clientSecret;
    private String scope = "cloudbank.internal";
    private long refreshSkewSeconds = 30;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getTokenUri() {
        return tokenUri;
    }

    public void setTokenUri(String tokenUri) {
        this.tokenUri = tokenUri;
    }

    public String getClientId() {
        return clientId;
    }

    public void setClientId(String clientId) {
        this.clientId = clientId;
    }

    public String getClientSecret() {
        return clientSecret;
    }

    public void setClientSecret(String clientSecret) {
        this.clientSecret = clientSecret;
    }

    public String getScope() {
        return scope;
    }

    public void setScope(String scope) {
        this.scope = scope;
    }

    public long getRefreshSkewSeconds() {
        return refreshSkewSeconds;
    }

    public void setRefreshSkewSeconds(long refreshSkewSeconds) {
        this.refreshSkewSeconds = refreshSkewSeconds;
    }
}
