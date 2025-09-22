drop view ticket_dv;
drop table related_ticket;
drop index ticket_Vector_ivf_idx;
drop table support_ticket;

-- drop the user to completely remove the lab schema
drop user testuser cascade;