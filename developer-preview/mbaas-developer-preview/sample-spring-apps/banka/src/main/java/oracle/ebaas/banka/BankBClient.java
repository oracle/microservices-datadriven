// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package oracle.ebaas.banka;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient("bankb") // corresponds to spring.app.name of target
public interface BankBClient {

    @PostMapping("/transfer")
    void transfer(@RequestBody Transfer transfer);
}