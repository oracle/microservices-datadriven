package com.examples.dao;

import java.sql.SQLException;

public interface UserDetailsDao {

	public void add(UserDetails user) throws SQLException, ClassNotFoundException;
	public UserDetails getUserDetails(int id)throws SQLException, ClassNotFoundException;
	public void update(int orderId, String deliveryStatus) throws SQLException, ClassNotFoundException;
}
