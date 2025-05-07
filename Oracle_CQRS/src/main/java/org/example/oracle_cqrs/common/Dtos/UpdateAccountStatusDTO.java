
package org.example.oracle_cqrs.common.Dtos;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.oracle_cqrs.common.enums.AccountStatus;

@Data @AllArgsConstructor @NoArgsConstructor
public class UpdateAccountStatusDTO {
    private String accountId ;
    private AccountStatus accountStatus ;
}
