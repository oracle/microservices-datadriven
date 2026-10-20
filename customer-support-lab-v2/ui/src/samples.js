// Synthetic requests paired with the illustrative policies and historical cases in db/.
export const ticketSamples = [
  {
    id: "mfa",
    name: "Lost MFA authenticator",
    category: "AI enrichment",
    title: "Lost MFA authenticator",
    description:
      "I replaced my lost phone and cannot sign in to our Northstar demo tenant because the MFA prompt still targets the old authenticator. My password reset completed, but I have no registered backup factor or recovery method. I have not completed identity verification with support. How can I restore access without bypassing MFA?",
    outcome:
      "Separates a missing MFA factor from a password issue and proposes verified, administrator-assisted recovery. Compare the policy with the recorded reference outcome.",
    source: "MFA_RECOVERY policy / synthetic lost-authenticator reference",
  },
  {
    id: "access",
    name: "Account access",
    category: "Policy retrieval",
    title: "Password reset worked for personal account, not work tenant",
    description:
      "I can sign in to my personal account after resetting its password, but the Northstar demo tenant says account not found when I use my work email. My existing MFA factor still works. I may have reset the wrong account. What information should I provide to restore work access?",
    outcome:
      "Uses the account/tenant mismatch reference to suggest targeted troubleshooting rather than replacing a working MFA factor.",
    source: "ACCOUNT_ACCESS policy / synthetic sign-in reference",
  },
  {
    id: "billing",
    name: "Billing dispute",
    category: "Different intent",
    title: "Duplicate charge on invoice DEMO-1042",
    description:
      "My synthetic account shows two USD 49.00 card charges for invoice DEMO-1042, dated October 10 and October 11. Both entries are posted, not pending authorizations. I think this is a duplicate charge; please review it before making any refund or payment changes.",
    outcome:
      "Provides enough charge detail for a billing-review suggestion, grounded in a different historical invoice. A previous adjustment does not authorize a new refund.",
    source: "BILLING_DISPUTE policy",
  },
  {
    id: "unsupported",
    name: "Outside the policy corpus",
    category: "Evidence limits",
    title: "Change the CSV export separator",
    description:
      "In our synthetic reporting workspace, I need exported CSV files to use semicolons instead of commas. Where is that setting, and is it configurable for each report? I can open the reporting workspace successfully.",
    outcome:
      "The corpus has no reporting configuration guidance. Look for an acknowledgement of missing evidence and a request for product/report details, rather than invented menu instructions. Retrieval may still return weak matches.",
    source: "Evidence-limit example; no matching seeded policy or recorded resolution",
  },
  {
    id: "failure",
    name: "Failure → replay → retry",
    category: "Recovery",
    title: "[demo-fail-once] Lost MFA authenticator",
    description:
      "I replaced my lost phone and cannot sign in to our Northstar demo tenant because the MFA prompt still targets the old authenticator. My password reset completed, but I have no registered backup factor or recovery method. I have not completed identity verification with support. How can I restore access without bypassing MFA?",
    outcome:
      "Fails deliberately on first delivery. Replay creates a new event; with at least two attempts configured, its first attempt fails transiently before succeeding.",
    source: "README failure walkthrough / DemoFailureInjector",
  },
];
