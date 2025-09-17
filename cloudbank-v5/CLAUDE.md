# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CloudBank v5 is a microservices-based banking application built with Spring Boot 3.4.6 and Java 21. It demonstrates Oracle Backend for Microservices and AI (OBaaS) capabilities, including distributed transactions using Long Running Actions (LRA), observability, and service mesh integration.

## Build and Development Commands

### Build the entire project
```bash
mvn clean package
```

### Run specific tests for a module
```bash
mvn test -pl <module-name>
# Example: mvn test -pl account
```

### Code quality checks
```bash
# Run checkstyle validation
mvn checkstyle:check

# Run dependency vulnerability scan
mvn org.owasp:dependency-check-maven:check
```

### Docker image build and push
```bash
mvn k8s:build
```

## Architecture

### Microservices Structure
- **account**: Account management service with journal/transaction tracking
- **customer**: Customer management and profile operations
- **transfer**: Inter-account transfer service with LRA support
- **checks**: Check deposit/clearance processing
- **creditscore**: Credit scoring service
- **chatbot**: AI-powered chatbot service (optional)
- **testrunner**: Test automation and system testing utilities
- **common**: Shared configuration and utilities
- **buildtools**: Development tooling and quality checks

### Key Architectural Patterns
- **Event-driven Architecture**: Services communicate via REST APIs with distributed transaction support
- **Saga Pattern**: Implemented using Oracle MicroTx LRA for distributed transactions
- **Service Discovery**: Eureka-based service registration and discovery
- **Circuit Breaker**: OpenFeign with resilience patterns
- **Observability**: OpenTelemetry tracing, Micrometer metrics, Prometheus monitoring

### Database Design
- Oracle Database with UCP connection pooling
- Liquibase for database migrations
- JPA/Hibernate for ORM with optimistic locking
- Each service has its own schema (account, customer, etc.)

### Configuration Management
- Spring Cloud Config for centralized configuration
- Service-specific `application.yaml` files
- Common configuration shared via `common.yaml`
- Environment-specific overrides through externalized config

## Technology Stack

### Core Framework
- Spring Boot 3.4.6 with Virtual Threads enabled
- Spring Cloud 2024.0.1 for microservices infrastructure
- Oracle MicroTx for distributed transactions

### Database & Persistence
- Oracle Database with oracle-spring-boot-starter-ucp
- Liquibase for schema migrations
- JPA/Hibernate with Oracle dialect

### Observability & Monitoring
- OpenTelemetry for distributed tracing
- Micrometer with Prometheus for metrics
- SigNoz for APM and observability dashboards
- Spring Boot Actuator for health checks

### Service Communication
- OpenFeign for service-to-service communication
- Eureka for service discovery
- APISIX for API gateway and routing

## Development Guidelines

### LRA Transaction Patterns
- Use `@LRA(value = LRA.Type.REQUIRES_NEW)` for new transaction boundaries
- Implement `@Complete` and `@Compensate` methods for saga compensation
- Pass LRA context headers between services for transaction correlation

### REST API Conventions
- All APIs follow `/api/v1/` versioning pattern
- Use standard HTTP status codes (201 for creation, 204 for deletion)
- Return `Location` headers for created resources
- Implement proper error handling with meaningful HTTP status codes

### Database Patterns
- Use repository pattern with Spring Data JPA
- Implement proper transaction boundaries at service layer
- Follow naming conventions: `findBy*`, `existsById`, etc.
- Use `saveAndFlush()` for immediate persistence when needed

### Testing Approach
- Unit tests with Spring Boot Test slice annotations
- Integration tests using `@SpringBootTest`
- Use testrunner service for end-to-end system testing
- Mock external service dependencies with WireMock or similar

## Common Issues & Solutions

### LRA Transaction Timeouts
- Check MicroTx coordinator connectivity via `${MP_LRA_COORDINATOR_URL}`
- Verify LRA headers are properly propagated between services
- Monitor transaction logs for compensation trigger patterns

### Service Discovery Issues
- Verify Eureka client configuration in `common.yaml`
- Check service registration with Eureka dashboard
- Ensure `spring.application.name` matches service discovery expectations

### Database Connection Problems
- Validate Oracle UCP configuration in service-specific `application.yaml`
- Check connection pool sizing (`initial-pool-size`, `max-pool-size`)
- Verify Liquibase migrations complete successfully during startup