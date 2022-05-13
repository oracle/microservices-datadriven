-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

SET ECHO ON

alter table inventory add inventorydescription varchar (32);

update inventory set inventorydescription='California Roll' where inventoryid='sushi';
update inventory set inventorydescription='Pizza Margherita' where inventoryid='pizza';
update inventory set inventorydescription='Classic Burger' where inventoryid='burger';


