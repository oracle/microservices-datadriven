-- Optional approval-history chapter. Run once as the application user.
-- Zero-day table retention permits deliberate lab cleanup; row retention is 16 days.
whenever sqlerror exit failure
create blockchain table ticket_approval_history (
    action_id       raw(16) primary key,
    ticket_id       number not null,
    decision        varchar2(16) not null check (decision in ('APPROVED', 'REJECTED')),
    actor_id        varchar2(128 char) not null,
    reason          varchar2(1000 char),
    reviewed_summary clob not null,
    summary_digest  varchar2(64) not null,
    summary_model   varchar2(256) not null,
    prompt_version  varchar2(64) not null,
    decided_at      timestamp default sys_extract_utc(systimestamp) not null,
    constraint fk_approval_ticket foreign key (ticket_id) references support_ticket(id)
)
no drop until 0 days idle
no delete until 16 days after insert
hashing using "SHA2_512" version "v2";

create index ticket_approval_ticket_idx on ticket_approval_history(ticket_id, decided_at);
