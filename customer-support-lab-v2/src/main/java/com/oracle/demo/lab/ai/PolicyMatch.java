// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai;

/** A scored reference to an illustrative support policy. */
public record PolicyMatch(String policyId, String title, double score, String body) {
}
