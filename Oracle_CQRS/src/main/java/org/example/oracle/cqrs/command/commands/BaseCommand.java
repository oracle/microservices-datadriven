package org.example.oracle.cqrs.command.commands;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;


@AllArgsConstructor @NoArgsConstructor
public class BaseCommand<T>{
    @Getter
    private T id;

}
