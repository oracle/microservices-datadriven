// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Tables18NodesDto {
	private String table_name;

	public Tables18NodesDto() {
	}

	public Tables18NodesDto(String table_name) {
		this.table_name = table_name;
	}

	@Override
	public String toString() {
		return String.format("TABLES_18_NODES[table_name='%s']", table_name);
	}

}
