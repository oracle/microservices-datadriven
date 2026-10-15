// Presets follow the HTTP walkthroughs, seeded policy corpus, and processing tests.
export const ticketSamples = [
  {
    id: "mfa",
    name: "Lost MFA authenticator",
    category: "AI enrichment",
    title: "Lost MFA authenticator",
    description:
      "I lost my authenticator and cannot sign in. How can I recover access safely?",
    outcome:
      "Enriches with an MFA recovery summary and matching policies when ai is enabled. Submit twice to demonstrate related-ticket retrieval.",
    source: "demo-ai-assistance.sh / demo-human-feedback.sh",
  },
  {
    id: "access",
    name: "Account access",
    category: "Policy retrieval",
    title: "Sign-in failure",
    description:
      "Cannot access my account after a password reset. I need help verifying my identity and restoring access safely.",
    outcome:
      "Demonstrates account-access policy retrieval and a new saved summary.",
    source: "GenAIEventProcessorTest / ACCOUNT_ACCESS policy",
  },
  {
    id: "billing",
    name: "Billing dispute",
    category: "Different intent",
    title: "Duplicate charge on invoice DEMO-1042",
    description:
      "My test account was charged twice for invoice DEMO-1042. Please review the disputed charge before making any refund or payment changes.",
    outcome:
      "Demonstrates billing-policy suggestions. No refund or customer action is executed.",
    source: "BILLING_DISPUTE policy",
  },
  {
    id: "failure",
    name: "Failure → replay → retry",
    category: "Recovery",
    title: "[demo-fail-once] Lost MFA authenticator",
    description:
      "I lost my authenticator and cannot sign in. How can I recover access safely?",
    outcome:
      "Fails deliberately on first delivery. Replay creates a new event; with at least two attempts configured, its first attempt fails transiently before succeeding.",
    source: "demo-failed-event-replay.sh / DemoFailureInjector",
    requires: "demo-failures",
  },
];

export const feedbackSamples = [
  {
    id: "tenant",
    name: "Include tenant context",
    reason:
      "The affected account belongs to the test tenant. Include that context in the summary.",
  },
  {
    id: "correction",
    name: "Correct the affected account",
    reason:
      "This request concerns a test account, not a production account. Correct the summary and retain the original access-recovery request.",
  },
  { id: "custom", name: "Write your own feedback", reason: "" },
];
