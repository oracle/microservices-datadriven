package com.examples.dao;

import java.io.Serializable;
import java.sql.SQLData;
import java.sql.SQLException;
import java.sql.SQLInput;
import java.sql.SQLOutput;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

/*@Entity
@Table(name = "USERDETAILS")*/
public class UserDetails { /*implements Serializable {

	private static final long serialVersionUID = 1L;

	@Id
	@Column(name = "ORDERID")*/
	private int orderId;

	/*@Column(name = "USERNAME")*/
	private String username;

	/*@Column(name = "OTP")*/
	private int otp;

	/*@Column(name = "DELIVERY_STATUS")*/
	private String deliveryStatus;

	/*@Column(name = "DELIVERY_LOCATION")*/
	private String deliveryLocation;
	
	public UserDetails() {
		super();
	}

	public UserDetails(int orderId, String username, int otp, String deliveryStatus, String deliveryLocation) {
		super();
		this.orderId = orderId;
		this.username = username;
		this.otp = otp;
		this.deliveryStatus = deliveryStatus;
		this.deliveryLocation = deliveryLocation;
	}

	public int getOrderId() {
		return orderId;
	}

	public void setOrderId(int orderId) {
		this.orderId = orderId;
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public int getOtp() {
		return otp;
	}

	public void setOtp(int otp) {
		this.otp = otp;
	}

	public String getDeliveryStatus() {
		return deliveryStatus;
	}

	public void setDeliveryStatus(String deliveryStatus) {
		this.deliveryStatus = deliveryStatus;
	}

	public String getDeliveryLocation() {
		return deliveryLocation;
	}

	public void setDeliveryLocation(String deliveryLocation) {
		this.deliveryLocation = deliveryLocation;
	}

}
