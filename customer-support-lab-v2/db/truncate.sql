-- Destructive local-demo reset: stop the app and verify the schema first.
truncate table failed_ticket_event;
truncate table ticket_event_processed;
truncate table support_ticket cascade;
