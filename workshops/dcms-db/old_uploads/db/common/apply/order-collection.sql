-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- order_collection package
create or replace package order_collection
  authid current_user
as
  procedure insert_order (in_order in json_object_t);
  function  get_order (in_order_id in varchar2) return json_object_t;
  procedure update_order (in_order in json_object_t);
  procedure delete_all_orders;
  procedure create_collection;
  procedure drop_collection;
end order_collection;
/
show errors

create or replace package body order_collection
as
  -- Private constants
  collection_metadata   constant varchar2(4000) := '{"keyColumn" : {"assignmentMethod": "CLIENT"}}';
  collection_name       constant nvarchar2(20) := 'orderscollection';

  function get_collection return soda_collection_t
  is
  begin
    return dbms_soda.open_collection(collection_name);
  end get_collection;

  procedure insert_order (in_order in json_object_t)
  is
    order_doc   soda_document_t;
    status      number;
    collection  soda_collection_t;
  begin
    -- write the order object
    order_doc := soda_document_t(in_order.get_string('orderid'), in_order.to_blob);
    collection := get_collection;
    status := collection.insert_one(order_doc);
  end insert_order;

  function get_order (in_order_id in varchar2) return json_object_t
  is
    order_doc   soda_document_t;
    status      number;
    collection  soda_collection_t;
  begin
    -- get the order object
    collection := get_collection;
    order_doc := collection.find().key(in_order_id).get_one;
    return json_object_t(order_doc.get_blob);
  end get_order;

  procedure update_order (in_order in json_object_t)
  is
    order_doc   soda_document_t;
    status      number;
    collection  soda_collection_t;
  begin
    -- update the order object
    order_doc := soda_document_t(in_order.get_string('orderid'), in_order.to_blob);
    collection := get_collection;
    status := collection.replace_one(in_order.get_string('orderid'), order_doc);
  end update_order;

  procedure delete_all_orders
  is
    status      number;
    collection  soda_collection_t;
  begin
    -- write the order object
    collection := get_collection;
    status := collection.truncate;
  end delete_all_orders;

  procedure create_collection
  is
    collection  soda_collection_t;
  begin
    collection := dbms_soda.create_collection(collection_name => collection_name, metadata => collection_metadata);
  end create_collection;

  procedure drop_collection
  is
    status number;
  begin
    status := dbms_soda.drop_collection(collection_name => collection_name);
  end drop_collection;

end order_collection;
/
show errors

-- Create the order collection
begin
  order_collection.create_collection;
end;
/
