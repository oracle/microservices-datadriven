package org.example.oracle_cqrs.common.Dtos;

import lombok.*;

@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateAccountDTO {
    double initialBalance ;
    String currency ;
}
