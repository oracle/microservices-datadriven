package com.examples.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.examples.config.ConfigData;

import oracle.AQ.AQException;

@Service
	public class UserDetailsDaoImpl implements UserDetailsDao {

	@Autowired(required=true)
	private ConfigData configData;
		
		static Connection con= null;

//		 @PostConstruct     
//		 public void createTable(UserDetails user)throws SQLException, ClassNotFoundException, AQException{
//			 con= configData.dbConnection();
//
//		    String sqlCreate = "CREATE TABLE IF NOT EXISTS " + "USERDETAILS"
//		            + "  ( ORDERID  number(10),"
//		            + "    USERNAME varchar2(255), "
//		            + "    OTP      number(4),"
//		            + "    DELIVERY_STATUS varchar2(10),"
//		            + "    DELIVERY_LOCATION varchar2(255),"
//		            + "    PRIMARY KEY(ORDERID))";
//
//		    Statement stmt = con.createStatement();
//		    stmt.executeUpdate(sqlCreate);
//		}
		 
		@Override
		public void add(UserDetails user)throws SQLException, ClassNotFoundException, AQException{
			
			con= configData.dbConnection();
			String query= "insert into UserDetails(orderId, username, otp, deliveryStatus, deliveryLocation) VALUES (?, ?, ?, ?, ?)";
			
			PreparedStatement ps = con.prepareStatement(query);
			ps.setInt   (1, user.getOrderId());
			ps.setString(2, user.getUsername());
			ps.setInt   (3, user.getOtp());
			ps.setString(4, user.getDeliveryStatus());
			ps.setString(5, user.getDeliveryLocation());

			ps.executeUpdate();
		}

		@Override
		public UserDetails getUserDetails(int id) throws SQLException, ClassNotFoundException, AQException{

			con= configData.dbConnection();

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
		public void update(int orderId, String deliveryStatus)throws SQLException, ClassNotFoundException, AQException{

			con= configData.dbConnection();

			String query= "update UserDetails set deliveryStatus=? where orderId = ?";
			PreparedStatement ps = con.prepareStatement(query);
			ps.setString(1, deliveryStatus);
			ps.setInt(2, orderId);
			ps.executeUpdate();
		}
	}

	 

