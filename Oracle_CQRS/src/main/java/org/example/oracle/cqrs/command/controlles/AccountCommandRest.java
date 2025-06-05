package org.example.oracle.cqrs.command.controlles;


import jakarta.validation.Valid;
import org.example.oracle.cqrs.command.commands.CreateAccountCommand;
import org.example.oracle.cqrs.command.commands.CreditAccountCommand;
import org.example.oracle.cqrs.command.commands.DebitAccountCommand;
import org.example.oracle.cqrs.command.commands.UpdateAccountStatusCommand;
import org.example.oracle.cqrs.command.producers.CommandsProducer;
import org.example.oracle.cqrs.command.repository.EventStoreRepository;
import org.example.oracle.cqrs.common.Dtos.CreateAccountDTO;
import org.example.oracle.cqrs.common.Dtos.CreditAccountDTO;
import org.example.oracle.cqrs.common.Dtos.DebitAccountDTO;
import org.example.oracle.cqrs.common.Dtos.UpdateAccountStatusDTO;
import org.example.oracle.cqrs.common.events.BaseEvent;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/commands")
public class AccountCommandRest {

    private CommandsProducer commandsProducer;
    private EventStoreRepository eventStoreRepository;

    AccountCommandRest(CommandsProducer commandsProducer, EventStoreRepository eventStoreRepository) {
        this.commandsProducer = commandsProducer;
        this.eventStoreRepository = eventStoreRepository;
    }

    @PostMapping("/create")
    public ResponseEntity createAccount(@Valid @RequestBody CreateAccountDTO request) {
        String accountId = UUID.randomUUID().toString();
        commandsProducer.enqueue(new CreateAccountCommand(UUID.randomUUID().toString(), request.getInitialBalance(), request.getCurrency(), accountId));

        return ResponseEntity.status(HttpStatus.ACCEPTED).header(HttpHeaders.LOCATION, "/api/queries/status/" + accountId).build();
    }

    @PostMapping("/debit")
    public ResponseEntity debitAccount(@Valid @RequestBody DebitAccountDTO request) {
        commandsProducer.enqueue(new DebitAccountCommand(UUID.randomUUID().toString(), request.getAccountId(), request.getAmount(), request.getCurrency()));

        return ResponseEntity.status(HttpStatus.ACCEPTED).header(HttpHeaders.LOCATION, "/api/queries/" + request.getAccountId()).build();
    }

    @PostMapping("/credit")
    public ResponseEntity creditAccount(@Valid @RequestBody CreditAccountDTO request) {
        commandsProducer.enqueue(new CreditAccountCommand(UUID.randomUUID().toString(), request.getAccountId(), request.getAmount(), request.getCurrency()));

        return ResponseEntity.status(HttpStatus.ACCEPTED).header(HttpHeaders.LOCATION, "/api/queries/" + request.getAccountId()).build();
    }

    @PutMapping("/updateStatus")
    public ResponseEntity updateStatus(@Valid @RequestBody UpdateAccountStatusDTO request) {
        commandsProducer.enqueue(new UpdateAccountStatusCommand(UUID.randomUUID().toString(), request.getAccountId(), request.getAccountStatus()));
        return ResponseEntity.status(HttpStatus.ACCEPTED).header(HttpHeaders.LOCATION, "/api/queries/status/" + request.getAccountId()).build();
    }


    @GetMapping("allEvents")
    public List<BaseEvent> getAllEvents() {
        return eventStoreRepository.findAll();
    }

    @ExceptionHandler(Exception.class)
    public String exceptionHandler(Exception exception) {
        return exception.getMessage();
    }


}
