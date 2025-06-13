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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.util.UriComponentsBuilder;


import java.net.URI;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/commands")
public class AccountCommandRest {

    private CommandsProducer commandsProducer;
    private EventStoreRepository eventStoreRepository;
    private String queryBsedUrl ;

    AccountCommandRest(CommandsProducer commandsProducer, EventStoreRepository eventStoreRepository, @Value("${query.base.url}") String queryBsedUrl) {
        this.commandsProducer = commandsProducer;
        this.eventStoreRepository = eventStoreRepository;
        this.queryBsedUrl = queryBsedUrl;
    }

    @PostMapping("/create")
    public ResponseEntity createAccount(@Valid @RequestBody CreateAccountDTO request) {
        String accountId = UUID.randomUUID().toString();
        commandsProducer.enqueue(new CreateAccountCommand(UUID.randomUUID().toString(), request.getInitialBalance(), request.getCurrency(), accountId));
        URI location = getGetQueryUri(accountId);
        return ResponseEntity.created(location).build();
    }

    @PostMapping("/debit")
    public ResponseEntity debitAccount(@Valid @RequestBody DebitAccountDTO request) {
        commandsProducer.enqueue(new DebitAccountCommand(UUID.randomUUID().toString(), request.getAccountId(), request.getAmount(), request.getCurrency()));
        URI location = getGetQueryUri(request.getAccountId());
        return ResponseEntity.created(location).build();
    }

    @PostMapping("/credit")
    public ResponseEntity creditAccount(@Valid @RequestBody CreditAccountDTO request) {
        commandsProducer.enqueue(new CreditAccountCommand(UUID.randomUUID().toString(), request.getAccountId(), request.getAmount(), request.getCurrency()));
        URI location = getGetQueryUri(request.getAccountId());
        return ResponseEntity.created(location).build();
    }

    @PutMapping("/updateStatus")
    public ResponseEntity updateStatus(@Valid @RequestBody UpdateAccountStatusDTO request) {
        commandsProducer.enqueue(new UpdateAccountStatusCommand(UUID.randomUUID().toString(), request.getAccountId(), request.getAccountStatus()));
        URI location = getGetQueryUri(request.getAccountId());
        return ResponseEntity.created(location).build();
    }


    @GetMapping("allEvents")
    public List<BaseEvent> getAllEvents() {
        return eventStoreRepository.findAll();
    }

    @ExceptionHandler(Exception.class)
    public String exceptionHandler(Exception exception) {
        return exception.getMessage();
    }

    private URI getGetQueryUri(String accountId) {
        URI location = UriComponentsBuilder.fromHttpUrl(queryBsedUrl)
                .path("/" + accountId)
                .build()
                .toUri();
        return location;
    }


}
