// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32.service;

import java.util.List;
import java.util.Optional;

import com.example.customer32.model.Customer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
@Slf4j
public class JdbcClientCustomerService implements CustomerService {

    private final JdbcClient jdbcClient;

    public JdbcClientCustomerService(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    @Override
    public List<Customer> findAll() {
        return jdbcClient.sql("Select id, name, email from customers32")
                .query(Customer.class)
                .list();
    }

    @Override
    public Optional<Customer> findByCustomerByName(String name) {
        log.debug("Name : " + name);
        return jdbcClient.sql("select id, name, email from customers32 where name = :name")
                .param("name", name)
                .query(Customer.class)
                .optional();
    }

    @Override
    public Optional<Customer> findCustomerById(String id) {
        log.debug("Id : " + id);
        return jdbcClient.sql("select id, name, email from customers32 where id = :id")
                .param("id", id)
                .query(Customer.class)
                .optional();
    }

    @Override
    public Optional<Customer> findCustomerByEmail(String email) {
        log.debug("Email " + email);
        return jdbcClient.sql("select id, name, email from customers32 where email = :email")
                .param("email", email)
                .query(Customer.class)
                .optional();
    }

    @Override
    public int createCustomer(Customer customer) {
        log.debug("createCustomer : " + customer);
        var newCustomer = jdbcClient.sql("insert into customers32(id, name, email) values (?,?,?)")
                .params(List.of(customer.id(), customer.name(), customer.email()))
                .update();
        return newCustomer;
    }

    @Override
    public int updateCustomer(Customer customer, String id) {
        log.debug("updateCustomer : " + customer + " id " + id);
        var updCustomer = jdbcClient.sql("update customers32 set name = ?, email = ? where id = ?")
                .params(List.of(customer.name(), customer.email(), id))
                .update();
        return updCustomer;
    }

    @Override
    public int deleteCustomer(String id) {
        log.debug("Id :" + id);
        var delCustomer = jdbcClient.sql("delete from customers32 where id = :id")
                .param("id", id)
                .update();
        return delCustomer;
    }
}
