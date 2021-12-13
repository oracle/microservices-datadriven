package com.aq.dto;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.aq.config.UserDetails;

@Repository
@Transactional
public interface WorkflowRepository extends JpaRepository<UserDetails, Integer> {


	UserDetails findByOrderId(int orderId);



}
