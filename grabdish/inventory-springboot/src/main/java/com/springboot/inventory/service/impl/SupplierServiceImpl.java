package com.springboot.inventory.service.impl;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.springboot.inventory.dto.InventoryTable;
import com.springboot.inventory.repo.SupplierRepository;
import com.springboot.inventory.service.SupplierService;

@Service
public class SupplierServiceImpl implements SupplierService{

	@Autowired
	private SupplierRepository supplierRepo;
	
	Logger logger = LoggerFactory.getLogger(SupplierServiceImpl.class);

	@Override
	public String addInventory(InventoryTable user) {

		String status = "";

		InventoryTable existingData = supplierRepo.findByItemIdContainingIgnoreCase(user.getItemId());
		
        try {
			if(null != existingData) {
				
				if (user.getItemId().equalsIgnoreCase(existingData.getItemId())) {
					existingData.setInventoryCount(existingData.getInventoryCount()+1);
					supplierRepo.saveAndFlush(existingData);
				}
				status = "Success";
			}
			else {
				InventoryTable newInventory = new InventoryTable();
	
				newInventory.setItemId(user.getItemId());
				newInventory.setInventoryCount(1);
				if(user.getInventoryLocation()!=null) {
					newInventory.setInventoryLocation(user.getInventoryLocation());
				}
				else {
					newInventory.setInventoryLocation("");
				}
				supplierRepo.saveAndFlush(newInventory);
				status = "Success";
			} 
		} catch (Exception e) {
			logger.info(e.getMessage());
		}
		return status;
	}

	@Override
	public String removeInventory(String itemId) {
		String status = "";
		InventoryTable existingData = supplierRepo.findByItemIdContainingIgnoreCase(itemId);

	
			if(existingData != null && existingData.getInventoryCount()!=0) {
				existingData.setInventoryCount(existingData.getInventoryCount()-1);	
				supplierRepo.saveAndFlush(existingData);
				status = "Success";
			}else {
				status = "Failed";
			}
		
		return status;
	}

	@Override
	public InventoryTable getInventory(String itemId) {
		InventoryTable inventoryData = new InventoryTable();
		try {
			if (itemId != null) {
				inventoryData = supplierRepo.findByItemIdContainingIgnoreCase(itemId);
			}
		} catch (Exception e) {
			logger.info(e.getMessage());
		}
		return inventoryData;
	}

}
