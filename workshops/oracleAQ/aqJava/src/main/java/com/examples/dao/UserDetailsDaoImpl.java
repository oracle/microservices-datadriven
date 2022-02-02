package com.examples.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
	public class UserDetailsDaoImpl implements UserDetailsDao {

	@Value("${username}")
	private String username;

	@Value("${url}")
	private String url;
	
//	@Value("${password}")
//	private String password;
		
		static Connection con= null;

		@Override
		public void add(UserDetails user)throws SQLException, ClassNotFoundException{
			
			Class.forName("oracle.jdbc.OracleDriver");
			con = DriverManager.getConnection(url);
			String query
				= "insert into UserDetails(orderId, username, otp, deliveryStatus, deliveryLocation) VALUES (?, ?, ?, ?, ?)";
			
			PreparedStatement ps = con.prepareStatement(query);
			ps.setInt   (1, user.getOrderId());
			ps.setString(2, user.getUsername());
			ps.setInt   (3, user.getOtp());
			ps.setString(4, user.getDeliveryStatus());
			ps.setString(5, user.getDeliveryLocation());

			ps.executeUpdate();
		}

		@Override
		public UserDetails getUserDetails(int id) throws SQLException, ClassNotFoundException{

			Class.forName("oracle.jdbc.OracleDriver");
			con = DriverManager.getConnection(url);
			
			String query
				= "select * from UserDetails where orderId= ?";
			PreparedStatement ps
				= con.prepareStatement(query);

			ps.setInt(1, id);
			UserDetails user = new UserDetails();
			ResultSet rs = ps.executeQuery();
			boolean check = false;

			while (rs.next()) { 
				check = true;
				user.setOrderId(rs.getInt("orderId"));
				user.setUsername(rs.getString("username"));
				user.setOtp(rs.getInt("otp"));
				user.setDeliveryStatus(rs.getString("deliveryStatus"));
				user.setDeliveryLocation(rs.getString("deliveryLocation"));
			}

			if (check == true) {
				return user;
			}
			else
				return null;
		}


		@Override
		public void update(int orderId, String deliveryStatus)throws SQLException, ClassNotFoundException{

			Class.forName("oracle.jdbc.OracleDriver");
			con = DriverManager.getConnection(url);
			
			String query= "update UserDetails set deliveryStatus=? where orderId = ?";
			PreparedStatement ps = con.prepareStatement(query);
			ps.setString(1, deliveryStatus);
			ps.setInt(2, orderId);
			ps.executeUpdate();
		}
	}

	 

