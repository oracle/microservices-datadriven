package org.example.oracle_cqrs.command.commands;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;


@AllArgsConstructor @NoArgsConstructor
public class BaseCommand<T>{
    @Getter
    private T id;

}
