// Copyright (c) 2026, Oracle and/or its affiliates.

package com.example.common.security;

import java.util.Set;

import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;

public final class CloudBankAuthorization {

    private static final Set<String> PRIVILEGED_AUTHORITIES = Set.of(
            "SCOPE_cloudbank.admin",
            "SCOPE_cloudbank.internal");

    private CloudBankAuthorization() {
    }

    /**
     * Checks whether the authenticated caller may access resources owned by a customer id.
     *
     * @param authentication current Spring Security authentication.
     * @param customerId customer id that owns the resource.
     * @return true when the caller owns the resource or has a privileged service/admin scope.
     */
    public static boolean canAccessCustomer(Authentication authentication, String customerId) {
        if (customerId == null || !isAuthenticated(authentication)) {
            return false;
        }
        return isPrivileged(authentication) || customerId.equals(authentication.getName());
    }

    /**
     * Checks whether the authenticated caller has an administrative or internal-service scope.
     *
     * @param authentication current Spring Security authentication.
     * @return true when the caller is authenticated with a privileged authority.
     */
    public static boolean isPrivileged(Authentication authentication) {
        if (!isAuthenticated(authentication)) {
            return false;
        }
        return authentication.getAuthorities().stream()
                .anyMatch(authority -> PRIVILEGED_AUTHORITIES.contains(authority.getAuthority()));
    }

    private static boolean isAuthenticated(Authentication authentication) {
        return authentication != null
                && authentication.isAuthenticated()
                && !(authentication instanceof AnonymousAuthenticationToken)
                && authentication.getName() != null;
    }
}
