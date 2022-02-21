package com.examples.dao;

import java.sql.SQLException;

import oracle.AQ.AQException;

public interface UserDetailsDao {

	public void add(UserDetails user) throws SQLException, ClassNotFoundException, AQException;
	public UserDetails getUserDetails(int id)throws SQLException, ClassNotFoundException, AQException;
	public void update(int orderId, String deliveryStatus) throws SQLException, ClassNotFoundException, AQException;
}
