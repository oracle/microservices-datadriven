/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.utils;

import java.io.File;
import java.io.FileReader;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

import javax.jms.JMSException;
import javax.jms.TopicSession;
import javax.jms.TopicConnection;
import javax.jms.TopicConnectionFactory;

import oracle.jdbc.OracleConnection;
import org.oracle.okafka.clients.CommonClientConfigs;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.config.AbstractConfig;
import org.oracle.okafka.common.config.SslConfigs;
import org.oracle.okafka.common.errors.ConnectionException;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jms.AQjmsFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ConnectionUtils {
	//TODO Including Logger
	private static final Logger log = LoggerFactory.getLogger(ConnectionUtils.class);

    public static String createUrl(Node node, AbstractConfig configs) {
    	
    	if( !configs.getString(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG).equalsIgnoreCase("PLAINTEXT")) {
			// TODO fill the URL with TNS_ADMIN
			String url = "jdbc:oracle:thin:@";
			url += configs.getString(SslConfigs.TNS_ALIAS);
			url += "?TNS_ADMIN=";
			url += configs.getString("oracle.net.tns_admin");
			return url;
		  //return "jdbc:oracle:thin:@" + configs.getString(SslConfigs.TNS_ALIAS); // + "?TNS_ADMIN=" + configs.getString(SslConfigs.ORACLE_NET_TNS_ADMIN);
        }
		//StringBuilder urlBuilder =new StringBuilder("jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(PORT=" + Integer.toString(node.port())+")(HOST=150.230.160.89))");
		StringBuilder urlBuilder =new StringBuilder("jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(PORT=" + Integer.toString(node.port())+")(HOST=" + node.host() +"))");
		urlBuilder.append("(CONNECT_DATA=(SERVICE_NAME=" + node.serviceName() + ")))");
		// TODO REMOVE IT!
		//urlBuilder.append("(CONNECT_DATA=(SERVICE_NAME=" + node.serviceName() + ")"+"(INSTANCE_NAME=" + node.instanceName() + ")))");
    	return urlBuilder.toString();

		//"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=150.230.160.89)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=pdb1.lab8022subdbsys.lab8022vcndbsys.oraclevcn.com)))"
    }
    public static Connection createJDBCConnection(Node node, AbstractConfig configs) throws SQLException{
    	OracleDataSource s=new OracleDataSource();
		s.setURL(createUrl(node, configs));
	    return s.getConnection();
    }
    
    public static TopicConnection createTopicConnection(Node node,AbstractConfig configs) throws JMSException {
    	if(node==null) 
    		throw new ConnectionException("Invalid argument: Node cannot be null");
    	String url = createUrl(node, configs);
    	OracleDataSource dataSource;
    	try {
    		dataSource =new OracleDataSource();
    		dataSource.setURL(url);

			//TODO Change the original code to pass Credentials to OracleDataSource
			Properties info = new Properties();
			info.put(OracleConnection.CONNECTION_PROPERTY_USER_NAME, configs.getString(CommonClientConfigs.ORACLE_USER_NAME));
			info.put(OracleConnection.CONNECTION_PROPERTY_PASSWORD, configs.getString(CommonClientConfigs.ORACLE_PASSWORD));
			//info.put(OracleConnection.CONNECTION_PROPERTY_DEFAULT_ROW_PREFETCH, "20");

			dataSource.setConnectionProperties(info);
		}
    	catch(SQLException sql) {
			// TODO DEBUG Connection
			System.out.println(sql.toString());
    		throw new JMSException(sql.toString());
    	}

		TopicConnection conn = null;

		try {
			TopicConnectionFactory connFactory = AQjmsFactory.getTopicConnectionFactory(dataSource);
			conn = connFactory.createTopicConnection();
			conn.setClientID(configs.getString(CommonClientConfigs.CLIENT_ID_CONFIG));
		} catch (Exception ex) {
			// TODO DEBUG Connection
			System.out.println("ERRO DE CONNECTION: \n");
			ex.printStackTrace();
		}
        return conn;  	
    }
    
    public static TopicSession createTopicSession(TopicConnection conn, int mode, boolean transacted) throws JMSException {
    	if(conn == null)
    		throw new ConnectionException("Invalid argument: Connection cannot be null");
    	return conn.createTopicSession(transacted, mode);
    	
    }

	// TODO Create getOwner method to return Topic Owner based on App Configuration
	/* getOwner return the Topic Owner based on oracle.user.name property */
	public static String getOwner(AbstractConfig configs) {
		return configs.getString(CommonClientConfigs.ORACLE_USER_NAME);
	}

    public static String getUsername(AbstractConfig configs) {
    	File file = null;
    	FileReader fr = null;
    	try {
    	file = new File(configs.getString(CommonClientConfigs.ORACLE_NET_TNS_ADMIN)+"/ojdbc.properties");
    	fr = new FileReader(file);
    	Properties prop = new Properties();
    	prop.load(fr);
    	return prop.getProperty("user");
    	} catch( Exception exception) {
    		//do nothing
    	} finally {
    		try {
    			if(fr != null)
  				  fr.close();
    		}catch (Exception e) {
    			
    		}	

    	}
    	return null;
    }

}
