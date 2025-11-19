# CloudBank Version 5

CloudBank v5 is a reference application that demonstrates modern cloud-native microservices architecture using Oracle Backend as a Service (OBaaS). This comprehensive banking application showcases enterprise-grade distributed systems patterns, event-driven architecture, and production observability practices.

## 📦 Installation Guide

For complete installation instructions, see **[cloudbank-v5-install.md](cloudbank-v5-install.md)**

This guide covers:
- Building and containerizing the services
- Database setup with Oracle AI Autonomous Database
- Kubernetes deployment with Helm
- APISIX API gateway configuration

### 🧪 Testing Guide

For comprehensive testing procedures, see **[cloudbank-test-doc.md](cloudbank-test-doc.md)**

This guide covers:
- Testing individual microservices (account, customer, creditscore etc.)
- Check deposit and clearance workflow
- LRA distributed transaction testing (transfer service)
- Observability and tracing verification

## Project Structure

```
cloudbank-v5/
├── account/           # Account management service
├── customer/          # Customer management service
├── transfer/          # Money transfer orchestration service
├── checks/            # Check processing service
├── creditscore/       # Credit scoring service
├── testrunner/        # Testing utility service
├── common/            # Shared configuration and utilities
└── buildtools/        # Code quality tools (checkstyle, dependency-check)
```
