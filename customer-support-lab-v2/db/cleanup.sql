-- Destructive removal of the local lab schema.
drop table ticket_policy_match;
drop table ticket_assistance;
drop table support_policy;
drop table failed_ticket_event;
drop table ticket_event_processed;
drop table related_ticket;
drop table support_ticket;

-- drop the user to completely remove the lab schema
drop user &&app_username cascade;
