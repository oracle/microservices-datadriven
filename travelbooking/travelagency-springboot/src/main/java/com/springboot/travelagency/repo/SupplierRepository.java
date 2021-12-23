package com.springboot.travelagency.repo;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import org.springframework.transaction.annotation.Transactional;

import com.springboot.travelagency.dto.InventoryTable;
@EnableJpaRepositories
@Repository
@Transactional
@EnableTransactionManagement
public interface SupplierRepository extends JpaRepository<InventoryTable, String> {

	InventoryTable findByItemIdContainingIgnoreCase(String itemId);

}
