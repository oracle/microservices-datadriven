package com.example.queuereader.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.queuereader.service.AIVisionService;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
@RequestMapping("/image")
public class TollImageValidationController {
    
    private AIVisionService service;

    TollImageValidationController(AIVisionService service) {
        this.service = service;
    }

    @PostMapping("/analyze")
    public ResponseEntity<String> analyzeImage(@RequestBody String imageUrl) {
        log.info("imageUrl = " + imageUrl);        
        String response = service.analyzeImage(imageUrl);
        if (response == null) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
        return new ResponseEntity<>(response, HttpStatus.OK);
    }
    

}
