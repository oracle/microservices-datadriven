package com.springboot.inventory.controller;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.CollectionUtils;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.springboot.inventory.dto.InventoryTable;
import com.springboot.inventory.service.SupplierService;

@RestController
@RequestMapping("/inventory")
@CrossOrigin(maxAge = 3600)
public class SupplierController {
	Logger logger = LoggerFactory.getLogger(SupplierController.class);
	
	@Autowired
	private SupplierService supplierService;
	  
	
	@PostMapping(value = "/addInventory")
	public Map<String, Object> addInventory(@RequestBody InventoryTable userData) throws Exception {
		Map<String, Object> response = new HashMap<String, Object>();

		String status = supplierService.addInventory(userData);

		if (status.equalsIgnoreCase("Success")) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "Inventory has been successfully added");
		} else {
			response.put("ResponseCode", "400");
			response.put("ResponseText", "Failed to add inventory");
		}
		logger.info("Add inventory response:{", response);

		return response;
	}

	@DeleteMapping(value = "/removeInventory/{itemId}/")
	public Map<String, Object> removeInventory(@PathVariable String itemId) throws Exception {
		Map<String, Object> response = new HashMap<String, Object>();

		String status = supplierService.removeInventory(itemId);

		if (status.equalsIgnoreCase("Success")) {
			response.put("ResponseCode", "204");
			response.put("ResponseText", "Inventory has been removed successfully");
		} else {
			response.put("ResponseCode", "400");
			response.put("ResponseText", "Failed to remove inventory");
		}
		logger.info("Remove Inventory response:{}", response);

		return response;
	}


	@GetMapping(value = "/getInventory")
	public Map<String, Object> getInventory(@RequestParam(name = "itemId", required = true) String itemId)
			throws Exception {
		Map<String, Object> response = new HashMap<String, Object>();

		InventoryTable inventoryData = supplierService.getInventory(itemId);

		if (!CollectionUtils.isEmpty((Collection<?>) inventoryData)) {
			response.put("ResponseCode", "200");
			response.put("ResponseText", "Success");
			response.put("ResponseBody", inventoryData);
		} else {
			response.put("ResponseCode", "300");
			response.put("ResponseText", "Failed");
		}
		logger.info("Get Inventory response:{}", response);

		return response;
	}
}
