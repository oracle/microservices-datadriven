package org.example.oracle_cqrs.common.Dtos;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @NoArgsConstructor @AllArgsConstructor
public class CreditAccountDTO {
    private String accountId ;
    private double amount ;
}
