package org.example.oracle.cqrs.command.commands;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.oracle.cqrs.common.events.BaseEvent;


@AllArgsConstructor @NoArgsConstructor
public abstract class BaseCommand<T>{
    @Getter
    private T id;
    public abstract BaseEvent createEvent();

}
