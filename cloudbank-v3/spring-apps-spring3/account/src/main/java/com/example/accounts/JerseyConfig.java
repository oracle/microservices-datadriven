// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.accounts;

import jakarta.ws.rs.ApplicationPath;

import org.glassfish.hk2.utilities.binding.AbstractBinder;
import org.glassfish.jersey.server.ResourceConfig;
import org.glassfish.jersey.servlet.ServletProperties;
import org.springframework.stereotype.Component;

import com.example.accounts.services.DepositService;
import com.example.accounts.services.WithdrawService;

import io.narayana.lra.client.internal.proxy.nonjaxrs.LRAParticipantRegistry;

@Component
@ApplicationPath("/")
public class JerseyConfig extends ResourceConfig {

    public JerseyConfig()  {
        register(DepositService.class);
        register(WithdrawService.class);
        register(io.narayana.lra.filter.ServerLRAFilter.class);
        register(new AbstractBinder(){
            @Override
            protected void configure() {
                bind(LRAParticipantRegistry.class)
                    .to(LRAParticipantRegistry.class);
            }
        });
        property(ServletProperties.FILTER_FORWARD_ON_404, true);
    }
}