package io.micronaut.data.examples;

import io.micronaut.runtime.Micronaut;

public class Application {

    public static void main(String[] args) {

//        Micronaut.run(Application.class, args);
        Micronaut.build(args)
                .eagerInitSingletons(true)
                .mainClass(Application.class)
                .start();
    }
}
