// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.tollreader.data;

import java.util.List;
import org.springframework.stereotype.Component;
import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j
public class DataBean {

    private List<Customer> customers;
    private List<Vehicle> vehicles;

    private CustomerRepository customerRepository;
    private VehicleRespository vehicleRespository;

    public DataBean(CustomerRepository customerRepository, VehicleRespository vehicleRespository) {
        this.customerRepository = customerRepository;
        this.vehicleRespository = vehicleRespository;
    }

    public void populateData() {
        customers = customerRepository.findAll();
        vehicles = vehicleRespository.findAll();

        log.info("loaded " + customers.size() + " customer records");
        log.info("loaded " + vehicles.size() + " vehicle records");
    }

    public List<Customer> getCustomers() {
        return customers;
    }

    public List<Vehicle> getVehicles() {
        return vehicles;
    }

    public Customer getCustomer(String customerId) {
        for (Customer c : customers) {
            if (c.getCustomerId().equalsIgnoreCase(customerId)) {
                return c;
            }
        }
        return null;
    }

}
