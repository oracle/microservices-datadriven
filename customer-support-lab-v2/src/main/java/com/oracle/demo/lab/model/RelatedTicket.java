// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.model;

import com.fasterxml.jackson.annotation.JsonInclude;

/** A scored ticket reference; only recorded resolutions are grounding evidence. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record RelatedTicket(long relatedTicketId, double score, String title, String resolution) {
}
