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
