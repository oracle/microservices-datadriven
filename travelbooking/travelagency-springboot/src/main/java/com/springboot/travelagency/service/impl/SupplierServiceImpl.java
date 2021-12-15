package com.springboot.travelagency.service.impl;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.springboot.travelagency.dto.InventoryTable;
import com.springboot.travelagency.repo.SupplierRepository;
import com.springboot.travelagency.service.SupplierService;

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
		InventoryTable travelagencyData = new InventoryTable();
		try {
			if (itemId != null) {
				travelagencyData = supplierRepo.findByItemIdContainingIgnoreCase(itemId);
			}
		} catch (Exception e) {
			logger.info(e.getMessage());
		}
		return travelagencyData;
	}

}
