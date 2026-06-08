// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
package com.example;

import java.net.URI;
import java.util.Collection;
import java.util.List;

import io.helidon.security.annotations.Authenticated;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.json.JsonString;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.SecurityContext;
import jakarta.ws.rs.core.UriInfo;
import org.eclipse.microprofile.jwt.JsonWebToken;
import java.util.logging.Logger;
import java.util.logging.Level;

/**
 * Helidon MP Customer REST Resource
 */
@RequestScoped
@Path("/api/v1/customer")
@Authenticated
public class CustomerResource {

    private static final String READ_SCOPE = "cloudbank.read";
    private static final String WRITE_SCOPE = "cloudbank.write";
    private static final String ADMIN_SCOPE = "cloudbank.admin";
    private static final String INTERNAL_SCOPE = "cloudbank.internal";

    private static final Logger LOGGER = Logger.getLogger(CustomerResource.class.getName());

    @PersistenceContext(unitName = "customer")
    private EntityManager entityManager;

    @Context
    private UriInfo uriInfo;

    @Context
    private SecurityContext securityContext;

    @Inject
    private JsonWebToken jwt;

    /**
     * Get all customers
     * 
     * @return List of all customers
     */
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response getCustomers() {
        try {
            if (!hasAnyScope(READ_SCOPE, ADMIN_SCOPE, INTERNAL_SCOPE)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            if (!isAdmin()) {
                Customer customer = currentCustomer();
                return Response.ok(customer == null ? List.of() : List.of(customer)).build();
            }
            LOGGER.info("Fetching all customers");
            List<Customer> customers = entityManager.createNamedQuery("getCustomers", Customer.class).getResultList();
            return Response.ok(customers).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error finding all customers", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Find customers by name (containing)
     * 
     * @param customerName The customer name to search for
     * @return List of customers with matching names
     */
    @GET
    @Path("name/{customerName}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getCustomerByName(@PathParam("customerName") String customerName) {
        try {
            if (!hasAnyScope(READ_SCOPE, ADMIN_SCOPE, INTERNAL_SCOPE)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            if (!isAdmin()) {
                Customer customer = currentCustomer();
                if (customer == null || !contains(customer.getCustomerName(), customerName)) {
                    return Response.ok(List.of()).build();
                }
                return Response.ok(List.of(customer)).build();
            }
            LOGGER.info("Fetching customer by name: " + customerName);
            TypedQuery<Customer> query = entityManager.createNamedQuery("getCustomerByCustomerNameContaining",
                    Customer.class);
            query.setParameter("customerName", "%" + customerName + "%");
            List<Customer> customers = query.getResultList();
            return Response.ok(customers).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error finding customers by name: " + customerName, e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Get Customer with specific ID.
     *
     * @param id The CustomerId
     * @return If the customer is found, a customer and HTTP Status code.
     */
    @GET
    @Path("{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getCustomerById(@PathParam("id") String id) {
        try {
            if (!hasAnyScope(READ_SCOPE, ADMIN_SCOPE, INTERNAL_SCOPE)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            if (!canAccessCustomer(id)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            LOGGER.info("Fetching customer by ID: " + id);
            Customer customer = entityManager.find(Customer.class, id);
            if (customer != null) {
                return Response.ok(customer).build();
            } else {
                return Response.status(Response.Status.NOT_FOUND).build();
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error getting customer by ID: " + id, e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Get customer that contains an email.
     *
     * @param email of the customer
     * @return Returns a list of customers if found
     */
    @GET
    @Path("byemail/{email}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getCustomerByEmail(@PathParam("email") String email) {
        try {
            if (!hasAnyScope(READ_SCOPE, ADMIN_SCOPE, INTERNAL_SCOPE)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            if (!isAdmin()) {
                Customer customer = currentCustomer();
                if (customer == null || !contains(customer.getCustomerEmail(), email)) {
                    return Response.ok(List.of()).build();
                }
                return Response.ok(List.of(customer)).build();
            }
            LOGGER.info("Fetching customer by email: " + email);
            TypedQuery<Customer> query = entityManager.createNamedQuery("getCustomerByCustomerEmailContaining",
                    Customer.class);
            query.setParameter("customerEmail", "%" + email + "%");
            List<Customer> customers = query.getResultList();
            return Response.ok(customers).build();
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error finding customers by email: " + email, e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Create a customer.
     *
     * @param customer Customer object with the customer details.
     * @return Returns HTTP Status code or the URI of the created object.
     */
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional(Transactional.TxType.REQUIRED)
    public Response createCustomer(Customer customer) {
        try {
            if (!hasAnyScope(WRITE_SCOPE, ADMIN_SCOPE)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            if (!canAccessCustomer(customer.getCustomerId())) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            LOGGER.info("Creating new customer with ID: " + customer.getCustomerId());
            // Check if customer already exists
            Customer existingCustomer = entityManager.find(Customer.class, customer.getCustomerId());

            if (existingCustomer == null) {
                entityManager.persist(customer);
                entityManager.flush(); // Ensure the entity is persisted

                // Build the location URI for the created resource
                URI location = UriBuilder.fromResource(CustomerResource.class)
                        .path("{id}")
                        .build(customer.getCustomerId());

                return Response.created(location).build();
            } else {
                return Response.status(Response.Status.CONFLICT).entity(customer).build();
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error creating customer", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Update a specific Customer (ID).
     *
     * @param id       The id of the customer
     * @param customer A customer object
     * @return A Http Status code and updated customer
     */
    @PUT
    @Path("{id}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional(Transactional.TxType.REQUIRED)
    public Response updateCustomer(@PathParam("id") String id, Customer customer) {
        try {
            if (!hasAnyScope(WRITE_SCOPE, ADMIN_SCOPE)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            if (!canAccessCustomer(id)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            LOGGER.info("Updating customer with ID: " + id);
            Customer existingCustomer = entityManager.find(Customer.class, id);
            if (existingCustomer != null) {
                // Update the existing customer with new values
                existingCustomer.setCustomerName(customer.getCustomerName());
                existingCustomer.setCustomerEmail(customer.getCustomerEmail());
                existingCustomer.setCustomerOtherDetails(customer.getCustomerOtherDetails());

                Customer updatedCustomer = entityManager.merge(existingCustomer);
                return Response.ok(updatedCustomer).build();
            } else {
                return Response.status(Response.Status.NOT_FOUND).build();
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error updating customer with ID: " + id, e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Delete a specific customer (ID).
     *
     * @param customerId the Id of the customer to be deleted
     * @return A Http Status code
     */
    @DELETE
    @Path("{customerId}")
    @Transactional(Transactional.TxType.REQUIRED)
    public Response deleteCustomer(@PathParam("customerId") String customerId) {
        try {
            if (!hasAnyScope(ADMIN_SCOPE)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            LOGGER.info("Deleting customer with ID: " + customerId);
            Customer customer = entityManager.find(Customer.class, customerId);
            if (customer != null) {
                entityManager.remove(customer);
                return Response.status(Response.Status.NO_CONTENT).build();
            } else {
                return Response.status(Response.Status.NOT_FOUND).build();
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error deleting customer with ID: " + customerId, e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Apply for loan - Method isn't fully implemented.
     *
     * @param amount Loan amount
     * @return A Http Status
     */
    @POST
    @Path("applyLoan/{amount}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response applyForLoan(@PathParam("amount") long amount) {
        try {
            if (!hasAnyScope(WRITE_SCOPE, ADMIN_SCOPE)) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }
            LOGGER.info("Processing loan application for amount: " + amount);
            // Check Credit Rating
            // Amount vs Rating approval?
            // Create Account
            // Update Account Balance
            // Notify
            return Response.status(418).build(); // I_AM_A_TEAPOT equivalent
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error processing loan application for amount: " + amount, e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).build();
        }
    }

    private boolean canAccessCustomer(String customerId) {
        return isAdmin()
                || hasAnyScope(INTERNAL_SCOPE)
                || (securityContext != null
                && securityContext.getUserPrincipal() != null
                && customerId != null
                && customerId.equals(principalName()));
    }

    private boolean isAdmin() {
        return hasAnyScope(ADMIN_SCOPE);
    }

    private Customer currentCustomer() {
        String principalName = principalName();
        if (principalName == null) {
            return null;
        }
        return entityManager.find(Customer.class, principalName);
    }

    private boolean hasAnyScope(String... allowedScopes) {
        Object scopeClaim = jwt == null ? null : jwt.getClaim("scope");
        if (scopeClaim instanceof Collection<?> scopes) {
            for (Object scope : scopes) {
                if (matchesAny(normalizeScope(scope), allowedScopes)) {
                    return true;
                }
            }
        }
        if (scopeClaim instanceof String scopes) {
            for (String scope : scopes.split(" ")) {
                if (matchesAny(scope, allowedScopes)) {
                    return true;
                }
            }
        }
        return false;
    }

    private static String normalizeScope(Object scope) {
        if (scope instanceof JsonString jsonString) {
            return jsonString.getString();
        }
        String value = String.valueOf(scope);
        if (value.length() > 1 && value.startsWith("\"") && value.endsWith("\"")) {
            return value.substring(1, value.length() - 1);
        }
        return value;
    }

    private String principalName() {
        if (jwt != null && jwt.getName() != null) {
            return jwt.getName();
        }
        if (jwt != null && jwt.getSubject() != null) {
            return jwt.getSubject();
        }
        if (securityContext != null && securityContext.getUserPrincipal() != null) {
            return securityContext.getUserPrincipal().getName();
        }
        return null;
    }

    private static boolean matchesAny(String scope, String... allowedScopes) {
        for (String allowedScope : allowedScopes) {
            if (allowedScope.equals(scope)) {
                return true;
            }
        }
        return false;
    }

    private static boolean contains(String value, String fragment) {
        return value != null && fragment != null && value.contains(fragment);
    }
}
