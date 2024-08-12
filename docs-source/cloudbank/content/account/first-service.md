+++
archetype = "page"
title = "Implement First Service"
weight = 4
+++

1. Implement the first simple endpoint

    1. Create `AccountController.java`

      Create a new directory in the directory `src/main/java/com/example/accounts` called `controller`. In that new directory, create a new Java file called `AccountController.java`.  When prompted for the type, choose **class**.

      Your new file should look like this:

      ```java
      package com.example.accounts.controller;
        
      public class AccountController {
            
      }
      ```

    1. Add the `RestController` annotation

      Add the `RestController` annotation to this class to tell Spring Boot that we want this class to expose REST services. You can just start typing `@RestController` before the `public class` statement and Visual Studio Code will offer code completion for you. When you select from the pop-up, Visual Studio Code will also add the import statement for you.  The list of suggestions is based on the dependencies you added to your project.

      Add the `RequestMapping` annotation to this class as well, and set the URL path to `/api/v1`. Your class should now look like this:

      ```java
      package com.example.accounts.controller;
        
      import org.springframework.web.bind.annotation.RequestMapping;
      import org.springframework.web.bind.annotation.RestController;
        
      @RestController
      @RequestMapping("/api/v1")
      public class AccountController {
            
      }
      ```

    1. Add `ping` method

      Add a method to this class called `ping` which returns a `String` with a helpful message. Add the `GetMapping` annotation to this method and set the URL path to `/hello`. Your class should now look like this:

      ```java
      package com.example.accounts.controller;
      
      import org.springframework.web.bind.annotation.GetMapping;
      import org.springframework.web.bind.annotation.RequestMapping;
      import org.springframework.web.bind.annotation.RestController;
      
      @RestController
      @RequestMapping("/api/v1")
      public class AccountController {
          
        @GetMapping("/hello")
        public String ping() {
          return "Hello from Spring Boot";
        }
      
      }
      ```

    You have just implemented your first REST service in Spring Boot! This service will be available on `http://localhost:8080/api/v1/hello`. And the `GetMapping` annotation tells Spring Boot that this service will respond to the HTTP GET method.

    You can test your service now by building and running again. Make sure you save the file. If you still have the application running from before, hit Ctrl+C (or equivalent) to stop it, and then build and run with this command:

    ```shell
    $ mvn spring-boot:run
    ```

    Then try to call your service with this command:

    ```shell
    $ curl -i http://localhost:8080/api/v1/hello
    HTTP/1.1 200 
    Content-Type: text/plain;charset=UTF-8
    Content-Length: 22
    Date: Sat, 25 Feb 2023 17:59:52 GMT
    
    Hello from Spring Boot
    ```

    Great, it works! Notice it returned HTTP Status Code 200 (OK) and some HTTP Headers along with the body which contained your message. Later we will see how to return JSON and to set the status code appropriately.

