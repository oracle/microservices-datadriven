-- Illustrative policies for this lab, not production account or billing procedures.
-- Refresh only changed seed text; unchanged embeddings remain valid.
whenever sqlerror exit failure
merge into support_policy t
using (select 'ACCOUNT_ACCESS' policy_id, 'Account access and password reset' title,
              'Illustrative lab policy for sign-in failures after a password reset. Collect the affected account identifier, intended organization or tenant, exact sign-in error, and whether the reset completed. Never request a password, reset token, or one-time code. Verify identity through the approved recovery process before any account change. Check that the reset and sign-in target the same account and tenant; a reset for a personal account does not restore access to an organization account. Guide the requester through the approved reset flow for the correct account if needed, then ask them to confirm sign-in. Revoke sessions only when compromise is suspected, not for every sign-in error. Escalate unresolved tenant membership or access restrictions to the account administrator; do not bypass MFA or grant access based on a ticket.' body from dual) s
on (t.policy_id = s.policy_id)
when matched then update set t.title = s.title, t.body = s.body, t.embedding = null
    where t.title <> s.title or t.body <> s.body
when not matched then insert (policy_id, title, body)
    values (s.policy_id, s.title, s.body);

merge into support_policy t
using (select 'MFA_RECOVERY' policy_id, 'Multi-factor authentication recovery' title,
              'Illustrative lab policy for a lost or replaced MFA authenticator. Ask which account and organization or tenant are affected and whether a previously registered backup factor or recovery method is still available. Never ask the requester to send a password, one-time code, or recovery code in a ticket. If a registered recovery method is available, guide the user through the approved recovery flow. Otherwise route the request for identity verification and administrator-assisted recovery; do not disable or bypass MFA based only on the request. After identity is verified, an authorized administrator can revoke the lost factor and help enroll a replacement. Ask the requester to confirm a successful sign-in. A completed password reset alone is not identity verification and does not replace the missing MFA factor.' body from dual) s
on (t.policy_id = s.policy_id)
when matched then update set t.title = s.title, t.body = s.body, t.embedding = null
    where t.title <> s.title or t.body <> s.body
when not matched then insert (policy_id, title, body)
    values (s.policy_id, s.title, s.body);

merge into support_policy t
using (select 'BILLING_DISPUTE' policy_id, 'Billing dispute review' title,
              'Illustrative lab policy for suspected duplicate invoice charges. Collect the invoice identifier, dates, amounts and currency of both entries, and whether each entry is pending or posted. Do not collect full card numbers or banking credentials. A pending authorization is not evidence of a second settled charge; explain this distinction and ask for the entry status if missing. Route two posted charges for the same invoice to the billing team for review with the collected details. Only billing review can confirm a duplicate and authorize an adjustment. Do not promise a refund, issue one, or change payment details based on a support request or a similar historical case.' body from dual) s
on (t.policy_id = s.policy_id)
when matched then update set t.title = s.title, t.body = s.body, t.embedding = null
    where t.title <> s.title or t.body <> s.body
when not matched then insert (policy_id, title, body)
    values (s.policy_id, s.title, s.body);

commit;
