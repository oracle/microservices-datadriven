package org.example.oracle_cqrs.command.controlles;


import org.example.oracle_cqrs.command.commands.CreateAccountCommand;
import org.example.oracle_cqrs.command.commands.CreditAccountCommand;
import org.example.oracle_cqrs.command.commands.DebitAccountCommand;
import org.example.oracle_cqrs.command.commands.UpdateAccountStatusCommand;
import org.example.oracle_cqrs.command.producers.CommandsProducer;
import org.example.oracle_cqrs.command.repository.EventStoreRepository;
import org.example.oracle_cqrs.common.Dtos.CreateAccountDTO;
import org.example.oracle_cqrs.common.Dtos.CreditAccountDTO;
import org.example.oracle_cqrs.common.Dtos.DebitAccountDTO;
import org.example.oracle_cqrs.common.Dtos.UpdateAccountStatusDTO;
import org.example.oracle_cqrs.common.events.BaseEvent;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/commands")
public class AccountCommandRest {

    private CommandsProducer commandsProducer ;
    private EventStoreRepository eventStoreRepository;

    AccountCommandRest(CommandsProducer commandsProducer, EventStoreRepository eventStoreRepository) {
        this.commandsProducer = commandsProducer;
        this.eventStoreRepository = eventStoreRepository;
    }

    @PostMapping("/create")
    public void createAccount(@RequestBody CreateAccountDTO request){
        commandsProducer.enqueue(new CreateAccountCommand(UUID.randomUUID().toString() ,
                request.getInitialBalance() , request.getCurrency()));
    }
    @PostMapping("/debit")
    public void debitAccount(@RequestBody DebitAccountDTO request){
        commandsProducer.enqueue(new DebitAccountCommand(UUID.randomUUID().toString()
                , request.getAccountId()
                , request.getAmount()
                , request.getCurrency())) ;
    }
    @PostMapping("/credit")
    public void creditAccount(@RequestBody CreditAccountDTO request){
        commandsProducer.enqueue(new CreditAccountCommand(UUID.randomUUID().toString()
                , request.getAccountId()
                , request.getAmount()));
    }
    @PutMapping("/updateStatus")
    public void updateStatus(@RequestBody UpdateAccountStatusDTO request){
        commandsProducer.enqueue(new UpdateAccountStatusCommand(UUID.randomUUID().toString()
                , request.getAccountId()
                , request.getAccountStatus()));
    }


    @GetMapping("allEvents")
    public List<BaseEvent> getAllEvents(){
        return eventStoreRepository.findAll();
    }
    @ExceptionHandler(Exception.class)
    public String exceptionHandler(Exception  exception){
        return exception.getMessage();
    }


}
