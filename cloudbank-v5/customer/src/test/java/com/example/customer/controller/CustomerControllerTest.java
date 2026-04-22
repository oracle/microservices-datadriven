package com.example.customer.controller;

import java.util.Optional;

import com.example.customer.model.Customers;
import com.example.customer.repository.CustomersRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mindrot.jbcrypt.BCrypt;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CustomerControllerTest {

    @Mock
    private CustomersRepository customersRepository;

    @InjectMocks
    private CustomerController customerController;

    @Test
    @DisplayName("Should hash password when creating a customer")
    void shouldHashPasswordOnCreate() {
        Customers customer = new Customers("CUST004", "New Customer", "new@example.com", "Details", "Welcome123");
        ArgumentCaptor<Customers> savedCustomer = ArgumentCaptor.forClass(Customers.class);

        when(customersRepository.existsById("CUST004")).thenReturn(false);
        when(customersRepository.saveAndFlush(savedCustomer.capture())).thenAnswer(invocation -> invocation.getArgument(0));

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/v1/customer");
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
        try {
            ResponseEntity<Customers> response = customerController.createCustomer(customer);

            assertEquals(HttpStatus.CREATED, response.getStatusCode());
            assertNotNull(savedCustomer.getValue().getCustomerPassword());
            assertNotEquals("Welcome123", savedCustomer.getValue().getCustomerPassword());
            assertTrue(BCrypt.checkpw("Welcome123", savedCustomer.getValue().getCustomerPassword()));
        } finally {
            RequestContextHolder.resetRequestAttributes();
        }
    }

    @Test
    @DisplayName("Should hash password when updating a customer")
    void shouldHashPasswordOnUpdate() {
        Customers existingCustomer = new Customers("CUST001", "John Doe", "john@example.com", "Old details",
                "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy");
        Customers update = new Customers("CUST001", "John Doe Updated", "john.updated@example.com", "New details",
                "UpdatedPassword");

        when(customersRepository.findById("CUST001")).thenReturn(Optional.of(existingCustomer));
        when(customersRepository.save(existingCustomer)).thenReturn(existingCustomer);

        ResponseEntity<Customers> response = customerController.updateCustomer("CUST001", update);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("John Doe Updated", existingCustomer.getCustomerName());
        assertEquals("john.updated@example.com", existingCustomer.getCustomerEmail());
        assertEquals("New details", existingCustomer.getCustomerOtherDetails());
        assertTrue(BCrypt.checkpw("UpdatedPassword", existingCustomer.getCustomerPassword()));
        verify(customersRepository).save(existingCustomer);
    }
}
