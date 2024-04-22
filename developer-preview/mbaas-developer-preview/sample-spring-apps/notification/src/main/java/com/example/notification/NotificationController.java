// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package com.example.notification;

import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("api/v1/notify")
@AllArgsConstructor
@Slf4j
public class NotificationController {

    private final NotificationService service;

    @PostMapping
    public void notify(@RequestBody NotificationRequest notificationRequest) {
        log.info("New notification... {}", notificationRequest);
        service.notify(notificationRequest);
    }
}