
package org.example.oracle.cqrs.common.Dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.oracle.cqrs.common.enums.AccountStatus;

@Data @AllArgsConstructor @NoArgsConstructor
public class UpdateAccountStatusDTO {
    @NotBlank
    private String accountId ;
    @NotNull
    private AccountStatus accountStatus ;
}
