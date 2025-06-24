package com.example;

import java.util.List;

import jakarta.enterprise.context.RequestScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@RequestScoped
@Path("/api/v1/customer")
public class CustomerResource {

    @PersistenceContext(unitName = "customer")
    private EntityManager entityManager;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Customer> getCustomers() {
        return entityManager.createNamedQuery("getCustomers", Customer.class).getResultList();
    }

    @GET
    @Path("name/{customerName}")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Customer> getCustomerByName(@PathParam("customerName") String customerName) {
        return entityManager.createNamedQuery("getCustomerByCustomerNameContaining", Customer.class).getResultList();
    }

    @GET
    @Path("{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public Customer getCustomerById(@PathParam("id") String id) {
        return entityManager.find(Customer.class, id);
    }

    @GET
    @Path("byemail/{email}")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Customer> getCustomerByEmail(@PathParam("email") String email) {
        return entityManager.createNamedQuery("getCustomerByCustomerEmailContaining", Customer.class).getResultList();
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Transactional(Transactional.TxType.REQUIRED)
    public void createCustomer(Customer customer) {
        try {
            entityManager.persist(customer);
        } catch (Exception e) {
            throw new BadRequestException("Unable to create customer");
        }
    }

    @DELETE
    @Path("{id}")
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional(Transactional.TxType.REQUIRED)
    public void deleteCustomer(@PathParam("id") String id) {
        Customer customer = getCustomerById(id);
        entityManager.remove(customer);
    }
    
}
