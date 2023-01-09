// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package oracle.ebaas.bank;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Slf4j
public class AccountController {

    @PostMapping(value = "/transfer")
    ResponseEntity<Void> placeOrder(@RequestBody Transfer transfer) {
        log.info("Transferring from account: {} to account: {} amount: {}", transfer.getFromAccount(), transfer.getToAccount(), transfer.getAmount());
        return ResponseEntity.ok().body(null);
    }
}