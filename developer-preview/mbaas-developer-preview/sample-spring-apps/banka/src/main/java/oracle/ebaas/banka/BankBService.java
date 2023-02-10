// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package oracle.ebaas.banka;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class BankBService {

    private final BankBClient bankBClient;

    public void transfer(Transfer transfer) {
        log.info("BankA making call to BankB for transfer");
        bankBClient.transfer(transfer);
    }
}