package org.example.oracle.cqrs.common.Dtos;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateAccountDTO {
    @Min(value = 0, message = "initialBalance can not be negative")
    double initialBalance;
    @NotBlank
    String currency;
}
