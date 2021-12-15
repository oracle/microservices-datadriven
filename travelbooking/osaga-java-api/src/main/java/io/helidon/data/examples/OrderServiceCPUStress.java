/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

public class OrderServiceCPUStress {
    boolean isStressOn = false;

    public void start() {
        isStressOn = true;
        for (int thread = 0; thread < 10; thread++) {
            new CPUStressThread().start();
        }
    }

    public void stop() {
        isStressOn = false;
    }

    private class CPUStressThread extends Thread {
        public void run() {
            try {
                System.out.println("CPUStressThread.run isStressOn:" + isStressOn + " thread:" + Thread.currentThread());
                while (isStressOn) {
                    if (System.currentTimeMillis() % 100 == 0) {
                        Thread.sleep((long) Math.floor((.2) * 100));
                    }
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
