package com.oracle.demo.lab.ai.vectorstore;

import oracle.sql.VECTOR;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.sql.SQLException;
import java.util.List;

@Component
@Profile("ai")
public class VectorDataAdapter {
    public float[] toFloatArray(List<Float> e) {
        float[] vector = new float[e.size()];
        for (int i = 0; i < e.size(); i++) {
            vector[i] = e.get(i);
        }
        return vector;
    }


    /**
     * Normalizes a vector, converting it to a unit vector with length 1.
     * @param v Vector to normalize.
     * @return The normalized vector.
     */
    private float[] normalize(float[] v) {
        double squaredSum = 0d;

        for (float e : v) {
            squaredSum += e * e;
        }

        final float magnitude = (float) Math.sqrt(squaredSum);

        if (magnitude > 0) {
            final float multiplier = 1f / magnitude;
            final int length = v.length;
            for (int i = 0; i < length; i++) {
                v[i] *= multiplier;
            }
        }

        return v;
    }
}
