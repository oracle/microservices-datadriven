package com.springboot.inventory.dto;

import java.io.Serializable;
import javax.persistence.Transient;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;


@Entity
	@Table(name = "INVENTORY")

	public class InventoryTable implements Serializable {

		private static final long serialVersionUID = 1L;
	
		@Transient
		private String orderId;

		@Id
		@Column(name = "INVENTORYID")
		private String itemId;
		
		@Column(name = "INVENTORYCOUNT")
		private long inventoryCount;
		
		@Column(name = "INVENTORYLOCATION")
		private String inventoryLocation;

		@Transient
		private String suggestiveSale;
	
		public InventoryTable() {
	
		}
	
		public InventoryTable(String orderId, String itemId, String inventoryLocation, String suggestiveSale) {
			this.orderId = orderId;
			this.itemId = itemId;
			this.inventoryLocation = inventoryLocation;
			this.suggestiveSale = suggestiveSale;
		}

		public String getOrderId() {
			return orderId;
		}

		public void setOrderId(String orderId) {
			this.orderId = orderId;
		}

		public String getItemId() {
			return itemId;
		}

		public void setItemId(String itemId) {
			this.itemId = itemId;
		}

		public long getInventoryCount() {
			return inventoryCount;
		}

		public void setInventoryCount(long inventoryCount) {
			this.inventoryCount = inventoryCount;
		}

		public String getInventoryLocation() {
			return inventoryLocation;
		}

		public void setInventoryLocation(String inventoryLocation) {
			this.inventoryLocation = inventoryLocation;
		}

		public String getSuggestiveSale() {
			return suggestiveSale;
		}

		public void setSuggestiveSale(String suggestiveSale) {
			this.suggestiveSale = suggestiveSale;
		}
}
