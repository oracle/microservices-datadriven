/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;

import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;

@Liveness
@ApplicationScoped
public class OrderServiceLivenessHealthCheck implements HealthCheck {

    @Inject
    public OrderServiceLivenessHealthCheck() {
    }

    @Override
    public HealthCheckResponse call() {
        if (!OrderResource.liveliness) {
            return HealthCheckResponse.named("OrderServerLivenessDown")
                    .down()
                    .withData("databaseconnections", "not live")
                    .build();
        } else return HealthCheckResponse.named("OrderServerLivenessUp")
                .up()
                .withData("databaseconnections", "live")
                .build();
    }
}

