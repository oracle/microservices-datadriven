package org.example.oracle.cqrs.common.Dtos;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreditAccountDTO {
    @NotBlank
    private String accountId;
    @Min(value = 1, message = "amount can not be zero or negative")
    private double amount;
    @NotBlank
    private String currency;
}
