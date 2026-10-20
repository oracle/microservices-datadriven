-- Synthetic resolved cases, not real customer outcomes or generated suggestions.
-- Refresh only imported, unreviewed reference cases; never rewrite generated assistance or review history.
whenever sqlerror exit failure
merge into support_ticket t
using (select '[Reference] Lost MFA authenticator' title,
              'Training case: a user replaced a lost phone and could not sign in to the Northstar demo tenant because MFA still targeted the old authenticator. A password reset had completed, but no registered backup factor was available.' description,
              'Synthetic recorded outcome: support established that the missing MFA factor, not the password, blocked sign-in. Because the requester had no backup factor, support routed the case to an authorized administrator for identity verification. After verification, the administrator revoked the lost factor, helped enroll a replacement, and the user confirmed access to the Northstar demo tenant. Password reset alone did not satisfy verification; MFA was not bypassed.' resolution from dual) s
on (t.title = s.title)
when matched then update set t.description = s.description, t.resolution = s.resolution,
                            t.embedding = null
    where t.workflow_status = 'TRIAGED' and t.review_feedback is null
      and t.description like 'Training case:%'
      and (t.description <> s.description or t.resolution is null
           or dbms_lob.compare(t.resolution, to_clob(s.resolution)) <> 0)
when not matched then insert (title, description, workflow_status, resolution)
    values (s.title, s.description, 'TRIAGED', s.resolution);

merge into support_ticket t
using (select '[Reference] Sign-in failure after password reset' title,
              'Training case: a user could sign in to a personal account after resetting its password, but still received account-not-found when opening the Northstar demo tenant with a different work email. The registered MFA factor was available.' description,
              'Synthetic recorded outcome: support collected the work account identifier, intended tenant, and exact account-not-found error without collecting credentials. Identity was verified before an authorized administrator confirmed that the reset targeted a personal account rather than the work account. The user completed the approved reset for the correct work account and confirmed sign-in to the Northstar demo tenant using the existing MFA factor. No MFA replacement or blanket session revocation was needed.' resolution from dual) s
on (t.title = s.title)
when matched then update set t.description = s.description, t.resolution = s.resolution,
                            t.embedding = null
    where t.workflow_status = 'TRIAGED' and t.review_feedback is null
      and t.description like 'Training case:%'
      and (t.description <> s.description or t.resolution is null
           or dbms_lob.compare(t.resolution, to_clob(s.resolution)) <> 0)
when not matched then insert (title, description, workflow_status, resolution)
    values (s.title, s.description, 'TRIAGED', s.resolution);

merge into support_ticket t
using (select '[Reference] Duplicate invoice charge' title,
              'Training case: invoice DEMO-1038 for USD 49.00 showed two posted card charges dated October 3 and October 4 in a synthetic billing account. Neither entry was a pending authorization.' description,
              'Synthetic recorded outcome: support collected the invoice identifier, both charge dates, amounts, currency, and posted status, without requesting full payment credentials. Support routed the suspected duplicate to billing review. Billing confirmed that both posted charges belonged to the same invoice and authorized a USD 49.00 adjustment. Support relayed the billing decision. This outcome does not authorize a refund for a new requester or establish that a pending entry is a duplicate charge.' resolution from dual) s
on (t.title = s.title)
when matched then update set t.description = s.description, t.resolution = s.resolution,
                            t.embedding = null
    where t.workflow_status = 'TRIAGED' and t.review_feedback is null
      and t.description like 'Training case:%'
      and (t.description <> s.description or t.resolution is null
           or dbms_lob.compare(t.resolution, to_clob(s.resolution)) <> 0)
when not matched then insert (title, description, workflow_status, resolution)
    values (s.title, s.description, 'TRIAGED', s.resolution);

commit;
