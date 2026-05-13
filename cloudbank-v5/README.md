# CloudBank Version 5

CloudBank v5 is a reference application that demonstrates modern cloud-native microservices architecture using Oracle Backend as a Service (OBaaS). This comprehensive banking application showcases enterprise-grade distributed systems patterns, event-driven architecture, secured service-to-service calls, and production observability practices.

## 📦 Installation Guide

For complete installation instructions, see **[cloudbank-v5-install.md](cloudbank-v5-install.md)**

This guide covers:
- Building and containerizing the services
- Database setup with Oracle AI Autonomous Database
- Kubernetes deployment with Helm
- Spring Authorization Server and database secret setup
- Secured APISIX API gateway configuration
- OBaaS Java auto-instrumentation for observability

### 🧪 Testing Guide

For comprehensive testing procedures, see **[cloudbank-test-doc.md](cloudbank-test-doc.md)**

This guide covers:
- Getting OAuth2 access tokens from `azn-server`
- Running the automated secured smoke test with `6-smoke_test_secure_services.sh`
- Testing individual microservices with bearer tokens (account, customer, creditscore etc.)
- Check deposit and clearance workflow
- LRA distributed transaction testing (transfer service)
- Observability and tracing verification

## Project Structure

```
cloudbank-v5/
├── azn-server/        # Spring Authorization Server for CloudBank tokens
├── account/           # Account management service
├── customer/          # Customer management service
├── transfer/          # Money transfer orchestration service
├── checks/            # Check processing service
├── creditscore/       # Credit scoring service
├── testrunner/        # Testing utility service
├── common/            # Shared configuration and utilities
└── buildtools/        # Code quality tools (checkstyle, dependency-check)
```
