/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Readiness;

import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;

@Readiness
@ApplicationScoped
public class OrderServiceReadinessHealthCheck implements HealthCheck {

    @Inject
    public OrderServiceReadinessHealthCheck() {
    }

    @Override
    public HealthCheckResponse call() {
        if (!OrderResource.readiness) {
            return HealthCheckResponse.named("OrderServerReadinessDown")
                    .down()
                    .withData("data-initialized", "not ready") //data initialized via eventsourcing, view query, etc.
                    .withData("connections-created", "not ready")
                    .build();
        } else return HealthCheckResponse.named("OrderServerReadinessUp")
                .up()
                .withData("data-initialized", "ready") //data initialized via eventsourcing, view query, etc.
                .withData("connections-created", "ready")
                .build();
    }
}
