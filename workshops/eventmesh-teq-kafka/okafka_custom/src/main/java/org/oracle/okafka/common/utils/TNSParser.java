/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

package org.oracle.okafka.common.utils;

import org.oracle.okafka.clients.CommonClientConfigs;
import org.oracle.okafka.common.config.AbstractConfig;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.Stack;
import java.util.StringTokenizer;
public class TNSParser {
	private final AbstractConfig configs;
	private String fileStr ;
	private final String hashChar = "#";
	private final String eol = "\r\n";
	
	public TNSParser( AbstractConfig configs) {
		this.configs = configs;
	}

	public String getProperty(String connStr, String property) {
		int index = connStr.indexOf(property);
		if(index == -1)
			return null;
        int index1 = connStr.indexOf("=", index);
        if(index1 == -1)
        	return null;
        int index2 = connStr.indexOf(")", index1);
        if(index2 == -1)
        	return null;
        return connStr.substring(index1 + 1, index2).trim();
    }
    public String getConnectionString(String alias) {
        String aliasTmp = alias.trim().toUpperCase();
        Stack<String> stack = new Stack<>();
        int index = -1;
        boolean found = false;
        while((index = fileStr.indexOf(aliasTmp, index + 1)) != -1 ) {
        	 if( fileStr.indexOf("=(DESCRIPTION", index) == index + aliasTmp.length()) {
        		 found = true;
        		 break;
        	 }
        }
        if ( found ) {
            for(int ind = index; ind < fileStr.length() ; ind++) {
                if(fileStr.charAt(ind) == '(') 
                   {stack.push("("); }
                else if(fileStr.charAt(ind) == ')'){
                	if(stack.empty())
                		return null;
                    stack.pop();
                    if(stack.empty())
                      return fileStr.substring(index, ind + 1);
                    //if( ind + 1 < fileStr.length() && (fileStr.charAt(ind + 1) != '(' || fileStr.charAt(ind + 1) != ')'))
                		//return null;
                }
                
            }
        }
        return null;
    }
	  private String removeUnwanted(String fileStr) {
		    
		    StringBuilder sb = new StringBuilder();
	        for(int ind = 0 ; ind < fileStr.length(); ind++) {
	        	if( fileStr.charAt(ind) != ' ' )
	        	   sb.append(fileStr.charAt(ind));
	        }
	        String strtmp = new String (sb.toString());
	        String filestr = "";
	        String tokenstr = new String ();
	        StringTokenizer st = new StringTokenizer(strtmp, eol);
	        while(st.hasMoreTokens()) {
	          tokenstr = st.nextToken().trim();
	          if (!tokenstr.contains(hashChar))
	             filestr = filestr + tokenstr + eol;
	          else {
	        	  if(tokenstr.indexOf(hashChar) != 0)
	        		  filestr = filestr + tokenstr.substring(0, tokenstr.indexOf(hashChar)) + eol;
              }
	        }
            return filestr;	        
	        
	    }
		public void readFile() throws FileNotFoundException, IOException {
			char[] buf = null;
			FileReader fr = null;
			try {
				File f = new File(configs.getString(CommonClientConfigs.ORACLE_NET_TNS_ADMIN) + "/tnsnames.ora");
			    fr = new FileReader(f);
			    int length = (int)f.length();
			    buf = new char[length];
			    fr.read(buf, 0, length);
			    

			    String fileStr = new String(buf);
			    fileStr = fileStr.toUpperCase();
			    this.fileStr = removeUnwanted(fileStr);
			} finally {
				if(fr != null)
				  fr.close();	
			}

			
		    
		}

}
