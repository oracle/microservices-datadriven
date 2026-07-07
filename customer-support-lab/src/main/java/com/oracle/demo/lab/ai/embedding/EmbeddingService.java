// Copyright (c) 2026, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.oracle.demo.lab.ai.embedding;

import oracle.sql.VECTOR;

import java.util.Collections;
import java.util.List;

public interface EmbeddingService {
    List<float[]> embedAll(List<String> chunks);
    default float[] embed(String chunk) {
        return embedAll(Collections.singletonList(chunk)).getFirst();
    }
}
