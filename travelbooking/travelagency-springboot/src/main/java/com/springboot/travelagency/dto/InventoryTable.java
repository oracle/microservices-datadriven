package com.springboot.travelagency.dto;

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
		private String travelagencyId;

		@Id
		@Column(name = "INVENTORYID")
		private String itemId;
		
		@Column(name = "INVENTORYCOUNT")
		private long travelagencyCount;
		
		@Column(name = "INVENTORYLOCATION")
		private String travelagencyLocation;

		@Transient
		private String suggestiveSale;
	
		public InventoryTable() {
	
		}
	
		public InventoryTable(String travelagencyId, String itemId, String travelagencyLocation, String suggestiveSale) {
			this.travelagencyId = travelagencyId;
			this.itemId = itemId;
			this.travelagencyLocation = travelagencyLocation;
			this.suggestiveSale = suggestiveSale;
		}

		public String getOrderId() {
			return travelagencyId;
		}

		public void setOrderId(String travelagencyId) {
			this.travelagencyId = travelagencyId;
		}

		public String getItemId() {
			return itemId;
		}

		public void setItemId(String itemId) {
			this.itemId = itemId;
		}

		public long getInventoryCount() {
			return travelagencyCount;
		}

		public void setInventoryCount(long travelagencyCount) {
			this.travelagencyCount = travelagencyCount;
		}

		public String getInventoryLocation() {
			return travelagencyLocation;
		}

		public void setInventoryLocation(String travelagencyLocation) {
			this.travelagencyLocation = travelagencyLocation;
		}

		public String getSuggestiveSale() {
			return suggestiveSale;
		}

		public void setSuggestiveSale(String suggestiveSale) {
			this.suggestiveSale = suggestiveSale;
		}
}
