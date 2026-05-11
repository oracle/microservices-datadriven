# Repository Guidelines

## Project Structure & Module Organization

CloudBank v5 is a Java 21 microservices reference application. The root `pom.xml` builds the main Spring Boot modules: `account`, `checks`, `customer`, `creditscore`, `transfer`, `testrunner`, `chatbot`, plus shared `common` and `buildtools`. Service code follows Maven layout: `src/main/java`, `src/main/resources`, and `src/test/java`. Database migrations live in service-local `src/main/resources/db/changelog`. Helm configuration is in each service's `values.yaml`. APISIX scripts are in `apisix-routes/`, and numbered root scripts cover OCI repositories, image builds, Kubernetes secrets, deployment, and gateway routes. Helidon samples (`customer-helidon`, `helidon-producer`, `helidon-consumer`) have separate POMs and README files.

## Build, Test, and Development Commands

- `mvn test`: compile parent POM modules, run unit tests, and enforce Checkstyle during the `test` phase.
- `mvn package`: build service JARs and run the same test-phase checks.
- `mvn -pl account -am test`: test one module and any required upstream modules; replace `account` with another module name.
- `mvn -pl customer spring-boot:run`: run a Spring Boot service locally from its module.
- `./check_prereqs.sh`: verify local tooling before deployment.
- `./2-images_build_push.sh` and `./4-deploy_all_services.sh`: build/push images and deploy; review environment variables first.

## Coding Style & Naming Conventions

Use Java 21 and keep package names under `com.example`. Classes use `PascalCase`; methods and fields use `camelCase`; test classes generally end with `Tests` or `Test`. Checkstyle rules are in `buildtools/src/main/resources/cloudbank/checkstyle/`: Java line length is 120 characters, indentation is 4 spaces, and Java files must retain the Oracle copyright header. Prefer existing Spring patterns: controllers in `controller`, entities in `model`, repositories in `repository`, and logic in `service` or `services`.

## Testing Guidelines

Tests use Spring Boot's test stack and JUnit conventions. Add tests beside the service they cover under `src/test/java`, mirroring production packages. For database-backed changes, include migration coverage or document required manual validation in `cloudbank-test-doc.md`. Run `mvn test` before opening a PR; use `mvn -pl <module> -am test` for focused iteration.

## Commit & Pull Request Guidelines

Recent history uses short imperative summaries, often with PR numbers, for example `add helidon-consumer project with OTEL and Kafka metrics (#1310)` or `Fix broken links (#1312)`. Keep commits focused on one concern. PRs should include a concise description, linked issue when applicable, test results, and screenshots or trace/log evidence for UI, observability, or deployment changes.

## Security & Configuration Tips

Do not commit secrets, wallet files, kubeconfigs, or generated credentials. Keep environment-specific settings in deployment configuration and document required variables in the relevant README or install guide.
