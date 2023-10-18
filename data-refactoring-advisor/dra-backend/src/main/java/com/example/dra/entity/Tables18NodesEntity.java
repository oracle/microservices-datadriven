// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.dra.entity;

import jakarta.persistence.*;
import lombok.Getter;

import lombok.Setter;

import java.io.Serializable;

@Getter
@Setter
@Entity
@Table(name = "TABLES_18_NODES")
public class Tables18NodesEntity implements Serializable {

	@Id
	@Column(name = "TABLE_ID")
	private Long id;

	@Column(name = "TABLE_SET_NAME")
	private String tableSetName;

	@Column(name = "TABLE_NAME")
	private String tableName;
}
