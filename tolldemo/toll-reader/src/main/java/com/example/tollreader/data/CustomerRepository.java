package com.example.tollreader.data;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CustomerRepository extends JpaRepository<Customer, String> {
    public Customer findByCustomerId(String customerId);
}
