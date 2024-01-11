// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.customer32.service;

import com.example.customer32.model.Customer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
@Slf4j
public class JdbcTemplateCustomerService implements CustomerService {

    private final JdbcClient jdbcClient;

    public JdbcTemplateCustomerService(JdbcClient jdbcClient) {
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
        log.info("Name : " + name);
        return jdbcClient.sql("select id, name, email from customers32 where name = :name")
                .param("name", name)
                .query(Customer.class)
                .optional();
    }

    @Override
    public Optional<Customer> findCustomerById(String id) {
        log.info("Id : " + id);
        return jdbcClient.sql("select id, name, email from customers32 where id = :id")
                .param("id", id)
                .query(Customer.class)
                .optional();
    }

    @Override
    public Optional<Customer> findCustomerByEmail(String email) {
        log.info("Email " + email);
        return jdbcClient.sql("select id, name, email from customers32 where email = :email")
                .param("email", email)
                .query(Customer.class)
                .optional();
    }

    @Override
    public void createCustomer(Customer customer) {
        log.info("customer : " + customer);
        var newCustomer = jdbcClient.sql("insert into customers32(id, name, email) values (?,?,?)")
                .params(List.of(customer.Id(), customer.Name(), customer.Email()))
                .update();
        log.info("newCust : " + newCustomer);
        // if (updatedCustomer == 0) {
        //     return new ResponseEntity<>(customer, HttpStatus.CREATED);
        // } else {
        //     return new ResponseEntity<>(null, HttpStatus.NO_CONTENT);
        // }
    }

    @Override
    public void updateCustomer(Customer customer) {
        log.info("customer : " + customer);
        var updCustomer = jdbcClient.sql("update customers32 set name = ?, email = ? where id = ?")
                .params(List.of(customer.Name(), customer.Email(), customer.Id()))
                .update();
        log.info("updCust : " + updCustomer);
    }

    @Override
    public void deleteCustomer(String id) {
        log.info("Id :" + id);
        var delCustomer = jdbcClient.sql("delete from customers32 where id = :id")
                .param("id", id)
                .update();
        log.info("delCust : " + delCustomer);
    }
}
