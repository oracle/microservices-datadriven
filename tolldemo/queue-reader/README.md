# mark's dodgy bodgy sql slower downer

```sql
create or replace function remove_state(plate in varchar2)
return varchar2
is
begin
  dbms_lock.sleep(dbms_random.value(0.004,0.005));
  return regexp_replace(plate, '[A-Z]+-', '', 1, 1);
end;
```
