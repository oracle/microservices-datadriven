package com.example.tollreader;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/")
public class Controller {
    
    @Autowired
    private ConfigurableApplicationContext context;

    public Controller(ConfigurableApplicationContext context) {
        this.context = context;
    }

    // yes i know how ugly this is :) 
    @GetMapping("/start/{delay}")
    public String start(@PathVariable("delay") int delay) {
        MessageTaskExecutor mte = (MessageTaskExecutor) context.getBean("messageTaskExecutor");
        mte.setDelay(delay);
        mte.start();
        return "started\n";
    }
    
    @GetMapping("/stop")
    public String stop() {
        MessageTaskExecutor mte = (MessageTaskExecutor) context.getBean("messageTaskExecutor");
        mte.stop();
        return "stopped\n";
    }

}
