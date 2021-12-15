package com.springboot.travelagency.service;

import com.springboot.travelagency.dto.InventoryTable;

public interface SupplierService {

	String addInventory(InventoryTable userData);

	String removeInventory(String itemId);

	InventoryTable getInventory(String itemId);

}
