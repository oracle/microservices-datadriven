package com.oracle.ms.app;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public class FileProperties {

	private Properties properties;
	private Properties graphProperties;

	FileProperties() {
        properties = new Properties();
        try {
            properties.load(new FileReader("src/main/resources/db-config.properties"));
        } catch (FileNotFoundException ex) {
            Logger.getLogger(getClass().getName()).log(Level.ALL, "FileNotFoundException Occured while loading DB properties file::::" +ex.getMessage());
            ex.printStackTrace();
        } catch (IOException ioex) {
            Logger.getLogger(getClass().getName()).log(Level.ALL, "IOException Occured while loading DB properties file::::" +ioex.getMessage());
            ioex.printStackTrace();
        }
        
        graphProperties = new Properties();
        try {
        	graphProperties.load(new FileReader("src/main/resources/graph-config.properties"));
        } catch (FileNotFoundException ex) {
            Logger.getLogger(getClass().getName()).log(Level.ALL, "FileNotFoundException Occured while loading Graph properties file::::" +ex.getMessage());
            ex.printStackTrace();
        } catch (IOException ioex) {
            Logger.getLogger(getClass().getName()).log(Level.ALL, "IOException Occured while loading Graph properties file::::" +ioex.getMessage());
            ioex.printStackTrace();
        }
    }
    
    public String readProperty(String keyName) {
        Logger.getLogger(getClass().getName()).log(Level.INFO, "Reading Property " + keyName);
        return properties.getProperty(keyName, "There is no key in the db properties file");
    }
    
    public String readGraphProperty(String keyName) {
        Logger.getLogger(getClass().getName()).log(Level.INFO, "Reading Property " + keyName);
        return graphProperties.getProperty(keyName, "There is no key in the graph properties file");
    }
    
}
