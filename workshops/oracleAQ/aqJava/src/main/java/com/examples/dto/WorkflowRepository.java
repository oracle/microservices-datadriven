package com.examples.dto;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.examples.config.UserDetails;

@Repository
@Transactional
public interface WorkflowRepository extends JpaRepository<UserDetails, Integer> {

	UserDetails findByOrderId(int orderId);
}
