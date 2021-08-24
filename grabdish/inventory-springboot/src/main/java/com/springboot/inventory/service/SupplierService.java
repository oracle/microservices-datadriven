package com.springboot.inventory.service;

import com.springboot.inventory.dto.InventoryTable;

public interface SupplierService {

	String addInventory(InventoryTable userData);

	String removeInventory(String itemId);

	InventoryTable getInventory(String itemId);

}
