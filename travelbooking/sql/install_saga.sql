create table saga_message_broker$ (
             id  RAW(16) not NULL,         -- broker identifier GUID
             name VARCHAR2(128) not NULL,  -- broker name
             owner VARCHAR2(128) not NULL, -- owner
             broker_topic VARCHAR2(128),   -- broker JMS topic
             remote  NUMBER not NULL,      -- local or remote
                                           -- local=0
                                           -- remote=1
             CONSTRAINT SAGA$_MESSAGE_BROKER_PK primary key (id),
             CONSTRAINT SAGA$_MESSAGE_BROKER_UNIQUE UNIQUE(name,remote)
);

create table saga_participant$ (
             id  RAW(16) not NULL,               -- participant GUID
             name VARCHAR2(128) not NULL,        -- participant name
             owner VARCHAR2(128) not NULL,       -- participant owner#
             type NUMBER not NULL,               -- participant type
                                                    -- 0 participant
                                                    -- 1 coordinator
             broker_id  RAW(16) not NULL,        -- broker id
             coordinator_id   RAW(16),           -- coordinator id
             dblink_to_broker VARCHAR2(128),     -- dblink to broker
             dblink_to_participant   VARCHAR2(128),
                                                     -- dblink to participant
             incoming_topic VARCHAR2(128) not NULL,  -- saga IN topic
             outgoing_topic VARCHAR2(128) not NULL,  -- saga OUT topic
 	     callback_schema VARCHAR2(128),          -- callback schema
	     callback_package VARCHAR2(128),         -- callback package name
	     participant_iscomplete NUMBER,          -- is participant complete?
                                                   -- i.e attached to a callback
             remote  NUMBER not NULL,                -- local or remote
                                                        -- local=0
                                                        -- remote=1
             CONSTRAINT SAGA_PARTICIPANT$_PK primary key (id),
             CONSTRAINT SAGA_PARTICIPANT$_UNIQUE UNIQUE(name,broker_id),
             CONSTRAINT saga_participant_broker_constraint
             FOREIGN KEY (broker_id)
             REFERENCES SAGA_MESSAGE_BROKER$(ID) ON DELETE CASCADE
);

create table saga$ (
             id RAW(16) not NULL,               -- Saga identifier GUID
             saga_level  NUMBER not NULL,       -- level for the saga depth
                                                  -- 0 for saga initiator
                                                  -- 1 for saga participant
             initiator   VARCHAR2(128),         -- initiator name
             coordinator VARCHAR2(128),         -- coordinator name
             owner       VARCHAR2(128) not NULL,   -- participant schema
             participant VARCHAR2(128) not NULL,   -- participant name
             duration NUMBER,                   -- saga duration,
             begin_time  TIMESTAMP WITH TIME ZONE not NULL,  -- begin time
             end_time    TIMESTAMP WITH TIME ZONE,           -- end time
             status  NUMBER,                                 -- status
             CONSTRAINT SAGA$_PK primary key (id, participant)
);

create table saga_finalization$ (
             saga_id RAW(16) not NULL,         -- Saga identifier GUID
             participant VARCHAR2(128),        -- participant name
             txn_id RAW(16) not NULL,          -- local txn's txn id
             user#  NUMBER not NULL,           -- user# for txn
             escrow_obj# NUMBER not NULL,      -- obj# for escrow entry
             status  NUMBER not NULL,           -- status
        CONSTRAINT saga_finalization$_fk FOREIGN KEY(saga_id, participant)
        REFERENCES saga$(ID, PARTICIPANT) ON DELETE CASCADE
);

create table saga_participant_set$ (
             saga_id RAW(16) not NULL,            -- Saga identifier GUID
             coordinator VARCHAR2(128) not NULL,  -- coordinator name
             participant VARCHAR2(128) not NULL,  -- participant name
             status NUMBER not NULL,              -- status
             join_time  TIMESTAMP WITH TIME ZONE, -- join time
             completion_time TIMESTAMP WITH TIME ZONE  -- completion time
);

create table saga_secrets$ (
             id RAW(16) not NULL,                  -- participant id
             secret NUMBER not NULL,               -- saga secret
             operation NUMBER not NULL,            -- saga operation
             secret_time TIMESTAMP WITH TIME ZONE, -- secret time
        CONSTRAINT saga_secrets$_fk FOREIGN KEY(id)
        REFERENCES saga_participant$(ID) ON DELETE CASCADE
);

--creating role for saga admin operations
--CREATE ROLE saga_adm_role
--/
--creating role for saga participant operations
--CREATE ROLE saga_participant_role
--/
--creating role for saga connection operations
--CREATE ROLE saga_connect_role
--/
create or replace package dbms_saga_adm as

/* Will be added as a child project later */
--PRAGMA SUPPLEMENTAL_LOG_DATA(default, AUTO_WITH_COMMIT);

------------------------------------------------------------------------------
--------------------------PROCEDURES AND FUNCTIONS----------------------------
------------------------------------------------------------------------------

procedure add_coordinator(coordinator_name IN varchar2 ,
                          coordinator_schema IN varchar2
                          DEFAULT sys_context('USERENV' , 'CURRENT_USER'),
                          storage_clause IN varchar2 DEFAULT NULL,
                          dblink_to_broker IN varchar2 DEFAULT NULL,
                          mailbox_schema IN varchar2,
                          broker_name IN varchar2,
                          dblink_to_coordinator IN varchar2 DEFAULT NULL);


procedure drop_coordinator(coordinator_name IN varchar2);


procedure add_participant(participant_name IN varchar2 ,
                          participant_schema IN varchar2
                          DEFAULT sys_context('USERENV' , 'CURRENT_USER'),
                          storage_clause IN varchar2 DEFAULT NULL,
                          coordinator_name IN varchar2 DEFAULT NULL,
                          dblink_to_broker IN varchar2 DEFAULT NULL,
                          mailbox_schema IN varchar2,
                          broker_name IN varchar2,
                          callback_schema IN varchar2
                          DEFAULT sys_context('USERENV' , 'CURRENT_USER'),
                          callback_package IN varchar2 DEFAULT NULL,
                          dblink_to_participant IN varchar2 DEFAULT NULL);


procedure drop_participant(participant_name IN varchar2);


procedure add_broker(broker_name IN varchar2 ,
                     broker_schema IN varchar2
                     DEFAULT sys_context('USERENV' , 'CURRENT_USER'),
                     storage_clause IN varchar2 DEFAULT NULL);


procedure drop_broker(broker_name in varchar2);


procedure register_saga_callback(participant_name IN varchar2,
                                 callback_schema IN varchar2
                                 DEFAULT sys_context('USERENV','CURRENT_USER'),
                                 callback_package IN varchar2);

procedure notify_callback_coordinator(context RAW ,
                                      reginfo sys.aq$_reg_info ,
                                      descr sys.aq$_descriptor ,
                                      payload RAW ,
                                      payloadl NUMBER);

-------------------------------------------------------------------------------
------------------------------- EXCEPTIONS ------------------------------------
-------------------------------------------------------------------------------
ROLLINGUNSUPPORTED          EXCEPTION;
PRAGMA                      EXCEPTION_INIT(ROLLINGUNSUPPORTED, -45493);

END dbms_saga_adm;
/
show errors;
create or replace package dbms_saga as

/* Will be added later */
--PRAGMA SUPPLEMENTAL_LOG_DATA(default, MANUAL);

-------------------------------------------------------------------------------
---------------------------------OPCODES---------------------------------------
-------------------------------------------------------------------------------
CMT_SAGA CONSTANT NUMBER := 1;
ABRT_SAGA CONSTANT NUMBER := 2;
REQUEST CONSTANT NUMBER := 4;
RESPONSE CONSTANT NUMBER := 5;
CMT_FAIL CONSTANT NUMBER := 6;
ABRT_FAIL CONSTANT NUMBER := 7;

-------------------------------------------------------------------------------
-------------------------------- SUBTYPES -------------------------------------
-------------------------------------------------------------------------------
subtype saga_id_t IS RAW(16);

-------------------------------------------------------------------------------
------------------------------- EXCEPTIONS ------------------------------------
-------------------------------------------------------------------------------

ROLLINGUNSUPPORTED          EXCEPTION;
PRAGMA                      EXCEPTION_INIT(ROLLINGUNSUPPORTED, -45493);


-------------------------------------------------------------------------------
------------------------- PROCEDURES AND FUNCTIONS ----------------------------
-------------------------------------------------------------------------------
function begin_saga(initiator_name IN VARCHAR2 ,
                    timeout IN number DEFAULT 86400) return saga_id_t;

procedure enroll_participant(saga_id        IN saga_id_t,
                             sender         IN VARCHAR2,
                             recipient      IN VARCHAR2,
                             coordinator    IN VARCHAR2,
                             payload        IN JSON DEFAULT NULL);

function get_saga_id return saga_id_t;

procedure set_saga_id(saga_id IN saga_id_t);

procedure commit_saga(saga_participant IN VARCHAR2,
                      saga_id IN saga_id_t,
                      force IN boolean DEFAULT TRUE);

procedure rollback_saga(saga_participant IN VARCHAR2,
                        saga_id IN saga_id_t,
                        force IN boolean DEFAULT TRUE);

procedure forget_saga(saga_id IN saga_id_t);

procedure leave_saga(saga_id IN saga_id_t);

procedure after_saga(saga_id IN saga_id_t);

function is_incomplete(saga_id IN saga_id_t) return boolean;

function get_out_topic(entity_name IN varchar2) return varchar2;

procedure set_incomplete(saga_id IN saga_id_t);

procedure notify_callback_participant(context RAW,
                                      reginfo sys.aq$_reg_info,
                                      descr sys.aq$_descriptor,
                                      payload RAW,
                                      payloadl NUMBER);

procedure set_saga_sender(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                          sender IN varchar2);

procedure set_saga_recipient(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                             recipient IN varchar2);

procedure set_saga_opcode(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                          opcode IN NUMBER);

procedure set_saga_id(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                      saga_id IN RAW);

procedure set_saga_coordinator(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                               saga_coordinator IN VARCHAR2);

function get_saga_sender(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return VARCHAR2;

function get_saga_recipient(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return VARCHAR2;

function get_saga_opcode(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return NUMBER;

function get_saga_id(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return RAW;

function get_saga_coordinator(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return VARCHAR2;

end dbms_saga;
/
show errors;
create or replace package dbms_saga_adm_sys ACCESSIBLE BY
(PACKAGE DBMS_SAGA_ADM, DBMS_SAGA_CONNECT_INT) AS

-------------------------------------------------------------------------------
----------------------------ENTITY CONSTANTS-----------------------------------
-------------------------------------------------------------------------------
PARTICIPANT             CONSTANT NUMBER := 0;
COORDINATOR             CONSTANT NUMBER := 1;

-------------------------------------------------------------------------------
------------------------------- LOCATION---------------------------------------
-------------------------------------------------------------------------------
DBMS_LOCAL              CONSTANT NUMBER := 0;
DBMS_REMOTE             CONSTANT NUMBER := 1;

-------------------------------------------------------------------------------
----------------------------CALLBACK STATUS------------------------------------
-------------------------------------------------------------------------------
INCOMPLETE              CONSTANT NUMBER := 0;
COMPLETED               CONSTANT NUMBER := 1;

-------------------------------------------------------------------------------
--------------------------------SUBTYPES---------------------------------------
-------------------------------------------------------------------------------
subtype saga_id_t IS RAW(16);

-------------------------------------------------------------------------------
----------------------------- ENTITY STATES------------------------------------
-------------------------------------------------------------------------------
BROKER_MAX_STATE        CONSTANT NUMBER := 2;
PARTICIPANTENTRYDONE    CONSTANT NUMBER := 7;
BROKERENTRYDONE         CONSTANT NUMBER := 6;
CALLBACKDONE            CONSTANT NUMBER := 5;
PROPAGATIONDONE         CONSTANT NUMBER := 4;
BROKERSUBDONE           CONSTANT NUMBER := 3;
OUTBOUNDDONE            CONSTANT NUMBER := 2;
INBOUNDDONE             CONSTANT NUMBER := 1;
REGREMOTEDONE           CONSTANT NUMBER := 3;
REGLOCALDONE            CONSTANT NUMBER := 2;
REGCALLBACKDONE         CONSTANT NUMBER := 1;

-------------------------------------------------------------------------------
---------------------------------OPERATIONS------------------------------------
-------------------------------------------------------------------------------
CONNECT_BROKER          CONSTANT NUMBER := 1;
DISCONNECT_BROKER       CONSTANT NUMBER := 2;
UPDATE_CALLBACK         CONSTANT NUMBER := 3;

-------------------------------------------------------------------------------
---------------------------VALIDATION OPERATIONS-------------------------------
-------------------------------------------------------------------------------
CREATEENTITY            CONSTANT NUMBER := 0;
CREATEPACKAGE           CONSTANT NUMBER := 1;

------------------------------------------------------------------------------
--------------------------PROCEDURES AND FUNCTIONS----------------------------
------------------------------------------------------------------------------

procedure add_coordinator(coordinator_name IN varchar2 ,
                          coordinator_schema IN varchar2,
                          storage_clause IN varchar2 DEFAULT NULL,
                          dblink_to_broker IN varchar2 DEFAULT NULL,
                          mailbox_schema IN varchar2,
                          broker_name IN varchar2,
                          dblink_to_coordinator IN varchar2 DEFAULT NULL,
                          current_user IN varchar2);

procedure drop_coordinator(coordinator_name IN varchar2);

procedure add_participant(participant_name IN varchar2 ,
                          participant_schema IN varchar2,
                          storage_clause IN varchar2 DEFAULT NULL,
                          coordinator_name IN varchar2 DEFAULT NULL,
                          dblink_to_broker IN varchar2 DEFAULT NULL,
                          mailbox_schema IN varchar2,
                          broker_name IN varchar2,
                          callback_schema IN varchar2,
                          callback_package IN varchar2 DEFAULT NULL,
                          dblink_to_participant IN varchar2 DEFAULT NULL,
                          current_user IN varchar2);

procedure drop_participant(participant_name IN varchar2);

procedure add_broker(broker_name IN varchar2 ,
                     broker_schema IN varchar2,
                     storage_clause IN varchar2 DEFAULT NULL,
                     current_user IN varchar2);

procedure drop_broker(broker_name in varchar2);

procedure connectBrokerToInqueue(participant_id IN RAW,
                                 entity_name_int IN varchar2 ,
                                 entity_schema_int IN varchar2 ,
                                 coordinatorOrParticipant IN number,
                                 broker_id IN RAW,
                                 coordinator_id IN RAW,
                                 dblink_to_broker_int IN varchar2,
                                 dblink_to_entity_int IN varchar2,
                                 inbound_queue IN varchar2,
                                 outbound_queue IN varchar2,
                                 callback_schema_int IN varchar2 ,
                                 callback_package_int IN varchar2 ,
                                 participant_iscomplete IN number,
                                 broker_schema_int IN varchar2 ,
                                 broker_name_int IN varchar2,
                                 saga_secret IN number);

procedure disconnectBrokerFromInqueue(entity_name_int IN varchar2 ,
                                      entity_schema_int IN varchar2,
                                      dblink_to_entity_int IN varchar2,
                                      broker_schema_int IN varchar2,
                                      broker_name_int IN varchar2,
                                      dblink_to_broker IN varchar2,
                                      entity_id IN RAW,
                                      saga_secret IN number);

procedure register_saga_callback(participant_name IN varchar2,
                                 callback_schema IN varchar2,
                                 callback_package IN varchar2);

function uniqueEntityAtPDB(entity_name IN varchar2,
                           broker_name IN varchar2,
                           mailbox_schema IN varchar2,
                           broker_pdb_link IN varchar2,
                           entity_dblink IN varchar2) return boolean;

procedure getBrokerInfo(broker_id IN OUT RAW,
                        broker_name IN OUT varchar2,
                        broker_schema IN OUT varchar2,
                        isCreate IN BOOLEAN);

procedure updateCallbackInfo(cbk_schema IN varchar2,
                             cbk_package IN varchar2,
                             p_status IN number,
                             p_id IN RAW,
                             saga_secret IN number);

function validateSecret(entity_id IN RAW,
                        saga_operation IN NUMBER,
                        saga_secret IN NUMBER) return boolean;

procedure process_notification(recipient IN varchar2,
                               sender IN varchar2,
                               deq_saga_id IN saga_id_t,
                               opcode IN number,
                               coordinator IN varchar2,
                               req_res IN clob);

-------------------------------------------------------------------------------
------------------------------- EXCEPTIONS ------------------------------------
-------------------------------------------------------------------------------
CONNECTTOBROKERFAILURE      EXCEPTION;
PRAGMA                      EXCEPTION_INIT(CONNECTTOBROKERFAILURE, -20001);


END dbms_saga_adm_sys;
/
show errors;
create or replace package dbms_saga_sys ACCESSIBLE BY
(PACKAGE DBMS_SAGA, DBMS_SAGA_ADM_SYS) AS

-------------------------------------------------------------------------------
---------------------------- ENTITY CONSTANTS ---------------------------------
-------------------------------------------------------------------------------
INITIATOR CONSTANT NUMBER := 0;
PARTICIPANT CONSTANT NUMBER := 1;

-------------------------------------------------------------------------------
------------------------------ SAGA STATUS ------------------------------------
-------------------------------------------------------------------------------
JOINING CONSTANT NUMBER := -1;
INITIATED CONSTANT NUMBER := 0;
JOINED CONSTANT NUMBER := 0;
FINALIZATION CONSTANT NUMBER := 1;
COMMITED CONSTANT NUMBER := 2;
ROLLEDBACK CONSTANT NUMBER := 3;
COMMIT_FAILED CONSTANT NUMBER := 4;
ROLLEDBACK_FAILED CONSTANT NUMBER := 5;

-------------------------------------------------------------------------------
-------------------------------- SUBTYPES -------------------------------------
-------------------------------------------------------------------------------
subtype saga_id_t IS RAW(16);

-------------------------------------------------------------------------------
---------------------------------OPCODES---------------------------------------
-------------------------------------------------------------------------------
JOIN_SAGA CONSTANT NUMBER := 0;
CMT_SAGA CONSTANT NUMBER := 1;
ABRT_SAGA CONSTANT NUMBER := 2;
ACK_SAGA CONSTANT NUMBER := 3;
REQUEST CONSTANT NUMBER := 4;
RESPONSE CONSTANT NUMBER := 5;
CMT_FAIL CONSTANT NUMBER := 6;
ABRT_FAIL CONSTANT NUMBER := 7;

-------------------------------------------------------------------------------
------------------------------ JOIN STATUS ------------------------------------
-------------------------------------------------------------------------------
JOIN_EXISTS CONSTANT NUMBER := -1;
JOIN_SUCCESS CONSTANT NUMBER := 0;
JOIN_SKIP CONSTANT NUMBER := 1;

-------------------------------------------------------------------------------
------------------------------- EXCEPTIONS ------------------------------------
-------------------------------------------------------------------------------

ROLLINGUNSUPPORTED          EXCEPTION;
PRAGMA                      EXCEPTION_INIT(ROLLINGUNSUPPORTED, -45493);


-------------------------------------------------------------------------------
------------------------- PROCEDURES AND FUNCTIONS ----------------------------
-------------------------------------------------------------------------------
function begin_saga(initiator_name IN VARCHAR2 ,
                    timeout IN number DEFAULT NULL,
                    current_user IN VARCHAR2) return saga_id_t;

function join_saga_int(saga_id         IN  saga_id_t,
                       initiator_name  IN  VARCHAR2,
                       saga_initiator  IN  VARCHAR2,
                       coordinator     IN  VARCHAR2,
                       payload         IN  CLOB) return NUMBER;

procedure commit_saga(saga_participant IN VARCHAR2,
                      saga_id IN saga_id_t,
                      force IN boolean DEFAULT TRUE,
                      current_user IN varchar2);

procedure rollback_saga(saga_participant IN VARCHAR2,
                        saga_id IN saga_id_t,
                        force IN boolean DEFAULT TRUE,
                        current_user IN varchar2);

function get_out_topic(entity_name IN varchar2) return varchar2;

procedure process_notification(recipient IN varchar2,
                               sender IN varchar2,
                               saga_id IN saga_id_t,
                               opcode IN number,
                               coordinator IN varchar2,
                               req_res IN clob);

end dbms_saga_sys;
/
show errors;
create or replace package dbms_saga_connect_int as

-------------------------------------------------------------------------------
------------------------------- EXCEPTIONS ------------------------------------
-------------------------------------------------------------------------------

ROLLINGUNSUPPORTED          EXCEPTION;
PRAGMA                      EXCEPTION_INIT(ROLLINGUNSUPPORTED, -45493);

------------------------------------------------------------------------------
--------------------------PROCEDURES AND FUNCTIONS----------------------------
------------------------------------------------------------------------------

procedure connectBrokerToInqueue(participant_id IN RAW,
                                 entity_name_int IN varchar2 ,
                                 entity_schema_int IN varchar2 ,
                                 coordinatorOrParticipant IN number,
                                 broker_id IN RAW,
                                 coordinator_id IN RAW,
                                 dblink_to_broker_int IN varchar2,
                                 dblink_to_entity_int IN varchar2,
                                 inbound_queue IN varchar2,
                                 outbound_queue IN varchar2,
                                 callback_schema_int IN varchar2 ,
                                 callback_package_int IN varchar2 ,
                                 participant_iscomplete IN number,
                                 broker_schema_int IN varchar2 ,
                                 broker_name_int IN varchar2,
                                 saga_secret IN NUMBER);

procedure disconnectBrokerFromInqueue(entity_name_int IN varchar2 ,
                                      entity_schema_int IN varchar2,
                                      dblink_to_entity_int IN varchar2,
                                      broker_schema_int IN varchar2,
                                      broker_name_int IN varchar2,
                                      dblink_to_broker IN varchar2,
                                      entity_id IN RAW,
                                      saga_secret IN NUMBER);

function uniqueEntityAtPDB(entity_name IN varchar2,
                           broker_name IN varchar2,
                           mailbox_schema IN varchar2,
                           broker_pdb_link IN varchar2,
                           entity_dblink IN varchar2) return boolean;

procedure getBrokerInfo(broker_id IN OUT RAW,
                        broker_name IN OUT varchar2,
                        broker_schema IN OUT varchar2,
                        isCreate IN BOOLEAN);

procedure updateCallbackInfo(cbk_schema IN varchar2,
                             cbk_package IN varchar2,
                             p_status IN number,
                             p_id IN RAW,
                             saga_secret IN NUMBER);

function validateSecret(entity_id IN RAW,
                        saga_operation IN NUMBER,
                        saga_secret IN NUMBER) return boolean;

end dbms_saga_connect_int;
/
show errors;
create or replace package body dbms_saga_adm as

-------------------------------------------------------------------------------
----------------------------INTERNAL PROCEDURES--------------------------------
-------------------------------------------------------------------------------
procedure write_trace(message IN varchar2,
                      event IN binary_integer DEFAULT 10855,
                      event_level IN binary_integer DEFAULT 1,
                      time_info IN boolean DEFAULT FALSE);

procedure dump_trace(message IN varchar2,
                     time_info IN boolean DEFAULT FALSE);

-------------------------------------------------------------------------------
-------------------------------BODY DECLARATION--------------------------------
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
-- NAME :
--    add_broker
--
-- PARAMETERS :
--    broker_name      (IN) - name of the broker
--    broker_schema    (IN) - broker's schema
--    storage_clause   (IN)
--
--  DESCRIPTION:
--    This procedure creates the saga broker. It creates the respective
--    queue table, queue , starts the queue and inserts the broker entry
--    into the sys.saga_message_broker$ table.
--
-------------------------------------------------------------------------------

procedure add_broker(broker_name     IN VARCHAR2 ,
                     broker_schema   IN VARCHAR2
                     DEFAULT sys_context('USERENV', 'CURRENT_USER'),
                     storage_clause  IN VARCHAR2 DEFAULT NULL) AS

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_adm.ROLLINGUNSUPPORTED;
  END IF;

  write_trace('ADD_BROKER : BEGIN ADD_BROKER');

  dbms_saga_adm_sys.add_broker(
                     broker_name => broker_name,
                     broker_schema => broker_schema,
                     storage_clause => storage_clause,
                     current_user => sys_context('USERENV', 'CURRENT_USER'));

  write_trace('ADD_BROKER : END ADD_BROKER');

END;

-------------------------------------------------------------------------------
--
-- NAME :
--    add_coordinator
--
-- PARAMETERS :
--    coordinator_name      (IN) - name of the coordinator
--    coordinator_schema    (IN) - coordinator's schema
--    storage_clause        (IN)
--    dblink_to_broker      (IN) - dblink to the broker queue
--    mailbox schema        (IN) - broker's schema
--    broker_name           (IN) - broker's name
--    dblink_to_coordinator (IN) - dblink of the coordinator
--
--  DESCRIPTION:
--    This procedure creates the saga coordinator. The procedure calls
--    an internal procedure addParticipantOrCoordinator. It creates the
--    inbound/outbound queues for the coordinator and sets up the coordinator
--
-------------------------------------------------------------------------------

procedure add_coordinator(coordinator_name IN varchar2,
                          coordinator_schema IN varchar2
                          DEFAULT sys_context('USERENV' , 'CURRENT_USER'),
                          storage_clause IN varchar2 DEFAULT NULL,
                          dblink_to_broker IN varchar2 DEFAULT NULL,
                          mailbox_schema IN varchar2,
                          broker_name IN varchar2,
                          dblink_to_coordinator IN varchar2 DEFAULT NULL) as

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_adm.ROLLINGUNSUPPORTED;
  END IF;

  write_trace('ADD_COORDINATOR : BEGIN ADD_COORDINATOR');

  dbms_saga_adm_sys.add_coordinator(
                        coordinator_name => coordinator_name,
                        coordinator_schema => coordinator_schema,
                        storage_clause => storage_clause,
                        dblink_to_broker => dblink_to_broker,
                        mailbox_schema => mailbox_schema,
                        broker_name => broker_name,
                        dblink_to_coordinator => dblink_to_coordinator,
                        current_user => sys_context('USERENV', 'CURRENT_USER'));

  write_trace('ADD_COORDINATOR : END ADD_COORDINATOR');

END;

-------------------------------------------------------------------------------
--
-- NAME :
--    drop_coordinator
--
-- PARAMETERS :
--    coordinator_name      (IN) - name of the coordinator
--
--  DESCRIPTION:
--    This procedure drops an already existing saga coordinator.
--
-------------------------------------------------------------------------------

procedure drop_coordinator(coordinator_name IN varchar2) AS

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_adm.ROLLINGUNSUPPORTED;
  END IF;

  write_trace('DROP_COORDINATOR : BEGIN DROP_COORDINATOR');

  dbms_saga_adm_sys.drop_coordinator(coordinator_name => coordinator_name);

  write_trace('DROP_COORDINATOR : END DROP_COORDINATOR');

END;

-------------------------------------------------------------------------------
--
-- NAME :
--    add_participant
--
-- PARAMETERS :
--    participant_name      (IN) - name of the participant
--    participant_schema    (IN) - participant's schema
--    storage_clause        (IN)
--    coordinator_name      (IN) - name of the coordinator
--    dblink_to_broker      (IN) - dblink to the broker queue
--    mailbox schema        (IN) - broker's schema
--    broker_name           (IN) - broker's name
--    callback_schema       (IN) - schema of participant callback
--    callback_package      (IN) - participant callback
--    dblink_to_participant (IN) - dblink of the participant
--
--  DESCRIPTION:
--    This procedure creates a saga participant. The procedure calls an
--    internal procedure addParticipantOrCoordinator. It creates the
--    inbound/outbound queues for the participant and sets up the participant.
--
-------------------------------------------------------------------------------

procedure add_participant(participant_name IN varchar2,
                          participant_schema IN varchar2
                          DEFAULT sys_context('USERENV','CURRENT_USER'),
                          storage_clause IN varchar2 DEFAULT NULL,
                          coordinator_name IN varchar2 DEFAULT NULL,
                          dblink_to_broker IN varchar2 DEFAULT NULL,
                          mailbox_schema IN varchar2,
                          broker_name IN varchar2,
                          callback_schema IN varchar2
                          DEFAULT sys_context('USERENV','CURRENT_USER'),
                          callback_package IN varchar2 DEFAULT NULL,
                          dblink_to_participant IN varchar2 DEFAULT NULL) AS

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_adm.ROLLINGUNSUPPORTED;
  END IF;

  write_trace('ADD_PARTICIPANT : BEGIN ADD_PARTICIPANT');

  dbms_saga_adm_sys.add_participant(
                participant_name => participant_name,
                participant_schema => participant_schema,
                storage_clause => storage_clause,
                coordinator_name => coordinator_name,
                dblink_to_broker => dblink_to_broker,
                mailbox_schema => mailbox_schema,
                broker_name => broker_name,
                callback_schema => callback_schema,
                callback_package => callback_package,
                dblink_to_participant => dblink_to_participant,
                current_user => sys_context('USERENV', 'CURRENT_USER'));

  write_trace('ADD_PARTICIPANT : END ADD_PARTICIPANT');

END;

-------------------------------------------------------------------------------
--
-- NAME :
--    drop_participant
--
-- PARAMETERS :
--    participant_name      (IN) - name of the participant
--    drop_coordinator      (IN) - drop the coordinator along with participant
--
--  DESCRIPTION:
--    This procedure drops an already existing saga participant. It also drops
--    the participant's coordinator depending on the value of drop_coordinator
--
-------------------------------------------------------------------------------

procedure drop_participant(participant_name IN varchar2) AS

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_adm.ROLLINGUNSUPPORTED;
  END IF;

  write_trace('DROP_PARTICIPANT : BEGIN DROP_PARTICIPANT');

  dbms_saga_adm_sys.drop_participant(participant_name => participant_name);

  write_trace('ADD_PARTICIPANT : BEGIN ADD_PARTICIPANT');

END;

-------------------------------------------------------------------------------
--
-- NAME :
--    drop_broker
--
-- PARAMETERS :
--    broker_name      (IN) - name of the broker
--
--  DESCRIPTION:
--    This procedure drops an already existing saga broker.
--
-------------------------------------------------------------------------------

procedure drop_broker(broker_name in varchar2) as

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_adm.ROLLINGUNSUPPORTED;
  END IF;

  write_trace('DROP_BROKER : BEGIN DROP_BROKER');

  dbms_saga_adm_sys.drop_broker(broker_name => broker_name);

  write_trace('DROP_BROKER : END DROP_BROKER');

END;


-------------------------------------------------------------------------------
--
-- NAME :
--    register_saga_callback
--
-- PARAMETERS :
--      participant_name    (VARCHAR IN) - name of the participant
--      callback_schema     (VARCHAR IN) - participant callback schema
--      callback_package    (VARCHAR IN) - participant callback name
--
--  DESCRIPTION:
--    Registers a callback which the user declares if the user wants to
--    use a PL/SQL based saga infrastructure.
--
-------------------------------------------------------------------------------
procedure register_saga_callback(participant_name IN varchar2,
                              callback_schema IN varchar2
                              DEFAULT sys_context('USERENV' , 'CURRENT_USER'),
                              callback_package IN varchar2) as

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_adm.ROLLINGUNSUPPORTED;
  END IF;

  dbms_saga_adm_sys.register_saga_callback(
                        participant_name => participant_name,
                        callback_schema => callback_schema,
                        callback_package => callback_package);

END;


-------------------------------------------------------------------------------
--
-- NAME :
--    notify_callback_coordinator
--
--  DESCRIPTION:
--    This procedure is the coordinator notification callback.
--    When a coordinator is created it is registered to this procedure.
--    This procedure is repsonsible for dequeueing from the coordinator and
--    enqueueing messages to other participants in the saga infrastructure
--    based upon the opcode of the message.
--
-------------------------------------------------------------------------------
procedure notify_callback_coordinator(context RAW ,
                                      reginfo sys.aq$_reg_info ,
                                      descr sys.aq$_descriptor ,
                                      payload RAW ,
                                      payloadl NUMBER) as

  dequeue_options     sys.dbms_aq.dequeue_options_t;
  message_properties  dbms_aq.message_properties_t;
  message_handle      RAW(16);
  message             SYS.AQ$_JMS_TEXT_MESSAGE;
  enqueue_options     dbms_aq.enqueue_options_t;
  opcode              NUMBER;
  deq_saga_id         dbms_saga.saga_id_t;
  req_payload         CLOB;

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_adm.ROLLINGUNSUPPORTED;
  END IF;

  dequeue_options.msgid := descr.msg_id;
  dequeue_options.navigation := dbms_aq.first_message;

  --dequeue the message
  DBMS_AQ.DEQUEUE(
    queue_name => descr.queue_name,
    dequeue_options => dequeue_options,
    message_properties => message_properties,
    payload => message,
    msgid => message_handle);

    deq_saga_id := dbms_saga.get_saga_id(message);
    opcode  := dbms_saga.get_saga_opcode(message);
    message.get_text(req_payload);

  dbms_saga_adm_sys.process_notification(
                        recipient => dbms_saga.get_saga_recipient(message),
                        sender =>  dbms_saga.get_saga_sender(message),
                        deq_saga_id => deq_saga_id,
                        opcode => opcode,
                        coordinator => NULL,
                        req_res => req_payload);
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    write_trace
--
--  DESCRIPTION:
--    Write a message to the trace file for a given event and event level
--
-------------------------------------------------------------------------------

procedure write_trace(
  message      IN varchar2,
  event        IN binary_integer DEFAULT 10855,
  event_level  IN binary_integer DEFAULT 1,
  time_info    IN boolean DEFAULT FALSE) AS

  event_value BINARY_INTEGER := 0;
BEGIN
--  dbms_system.read_ev(event, event_value);
  IF bitand(event_value, event_level) = event_level THEN
    dump_trace(message, time_info);
  END IF;
END write_trace;

-------------------------------------------------------------------------------
--
-- NAME :
--    dump_trace
--
--  DESCRIPTION:
--    Called by write_trace after checking if the event and even_level
--    bits are set to write a message to the trace file.
--
-------------------------------------------------------------------------------

procedure dump_trace(
  message      IN varchar2,
  time_info    IN boolean DEFAULT FALSE) AS

  pos        BINARY_INTEGER := 1;
  mesg_len   BINARY_INTEGER := LENGTH(message);

BEGIN

--  IF time_info THEN
--    dbms_system.ksdddt;
--  END IF;
  WHILE pos <= mesg_len LOOP
--    dbms_system.ksdwrt(1, substr(message, pos, 80));
    pos := pos + 80;
  END LOOP;
END dump_trace;

end dbms_saga_adm;
/
show errors;
create or replace package body dbms_saga as

-------------------------------------------------------------------------------
-----------------------------INTERNAL TYPES -----------------------------------
-------------------------------------------------------------------------------
M_IDEN                  VARCHAR2(128);
M_IDEN_Q                VARCHAR2(130);
M_IDEN_SCM              VARCHAR2(261);

MAX_ENTITY_NAME         CONSTANT BINARY_INTEGER := 115;
-------------------------------------------------------------------------------
--------------------------INTERNAL PROCEDURES----------------------------------
-------------------------------------------------------------------------------

procedure write_trace(message       IN VARCHAR2,
                      event         IN BINARY_INTEGER DEFAULT 10855,
                      event_level   IN BINARY_INTEGER DEFAULT 1,
                      time_info     IN BOOLEAN DEFAULT FALSE);

procedure dump_trace(message    IN  varchar2,
                     time_info  IN boolean DEFAULT FALSE);

-------------------------------------------------------------------------------
---------------------------BODY DECLARATION------------------------------------
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
-- NAME :
--    begin_saga
--
-- PARAMETERS :
--    timeout   (IN) - saga timeout

-- RETURNS :
--    guid      (OUT) - saga id
--
--  DESCRIPTION:
--    This function begins a saga by returning a saga id. Saga timeout
--    could also be setup using this function.
--    Note: The default saga timeout is set to 86400 seconds (24 hours).
--
-------------------------------------------------------------------------------
function begin_saga(initiator_name IN VARCHAR2, timeout IN number DEFAULT 86400)
                   return saga_id_t AS

  guid                  RAW(16);

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  write_trace('BEGIN_SAGA : START begin_saga');

  guid := dbms_saga_sys.begin_saga(
                       initiator_name => initiator_name,
                       timeout => timeout,
                       current_user => sys_context('USERENV', 'CURRENT_USER'));

  RETURN guid;

  write_trace('BEGIN_SAGA : END begin_saga');

END;

-------------------------------------------------------------------------------
--
-- NAME :
--    enroll_participant
--
-- PARAMETERS :
--    saga_id      (IN)         - saga id
--    sender       (IN)         - saga initiator
--    recipient    (IN)         - saga recipient
--    coordinator  (IN)         - saga coordinator
--    payload      (IN)         - payload in JSON
--
--  DESCRIPTION:
--    TBD
--
-------------------------------------------------------------------------------

procedure enroll_participant(saga_id        IN saga_id_t,
                             sender         IN VARCHAR2,
                             recipient      IN VARCHAR2,
                             coordinator    IN VARCHAR2,
                             payload        IN JSON DEFAULT NULL) AS

  enroll_message      SYS.AQ$_JMS_TEXT_MESSAGE;
  enq_options         DBMS_AQ.ENQUEUE_OPTIONS_T;
  msg_properties      DBMS_AQ.MESSAGE_PROPERTIES_T;
  message_handle      RAW(16);
  payload_clob        CLOB;
  sender_out_topic    M_IDEN_SCM%TYPE;
  recipient_int       M_IDEN%TYPE;
  sender_int          M_IDEN%TYPE;
  coordinator_int     M_IDEN%TYPE;

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  /* Construct a saga message on behalf of the application */
  enroll_message := sys.aq$_jms_text_message.construct;
  dbms_saga.set_saga_opcode(enroll_message,dbms_saga.REQUEST);
  dbms_saga.set_saga_id(enroll_message,saga_id);
  dbms_saga.set_saga_coordinator(enroll_message,coordinator);
  dbms_saga.set_saga_sender(enroll_message,sender);
  dbms_saga.set_saga_recipient(enroll_message,recipient);
  /* If payload is not NULL then we need to reformat */
  IF payload IS NOT NULL THEN
    payload_clob := to_clob(json_serialize(payload));
    enroll_message.set_text(payload_clob);
  END IF;
  /* Get the OUT TOPIC and enqueue the message */
  sender_out_topic := dbms_saga.get_out_topic(sender);
  dbms_aq.enqueue(queue_name => sender_out_topic,
                  enqueue_options => enq_options,
                  message_properties => msg_properties,
                  payload => enroll_message,
                  msgid   => message_handle
                  );
COMMIT;
END;

-------------------------------------------------------------------------------
--
-- NAME :
--    get_saga_id
--
-- PARAMETERS :
--    NONE
--
-- RETURNS :
--    saga_id      (OUT) - saga id
--
--  DESCRIPTION:
--    This function returns the saga id stored in a session variable.
--
-------------------------------------------------------------------------------

function get_saga_id return saga_id_t as
BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  return null;
END;

-------------------------------------------------------------------------------
--
-- NAME :
--    set_saga_id
--
-- PARAMETERS :
--    saga_id      (IN)         - saga id
--
--  DESCRIPTION:
--    This procedure sets the saga id stored in a session variable.
--
-------------------------------------------------------------------------------

procedure set_saga_id(saga_id IN saga_id_t) as
BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  null;
END;

-------------------------------------------------------------------------------
--
-- NAME :
--    commit_saga
--
-- PARAMETERS :
--    saga_participant  (IN)         - saga participant name
--    saga_id           (IN)         - saga id
--    force             (IN)         - force commit or not
--
--  DESCRIPTION:
--    This procedure commits the saga by sending commit messages to all
--    participants on behalf of the coordinator.
--    [completion_callback] defined at join_saga is executed
--    for each participant.
--
-------------------------------------------------------------------------------

procedure commit_saga(saga_participant IN VARCHAR2,
                      saga_id IN saga_id_t ,
                      force IN boolean DEFAULT TRUE) as

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  write_trace('COMMIT_SAGA : BEGIN commit_saga. Saga ID :' || saga_id);

  /* Call SYS procedure */
  dbms_saga_sys.commit_saga(
                saga_participant => saga_participant,
                saga_id => saga_id,
                force => force,
                current_user => sys_context('USERENV', 'CURRENT_USER'));

  write_trace('COMMIT_SAGA : END commit_saga. Saga ID :' || saga_id);

END;


-------------------------------------------------------------------------------
--
-- NAME :
--    rollback_saga
--
-- PARAMETERS :
--    saga_participant  (IN)         - saga participant name
--    saga_id           (IN)         - saga id
--    force             (IN)         - force commit or not
--
-- DESCRIPTION:
--    This procedure rolls back the saga by sending abort messages
--    to all participants on behalf of the coordinator.
--    [compensation_callback] defined at join_saga is executed
--    for each participant.
--
-------------------------------------------------------------------------------

procedure rollback_saga(saga_participant IN VARCHAR2,
                        saga_id IN saga_id_t ,
                        force IN boolean DEFAULT TRUE) as

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  write_trace('ROLLBACK_SAGA : BEGIN rollback_saga. Saga ID : ' || saga_id);

  /* Call SYS procedure */
  dbms_saga_sys.rollback_saga(
                saga_participant => saga_participant,
                saga_id => saga_id,
                force => force,
                current_user => sys_context('USERENV', 'CURRENT_USER'));

  write_trace('ROLLBACK_SAGA : END rollback_saga. Saga ID : ' || saga_id);

END;


-------------------------------------------------------------------------------
--
-- NAME :
--    forget_saga
--
-- PARAMETERS :
--    saga_id      (IN)         - saga id
--
--  DESCRIPTION:
--    This procedure helps a participant to forget the saga.
--
-------------------------------------------------------------------------------

procedure forget_saga(saga_id IN saga_id_t) as

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  null;
END;

-------------------------------------------------------------------------------
--
-- NAME :
--    leave_saga
--
-- PARAMETERS :
--    saga_id      (IN)         - saga id
--
--  DESCRIPTION:
--    This procedure helps a participant to leave the saga.
--
-------------------------------------------------------------------------------

procedure leave_saga(saga_id IN saga_id_t) as

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  null;
END;

-------------------------------------------------------------------------------
--
-- NAME :
--    after_saga
--
-- PARAMETERS :
--    saga_id      (IN)         - saga id
--
--  DESCRIPTION:
--    This procedure helps a participant to define what happens when the
--    saga is complete.
--    [aftersaga_callback] defined at join_saga is executed for
--    the participant.
--
-------------------------------------------------------------------------------

procedure after_saga(saga_id IN saga_id_t) as
BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  null;
END;

-------------------------------------------------------------------------------
--
-- NAME :
--    is_incomplete
--
-- PARAMETERS :
--    saga_id       (IN)         - saga id

-- RETURNS :
--    is_incomplete (OUT)        - saga status : complete/incomplete
--
--  DESCRIPTION:
--    This function returns TRUE if the saga for the given
--    saga_id is INCOMPLETE.
--
-------------------------------------------------------------------------------

function is_incomplete(saga_id IN saga_id_t) return boolean as
BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  return null;
END;

-------------------------------------------------------------------------------
--
-- NAME :
--    set_incomplete
--
-- PARAMETERS :
--    saga_id      (IN)         - saga id
--
--  DESCRIPTION:
--    Marks the saga with the given saga id as INCOMPLETE.
--
-------------------------------------------------------------------------------

procedure set_incomplete(saga_id IN saga_id_t) as
BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  null;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    get_out_topic
--
-- PARAMETERS :
--    entity_name   (IN)     - participant/coordinator name
--
-- RETURNS :
--    out_topic     (OUT)    - OUTBOUND queue for the participant/coordinator.
--
--  DESCRIPTION:
--    This function returns the outbound queue for a
--    given participant / coordinator.
--
-------------------------------------------------------------------------------

function get_out_topic(entity_name IN varchar2) return varchar2 as

  out_queue         M_IDEN_SCM%TYPE;

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  out_queue := dbms_saga_sys.get_out_topic(entity_name => entity_name);

  return out_queue;

END;


-------------------------------------------------------------------------------
--
-- NAME :
--    notify_callback_participant
--
--  DESCRIPTION:
--    This procedure is the participant notification callback.
--    When a participant is created it is registered to this procedure.
--    This procedure is repsonsible for dequeueing NON-ACK messages
--    from the participant IN-QUEUE. Respective callback is triggered
--    depending on the opcode.
--    Note : callback package is declared by the user
--    while create_participant
--    The callback procedures a user can implement in the callback
--    package are :
--
--      OPCODE : REQUEST
--        Procedures :
--            JOIN_SAGA_INT();
--
--      OPCODE : ACK_SAGA
--        Procedures :
--            REQUEST();
--
--      OPCODE : COMMIT_SAGA
--        Procedures :
--            BEFORE_COMMIT();
--            AFTER_COMMIT();
--
--      OPCODE : ABORT_SAGA
--        Procedures :
--            BEFORE_ABORT();
--            AFTER_ABORT();
--
-------------------------------------------------------------------------------

procedure notify_callback_participant(context RAW ,
                                      reginfo sys.aq$_reg_info ,
                                      descr sys.aq$_descriptor ,
                                      payload RAW ,
                                      payloadl NUMBER) as

  r_dequeue_options       DBMS_AQ.DEQUEUE_OPTIONS_T;
  r_message_properties    DBMS_AQ.MESSAGE_PROPERTIES_T;
  v_message_handle        RAW(16);
  message                 SYS.AQ$_JMS_TEXT_MESSAGE;
  response_payload        SYS.AQ$_JMS_TEXT_MESSAGE;
  saga_id                 dbms_saga_sys.saga_id_t;
  recipient               M_IDEN%TYPE;
  coordinator             M_IDEN%TYPE;
  sender                  M_IDEN%TYPE;
  opcode                  NUMBER;
  req_res                 CLOB;

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga.ROLLINGUNSUPPORTED;
  END IF;

  r_dequeue_options.msgid := descr.msg_id;
  r_dequeue_options.navigation := dbms_aq.first_message;

  /* Dequeue the message from the participant's IN-QUEUE. */
  DBMS_AQ.DEQUEUE(
    queue_name         => descr.queue_name,
    dequeue_options    => r_dequeue_options,
    message_properties => r_message_properties,
    payload            => message,
    msgid              => v_message_handle);

  /* GET Saga Properties */
  recipient          := dbms_saga.get_saga_recipient(message);
  sender             := dbms_saga.get_saga_sender(message);
  saga_id            := dbms_saga.get_saga_id(message);
  opcode             := dbms_saga.get_saga_opcode(message);
  coordinator        := dbms_saga.get_saga_coordinator(message);
  message.get_text(req_res);


  /* Process Saga Message */
  --insert into test values(recipient);
  --insert into test values(saga_id);
  --insert into test values(opcode);
  --insert into test values(sender);
  --insert into test values(coordinator);
  dbms_saga_sys.process_notification(recipient => recipient,
                                         sender => sender,
                                         saga_id => saga_id,
                                         opcode => opcode,
                                         coordinator => coordinator,
                                         req_res => req_res);
END;


procedure set_saga_sender(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                          sender IN varchar2) IS
  saga_sender_int     VARCHAR(115);
BEGIN
  dbms_utility.canonicalize(sender, saga_sender_int, 115);
  message.set_string_property('jms_oracle_aq$_saga_sender' , saga_sender_int);
END;

procedure set_saga_recipient(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                             recipient IN varchar2) IS
  saga_recipient_int  VARCHAR(115);
BEGIN
  dbms_utility.canonicalize(recipient, saga_recipient_int, 115);
  message.set_string_property('jms_oracle_aq$_saga_recipient' , saga_recipient_int);
END;

procedure set_saga_opcode(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                          opcode IN NUMBER) IS
BEGIN
  message.set_int_property('jms_oracle_aq$_saga_opcode' , opcode);
END;

procedure set_saga_id(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                      saga_id IN RAW) IS
BEGIN
  message.set_string_property('jms_oracle_aq$_saga_id' , saga_id);
END;

procedure set_saga_coordinator(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE,
                               saga_coordinator IN VARCHAR2) IS
  saga_coordinator_int     VARCHAR(115);
BEGIN
  dbms_utility.canonicalize(saga_coordinator, saga_coordinator_int, 115);
  message.set_string_property('jms_oracle_aq$_saga_coordinator' , saga_coordinator_int);
END;

function get_saga_sender(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return VARCHAR2 IS
BEGIN
  return message.get_string_property('jms_oracle_aq$_saga_sender');
END;

function get_saga_recipient(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return VARCHAR2 IS
BEGIN
  return message.get_string_property('jms_oracle_aq$_saga_recipient');
END;

function get_saga_opcode(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return NUMBER IS
BEGIN
  return message.get_int_property('jms_oracle_aq$_saga_opcode');
END;

function get_saga_id(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return RAW IS
BEGIN
  return HEXTORAW(message.get_string_property('jms_oracle_aq$_saga_id'));
END;

function get_saga_coordinator(message IN OUT SYS.AQ$_JMS_TEXT_MESSAGE)
return VARCHAR2 IS
BEGIN
  return message.get_string_property('jms_oracle_aq$_saga_coordinator');
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    write_trace
--
--  DESCRIPTION:
--    Write a message to the trace file for a given event and event level
--
-------------------------------------------------------------------------------

procedure write_trace(
      message      IN varchar2,
      event        IN binary_integer DEFAULT 10855,
      event_level  IN binary_integer DEFAULT 1,
      time_info    IN boolean DEFAULT FALSE) AS

  event_value BINARY_INTEGER := 0;

BEGIN
--  dbms_system.read_ev(event, event_value);
  IF bitand(event_value, event_level) = event_level THEN
    dump_trace(message, time_info);
  END IF;
END write_trace;

-------------------------------------------------------------------------------
--
-- NAME :
--    dump_trace
--
-- DESCRIPTION:
--    Called by write_trace after checking if the event and even_level
--    bits are set to write a message to the trace file.
--
-------------------------------------------------------------------------------

procedure dump_trace(
    message      IN varchar2,
    time_info    IN boolean DEFAULT FALSE) AS

  pos        BINARY_INTEGER := 1;
  mesg_len   BINARY_INTEGER := LENGTH(message);

BEGIN
--  IF time_info THEN
--    dbms_system.ksdddt;
--  END IF;

  WHILE pos <= mesg_len LOOP
--    dbms_system.ksdwrt(1, substr(message, pos, 80));
    pos := pos + 80;
  END LOOP;
END dump_trace;


end dbms_saga;
/
show errors
create or replace package body dbms_saga_adm_sys as

-------------------------------------------------------------------------------
-----------------------------INTERNAL TYPES -----------------------------------
-------------------------------------------------------------------------------
M_IDEN_NAME             VARCHAR2(115);
M_IDEN_NAME_Q           VARCHAR2(117);
M_IDEN                  VARCHAR2(128);
M_IDEN_Q                VARCHAR2(130);
M_IDEN_SCM              VARCHAR2(261);

MAX_ENTITY_NAME         CONSTANT BINARY_INTEGER := 115;
MAX_IDENTIFIER_NAME     CONSTANT BINARY_INTEGER := 128;

-------------------------------------------------------------------------------
----------------------------INTERNAL PROCEDURES--------------------------------
-------------------------------------------------------------------------------
procedure addParticipantOrCoordinator(entity_name IN varchar2,
                                      entity_schema IN varchar2,
                                      storage_clause IN varchar2 DEFAULT NULL,
                                      dblink_to_broker IN varchar2,
                                      mailbox_schema IN varchar2,
                                      broker_name IN varchar2 DEFAULT NULL,
                                      callback_schema IN varchar2,
                                      callback_package IN varchar2,
                                      dblink_to_entity IN varchar2,
                                      isCoordinator IN boolean DEFAULT FALSE,
                                      coordinator_name IN varchar2 default NULL)
                                      ;

procedure dropParticipantOrCoordinator(entity_name IN varchar2 ,
                                       entity_ntfn_callback IN varchar2);

function uniqueEntity(entity_name IN varchar2,
                      entity_schema IN varchar2,
                      isBroker IN boolean) return boolean;

procedure drop_broker_int(queue_table IN varchar2,
                          broker_schema IN varchar2,
                          broker_name_int IN varchar2,
                          curr_state IN number);

procedure drop_entity_int(entity_name_int IN varchar2,
                          entity_schema_int IN varchar2,
                          broker_idr IN raw,
                          participant_status IN number,
                          broker_dblink_int IN varchar2,
                          broker_name_int IN varchar2,
                          mailbox_schema_int IN varchar2,
                          entity_ntfn_callback IN varchar2,
                          curr_state_int IN number,
                          saga_secret IN number);

procedure register_callback_comp(participant_name_int IN varchar2,
                                 participant_schema IN varchar2,
                                 broker_dblink IN varchar2,
                                 old_p_status IN number,
                                 old_p_callback_schm IN varchar2,
                                 old_p_callback_name IN varchar2,
                                 participant_id IN raw,
                                 curr_state_int IN number);

--function validateAccess(operation IN NUMBER,
--                        target_schema IN varchar2,
--                        current_user IN varchar2,
--                        cbk_package_int IN varchar2) return boolean;

procedure write_trace(message IN varchar2,
                      event IN binary_integer DEFAULT 10855,
                      event_level IN binary_integer DEFAULT 1,
                      time_info IN boolean DEFAULT FALSE);

procedure dump_trace(message IN varchar2,
                     time_info IN boolean DEFAULT FALSE);

-------------------------------------------------------------------------------
-------------------------------BODY DECLARATION--------------------------------
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
-- NAME :
--    add_broker
--
-- PARAMETERS :
--    broker_name      (IN) - name of the broker
--    broker_schema    (IN) - broker's schema
--    storage_clause   (IN)
--
--  DESCRIPTION:
--    This procedure creates the saga broker. It creates the respective
--    queue table, queue , starts the queue and inserts the broker entry
--    into the sys.saga_message_broker$ table.
--
-------------------------------------------------------------------------------
procedure add_broker(broker_name IN varchar2 ,
                     broker_schema IN varchar2,
                     storage_clause IN varchar2 DEFAULT NULL,
                     current_user IN varchar2) AS

  q_table             M_IDEN%TYPE;
  q_table_q           M_IDEN_Q%TYPE;
  q_table_schema      M_IDEN_SCM%TYPE;
  q_name              M_IDEN%TYPE;
  q_name_q            M_IDEN_Q%TYPE;
  q_name_schema       M_IDEN_SCM%TYPE;
  any_rows_found      NUMBER;
  saved_state         BOOLEAN;
  broker_name_int     M_IDEN_NAME%TYPE;
  broker_schema_int   M_IDEN_NAME%TYPE;
  broker_name_q       M_IDEN_NAME_Q%TYPE;
  broker_schema_q     M_IDEN_NAME_Q%TYPE;
  curr_state          NUMBER := 0;
  BROKER_EXISTS       EXCEPTION;
  UNAUTHACCESS        EXCEPTION;

BEGIN

  /* Canonicalize and enquote broker_name */
  dbms_utility.canonicalize(broker_name, broker_name_int, MAX_ENTITY_NAME);
  broker_name_q := dbms_assert.enquote_name(broker_name_int, FALSE);

  /* Canonicalize and enquote broker_schema */
  dbms_utility.canonicalize(broker_schema, broker_schema_int, MAX_ENTITY_NAME);
  broker_schema_q := dbms_assert.enquote_name(broker_schema_int, FALSE);

  /* Security Check : Check if the broker schema is valid and current
     user is authorized to access the schema if not current_schema */
  --IF current_user <> broker_schema THEN
  --  IF NOT validateAccess(dbms_saga_adm_sys.CREATEENTITY, broker_schema,
  --                        current_user, NULL) THEN
  --     RAISE UNAUTHACCESS;
  --  END IF;
  --END IF;

  --Sanity Check: see if the broker name is unique or not.
  IF uniqueEntity(broker_name_int, broker_schema_int, TRUE) = FALSE THEN
    RAISE BROKER_EXISTS;
  END IF;

  /* Construct SAGA QT and Queue */
  q_table := 'SAGA$_' || broker_name_int || '_INOUT_QT';
  q_table_q := dbms_assert.enquote_name(q_table, FALSE);
  q_table_schema := broker_schema_q || '.' || q_table_q;
  q_name := 'SAGA$_' || broker_name_int || '_INOUT';
  q_name_q := dbms_assert.enquote_name(q_name, FALSE);
  q_name_schema := broker_schema_q || '.' || q_name_q;

  write_trace('ADD_BROKER(SYS) : q_table : ' || q_table
                || ' q_name : ' || q_name_schema);

  -- Try to create the broker's queue table.
  dbms_aqadm.create_queue_table(
    QUEUE_TABLE => q_table_schema,
    QUEUE_PAYLOAD_TYPE => 'SYS.AQ$_JMS_TEXT_MESSAGE',
    MULTIPLE_CONSUMERS => TRUE
  );
  --curr_state = 1 : queue_table_created
  curr_state := curr_state + 1;

  -- Next try to create the broker's queue.
  dbms_aqadm.create_queue(
    QUEUE_NAME => q_name_schema,
    QUEUE_TABLE => q_table_schema
  );

  -- Next start the broker queue if the creation was successful.
  dbms_aqadm.start_queue(
    QUEUE_NAME => q_name_schema,
    ENQUEUE => TRUE,
    DEQUEUE => TRUE
  );

  --insert entry into message_broker$ table if everything was successful.
  insert into saga_message_broker$ values(sys_guid(), broker_name_int,
                                              broker_schema_int, q_name, 0);
  -- curr_state = 2 : dictionary updated
  curr_state := curr_state + 1;

COMMIT;
EXCEPTION
  WHEN UNAUTHACCESS THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Insufficient Privileges to access
    schema ' || broker_schema || '.');
  WHEN BROKER_EXISTS THEN
    RAISE_APPLICATION_ERROR(-20001 , 'broker name already exists');
  WHEN OTHERS THEN
    drop_broker_int(q_table, broker_schema_q, broker_name_int, curr_state);
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    drop_broker
--
-- PARAMETERS :
--    broker_name      (IN) - name of the broker
--
--  DESCRIPTION:
--    This procedure drops an already existing saga broker.
--
-------------------------------------------------------------------------------

procedure drop_broker(broker_name in varchar2) as

  any_rows_found              NUMBER;
  broker_name_int             M_IDEN%TYPE;
  broker_name_q               M_IDEN_Q%TYPE;
  broker_schema               M_IDEN%TYPE;
  broker_schema_q             M_IDEN_Q%TYPE;
  q_table                     M_IDEN%TYPE;
  q_table_q                   M_IDEN_Q%TYPE;
  q_table_schema              M_IDEN_SCM%TYPE;
  broker_qry                  VARCHAR2(500);
  BROKERNOTFOUND              EXCEPTION;
  PARTICIPANTATTERR           EXCEPTION;

BEGIN

  /* Canonicalize and enquote broker_name */
  dbms_utility.canonicalize(broker_name, broker_name_int, MAX_ENTITY_NAME);
  broker_name_q := dbms_assert.enquote_name(broker_name_int, FALSE);

  /* Check for Valid Broker name and get broker schema */
  BEGIN
    select owner into broker_schema from saga_message_broker$
    where name = broker_name_int;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE BROKERNOTFOUND;
  END;
  /* enquote broker_schema */
  broker_schema_q := dbms_assert.enquote_name(broker_schema, FALSE);

  -- Check if there are participants attached to this broker
  -- Todo : make it broker specific and not general. There can be other
  -- participants attached to different brokers and there might be local
  -- participants as well.
  broker_qry := 'select count(*) from saga_participant$
                 where broker_id = (select id from saga_message_broker$
                 where name = :1)';
  execute immediate broker_qry into any_rows_found using broker_name_int;
  IF any_rows_found <> 0 THEN
    RAISE PARTICIPANTATTERR;
  END IF;

  /* enquote queue table name */
  q_table := 'SAGA$_' || broker_name_int || '_INOUT_QT';
  q_table_q := dbms_assert.enquote_name(q_table, FALSE);
  q_table_schema := broker_schema_q || '.' || q_table_q;

  write_trace('DROP_BROKER(SYS) : q_table : ' || q_table_schema);

  /*Try dropping broker */
  drop_broker_int(q_table, broker_schema_q, broker_name_int,
                  dbms_saga_adm_sys.BROKER_MAX_STATE);

COMMIT;
EXCEPTION
  /* No broker exists with this name */
  WHEN BROKERNOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'Cannot Drop Broker: Broker not found');
  /* If there are other participants who are attached to this broker we should not
     drop the broker since the participant would be affected. Let's wait for the
     dependent participants to be dropped */
  WHEN PARTICIPANTATTERR THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Broker : Some
    Participants are still attached to the broker');
  WHEN OTHERS THEN
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    add_coordinator
--
-- PARAMETERS :
--    coordinator_name      (IN) - name of the coordinator
--    coordinator_schema    (IN) - coordinator's schema
--    storage_clause        (IN)
--    dblink_to_broker      (IN) - dblink to the broker queue
--    mailbox schema        (IN) - broker's schema
--    broker_name           (IN) - broker's name
--    dblink_to_coordinator (IN) - dblink of the coordinator
--
--  DESCRIPTION:
--    This procedure creates the saga coordinator. The procedure calls
--    an internal procedure addParticipantOrCoordinator. It creates the
--    inbound/outbound queues for the coordinator and sets up the coordinator
--
-------------------------------------------------------------------------------
procedure add_coordinator(coordinator_name IN varchar2 ,
                          coordinator_schema IN varchar2,
                          storage_clause IN varchar2 DEFAULT NULL,
                          dblink_to_broker IN varchar2 DEFAULT NULL,
                          mailbox_schema IN varchar2,
                          broker_name IN varchar2,
                          dblink_to_coordinator IN varchar2 DEFAULT NULL,
                          current_user IN varchar2) AS

  COORDINATOR_EXISTS       EXCEPTION;
  UNAUTHACCESS             EXCEPTION;

BEGIN

  /* Security Check : Check if the coordinator schema is valid and current
     user is authorized to access the schema if not current_schema */
--  IF current_user <> coordinator_schema THEN
--    IF NOT validateAccess(dbms_saga_adm_sys.CREATEENTITY, coordinator_schema,
--                          current_user, NULL) THEN
--       RAISE UNAUTHACCESS;
--    END IF;
--  END IF;

  /* If the coordinator already exists throw error. */
  IF uniqueEntity(coordinator_name,coordinator_schema,FALSE) = FALSE THEN
    RAISE COORDINATOR_EXISTS;
  END IF;

  /* Ready to create the coordinator with these parameters :
     PARAMETERS:
      entity_name         (VARCHAR IN) - name of the coordinator
      entity_schema       (VARCHAR IN) - coordinators schema
      storage_clause      (VARCHAR IN) - storage clause
      dblink_to_broker    (VARCHAR IN) - broker's dblink
      mailbox schema      (VARCHAR IN) - broker's schema
      broker_name         (VARCHAR IN) - broker's name
      dblink_to_entity    (VARCHAR IN) - dblink of the coordinator
      isCoordinator       (BOOLEAN IN) - TRUE for coordinator
      coordinator_name    (VARCHAR IN) - NULL since only coordinator
                                         is being created */
  addParticipantOrCoordinator(coordinator_name, coordinator_schema,
                              storage_clause, dblink_to_broker,
                              mailbox_schema, broker_name, NULL,
                              NULL, dblink_to_coordinator , TRUE);

COMMIT;
EXCEPTION
  WHEN UNAUTHACCESS THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Insufficient Privileges to access
    schema ' || coordinator_schema || '.');
  WHEN COORDINATOR_EXISTS THEN
    RAISE_APPLICATION_ERROR(-20001 , 'coordinator name already exists');
  WHEN OTHERS THEN
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    drop_coordinator
--
-- PARAMETERS :
--    coordinator_name      (IN) - name of the coordinator
--
--  DESCRIPTION:
--    This procedure drops an already existing saga coordinator.
--
-------------------------------------------------------------------------------
procedure drop_coordinator(coordinator_name IN varchar2) AS

  dependent_participants      NUMBER;
  coordinator_name_int        M_IDEN%TYPE;
  PARTICIPANTDEPEXCEPTION     EXCEPTION;

BEGIN

  /* Canonicalize coordinator name */
  dbms_utility.canonicalize(coordinator_name, coordinator_name_int,
                            MAX_ENTITY_NAME);

  /* Check if there are any participants dependent on this coordinator. If
     yes , then we should avoid dropping this coordinator since other
     participants may get affected */
  select count(*) into dependent_participants from saga_participant$
  where coordinator_id = (select id from saga_participant$
  where name = coordinator_name_int);

  /* If there are dependent participants raise exception */
  IF dependent_participants <> 0 THEN
    RAISE PARTICIPANTDEPEXCEPTION;
  END IF;

  /* Ready to drop the coordinator */
  dropParticipantOrCoordinator(coordinator_name,
                     'plsql://dbms_saga_adm.notify_callback_coordinator');

COMMIT;
EXCEPTION
  WHEN PARTICIPANTDEPEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot drop coordinator since there
    are participants dependent on this. Please drop dependent participant
    and then try again.');
  WHEN OTHERS THEN
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    add_participant
--
-- PARAMETERS :
--    participant_name      (IN) - name of the participant
--    participant_schema    (IN) - participant's schema
--    storage_clause        (IN)
--    coordinator_name      (IN) - name of the coordinator
--    dblink_to_broker      (IN) - dblink to the broker queue
--    mailbox schema        (IN) - broker's schema
--    broker_name           (IN) - broker's name
--    callback_schema       (IN) - schema of participant callback
--    callback_package      (IN) - participant callback
--    dblink_to_participant (IN) - dblink of the participant
--
--  DESCRIPTION:
--    This procedure creates a saga participant. The procedure calls an
--    internal procedure addParticipantOrCoordinator. It creates the
--    inbound/outbound queues for the participant and sets up the participant.
--
-------------------------------------------------------------------------------
procedure add_participant(participant_name IN varchar2 ,
                          participant_schema IN varchar2,
                          storage_clause IN varchar2 DEFAULT NULL,
                          coordinator_name IN varchar2 DEFAULT NULL,
                          dblink_to_broker IN varchar2 DEFAULT NULL,
                          mailbox_schema IN varchar2,
                          broker_name IN varchar2,
                          callback_schema IN varchar2,
                          callback_package IN varchar2 DEFAULT NULL,
                          dblink_to_participant IN varchar2 DEFAULT NULL,
                          current_user IN varchar2) AS

  PARTICIPANT_EXISTS       EXCEPTION;
  UNAUTHACCESS             EXCEPTION;

BEGIN

  /* Security Check : Check if the participant schema is valid and current
     user is authorized to access the schema if not current_schema */
--  IF current_user <> participant_schema THEN
--    IF NOT validateAccess(dbms_saga_adm_sys.CREATEENTITY, participant_schema,
--                          current_user, NULL) THEN
--       RAISE UNAUTHACCESS;
--    END IF;
--  END IF;

  /* If the participant already exists throw error. */
  IF uniqueEntity(participant_name,participant_schema,FALSE) = FALSE THEN
    RAISE PARTICIPANT_EXISTS;
  END IF;

  /* Ready to create the participant */
  addParticipantOrCoordinator(participant_name, participant_schema,
                              storage_clause, dblink_to_broker,
                              mailbox_schema, broker_name, callback_schema,
                              callback_package, dblink_to_participant,
                              FALSE, coordinator_name);

COMMIT;
EXCEPTION
  WHEN UNAUTHACCESS THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Insufficient Privileges to access
    schema ' || participant_schema || '.');
  WHEN PARTICIPANT_EXISTS THEN
    RAISE_APPLICATION_ERROR(-20001 , 'participant name already exists');
  WHEN OTHERS THEN
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    drop_participant
--
-- PARAMETERS :
--    participant_name      (IN) - name of the participant
--    drop_coordinator      (IN) - drop the coordinator along with participant
--
--  DESCRIPTION:
--    This procedure drops an already existing saga participant. It also drops
--    the participant's coordinator depending on the value of drop_coordinator
--
-------------------------------------------------------------------------------
procedure drop_participant(participant_name IN varchar2) AS

BEGIN

  /* Ready to drop the participant */
  dropParticipantOrCoordinator(participant_name,
                    'plsql://dbms_saga.notify_callback_participant');

COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    register_saga_callback
--
-- PARAMETERS :
--      participant_name    (VARCHAR IN) - name of the participant
--      callback_schema     (VARCHAR IN) - participant callback schema
--      callback_package    (VARCHAR IN) - participant callback name
--
--  DESCRIPTION:
--    Registers a callback which the user declares if the user wants to
--    use a PL/SQL based saga infrastructure.
--
-------------------------------------------------------------------------------
procedure register_saga_callback(participant_name IN varchar2,
                                 callback_schema IN varchar2,
                                 callback_package IN varchar2) AS

  participant_name_int      M_IDEN%TYPE;
  part_qin                  M_IDEN%TYPE;
  part_qin_q                M_IDEN_Q%TYPE;
  part_qin_q_schema         M_IDEN_SCM%TYPE;
  participant_schema        M_IDEN%TYPE;
  participant_schema_q      M_IDEN_Q%TYPE;
  cbk_pkg                   M_IDEN%TYPE;
  cbk_pkg_old               M_IDEN%TYPE;
  cbk_schema                M_IDEN%TYPE;
  cbk_schema_old            M_IDEN%TYPE;
  broker_dblink             M_IDEN%TYPE;
  broker_dblink_q           M_IDEN_Q%TYPE;
  participant_id            RAW(16);
  participant_status        NUMBER;
  participant_type          NUMBER;
  curr_state                NUMBER;
  saga_secret               NUMBER;
  broker_string             M_IDEN_SCM%TYPE;
  v_sql                     VARCHAR2(600);
  PARTICIPANTNOTFOUND       EXCEPTION;
  INVALIDENTITY             EXCEPTION;
  INVALIDPKG                EXCEPTION;

BEGIN

  /* Canonicalize participant name */
  dbms_utility.canonicalize(participant_name, participant_name_int,
                            MAX_ENTITY_NAME);

  /* Fetch participant data */
  BEGIN
    select owner, participant_iscomplete, id, type, dblink_to_broker,
    callback_schema, callback_package
    into participant_schema, participant_status, participant_id,
    participant_type, broker_dblink, cbk_schema_old, cbk_pkg_old
    from saga_participant$ where name = participant_name_int;
  /* Cant find the particiapant */
  EXCEPTION
    -- Invalid Participant name
    WHEN NO_DATA_FOUND THEN
      RAISE PARTICIPANTNOTFOUND;
  END;

  /* Canonicalize callback schema and package name */
  dbms_utility.canonicalize(callback_schema, cbk_schema, MAX_IDENTIFIER_NAME);
  dbms_utility.canonicalize(callback_package, cbk_pkg, MAX_IDENTIFIER_NAME);

  /* Security Check : Check if the current user has the execute privilege
     on the callback it is trying to register */
--  IF NOT validateAccess(dbms_saga_adm_sys.CREATEPACKAGE, cbk_schema,
--                        participant_schema, cbk_pkg) THEN
--    RAISE INVALIDPKG;
--  END IF;

  /* Callbacks not allowed for coordinators */
  IF participant_type = dbms_saga_adm_sys.COORDINATOR THEN
    RAISE INVALIDENTITY;
  END  IF;

  /* If the status is incomplete add a callback subscriber and register
     for notification. If the participant is already complete and just
     wants to change their callback we dont have to do this again */
  IF participant_status = dbms_saga_adm_sys.INCOMPLETE THEN
    /* Enquote participant schema */
    participant_schema_q := dbms_assert.enquote_name(participant_schema,FALSE);
    /* Construct IN queue */
    part_qin := 'SAGA$_' || participant_name_int || '_IN_Q';
    part_qin_q := dbms_assert.enquote_name(part_qin, FALSE);
    part_qin_q_schema := participant_schema_q || '.' || part_qin_q;

    /* Register for the callback which is invoked whenever there is a
       message in the INBOUND queue for the participant. */
    DBMS_AQ.REGISTER(sys.aq$_reg_info_list(sys.aq$_reg_info(part_qin_q_schema
    , dbms_aq.namespace_aq ,
    'plsql://dbms_saga.notify_callback_participant' , HEXTORAW('FF'))) , 1);

  END IF;

  /* curr_state = 1 : Assume participant callback created */
  curr_state := curr_state + 1;

  /* Update saga_participant$ locally */
  update saga_participant$ set callback_schema = cbk_schema,
  callback_package = cbk_pkg,
  participant_iscomplete = dbms_saga_adm_sys.COMPLETED
  where name = participant_name_int;

  /* curr_state = 2 : Local update successful */
  curr_state := curr_state + 1;

  /* If Broker_DBlink is NULL then we dont need to perform this */
  IF broker_dblink IS NOT NULL THEN
    /* Enquote broker dblink */
    broker_dblink_q := dbms_assert.enquote_name(broker_dblink, FALSE);

    /* Update saga_participant$ at broker PDB */
    broker_string := 'dbms_saga_connect_int' || '.' ||
    'updateCallbackInfo' || '@' || broker_dblink_q;
    v_sql := 'BEGIN ' ||
              broker_string ||
             '(:1, :2, :3, :4, :5); END;';
    execute immediate v_sql using callback_schema, callback_package,
                                dbms_saga_adm_sys.COMPLETED, participant_id,
                                saga_secret;

  END IF;

  /* curr_state = 3 : Remote update successful */
  curr_state := curr_state + 1;

COMMIT;
EXCEPTION
  WHEN PARTICIPANTNOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Participant Not Found :
    participant name does not exist');
  WHEN INVALIDPKG THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Missing package or execution rights
    for package ' || cbk_schema || '.' || cbk_pkg);
  WHEN INVALIDENTITY THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Callback package cannot be set
    for coordinator');
  WHEN OTHERS THEN
    /* We have to compensate for whatever happened till the exception */
    register_callback_comp(participant_name_int, participant_schema,
                           broker_dblink, participant_status, cbk_schema_old,
                           cbk_pkg_old, participant_id, curr_state);
    RAISE;

END;


-------------------------------------------------------------------------------
--
-- NAME :
--    addParticipantOrCoordinator
--
-- PARAMETERS :
--      entity_name         (VARCHAR IN) - name of the coordinator/participant
--      entity_schema       (VARCHAR IN) - coordinator's/participant's schema
--      storage_clause      (VARCHAR IN) - storage clause
--      dblink_to_broker    (VARCHAR IN) - broker's dblink
--      mailbox schema      (VARCHAR IN) - broker's schema
--      broker_name         (VARCHAR IN) - broker's name
--      dblink_to_entity    (VARCHAR IN) - dblink of the coordinator/participant
--      isCoordinator       (BOOLEAN IN) - TRUE for coordinator
--      coordinator_name    (VARCHAR IN) - name of coordinator if created
--                                         with participant
--
--  DESCRIPTION:
--    This is an internal procedure which is responsible for creating
--    the coordinator and the participant.
--
-------------------------------------------------------------------------------
procedure addParticipantOrCoordinator(entity_name IN varchar2,
                                      entity_schema IN varchar2,
                                      storage_clause IN varchar2 DEFAULT NULL,
                                      dblink_to_broker IN varchar2,
                                      mailbox_schema IN varchar2,
                                      broker_name IN varchar2 DEFAULT NULL,
                                      callback_schema IN varchar2,
                                      callback_package IN varchar2,
                                      dblink_to_entity IN varchar2,
                                      isCoordinator IN boolean DEFAULT FALSE,
                                      coordinator_name IN varchar2 DEFAULT NULL)
                                      as

  entity_name_int             M_IDEN%TYPE;
  entity_name_q               M_IDEN_Q%TYPE;
  entity_schema_int           M_IDEN%TYPE;
  entity_schema_q             M_IDEN_Q%TYPE;
  qt_in                       M_IDEN%TYPE;
  qt_in_q                     M_IDEN_Q%TYPE;
  qt_in_schema                M_IDEN_SCM%TYPE;
  qt_out                      M_IDEN%TYPE;
  qt_out_q                    M_IDEN_Q%TYPE;
  qt_out_schema               M_IDEN_SCM%TYPE;
  q_in                        M_IDEN%TYPE;
  q_in_q                      M_IDEN_Q%TYPE;
  q_out                       M_IDEN%TYPE;
  q_out_q                     M_IDEN_Q%TYPE;
  q_in_schema                 M_IDEN%TYPE;
  q_out_schema                M_IDEN%TYPE;
  q_in_coordinator            M_IDEN%TYPE;
  broker_queue                M_IDEN%TYPE;
  broker_queue_q              M_IDEN_Q%TYPE;
  broker_queue_schema         M_IDEN_SCM%TYPE;
  connectbroker_string        M_IDEN_SCM%TYPE;
  disconnectbroker_string     M_IDEN_SCM%TYPE;
  broker_string               M_IDEN_SCM%TYPE;
  v_sql                       VARCHAR2(1500);
  dblink_to_broker_int        M_IDEN%TYPE;
  dblink_to_broker_sec        M_IDEN_Q%TYPE;
  dblink_to_entity_int        M_IDEN%TYPE;
  broker_name_int             M_IDEN%TYPE;
  mailbox_schema_int          M_IDEN%TYPE;
  mailbox_schema_q            M_IDEN_Q%TYPE;
  coordinator_name_int        M_IDEN%TYPE;
  callback_schema_int         M_IDEN%TYPE;
  callback_package_int        M_IDEN%TYPE;
  internal_callback           M_IDEN%TYPE;
  subscriber_out              sys.aq$_agent;
  coordinator_id              RAW(16);
  broker_id                   RAW(16);
  participant_id              RAW(16);
  participant_status          NUMBER := dbms_saga_adm_sys.INCOMPLETE;
  coordinatorOrParticipant    NUMBER;
  any_rows_found              NUMBER;
  curr_state                  NUMBER := 0;
  saga_secret                 NUMBER;
  uniqueentitybroker          BOOLEAN;
  BROKERINVALID               EXCEPTION;
  BROKERIDERR                 EXCEPTION;
  COORDINATORNOTFOUND         EXCEPTION;
  ENTITY_EXISTS_PDB           EXCEPTION;
  NULLDBLINK                  EXCEPTION;
  REMOTECALLERROR             EXCEPTION;
  INVALIDPKG                  EXCEPTION;

BEGIN

  /* Canonicalize and enquote entity name */
  dbms_utility.canonicalize(entity_name, entity_name_int, MAX_ENTITY_NAME);
  entity_name_q := dbms_assert.enquote_name(entity_name_int, FALSE);

  /* Canonicalize and enquote entity schema */
  dbms_utility.canonicalize(entity_schema, entity_schema_int, MAX_ENTITY_NAME);
  entity_schema_q := dbms_assert.enquote_name(entity_schema_int, FALSE);

  /* Construct Inbound Queue Table */
  qt_in := 'SAGA$_' || entity_name_int || '_IN_QT';
  qt_in_q := dbms_assert.enquote_name(qt_in, FALSE);
  qt_in_schema := entity_schema_q || '.' || qt_in_q;

  /* Construct Outbound Queue Table */
  qt_out := 'SAGA$_' || entity_name_int || '_OUT_QT';
  qt_out_q := dbms_assert.enquote_name(qt_out, FALSE);
  qt_out_schema := entity_schema_q || '.' || qt_out_q;

  /* Construct Inbound Queue */
  q_in := 'SAGA$_' || entity_name_int || '_IN_Q';
  q_in_q := dbms_assert.enquote_name(q_in, FALSE);
  q_in_schema := entity_schema_q || '.' || q_in_q;

  /* Construct Outbound Queue */
  q_out := 'SAGA$_' || entity_name_int || '_OUT_Q';
  q_out_q := dbms_assert.enquote_name(q_out, FALSE);
  q_out_schema := entity_schema_q || '.' || q_out;

  write_trace('ADDPARTICIPANTORCOORDINATOR(SYS) : qt_in :' || qt_in
  || ' qt_out : ' || qt_out || ' q_in : ' || q_in_schema
  || 'q_out : ' || q_out_schema);

  /* Security Check: If the calllback that is trying to be registered exists, or
     if it exists in some other schema, then current_user should have access
     to this callback */
  IF callback_package IS NOT NULL THEN
    /* Canonicalize callback schema and package name */
    dbms_utility.canonicalize(callback_schema, callback_schema_int,
                              MAX_IDENTIFIER_NAME);
    dbms_utility.canonicalize(callback_package, callback_package_int,
                              MAX_IDENTIFIER_NAME);
    --IF NOT validateAccess(dbms_saga_adm_sys.CREATEPACKAGE, callback_schema_int,
    --                    entity_schema_int, callback_package_int) THEN
    --  RAISE INVALIDPKG;
    --END IF;
  END IF;

  IF dblink_to_broker IS NOT NULL THEN
    /* Enquote and canonicalize dblinks */
    dbms_utility.canonicalize(dblink_to_broker, dblink_to_broker_int,
                              MAX_IDENTIFIER_NAME);
    dblink_to_broker_sec := dbms_assert.enquote_name(dblink_to_broker_int,
                                                     FALSE);

    IF dblink_to_entity IS NULL THEN
      RAISE NULLDBLINK;
    END IF;

    dbms_utility.canonicalize(dblink_to_entity, dblink_to_entity_int,
                              MAX_IDENTIFIER_NAME);

    /* If the broker dblink is equal to the entity dblink then broker and
       the entity are colocated. We NULLIFY the broker_dblink expilcitly
     */
    IF dblink_to_broker_int = dblink_to_entity_int THEN
      dblink_to_broker_int := NULL;
      dblink_to_broker_sec := NULL;
      dblink_to_entity_int := NULL;
    END IF;

    /* Check if the broker already has a coordinator with this name, if yes
     broker cannot handle two coordinators with the same name so throw
     error */
    IF dblink_to_broker_int IS NOT NULL THEN
      BEGIN
        broker_string := ':r := dbms_saga_connect_int'
               || '.' || 'uniqueEntityAtPDB' || '@' || dblink_to_broker_sec;
        v_sql := 'BEGIN ' ||
                 broker_string ||
                 '(:1, :2, :3, :4, :5); END;';
        execute immediate v_sql using OUT uniqueentitybroker, IN entity_name,
                IN broker_name, IN mailbox_schema, IN dblink_to_broker,
                IN dblink_to_entity;

        IF uniqueentitybroker = FALSE THEN
          RAISE ENTITY_EXISTS_PDB;
        END IF;
      EXCEPTION
        WHEN ENTITY_EXISTS_PDB THEN
          RAISE ENTITY_EXISTS_PDB;
        WHEN NO_DATA_FOUND THEN
          RAISE NULLDBLINK;
        WHEN OTHERS THEN
          RAISE REMOTECALLERROR;
      END;
    END IF;
  END IF;

  /* Canonicalize broker name and schema */
  dbms_utility.canonicalize(broker_name, broker_name_int, MAX_ENTITY_NAME);
  dbms_utility.canonicalize(mailbox_schema, mailbox_schema_int,
                            MAX_IDENTIFIER_NAME);
  mailbox_schema_q := dbms_assert.enquote_name(mailbox_schema_int, FALSE);

  -- Fetch the broker id from the broker PDB.
  BEGIN
    /* Check for a valid broker */
    /* If dblink_to_broker is supplied it means that the broker is on a
       remote PDB, otherwise local
     */
    IF dblink_to_broker_int IS NOT NULL THEN
      broker_string := 'dbms_saga_connect_int' || '.' ||
      'getBrokerInfo' || '@' || dblink_to_broker_sec;
      v_sql := 'BEGIN ' ||
               broker_string ||
               '(:1, :2, :3, :4); END;';
      execute immediate v_sql using IN OUT broker_id, IN OUT broker_name_int,
                                    IN OUT mailbox_schema_int, TRUE;
    ELSE
      execute immediate 'select id from saga_message_broker$ where
      name = :1 and owner = :2' into broker_id using broker_name_int,
      mailbox_schema_int;
    END IF;

  EXCEPTION
    /* Broker not found , throw error and stop. */
    WHEN NO_DATA_FOUND THEN
      RAISE BROKERINVALID;
    WHEN OTHERS THEN
      RAISE BROKERIDERR;
  END;

  /* getting the coordinator id in case a valid coordinator name is passed,
     raise error otherwise and stop. */
  /* Coordinator name is NULL incase we are creating a coordinator */
  IF coordinator_name IS NOT NULL THEN
    /* Canonicalize coordinator name */
    dbms_utility.canonicalize(coordinator_name, coordinator_name_int,
                              MAX_ENTITY_NAME);
    BEGIN
      /* Get the coordinator id*/
      select id into coordinator_id from saga_participant$
      where name = coordinator_name_int;
    EXCEPTION
      /* Invalid Coordinator Name, raise error and return. */
      WHEN NO_DATA_FOUND THEN
        RAISE COORDINATORNOTFOUND;
    END;
  END IF;

  -- Try to create the entity's (IN) queue table.
  /* Bug 33304871: Inbound Queue doesnt need to be multiconsumer since
                   we have stateless join saga and we dont need any
                   ACK DEQ subscribers */
  dbms_aqadm.create_queue_table(
    QUEUE_TABLE => qt_in_schema,
    QUEUE_PAYLOAD_TYPE => 'SYS.AQ$_JMS_TEXT_MESSAGE'
  );
  --curr_state = 1 : Inbound queue table is created
  curr_state := curr_state + 1;

  -- Try to create the entity's (OUT) queue table.
  dbms_aqadm.create_queue_table(
    QUEUE_TABLE => qt_out_schema,
    QUEUE_PAYLOAD_TYPE => 'SYS.AQ$_JMS_TEXT_MESSAGE',
    MULTIPLE_CONSUMERS => TRUE
  );
  --curr_state = 2 : Outbound queue table is created
  curr_state := curr_state + 1;

  -- Next try to create the entity's INBOUND queue.
  dbms_aqadm.create_queue(
    QUEUE_NAME => q_in_schema,
    QUEUE_TABLE => qt_in_schema
  );

  -- Next try to create the entity's OUTBOUND queue.
  dbms_aqadm.create_queue(
    QUEUE_NAME => q_out_schema,
    QUEUE_TABLE => qt_out_schema
  );

  -- Next start the entity's IN queue if the creation was successful.
  dbms_aqadm.start_queue(
    QUEUE_NAME => q_in_schema,
    ENQUEUE => TRUE,
    DEQUEUE => TRUE
  );

  -- Next start the entity's OUT queue if the creation was successful.
  dbms_aqadm.start_queue(
    QUEUE_NAME => q_out_schema,
    ENQUEUE => TRUE,
    DEQUEUE => TRUE
  );

  /* Construct Broker Queue */
  broker_queue := 'SAGA$_' || broker_name_int || '_INOUT';
  broker_queue_q := dbms_assert.enquote_name(broker_queue, FALSE);
  broker_queue_schema := mailbox_schema_q || '.' || broker_queue_q;

  /* create broker queue as a subscriber and schedule propagation */
  IF dblink_to_broker_int IS NOT NULL THEN
    subscriber_out := sys.aq$_agent(NULL,
                broker_queue_schema || '@' || dblink_to_broker_sec, 0);
  ELSE
    subscriber_out := sys.aq$_agent(NULL, broker_queue_schema, 0);
  END IF;

  /* adding broker as the subscriber */
  dbms_aqadm.add_subscriber(
    queue_name => q_out_schema,
    subscriber => subscriber_out,
    queue_to_queue => TRUE
  );
  write_trace('ADDPARTICIPANTORCOORDINATOR(SYS) : schedule propagation from
  OUT queue to broker. queue_name : ' || q_out_schema ||' destination: '
  || dblink_to_broker_sec);
  --curr_state = 3 : Broker queue added as a subscriber.
  curr_state := curr_state + 1;

  -- scheduling propagation from OUTBOUND queue to broker queue
  dbms_aqadm.schedule_propagation(
    queue_name => q_out_schema,
    destination => dblink_to_broker_int,
    destination_queue => broker_queue_schema,
    latency => 0
  );
  /* curr_state = 4 : Propagation scheduled from OUTBOUND Queue
                      to broker. */
  curr_state := curr_state + 1;

  /* We are creating a coordinator */
  IF isCoordinator = TRUE THEN
    /* In case of coordinator , register for the coordinator callback which
       completes the join / commit /abort saga. */
    coordinatorOrParticipant := dbms_saga_adm_sys.COORDINATOR;
    participant_status := NULL;

    /* Register to this callback */
    internal_callback :='plsql://dbms_saga_adm.notify_callback_coordinator';

    /* Register for the callback which is invoked whenever there is a
       message in the INBOUND queue for the coordinator. */
    DBMS_AQ.REGISTER(sys.aq$_reg_info_list(sys.aq$_reg_info(q_in_schema,
    dbms_aq.namespace_aq, internal_callback, HEXTORAW('FF'))), 1);

    /* curr_state = 5 : Coordinator callback created */
    curr_state := curr_state + 1;

    write_trace('ADDPARTICIPANTORCOORDINATOR(SYS) : registering callback for
    coordinator - plsql://dbms_saga_adm.notify_callback_coordinator');

  /* We are creating a participant */
  ELSE

    coordinatorOrParticipant := dbms_saga_adm_sys.PARTICIPANT;
    /* Register saga callback for participant only if callback_package
       name is not null. If user provides a callback_package it means
       user wants to use PL/SQL saga callbacks */
    /* If the callback package is null it means the user is using the
       PL/SQL admin package to just create the participant, the user-
       defined methods will be declared in Java,Python,OCI etc */
    IF callback_package IS NOT NULL THEN
      /* Using a PL/SQL based participant and this particpant is now
         complete since we know where to send the notification
         messages. */
      participant_status := dbms_saga_adm_sys.COMPLETED;

      /* Register to this callback */
      internal_callback := 'plsql://dbms_saga.notify_callback_participant';

      /* Register for the callback which is invoked whenever there is a
         message in the INBOUND queue for the participant. */
      DBMS_AQ.REGISTER(sys.aq$_reg_info_list(sys.aq$_reg_info(q_in_schema,
      dbms_aq.namespace_aq, internal_callback, HEXTORAW('FF'))), 1);

    END IF;

    /* curr_state = 5 : No matter if we create the registration or not
                        we need to fill the state gap. */
    curr_state := curr_state + 1;

    write_trace('ADDPARTICIPANTORCOORDINATOR(SYS) : registering callback for
    participant - plsql://dbms_saga.notify_callback_participant');
  END IF;

  /* Check if there is already an entry for this broker id. There might
     be a case when a previously created coordinator has already added
     the broker into message_broker$ table. We dont want to put it
     again. */
  /* If the entity is being created locally to a broker then skip this
     check because broker$ already has this information.
   */
  IF dblink_to_broker_int IS NOT NULL THEN
    select count(*) into any_rows_found from saga_message_broker$
    where name = broker_name_int and owner = mailbox_schema_int
    and remote = dbms_saga_adm_sys.DBMS_REMOTE;
    /* Seeing it for the first time */
    IF any_rows_found = 0 THEN
      insert into saga_message_broker$ values(broker_id, broker_name_int,
                 mailbox_schema_int, 'SAGA$_' || broker_name_int || '_INOUT',
                 dbms_saga_adm_sys.DBMS_REMOTE);
    END IF;
  END IF;
  /* curr_state = 6 : Entry made in broker$ */
  curr_state := curr_state + 1;

  /* Generate a entity GUID */
  participant_id := sys_guid();
  write_trace('ADDPARTICIPANTORCOORDINATOR(SYS) : participant GUID : '
  || participant_id);

  /* Insert into the sys.saga_participant$. */
  insert into saga_participant$ values(participant_id, entity_name_int,
                                           entity_schema_int,
                                           coordinatorOrParticipant,
                                           broker_id,
                                           coordinator_id,
                                           dblink_to_broker_int,
                                           dblink_to_entity_int,
                                           q_in, q_out,
                                           callback_schema_int,
                                           callback_package_int,
                                           participant_status,
                                           dbms_saga_adm_sys.DBMS_LOCAL);

  /* Generate saga_secret and insert into saga_secret$ */
  saga_secret := trunc(dbms_random.value(0,99999999));
  insert into saga_secrets$ values(participant_id,
                                       saga_secret,
                                       dbms_saga_adm_sys.CONNECT_BROKER,
                                       CURRENT_TIMESTAMP);

  /* curr_state = 7 : Entry made in participant$ and secret$ */
  curr_state := curr_state + 1;

  /* We have setup all links from entity to broker, now time to do work
     from broker -> entity */
  /* Setup the broker PDB to setup propagation.
     This is illustrated below:
     Parti/Coordi OUTBOUND queue -> propagates -> Broker's INOUT queue.
     Broker INOUT queue -> propagates ->
     Participant's/Coordinator's INBOUND queue */
  IF dblink_to_broker_int IS NOT NULL THEN
    connectbroker_string := 'dbms_saga_connect_int'
    || '.' || 'connectBrokerToInqueue' || '@' || dblink_to_broker_sec;
  ELSE
    null;
    connectbroker_string := 'dbms_saga_connect_int'
    || '.' || 'connectBrokerToInqueue';
  END IF;
  v_sql := 'BEGIN ' ||
            connectbroker_string ||
            '(:1 , :2 , :3 , :4 , :5 , :6 , :7 , :8 , :9 , :10 , :11
            , :12 , :13 , :14 , :15, :16); END;';
  execute immediate v_sql using participant_id,entity_name_int,
  entity_schema_int,coordinatorOrParticipant,broker_id,coordinator_id,
  dblink_to_broker_int,dblink_to_entity_int,q_in,q_out,callback_schema_int,
  callback_package_int,participant_status,mailbox_schema_int,broker_name_int,
  saga_secret;

  /* delete the secret after validation */
  delete from saga_secrets$ where secret = saga_secret;

COMMIT;
EXCEPTION
  WHEN INVALIDPKG THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Missing package or execution rights
    for package ' || callback_schema_int || '.' || callback_package_int);
  WHEN NULLDBLINK THEN
    RAISE_APPLICATION_ERROR(-20001 , 'dblink cannot be NULL when broker dblink
                                      is non-null.');
  WHEN REMOTECALLERROR THEN
    RAISE_APPLICATION_ERROR(-20001 , 'unable to make remote call using the given
                                      db_link');
  /* Cannot find the broker that is specified */
  WHEN ENTITY_EXISTS_PDB THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Entity ' || entity_name_int ||
    ' already exists at the broker. Entity name should be unique across
      this pdb and broker dependents');
  /* Cannot find the broker that is specified */
  WHEN BROKERINVALID THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Create Entity :
    Cannot create participant or coordinator because the broker
    name or schema is invalid');
  /* Broker exists but cant fetch the broker id for some reason */
  WHEN BROKERIDERR THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Create Entity :
    Cannot fetch broker id from the remote pdb.');
  /* Cannot find the coordinator specified */
  WHEN COORDINATORNOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Create Participant:
    Invalid Coordinator Name');
  /* There is a problem when we do remote operation */
  WHEN dbms_saga_adm_sys.CONNECTTOBROKERFAILURE THEN
    /* Try disconnecting from broker to the entity - Compensation */
    IF dblink_to_broker_int IS NOT NULL THEN
      disconnectbroker_string := 'dbms_saga_connect_int' || '.'
      || 'disconnectBrokerFromInqueue' || '@' || dblink_to_broker_sec;
    ELSE
      disconnectbroker_string := 'dbms_saga_connect_int' || '.'
      || 'disconnectBrokerFromInqueue';
    END IF;
    v_sql := 'BEGIN ' ||
              disconnectbroker_string ||
              '(:1, :2, :3, :4, :5, :6, :7, :8); END;';
    execute immediate v_sql using entity_name_int, entity_schema_int,
                    dblink_to_entity_int, mailbox_schema_int,
                    broker_name_int, dblink_to_broker_int, participant_id,
                    saga_secret;

    /* Compensate for what we did on the local pdb with highest state
       because we did all operations successfully in the local pdb. */
    drop_entity_int(entity_name_int, entity_schema_int, broker_id,
    participant_status, dblink_to_broker_int, broker_name_int,
    mailbox_schema_int, internal_callback,
    dbms_saga_adm_sys.PARTICIPANTENTRYDONE, saga_secret);
    /* Raise the actual exception after compensation */
    RAISE;
  /* There is some local problem */
  WHEN OTHERS THEN
    /* We failed locally, let's initiate a local compensation */
    drop_entity_int(entity_name_int, entity_schema_int, broker_id,
    participant_status, dblink_to_broker_int, broker_name_int,
    mailbox_schema_int, internal_callback,
    curr_state, saga_secret);
    /* Raise the actual exception after compensation */
    RAISE;
END;


/* Procedure for reverse connecting the broker at other PDB to this
   participant/coordinator. */
procedure connectBrokerToInqueue(participant_id IN RAW,
                                 entity_name_int IN varchar2 ,
                                 entity_schema_int IN varchar2 ,
                                 coordinatorOrParticipant IN number,
                                 broker_id IN RAW,
                                 coordinator_id IN RAW,
                                 dblink_to_broker_int IN varchar2,
                                 dblink_to_entity_int IN varchar2,
                                 inbound_queue IN varchar2,
                                 outbound_queue IN varchar2,
                                 callback_schema_int IN varchar2 ,
                                 callback_package_int IN varchar2 ,
                                 participant_iscomplete IN number,
                                 broker_schema_int IN varchar2 ,
                                 broker_name_int IN varchar2,
                                 saga_secret IN number) as

  q_in                M_IDEN%TYPE;
  q_in_q              M_IDEN_Q%TYPE;
  q_in_dest           M_IDEN_SCM%TYPE;
  q_out               M_IDEN%TYPE;
  q_out_q             M_IDEN_Q%TYPE;
  q_out_schema        M_IDEN_SCM%TYPE;
  q_in_schema         M_IDEN%TYPE;
  broker_schema_q     M_IDEN_Q%TYPE;
  entity_schema_q     M_IDEN_Q%TYPE;
  dblink_to_entity_q  M_IDEN_Q%TYPE;
  dest_dblink         M_IDEN%TYPE;
  subscriber_out      sys.aq$_agent;

BEGIN

  /* Enquote broker, entity schema and dblink to entity */
  broker_schema_q := dbms_assert.enquote_name(broker_schema_int, FALSE);
  entity_schema_q := dbms_assert.enquote_name(entity_schema_int, FALSE);
  IF dblink_to_entity_int IS NOT NULL THEN
    dblink_to_entity_q := dbms_assert.enquote_name(dblink_to_entity_int, FALSE);
  END IF;

  /* Prepare the Broker Queue */
  q_out := 'SAGA$_' || broker_name_int || '_INOUT';
  q_out_q := dbms_assert.enquote_name(q_out, FALSE);
  q_out_schema := broker_schema_q || '.' || q_out_q;

  /* Prepare the entity queue */
  q_in := 'SAGA$_' || entity_name_int || '_IN_Q';
  q_in_q := dbms_assert.enquote_name(q_in, FALSE);
  q_in_schema := entity_schema_q || '.' || q_in_q
                                 || '@' || dblink_to_entity_q;
  /* Destination queue - participant / coordinator */
  q_in_dest := entity_schema_q || '.' || q_in_q;

  write_trace('CONNECTBROKERTOINQUEUE(SYS) : setting up reverse link from broker
   to participant/coordinator IN Queue. Queue_out : ' || q_out
  || 'destination_queue : ' || q_in_schema);

  /* If there is a message in the mailbox for a particular entity,
     forward it to that entity since the recipient name is unique
     for each broker */
  IF dblink_to_broker_int IS NOT NULL THEN
    subscriber_out := sys.aq$_agent(NULL , q_in_schema, 0);
    dest_dblink := dblink_to_entity_int;
  ELSE
    subscriber_out := sys.aq$_agent(NULL, q_in_dest, 0);
  END IF;

  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => q_out_schema,
                            subscriber => subscriber_out,
                            queue_to_queue => TRUE,
                            rule => 'tab.user_data.header.get_string_property(''jms_oracle_aq$_saga_recipient'') = '''
                            || entity_name_int || '''');

  /* Schedule propagation from the broker queue to the INBOUND queue
     of the entity */
  dbms_aqadm.schedule_propagation(queue_name => q_out_schema,
                                  destination => dest_dblink,
                                  destination_queue => q_in_dest,
                                  latency => 0);

  IF dblink_to_broker_int IS NOT NULL THEN
    /* insert into sys.saga_participant$ at the broker */
    insert into saga_participant$ values(participant_id,
                                           entity_name_int,
                                           entity_schema_int,
                                           coordinatorOrParticipant,
                                           broker_id, coordinator_id,
                                           dblink_to_broker_int,
                                           dblink_to_entity_int,
                                           inbound_queue, outbound_queue,
                                           callback_schema_int,
                                           callback_package_int,
                                           participant_iscomplete,
                                           dbms_saga_adm_sys.DBMS_REMOTE);
  END IF;

COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    RAISE dbms_saga_adm_sys.CONNECTTOBROKERFAILURE;

END;


/* Internal procedure called by drop_broker and the compensation mechanism
   in case of failed add_broker */
procedure drop_broker_int(queue_table IN varchar2,
                          broker_schema IN varchar2,
                          broker_name_int IN varchar2,
                          curr_state IN number) AS

  q_table_q               M_IDEN_Q%TYPE;
  q_table_schema          M_IDEN_SCM%TYPE;
  QTNOTFOUND              EXCEPTION;
  PRAGMA                  EXCEPTION_INIT(QTNOTFOUND, -24002);
  QTDROPEXCEPTION         EXCEPTION;
  LOCALDELETEEXCEPTION    EXCEPTION;

BEGIN

  /* Atleast the queue table has been created */
  IF curr_state > 0 THEN
    BEGIN
    /* Enquote queue table */
    q_table_q := dbms_assert.enquote_name(queue_table, FALSE);
    q_table_schema := broker_schema || '.' || q_table_q;
    /* Try dropping the queue table with force option */
    dbms_aqadm.drop_queue_table(
      queue_table => q_table_schema,
      force => TRUE
    );
    EXCEPTION
      /* If the queue table is already dropped just move on */
      WHEN QTNOTFOUND THEN
        null;
      /* Error while dropping the queue table - needs possible
         manual action or a retry */
      WHEN OTHERS THEN
        RAISE QTDROPEXCEPTION;
    END;
  END IF;


  /* Dictionary entry has also been made */
  IF curr_state > 1 THEN
    BEGIN
      delete from saga_message_broker$ where name = broker_name_int;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE LOCALDELETEEXCEPTION;
    END;
  END IF;

COMMIT;
EXCEPTION
  WHEN QTDROPEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Queue Table:
    Cannot drop broker queue table. Drop Queue table for this
    broker and then try again.');
  WHEN LOCALDELETEEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Broker:
    Dictionary Entry cannot be cleared. Please try again');
  WHEN OTHERS THEN
    RAISE;
END;


/* Internal procedure called from drop_participant() and drop_coordinator() */
procedure dropParticipantOrCoordinator(entity_name IN varchar2 ,
                                       entity_ntfn_callback IN varchar2) as

  entity_name_int             M_IDEN%TYPE;
  entity_schema               M_IDEN%TYPE;
  entity_q_in                 M_IDEN%TYPE;
  entity_q_out                M_IDEN%TYPE;
  entity_q_in_qt              M_IDEN%TYPE;
  entity_q_out_qt             M_IDEN%TYPE;
  entity_dblink               M_IDEN%TYPE;
  broker_schema               M_IDEN%TYPE;
  broker_name                 M_IDEN%TYPE;
  broker_dblink               M_IDEN%TYPE;
  broker_dblink_q             M_IDEN_Q%TYPE;
  broker_queue                M_IDEN%TYPE;
  participant_status          NUMBER;
  disconnectbroker_string     M_IDEN%TYPE;
  broker_string               M_IDEN_SCM%TYPE;
  v_sql                       VARCHAR2(800);
  broker_i                    RAW(16);
  entity_i                    RAW(16);
  saga_secret                 NUMBER;
  ENTITYNOTFOUND              EXCEPTION;
  BROKETNOTFOUND              EXCEPTION;
  BROKERVALIDATIONERR         EXCEPTION;
  REMOTEDROPFAILED            EXCEPTION;
  DROPFAILED                  EXCEPTION;

BEGIN

  /* Canonicalize entity name */
  dbms_utility.canonicalize(entity_name, entity_name_int, MAX_ENTITY_NAME);

  /* Collect initial information */
  BEGIN
    select owner,broker_id,dblink_to_participant,dblink_to_broker,
           participant_iscomplete, id into entity_schema,broker_i,
           entity_dblink,broker_dblink,participant_status, entity_i
    from saga_participant$ where name = entity_name_int;
  EXCEPTION
    -- Invalid Participant/Coordinator name
    WHEN NO_DATA_FOUND THEN
      RAISE ENTITYNOTFOUND;
  END;

  IF broker_dblink IS NOT NULL THEN
    broker_dblink_q := dbms_assert.enquote_name(broker_dblink, FALSE);
  END IF;

  /* Validate and get broker information */
  BEGIN
    /* Check for a valid broker */
    IF broker_dblink IS NOT NULL THEN
      broker_string := 'dbms_saga_connect_int' || '.' ||
      'getBrokerInfo' || '@' || broker_dblink_q;
      v_sql := 'BEGIN ' ||
               broker_string ||
               '(:1, :2, :3, :4); END;';
      execute immediate v_sql using IN OUT broker_i, IN OUT broker_schema,
                                    IN OUT broker_name, FALSE;
    ELSE
      execute immediate 'select owner, name from saga_message_broker$
      where id = :1' into broker_schema, broker_name using broker_i;
    END IF;
  EXCEPTION
    /* Broker not found , throw error and stop. */
    WHEN NO_DATA_FOUND THEN
      RAISE BROKETNOTFOUND;
    WHEN OTHERS THEN
      RAISE BROKERVALIDATIONERR;
  END;

  /* Generate saga_secret and insert into saga_secret$ */
  saga_secret := trunc(dbms_random.value(0,99999999));
  insert into saga_secrets$ values(entity_i,
                                       saga_secret,
                                       dbms_saga_adm_sys.DISCONNECT_BROKER,
                                       CURRENT_TIMESTAMP);

  /* Try disconnecting from broker to the entity */
  BEGIN
    IF broker_dblink IS NOT NULL THEN
      disconnectbroker_string := 'dbms_saga_connect_int' || '.'
        || 'disconnectBrokerFromInqueue' || '@' || broker_dblink_q;
    ELSE
      disconnectbroker_string := 'dbms_saga_connect_int' || '.'
        || 'disconnectBrokerFromInqueue';
    END IF;
    v_sql := 'BEGIN ' ||
              disconnectbroker_string ||
              '(:1, :2, :3, :4, :5, :6, :7, :8); END;';
    execute immediate v_sql using entity_name_int, entity_schema,
                                entity_dblink, broker_schema,
                                broker_name, broker_dblink, entity_i,
                                saga_secret;
  /* Drop operation failed at remote pdb */
  EXCEPTION
    WHEN OTHERS THEN
      RAISE REMOTEDROPFAILED;
  END;

  /* Try cleanup on local pdb */
  BEGIN
    /* Call internal drop prcoedure with the highest state for drop */
    drop_entity_int(entity_name_int, entity_schema, broker_i,
    participant_status, broker_dblink, broker_name, broker_schema,
    entity_ntfn_callback, dbms_saga_adm_sys.PARTICIPANTENTRYDONE,
    saga_secret);
  EXCEPTION
    /* Drop operation failed at local pdb */
    WHEN OTHERS THEN
      RAISE DROPFAILED;
  END;

COMMIT;
EXCEPTION
  WHEN ENTITYNOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Entity Not Found :
    participant/coordinator does not exist.');
  WHEN BROKETNOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity :
    Cannot drop participant or coordinator because the broker
    for this entity was not found on remote pdb');
  WHEN BROKERVALIDATIONERR THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity :
    Cannot validate if broker still exists on remote pdb');
  WHEN REMOTEDROPFAILED THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity :
    Drop operation at broker pdb failed.');
  WHEN DROPFAILED THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity :
    Drop operation failed. Please retry');
  WHEN OTHERS THEN
    RAISE;
END;


/* Procedure for destroying the reverse connection from the broker at other
   PDB to this participant/coordinator. */
procedure disconnectBrokerFromInqueue(entity_name_int IN varchar2 ,
                                      entity_schema_int IN varchar2,
                                      dblink_to_entity_int IN varchar2,
                                      broker_schema_int IN varchar2,
                                      broker_name_int IN varchar2,
                                      dblink_to_broker IN varchar2,
                                      entity_id IN RAW,
                                      saga_secret IN number) as

  broker_schema_q           M_IDEN_Q%TYPE;
  entity_schema_q           M_IDEN_Q%TYPE;
  broker_queue              M_IDEN%TYPE;
  broker_queue_q            M_IDEN_Q%TYPE;
  broker_queue_schema       M_IDEN_SCM%TYPE;
  entity_in_queue           M_IDEN%TYPE;
  entity_in_queue_q         M_IDEN_Q%TYPE;
  entity_in_queue_schema    M_IDEN_SCM%TYPE;
  dblink_to_entity_q        M_IDEN_Q%TYPE;
  subscriber_out            sys.aq$_agent;
  entity_pdb                M_IDEN%TYPE;
  dest_dblink               M_IDEN%TYPE;
  PROPAGATIONNOTFOUND       EXCEPTION;
  PRAGMA                    EXCEPTION_INIT(PROPAGATIONNOTFOUND, -24042);
  SUBSCRIBERNOTFOUND        EXCEPTION;
  PRAGMA                    EXCEPTION_INIT(SUBSCRIBERNOTFOUND, -24035);
  QUEUENOTFOUND             EXCEPTION;
  PRAGMA                    EXCEPTION_INIT(QUEUENOTFOUND, -24010);
  PROPAGATIONDROPERR        EXCEPTION;
  SUBSCRIBERDROPERR         EXCEPTION;
  DICTCLEARERR              EXCEPTION;

BEGIN

  /* Enquote broker and entity schema */
  broker_schema_q := dbms_assert.enquote_name(broker_schema_int, FALSE);
  entity_schema_q := dbms_assert.enquote_name(entity_schema_int, FALSE);

  /* Construct broker queue */
  broker_queue := 'SAGA$_' || broker_name_int || '_INOUT';
  broker_queue_q := dbms_assert.enquote_name(broker_queue, FALSE);
  broker_queue_schema := broker_schema_q || '.' || broker_queue_q;

  /* Construct entity queue */
  entity_in_queue := 'SAGA$_' || entity_name_int || '_IN_Q';
  entity_in_queue_q := dbms_assert.enquote_name(entity_in_queue, FALSE);
  entity_in_queue_schema := entity_schema_q || '.' || entity_in_queue_q;

  IF dblink_to_broker IS NOT NULL THEN
    dblink_to_entity_q := dbms_assert.enquote_name(dblink_to_entity_int, FALSE);
    dest_dblink := dblink_to_entity_int;
  END IF;

  /*Unschedule the propagation from broker to entity */
  BEGIN
    /* Try unscheduling the propagation */
    dbms_aqadm.unschedule_propagation(queue_name => broker_queue_schema,
                                    destination => dest_dblink,
                                    destination_queue => entity_in_queue_schema
                                    );
  EXCEPTION
    /* If propagation does not exist then its fine we can just move ahead */
    WHEN QUEUENOTFOUND OR PROPAGATIONNOTFOUND THEN
      null;
    /* Manual interventioned required otherwise */
    WHEN OTHERS THEN
      RAISE PROPAGATIONDROPERR;
  END;

  /* Try dropping the entity subscriber */
  BEGIN
    entity_pdb := entity_in_queue_schema || '@' || dblink_to_entity_q;
    IF dblink_to_broker IS NOT NULL THEN
      subscriber_out := sys.aq$_agent(NULL , entity_pdb , 0);
    ELSE
      subscriber_out := sys.aq$_agent(NULL, entity_in_queue_schema, 0);
    END IF;
    /* Entity is no longer a subscriber to the broker queue which means
       any more messages for this entity that comes into the mailbox will
       not be sent to the participant / coordinator. */
    DBMS_AQADM.REMOVE_SUBSCRIBER(queue_name => broker_queue_schema,
                                 subscriber => subscriber_out);
  EXCEPTION
    /* If the subscriber does not exist its okay move ahead */
    WHEN QUEUENOTFOUND OR SUBSCRIBERNOTFOUND THEN
      null;
    /* Manual interventioned required otherwise */
    WHEN OTHERS THEN
      RAISE SUBSCRIBERDROPERR;
  END;

  write_trace('DISCONNECTBROKERFROMINQUEUE : destroying reverse link
  from broker to participant/coordinator IN Queue. Queue_out : '
  || broker_queue_schema || 'destination_queue : ' || entity_in_queue);

  IF dblink_to_broker IS NOT NULL THEN
    /* clear the dictionary entry */
    BEGIN
      delete from saga_participant$ where name = entity_name_int;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE DICTCLEARERR;
    END;
  END IF;

COMMIT;
EXCEPTION
  WHEN PROPAGATIONDROPERR THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity: The propagation
    from broker to the entity could not be unscheduled. Please unschedule
    the propagation and try again.');
  WHEN SUBSCRIBERDROPERR THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity: The entity
    subscriber cannot be dropped at the broker PDB. Please drop the
    entity subscriber and try again.');
  WHEN DICTCLEARERR THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity:
    Dictionary Entry cannot be cleared. Please try again');
  WHEN OTHERS THEN
    RAISE;
END;


/* Internal procedure to drop a participant/coordinator */
procedure drop_entity_int(entity_name_int IN varchar2,
                          entity_schema_int IN varchar2,
                          broker_idr IN raw,
                          participant_status IN number,
                          broker_dblink_int IN varchar2,
                          broker_name_int IN varchar2,
                          mailbox_schema_int IN varchar2,
                          entity_ntfn_callback IN varchar2,
                          curr_state_int IN number,
                          saga_secret IN number) as

  entity_q_in             M_IDEN%TYPE;
  entity_q_in_q           M_IDEN_Q%TYPE;
  entity_q_in_schema      M_IDEN_SCM%TYPE;
  entity_q_out            M_IDEN%TYPE;
  entity_q_out_q          M_IDEN_Q%TYPE;
  entity_q_out_schema     M_IDEN_SCM%TYPE;
  entity_schema_q         M_IDEN_Q%TYPE;
  broker_queue            M_IDEN%TYPE;
  broker_queue_q          M_IDEN_Q%TYPE;
  broker_queue_schema     M_IDEN_SCM%TYPE;
  mailbox_schema_q        M_IDEN_Q%TYPE;
  broker_dblink_q         M_IDEN_Q%TYPE;
  qt_in                   M_IDEN%TYPE;
  qt_in_q                 M_IDEN_Q%TYPE;
  qt_in_schema            M_IDEN_SCM%TYPE;
  qt_out                  M_IDEN%TYPE;
  qt_out_q                M_IDEN_Q%TYPE;
  qt_out_schema           M_IDEN_SCM%TYPE;
  broker_dest             M_IDEN_SCM%TYPE;
  curr_state              NUMBER;
  broker_dependency       NUMBER;
  subscriber_out          sys.aq$_agent;
  QUEUENOTFOUND           EXCEPTION;
  PRAGMA                  EXCEPTION_INIT(QUEUENOTFOUND, -25205);
  QUEUENOTFOUND2          EXCEPTION;
  PRAGMA                  EXCEPTION_INIT(QUEUENOTFOUND2, -24010);
  REGNOTFOUND             EXCEPTION;
  PRAGMA                  EXCEPTION_INIT(REGNOTFOUND, -24950);
  SUBSCRIBERNOTFOUND      EXCEPTION;
  PRAGMA                  EXCEPTION_INIT(SUBSCRIBERNOTFOUND, -24035);
  PROPAGATIONNOTFOUND     EXCEPTION;
  PRAGMA                  EXCEPTION_INIT(PROPAGATIONNOTFOUND, -24042);
  QTNOTFOUND              EXCEPTION;
  PRAGMA                  EXCEPTION_INIT(QTNOTFOUND, -24002);
  DICTDELEXCEPTION        EXCEPTION;
  RMVCALLBACKEXCEPTION    EXCEPTION;
  RMVPROPEXCEPTION        EXCEPTION;
  RMVBQSBSCREXCEPTION     EXCEPTION;
  QTOUTDROPEXCEPTION      EXCEPTION;
  QTINDROPEXCEPTION       EXCEPTION;

BEGIN

  /* Copy the current state */
  curr_state := curr_state_int;

  /* Try to delete the participant$ entry */
  IF curr_state = dbms_saga_adm_sys.PARTICIPANTENTRYDONE THEN
    BEGIN
      delete from saga_participant$ where name = entity_name_int;
      delete from saga_secrets$ where secret = saga_secret;
    EXCEPTION
      /* Unable to clear the dictionary entry, maybe requires manual
         intervention */
      WHEN OTHERS THEN
        RAISE DICTDELEXCEPTION;
    END;
    /* Delete operation was successful - move to the next step */
    curr_state := curr_state - 1;
  END IF;

  /* Try to delete the broker$ entry */
  IF curr_state = dbms_saga_adm_sys.BROKERENTRYDONE THEN
    /* It is not drop_participants responsibility to clear broker$ if
       it is co-located with the broker */
    IF broker_dblink_int IS NOT NULL THEN
      BEGIN
        /* Check if this participant/coordinator is the last
           dependent of the broker. We dont want to delete the
           broker$ entry if other participants are attached to the
           same broker */
        select count(*) into broker_dependency from saga_participant$
        where broker_id = broker_idr;
        /* If this is the last dependent then DELETE the broker from local
           saga_message_broker$ table else don't delete since other entities
           are dependent on it. */
        IF broker_dependency = 0 THEN
          delete from saga_message_broker$ where id = broker_idr;
        END IF;
      EXCEPTION
        /* Unable to clear the dictionary entry, maybe requires manual
           intervention */
        WHEN OTHERS THEN
          RAISE DICTDELEXCEPTION;
      END;
    END IF;
    /* Delete operation was successful - move to the next step */
    curr_state := curr_state - 1;
  END IF;

  /* Enquote entity schema */
  entity_schema_q := dbms_assert.enquote_name(entity_schema_int, FALSE);

  /* Prepare entity IN Queue */
  entity_q_in := 'SAGA$_' || entity_name_int || '_IN_Q';
  entity_q_in_q := dbms_assert.enquote_name(entity_q_in, FALSE);
  entity_q_in_schema := entity_schema_q || '.' || entity_q_in_q;

  /* unregister for noticiation if entity is complete or coordinator */
  IF participant_status = dbms_saga_adm_sys.COMPLETED OR
     participant_status = NULL THEN
    /* Try to remove the notification callback */
    IF curr_state = dbms_saga_adm_sys.CALLBACKDONE THEN
      /* Unregister for the notification callback */
      write_trace('DROPPARTICIPANTORCOORDINATOR(SYS) : try unregister for
      notification:' || entity_ntfn_callback);
      BEGIN
        DBMS_AQ.UNREGISTER(
        sys.aq$_reg_info_list(sys.aq$_reg_info(entity_q_in_schema,
        dbms_aq.namespace_aq, entity_ntfn_callback, HEXTORAW('FF'))), 1);
      EXCEPTION
        /* If the queue is already deleted or the registration is deleted we
           are okay. Just move on. */
        WHEN QUEUENOTFOUND OR REGNOTFOUND THEN
          null;
        /* If anything else then possibly requires manual intervention or
           a retry */
        WHEN OTHERS THEN
          RAISE RMVCALLBACKEXCEPTION;
      END;
      /* Unregister notification callback is successful - move ahead */
      curr_state := curr_state - 1;
    END IF;

  ELSE
    /* Lets be sure we are at the correct stage to avoid unnecessary minus */
    IF curr_state = dbms_saga_adm_sys.CALLBACKDONE THEN
      /* This is an incomplete participant so we have to cover the state gap.
         Lets assume we removed the subscriber and unregistered the callback. */
      curr_state := curr_state - 1;
    END IF;
  END IF;

  /* Construct OUT queue for the entity */
  entity_q_out := 'SAGA$_' || entity_name_int || '_OUT_Q';
  entity_q_out_q := dbms_assert.enquote_name(entity_q_out, FALSE);
  entity_q_out_schema := entity_schema_q || '.' || entity_q_out_q;

  /* Construct Broker Queue */
  mailbox_schema_q := dbms_assert.enquote_name(mailbox_schema_int, FALSE);
  broker_dblink_q := dbms_assert.enquote_name(broker_dblink_int,FALSE);
  broker_queue := 'SAGA$_' || broker_name_int || '_INOUT';
  broker_queue_q := dbms_assert.enquote_name(broker_queue, FALSE);
  broker_queue_schema := mailbox_schema_q || '.' || broker_queue_q
                                          || '@' || broker_dblink_q;
  broker_dest := mailbox_schema_q || '.' || broker_queue_q;
  /* Try to unschedule the propagation from the outbound queue to the broker */
  IF curr_state = dbms_saga_adm_sys.PROPAGATIONDONE THEN
    /* Unschedule propagation */
    write_trace('DROPPARTICIPANTORCOORDINATOR(SYS) : try unschedule propagation
    Queue_name : ' || entity_q_out_schema || '
    destination : ' || broker_dblink_int);
    BEGIN
      dbms_aqadm.unschedule_propagation(
        queue_name => entity_q_out_schema,
        destination => broker_dblink_int,
        destination_queue => broker_dest);
    EXCEPTION
      /* If the queue does not exist or the propagation has already been
         unscheduled then we are okay. Just move on */
      WHEN QUEUENOTFOUND2 OR PROPAGATIONNOTFOUND THEN
        null;
      /* If anything else then possibly requires manual intervention or
         a retry */
      WHEN OTHERS THEN
        RAISE RMVPROPEXCEPTION;
    END;
    /* Unschedule propagation is successful - move ahead */
    curr_state := curr_state - 1;
  END IF;

  /* Try to remove broker queue as a subscriber of the outbound queue of
     the entity. */
  IF curr_state = BROKERSUBDONE THEN
    /* Try removing broker queue as a subscriber */
    BEGIN
      IF broker_dblink_int IS NOT NULL THEN
        subscriber_out := sys.aq$_agent(NULL , broker_queue_schema, 0);
      ELSE
        subscriber_out := sys.aq$_agent(NULL, broker_dest, 0);
      END IF;

      dbms_aqadm.remove_subscriber(
        queue_name => entity_q_out_schema,
        subscriber => subscriber_out
      );
    EXCEPTION
      /* If the queue does not exist or the subscriber is already
         deleted we are okay. Just move on */
      WHEN QUEUENOTFOUND2 OR SUBSCRIBERNOTFOUND THEN
        null;
      /* If anything else then possibly requires manual intervention or
         a retry */
      WHEN OTHERS THEN
        RAISE RMVBQSBSCREXCEPTION;
    END;
    /* Removing broker queue subscriber is successful - move ahead */
    curr_state := curr_state - 1;
  END IF;

  /* Try and remove the outbound queue table */
  IF curr_state = OUTBOUNDDONE THEN
    /* Construct Outbound Queue Table */
    qt_out := 'SAGA$_' || entity_name_int || '_OUT_QT';
    qt_out_q := dbms_assert.enquote_name(qt_out, FALSE);
    qt_out_schema := entity_schema_q || '.' || qt_out_q;

    /* Remove the outbound queue table */
    write_trace('DROPPARTICIPANTORCOORDINATOR(SYS) : qt_out :'|| qt_out_schema);
    BEGIN
      dbms_aqadm.drop_queue_table(
        queue_table => qt_out_schema,
        force => TRUE
      );
    EXCEPTION
      /* If the queue table is not found then we are okay. Just move on */
      WHEN QTNOTFOUND THEN
        null;
      /* If anything else then possibly requires manual intervention or
         a retry */
      WHEN OTHERS THEN
        RAISE QTOUTDROPEXCEPTION;
    END;
    /* Removing outbound QT is successful - move ahead */
    curr_state := curr_state - 1;
  END IF;

  IF curr_state = INBOUNDDONE THEN
    /* Construct Inbound Queue Table */
    qt_in := 'SAGA$_' || entity_name_int || '_IN_QT';
    qt_in_q := dbms_assert.enquote_name(qt_in, FALSE);
    qt_in_schema := entity_schema_q || '.' || qt_in_q;

    /* Remove the inbound queue table */
    write_trace('DROPPARTICIPANTORCOORDINATOR(SYS) : qt_out :'|| qt_in_schema);
    BEGIN
      dbms_aqadm.drop_queue_table(
        queue_table => qt_in_schema,
        force => TRUE
      );
    EXCEPTION
      /* If the queue table is not found then we are okay. Just move on */
      WHEN QTNOTFOUND THEN
        null;
      /* If anything else then possibly requires manual intervention or
         a retry */
      WHEN OTHERS THEN
        RAISE QTINDROPEXCEPTION;
    END;
    /* Removing outbound QT is successful - all done */
    curr_state := curr_state - 1;
  END IF;

COMMIT;
EXCEPTION
  WHEN DICTDELEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity:
    Dictionary Entry cannot be cleared. Please try again');
  WHEN RMVCALLBACKEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity:
    Cannot unregister notification callback for this entity.
    Unregister the notification callback for this entity and
    try again.');
  WHEN RMVPROPEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity: Cannot
    unschedule the propagation from outbound queue to the broker.
    Please unschedule the propagation and try again.');
  WHEN RMVBQSBSCREXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity: Cannot
    drop the broker queue subscriber. Please remove the broker queue
    subscriber and try again.');
  WHEN QTOUTDROPEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity: Cannot
    drop the outbound queue table. Please drop the outbound queue
    and then try again.');
  WHEN QTINDROPEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Drop Entity: Cannot
    drop the inbound queue table. Please drop the inbound queue
    and then try again.');
  WHEN OTHERS THEN
    RAISE;
END;


/* Procedure to compensation actions done by register_saga_callback incase
   there is an exception after doing some operations */
procedure register_callback_comp(participant_name_int IN varchar2,
                                 participant_schema IN varchar2,
                                 broker_dblink IN varchar2,
                                 old_p_status IN number,
                                 old_p_callback_schm IN varchar2,
                                 old_p_callback_name IN varchar2,
                                 participant_id IN raw,
                                 curr_state_int IN number) AS

  p_q_in                     M_IDEN%TYPE;
  p_q_in_q                   M_IDEN_Q%TYPE;
  p_q_in_q_schema            M_IDEN_SCM%TYPE;
  participant_schema_q       M_IDEN_Q%TYPE;
  brkr_dblink_q              M_IDEN_Q%TYPE;
  curr_state                 NUMBER;
  broker_string              M_IDEN_SCM%TYPE;
  v_sql                      VARCHAR2(600);
  saga_secret                NUMBER;
  QUEUENOTFOUND              EXCEPTION;
  PRAGMA                     EXCEPTION_INIT(QUEUENOTFOUND, -25205);
  REGNOTFOUND                EXCEPTION;
  PRAGMA                     EXCEPTION_INIT(REGNOTFOUND, -24950);
  QUEUENOTFOUND2             EXCEPTION;
  PRAGMA                     EXCEPTION_INIT(QUEUENOTFOUND2, -24010);
  REMOTEUPDATEEXCEPTION      EXCEPTION;
  LOCALUPDATEEXCEPTION       EXCEPTION;
  RMVCALLBACKEXCEPTION       EXCEPTION;

BEGIN

  /* Copy the current state */
  curr_state := curr_state_int;

  /* Failure after remote update, we need to go back to the old state */
  IF curr_state = dbms_saga_adm_sys.REGREMOTEDONE THEN
    IF broker_dblink IS NOT NULL THEN
      BEGIN
        /* Enquote broker dblink */
        brkr_dblink_q := dbms_assert.enquote_name(broker_dblink, FALSE);

        /* Update saga_participant$ at broker PDB */
        broker_string := 'dbms_saga_connect_int' || '.' ||
          'updateCallbackInfo' || '@' || brkr_dblink_q;
        v_sql := 'BEGIN ' ||
                  broker_string ||
                  '(:1, :2, :3, :4, :5); END;';
        execute immediate v_sql using old_p_callback_schm, old_p_callback_name,
                                old_p_status, participant_id, saga_secret;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE REMOTEUPDATEEXCEPTION;
      END;
    END IF;
    /* Update operation successful move ahead */
    curr_state := curr_state - 1;
  END IF;

  /* Failure after local update, we need to go back to old state */
  IF curr_state = dbms_saga_adm_sys.REGLOCALDONE THEN
    BEGIN
      /* Update saga_participant$ at local PDB */
      update saga_participant$ set callback_schema = old_p_callback_schm,
      callback_package = old_p_callback_name,
      participant_iscomplete = old_p_status
      where name = participant_name_int;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE LOCALUPDATEEXCEPTION;
    END;
    /* Update operation successful move ahead */
    curr_state := curr_state - 1;
  END IF;

  /* Check if the old participant status was complete then we just need
     to fill the state gap otherwise we might need to drop the subscriber
     or remove the callback or both */
  IF old_p_status = dbms_saga_adm_sys.INCOMPLETE THEN
    /* Enquote participant schema */
    participant_schema_q := dbms_assert.enquote_name(participant_schema,FALSE);
    /* Construct IN queue */
    p_q_in := 'SAGA$_' || participant_name_int || '_IN_Q';
    p_q_in_q := dbms_assert.enquote_name(p_q_in, FALSE);
    p_q_in_q_schema := participant_schema_q || '.' || p_q_in_q;

    /* Try to remove the notification callback */
    IF curr_state = dbms_saga_adm_sys.REGCALLBACKDONE THEN
      /* Unregister for the notification callback */
      BEGIN
        DBMS_AQ.UNREGISTER(
        sys.aq$_reg_info_list(sys.aq$_reg_info(p_q_in_q_schema
        , dbms_aq.namespace_aq,
        'plsql://dbms_saga.notify_callback_participant', HEXTORAW('FF'))), 1);
      EXCEPTION
        /* If the queue is already deleted or the registration is deleted we
           are okay. Just move on. */
        WHEN QUEUENOTFOUND OR REGNOTFOUND THEN
          null;
        /* If anything else then possibly requires manual intervention or
           a retry */
        WHEN OTHERS THEN
          RAISE RMVCALLBACKEXCEPTION;
      END;
    END IF;
  END IF;

  /* Unregister notification callback is successful - move ahead */
  curr_state := curr_state - 1;

COMMIT;
EXCEPTION
  WHEN REMOTEUPDATEEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Register Participant:
    Compensation callback for register_saga_callback failed to update
    broker table. Please try to register saga callback again.');
  WHEN LOCALUPDATEEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Register Participant:
    Compensation callback for register_saga_callback failed to update
    local table. Please try to register saga callback again.');
  WHEN RMVCALLBACKEXCEPTION THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot Register Participant:
    Compensation callback for register_saga_callback failed to remove
    registered callback. Please try to register saga callback again.');
  WHEN OTHERS THEN
    RAISE;
END;


/* helper procedure to process the coordinator's notification. We cannot keep
 * the whole callback inside dbms_saga_adm_sys because we don't get the call
 * stack when the notification is invoked hence the notification callback is
 * blocked due to accessible by clause.
 */
procedure process_notification(recipient IN varchar2,
                               sender IN varchar2,
                               deq_saga_id IN saga_id_t,
                               opcode IN number,
                               coordinator IN varchar2,
                               req_res IN clob) AS

  valid_sagaid        NUMBER;
  BAD_OPCODE          EXCEPTION;

  /* Enqueue back the acknowledgement to the participant to
     complete join saga. */
  procedure enqueue_ack(saga_id IN saga_id_t, receiver IN VARCHAR2,
                        initiator IN VARCHAR2, req_payload IN CLOB) is

    enqueue_options             sys.dbms_aq.enqueue_options_t;
    message_properties_enq      sys.dbms_aq.message_properties_t;
    message_handle_enq          RAW(16);
    message_enq                 SYS.AQ$_JMS_TEXT_MESSAGE;
    q_out                       M_IDEN%TYPE;
    q_out_q                     M_IDEN_Q%TYPE;
    q_out_schema                M_IDEN_SCM%TYPE;
    initiator_schema            M_IDEN%TYPE;
    initiator_schema_q          M_IDEN%TYPE;

    BEGIN

      /* Get the initiators schema */
      select owner into initiator_schema from saga_participant$
      where name = initiator;

      /* Enquote schema */
      initiator_schema_q := dbms_assert.enquote_name(initiator_schema, FALSE);
      /* Construct out queue */
      q_out := 'SAGA$_' || initiator || '_OUT_Q';
      q_out_q := dbms_assert.enquote_name(q_out, FALSE);
      q_out_schema := initiator_schema_q || '.' || q_out_q;
      /* Enqueue the ACK message */
      message_enq :=  SYS.AQ$_JMS_TEXT_MESSAGE.construct;
      dbms_saga.set_saga_sender(message_enq, initiator);
      dbms_saga.set_saga_recipient(message_enq, receiver);
      dbms_saga.set_saga_opcode(message_enq, dbms_saga_sys.ACK_SAGA);
      dbms_saga.set_saga_id(message_enq, saga_id);
      message_enq.set_text(req_payload);
      DBMS_AQ.ENQUEUE(queue_name => q_out_schema,
                      enqueue_options    => enqueue_options,
                      message_properties => message_properties_enq,
                      payload  => message_enq,
                      msgid   => message_handle_enq);
    COMMIT;
    END;

BEGIN

  /* Lets handle the opcode */
  CASE
    /* Participants wants to join this saga */
    WHEN (opcode = dbms_saga_sys.JOIN_SAGA) THEN
      /* Check if this saga_id really exists inside saga$ otherwise a malicious
         saga has been initiated and we should not give the ACK back for it
       */
      select count(*) into valid_sagaid from saga$ where id = deq_saga_id
      and status = dbms_saga_sys.INITIATED;

      IF valid_sagaid > 0 THEN
        /* insert into sys.saga_participant_set$ and enqueue an
           acknowledment back to the participant */
        insert into saga_participant_set$ values(deq_saga_id,
                                  recipient,
                                  sender,
                                  dbms_saga_sys.JOINED,
                                  CURRENT_TIMESTAMP,
                                  CURRENT_TIMESTAMP + INTERVAL '86400' SECOND);
        enqueue_ack(deq_saga_id, sender,
                    recipient, req_res);
      END IF;
    /* Participant has commited and sent a commited message */
    WHEN (opcode = dbms_saga.CMT_SAGA) THEN
      update saga_participant_set$ set status = dbms_saga_sys.COMMITED
      where saga_id = deq_saga_id and participant = sender;
      COMMIT;
    /* Participant has rolledback and sent a rollback message */
    WHEN (opcode = dbms_saga.ABRT_SAGA) THEN
      update saga_participant_set$ set status = dbms_saga_sys.ROLLEDBACK
      where  saga_id = deq_saga_id and participant = sender;
      COMMIT;
    /* Commit failed for participant */
    WHEN (opcode = dbms_saga.CMT_FAIL) THEN
      update saga_participant_set$ set status = dbms_saga_sys.COMMIT_FAILED
      where saga_id = deq_saga_id and participant = sender;
      COMMIT;
    /* Rollback failed for participant */
    WHEN (opcode = dbms_saga.ABRT_FAIL) THEN
      update saga_participant_set$
      set status = dbms_saga_sys.ROLLEDBACK_FAILED
      where saga_id = deq_saga_id and participant = sender;
      COMMIT;
    /* We don't recognize this opcode */
    ELSE
      RAISE BAD_OPCODE;
  END CASE;

COMMIT;
EXCEPTION
  WHEN BAD_OPCODE THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Invalid Opcode for coordinator.');
  WHEN OTHERS THEN
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    uniqueEntity
--
-- PARAMETERS :
--    entity_name       (IN)         - name of broker/coordinator/participant
--    isBroker          (IN)         - broker or coordinator/participant
--
-- RETURNS :
--    boolean           (OUT)        - if the entity is unique or not.
--
--  DESCRIPTION:
--    This is an internal function that returns TRUE if the
--    given broker/coordinator/entity name is unique and FALSE if
--    it already exists.
--
-------------------------------------------------------------------------------

function uniqueEntity(entity_name IN varchar2,
                      entity_schema IN varchar2,
                      isBroker IN boolean) return boolean as

  entity_name_int             M_IDEN%TYPE;
  entity_schema_int           M_IDEN%TYPE;
  any_rows_found              NUMBER;
  sql_stmt                    VARCHAR2(500);

BEGIN

  /* Canonicalize entity name and schema */
  dbms_utility.canonicalize(entity_name, entity_name_int, MAX_ENTITY_NAME);
  dbms_utility.canonicalize(entity_schema, entity_schema_int, MAX_ENTITY_NAME);

  /* Check if entity is broker or participant */
  /* CASE : BROKER */
  IF isBroker = TRUE THEN
    sql_stmt := 'select count(*) from saga_message_broker$
    where name = :1 and remote = ''' || dbms_saga_adm_sys.DBMS_LOCAL || '''';

    execute immediate sql_stmt into any_rows_found
    using entity_name_int;

  /* CASE : PARTICIPANT/COORDINATOR */
  ELSE
    sql_stmt := 'select count(*) from saga_participant$
                 where name = :1';
    execute immediate sql_stmt into any_rows_found using entity_name_int;
  END IF;

  /* Return result according to the number of rows */
  IF any_rows_found <> 0 THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;

END;


-------------------------------------------------------------------------------
--
-- Name :
--    uniqueEntityAtPDB
--
-- Parameters :
--    Entity_Name       (In)         - Name Of Coordinator/Participant
--    Broker_Name       (In)         - Broker Name
--    Mailbox_Schema    (In)         - Broker_Schema
--    broker_pdb_link   (In)         - Pdb Of The Broker
--    entity_dblink     (In)         - DBlink for the coordinator/participant
--
-- Returns :
--    Boolean           (Out)        - If The Entity Is Unique Or Not.
--
--  Description:
--    This Is An Internal Function That Returns True If The
--    given Coordinator/Entity Name Is Unique Across All Pdbs
--    and False If It Already Exists.
--
-------------------------------------------------------------------------------

function uniqueEntityAtPDB(entity_name IN varchar2 ,
                           broker_name IN varchar2,
                           mailbox_schema IN varchar2,
                           broker_pdb_link IN varchar2,
                           entity_dblink IN varchar2) return boolean as

  entity_name_int             M_IDEN%TYPE;
  broker_name_int             M_IDEN%TYPE;
  mailbox_schema_int          M_IDEN%TYPE;
  dblink_int                  M_IDEN%TYPE;
  entity_dblink_int           M_IDEN%TYPE;
  any_rows_found              NUMBER;
  sql_stmt                    VARCHAR2(700);

BEGIN
  /* If broker_pdb_link is non-NULL but entity_dblink is NULL then throw
     error.
   */
  IF entity_dblink IS NULL THEN
    RAISE NO_DATA_FOUND;
  END IF;

  /* Canonicalize items */
  dbms_utility.canonicalize(entity_name, entity_name_int, MAX_ENTITY_NAME);
  dbms_utility.canonicalize(broker_name, broker_name_int, MAX_ENTITY_NAME);
  dbms_utility.canonicalize(mailbox_schema, mailbox_schema_int,
                            MAX_IDENTIFIER_NAME);
  dbms_utility.canonicalize(broker_pdb_link, dblink_int,
                            MAX_IDENTIFIER_NAME);
  dbms_utility.canonicalize(entity_dblink, entity_dblink_int,
                            MAX_IDENTIFIER_NAME);

  IF dblink_int = entity_dblink_int THEN
    RETURN TRUE;
  END IF;

  sql_stmt := 'select count(*) from saga_participant$
        where name = :1 and broker_id =
        (select id from saga_message_broker$
        where name = :2 and owner = :3
        and remote = '''|| dbms_saga_adm_sys.DBMS_LOCAL || ''')';

  execute immediate sql_stmt into any_rows_found
    using entity_name_int, broker_name_int , mailbox_schema_int;

  /* Return result based upon the number of rows */
  IF any_rows_found <> 0 THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END;


/* Get Broker Information for Create/Drop operations */
procedure getBrokerInfo(broker_id IN OUT RAW,
                        broker_name IN OUT varchar2,
                        broker_schema IN OUT varchar2,
                        isCreate IN BOOLEAN) AS

  broker_name_int      M_IDEN%TYPE;
  broker_schema_int    M_IDEN%TYPE;

BEGIN
  IF isCreate = TRUE THEN
    dbms_utility.canonicalize(broker_name, broker_name_int, MAX_ENTITY_NAME);
    dbms_utility.canonicalize(broker_schema, broker_schema_int,
                              MAX_IDENTIFIER_NAME);

    select id into broker_id from saga_message_broker$
    where name = broker_name_int and owner = broker_schema_int;
  ELSE
    select owner, name into broker_name, broker_schema
    from saga_message_broker$ where id = broker_id;
  END IF;
END;


/* Function to determine if the entity creation schema/ callback schema is
   valid and there is no unauthorized access */
--function validateAccess(operation IN NUMBER,
--                        target_schema IN varchar2,
--                        current_user IN varchar2,
--                        cbk_package_int IN varchar2) return boolean as
--
--  target_schema_manager   VARCHAR2(1);
--  target_schema_int       M_IDEN%TYPE;
--  pkg_count               NUMBER;
--  priv_count              NUMBER;

--BEGIN
  /* We have an adm operation performed and an entity is being created. Now
     we need to check if the entity is being created in some other schema
     except current schema then that is not a SYS schema */
--  IF operation = dbms_saga_adm_sys.CREATEENTITY THEN
--    BEGIN
--      dbms_utility.canonicalize(target_schema, target_schema_int,
--                                MAX_ENTITY_NAME);
--      select oracle_maintained into target_schema_manager from all_users
--      where username = target_schema_int;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        RETURN FALSE;
--    END;
    /* If this is an oracle managed schema then there is no permission to
       create a saga entity in this schema */
--    IF target_schema_manager = 'Y' THEN
--      RETURN FALSE;
--    ELSE
--      RETURN TRUE;
--    END IF;
  /* We are trying to register a callback, if the callback schema is the same
     as current user we should make sure that the procedure exists, otherwise
     we should check we have execute rights on the procedure that belongs to the
     other schema */
--  ELSIF operation = dbms_saga_adm_sys.CREATEPACKAGE THEN
    /* Check if the package exists */
--    select count(*) into pkg_count from all_procedures
--    where owner = target_schema and object_name = cbk_package_int;

    /* The package does not even exist so return false */
--    IF pkg_count = 0 THEN
--      RETURN FALSE;
--    ELSE
      /* package belongs to current user schema so we are good */
--      IF current_user = target_schema THEN
--        RETURN TRUE;
      /* package belongs to different schema so lets verify if we have
         execute privileges on it or not */
--      ELSE
        /* check if the user has execute any procedure privilege, then
           simply return true */
--        select count(*) into priv_count from dba_sys_privs
--        where grantee = current_user and privilege = 'EXECUTE ANY PROCEDURE';
--        IF priv_count = 1 THEN
--          RETURN TRUE;
--        END IF;

        /* else check if the user has execute privileges on that package
           granted directly or through a role */
--        select count(*) into priv_count from dba_tab_privs
--        where table_name = cbk_package_int and owner = target_schema
--        and (grantee = current_user or grantee in (select granted_role from
--        dba_role_privs where grantee = current_user));

--        IF priv_count = 0 THEN
--          RETURN FALSE;
--        ELSE
--          RETURN TRUE;
--        END IF;
--      END IF;
--    END IF;
--  END IF;
--END;


/* Procedure to update callback_schema/callback_package in case
   register_saga_callback() is used */
procedure updateCallbackInfo(cbk_schema IN varchar2,
                             cbk_package IN varchar2,
                             p_status IN number,
                             p_id IN RAW,
                             saga_secret IN number) AS

  cbk_schema_int         M_IDEN%TYPE;
  cbk_pkg_int            M_IDEN%TYPE;

BEGIN

  /* Canonicalize callback schema and package name */
  IF cbk_schema IS NOT NULL THEN
    dbms_utility.canonicalize(cbk_schema, cbk_schema_int, MAX_IDENTIFIER_NAME);
  END IF;
  IF cbk_package IS NOT NULL THEN
    dbms_utility.canonicalize(cbk_package, cbk_pkg_int, MAX_IDENTIFIER_NAME);
  END IF;

  update saga_participant$ set callback_schema = cbk_schema_int,
        callback_package = cbk_pkg_int,
        participant_iscomplete = p_status
        where id = p_id;

EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;


/* Internal procedure to validate the saga secret */
function validateSecret(entity_id IN RAW,
                        saga_operation IN NUMBER,
                        saga_secret IN NUMBER) return boolean AS

  any_rows_found        NUMBER;

BEGIN
  /* Check if it is a valid secret */
  select count(*) into any_rows_found from saga_secrets$
  where id = entity_id and secret = saga_secret;

  IF any_rows_found <> 1 THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;

END;


-------------------------------------------------------------------------------
--
-- NAME :
--    write_trace
--
--  DESCRIPTION:
--    Write a message to the trace file for a given event and event level
--
-------------------------------------------------------------------------------

procedure write_trace(
  message      IN varchar2,
  event        IN binary_integer DEFAULT 10855,
  event_level  IN binary_integer DEFAULT 1,
  time_info    IN boolean DEFAULT FALSE) AS

  event_value BINARY_INTEGER := 0;
BEGIN
--  dbms_system.read_ev(event, event_value);
  IF bitand(event_value, event_level) = event_level THEN
    dump_trace(message, time_info);
  END IF;
END write_trace;


-------------------------------------------------------------------------------
--
-- NAME :
--    dump_trace
--
--  DESCRIPTION:
--    Called by write_trace after checking if the event and even_level
--    bits are set to write a message to the trace file.
--
-------------------------------------------------------------------------------

procedure dump_trace(
  message      IN varchar2,
  time_info    IN boolean DEFAULT FALSE) AS

  pos        BINARY_INTEGER := 1;
  mesg_len   BINARY_INTEGER := LENGTH(message);

BEGIN

--  IF time_info THEN
--    dbms_system.ksdddt;
--  END IF;
  WHILE pos <= mesg_len LOOP
--    dbms_system.ksdwrt(1, substr(message, pos, 80));
    pos := pos + 80;
  END LOOP;
END dump_trace;

end dbms_saga_adm_sys;
/
show errors;
create or replace package body dbms_saga_sys as

-------------------------------------------------------------------------------
-----------------------------INTERNAL TYPES -----------------------------------
-------------------------------------------------------------------------------
M_IDEN                  VARCHAR2(128);
M_IDEN_Q                VARCHAR2(130);
M_IDEN_SCM              VARCHAR2(261);

MAX_ENTITY_NAME         CONSTANT BINARY_INTEGER := 115;

-------------------------------------------------------------------------------
--------------------------INTERNAL PROCEDURES----------------------------------
-------------------------------------------------------------------------------
--function join_saga_int(saga_id         IN  saga_id_t,
--                       initiator_name  IN  VARCHAR2,
--                       saga_initiator  IN  VARCHAR2,
--                       coordinator     IN  VARCHAR2,
--                       payload         IN  CLOB) return NUMBER;

procedure call_callbacks(package_name    IN VARCHAR2,
                         package_schema  IN VARCHAR2,
                         proc_name       IN VARCHAR2,
                         saga_id         IN saga_id_t,
                         initiator       IN VARCHAR2,
                         saga_initiator  IN VARCHAR2,
                         coordinator     IN VARCHAR2,
                         payload         IN JSON DEFAULT NULL);

procedure write_trace(message       IN VARCHAR2,
                      event         IN BINARY_INTEGER DEFAULT 10855,
                      event_level   IN BINARY_INTEGER DEFAULT 1,
                      time_info     IN BOOLEAN DEFAULT FALSE);

procedure dump_trace(message    IN  varchar2,
                     time_info  IN boolean DEFAULT FALSE);

procedure commit_or_rollback(saga_participant IN VARCHAR2,
                              deq_saga_id IN saga_id_t,
                              saga_opcode IN NUMBER,
                              force IN boolean DEFAULT TRUE,
                              current_user IN VARCHAR2);

procedure commit_or_rollback_int(participant_name IN VARCHAR2,
                                 participant_level IN NUMBER,
                                 saga_id IN saga_id_t,
                                 saga_opcode IN NUMBER,
                                 force IN BOOLEAN,
                                 saga_status IN NUMBER,
                                 saga_sender IN VARCHAR2,
                                 coordinator IN VARCHAR2,
                                 cbk_package IN VARCHAR2,
                                 cbk_schema IN VARCHAR2);

procedure enqueue_opcode(saga_id IN saga_id_t,
                         sender IN VARCHAR2,
                         recipient IN VARCHAR2,
                         opcode IN NUMBER);

-------------------------------------------------------------------------------
---------------------------BODY DECLARATION------------------------------------
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--
-- NAME :
--    begin_saga
--
-- PARAMETERS :
--    initiator_name       (IN) - name of the initiator
--    timeout              (IN) - saga timeout
--    current_user         (IN) - current user
--
-- RETURNS :
--    guid                 (OUT) - saga id
--
--  DESCRIPTION:
--    This function begins a saga by returning a saga id. Saga timeout
--    could also be setup using this function.
--    Note: The default saga timeout is set to 86400 seconds (24 hours).
--
-------------------------------------------------------------------------------
function begin_saga(initiator_name IN VARCHAR2 ,
                    timeout IN number DEFAULT NULL,
                    current_user IN VARCHAR2) return saga_id_t AS

  stmt                  VARCHAR2(500);
  coordinator_name      M_IDEN%TYPE;
  owner_schema          M_IDEN%TYPE;
  initiator_name_int    M_IDEN%TYPE;
  guid                  RAW(16);
  INVALIDENTITY         EXCEPTION;
  UNAUTHACCESS          EXCEPTION;

BEGIN

  /* Canonicalize initiator name */
  dbms_utility.canonicalize(initiator_name, initiator_name_int, MAX_ENTITY_NAME);

  /* Build query to fetch the owner, coordinator id from the given
     participant */
  stmt := 'select s1.owner, s2.name from saga_participant$ s1,
           saga_participant$ s2 where s1.coordinator_id = s2.id and
           s1.name = :1';
  /* Get data */
  BEGIN
    execute immediate stmt into owner_schema,
                                coordinator_name using initiator_name_int;
  EXCEPTION
    /* Coordinator for this initiator was somehow not found, it means that
       either the coordinator was removed or the initiator name is not
       correct, or maybe the participant was never attached to a
       coordinator. */
    WHEN NO_DATA_FOUND THEN
      RAISE INVALIDENTITY;
  END;

  /* Check if the owner of the initiator is actually the one calling
     begin_saga() */
  IF owner_schema <> current_user THEN
   RAISE UNAUTHACCESS;
  END IF;

  --generate a saga id
  guid := sys_guid();
  --record the saga initiation
  insert into saga$ values(guid, dbms_saga_sys.INITIATOR,
                               initiator_name_int,
                               coordinator_name, owner_schema,
                               initiator_name_int, timeout, CURRENT_TIMESTAMP,
                               NULL, dbms_saga_sys.INITIATED);

  RETURN guid;

COMMIT;
EXCEPTION
  WHEN INVALIDENTITY THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Entity Not Found: The participant or
    its coordinator was not found');
  WHEN UNAUTHACCESS THEN
    RAISE_APPLICATION_ERROR(-20001, 'Unauthorized Access: owner of the
    initiator does not match the current user');
  WHEN OTHERS THEN
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    commit_saga
--
-- PARAMETERS :
--    saga_participant  (IN)         - saga participant name
--    saga_id           (IN)         - saga id
--    force             (IN)         - force commit or not
--
--  DESCRIPTION:
--    This procedure commits the saga by sending commit messages to all
--    participants on behalf of the coordinator.
--    [completion_callback] defined at join_saga is executed
--    for each participant.
--
-------------------------------------------------------------------------------

procedure commit_saga(saga_participant IN VARCHAR2,
                      saga_id IN saga_id_t,
                      force IN boolean DEFAULT TRUE,
                      current_user IN varchar2) AS

  UNAUTHACCESS        EXCEPTION;

BEGIN

  /* Call internal procedure */
  commit_or_rollback(saga_participant, saga_id, dbms_saga_sys.CMT_SAGA, force,
                     current_user);

EXCEPTION
  WHEN UNAUTHACCESS THEN
    RAISE_APPLICATION_ERROR(-20001, 'Unauthorized Access: owner of the
    initiator does not match the current user');
  WHEN OTHERS THEN
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    rollback_saga
--
-- PARAMETERS :
--    saga_participant  (IN)         - saga participant name
--    saga_id           (IN)         - saga id
--    force             (IN)         - force commit or not
--
-- DESCRIPTION:
--    This procedure rolls back the saga by sending abort messages
--    to all participants on behalf of the coordinator.
--    [compensation_callback] defined at join_saga is executed
--    for each participant.
--
-------------------------------------------------------------------------------

procedure rollback_saga(saga_participant IN VARCHAR2,
                        saga_id IN saga_id_t,
                        force IN boolean DEFAULT TRUE,
                        current_user IN varchar2) AS

BEGIN

  /* Call internal procedure */
  commit_or_rollback(saga_participant, saga_id, dbms_saga_sys.ABRT_SAGA, force,
                     current_user);

EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    get_out_topic
--
-- PARAMETERS :
--    entity_name   (IN)     - participant/coordinator name
--
-- RETURNS :
--    out_topic     (OUT)    - OUTBOUND queue for the participant/coordinator.
--
--  DESCRIPTION:
--    This function returns the outbound queue for a
--    given participant / coordinator.
--
-------------------------------------------------------------------------------

function get_out_topic(entity_name IN varchar2) return varchar2 as

  out_queue         M_IDEN%TYPE;
  entity_schema     M_IDEN%TYPE;
  entity_name_int   M_IDEN%TYPE;
  out_queue_q       M_IDEN_Q%TYPE;
  entity_schema_q   M_IDEN_Q%TYPE;

BEGIN

  /* Canonicalize entity_name */
  dbms_utility.canonicalize(entity_name, entity_name_int, MAX_ENTITY_NAME);
  /* collect information about the out queue , schema of the
     participant/coordinator. */
  select outgoing_topic,owner into out_queue, entity_schema
  from saga_participant$ where name = entity_name_int;

  /* Enquote OUT queue and schema */
  out_queue_q := dbms_assert.enquote_name(out_queue, FALSE);
  entity_schema_q := dbms_assert.enquote_name(entity_schema, FALSE);

  return entity_schema_q || '.' || out_queue_q;

EXCEPTION
  --invalid entity name
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Cannot fetch out queue. Please check
    the entity name');
  WHEN OTHERS THEN
    RAISE;
END;


/* Helper procedure to process the notification from dbms_saga package. We
 * cannot place the complete callback inside dbms_saga_sys because we don't
 * know the call stack after notification call hence the execution will
 * fail due to accessible by clause
 */
procedure process_notification(recipient IN varchar2,
                               sender IN varchar2,
                               saga_id IN saga_id_t,
                               opcode IN number,
                               coordinator IN varchar2,
                               req_res IN clob) AS

  cbk_schema              M_IDEN%TYPE;
  cbk_package             M_IDEN%TYPE;
  saga_initiator          M_IDEN%TYPE;
  req_res_json            JSON;
  join_status             NUMBER;
  BAD_OPCODE              EXCEPTION;

BEGIN

  BEGIN
    select callback_schema, callback_package into cbk_schema,
           cbk_package from saga_participant$
    where name = recipient;

    /* Sanity Check : if the user deleted the package after creating
                      the participant no data will be found. In that case
                      we dont call anything */
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      cbk_schema := NULL;
      cbk_package := NULL;
  END;

  /* If there is a payload attached we need to convert it back to JSON */
  IF req_res IS NOT NULL THEN
    req_res_json := json(req_res);
  END IF;

  CASE
    /* When opcode is REQUEST we initiate join_saga and call the
       request() callback defined by user. */
    WHEN (opcode = dbms_saga_sys.REQUEST) THEN
      --Todo : check if the saga status is joining or joined?
      join_status := join_saga_int(saga_id, recipient,
                                   sender, coordinator, req_res);

       /* If the saga is already joined but is neither commited nor
          rolledback. We call the request() again */
       IF join_status = dbms_saga_sys.JOIN_EXISTS THEN
         call_callbacks(cbk_package, cbk_schema, 'REQUEST', saga_id,
                        recipient, sender, coordinator, req_res_json);
       END IF;

    /* When opcode is ACK_SAGA we update saga$ since we just got an ACK
       from the coordinator. Also proceed to call user defined request
     */
    WHEN (opcode = dbms_saga_sys.ACK_SAGA) THEN
      /* Update saga$ */
      update saga$ set status = dbms_saga_sys.JOINED where id = saga_id
      and participant = recipient;
      /* Get information about the initiator */
      select initiator into saga_initiator from saga$
      where id = saga_id and participant = recipient;
      /* Call the user defined REQUEST() */
      call_callbacks(cbk_package, cbk_schema, 'REQUEST', saga_id, recipient,
                     saga_initiator, sender, req_res_json);

    /* When opcode is COMMIT we call before_commit() callback
       defined by user , saga infrastructure commit and after_commit()
       callback respectively. */
    WHEN (opcode = dbms_saga_sys.CMT_SAGA) THEN
      commit_or_rollback_int(recipient, dbms_saga_sys.PARTICIPANT, saga_id,
        dbms_saga_sys.CMT_SAGA, TRUE, null, sender, sender, cbk_package,
        cbk_schema);

    /* When opcode is ABORT we call before_rollback() callback
       defined by user , saga infrastructure rollback and after_rollback()
       callback respectively. */
    WHEN (opcode = dbms_saga_sys.ABRT_SAGA) THEN
      commit_or_rollback_int(recipient, dbms_saga_sys.PARTICIPANT, saga_id,
        dbms_saga_sys.ABRT_SAGA, TRUE, null, sender, sender, cbk_package,
        cbk_schema);

    /* When the opcode is RESPONSE we call the response() callback defined
       by the user */
    WHEN (opcode = dbms_saga_sys.RESPONSE) THEN
      call_callbacks(cbk_package, cbk_schema, 'RESPONSE', saga_id,
                     null, sender, null, req_res_json);

    ELSE
      /* We have a bad opcode, throw exception */
      RAISE BAD_OPCODE;
  END CASE;

COMMIT;
EXCEPTION
  WHEN BAD_OPCODE THEN
    RAISE_APPLICATION_ERROR(-20001 , 'bad opcode');
  WHEN OTHERS THEN
    RAISE;
END;


/* Internal procedure called by commit_saga() and rollback_saga() */
procedure commit_or_rollback(saga_participant IN VARCHAR2,
                             deq_saga_id IN saga_id_t,
                             saga_opcode IN NUMBER,
                             force IN boolean DEFAULT TRUE,
                             current_user IN VARCHAR2) AS

  saga_level_entity    NUMBER;
  coordinator_name     M_IDEN%TYPE;
  saga_owner           M_IDEN%TYPE;
  participant_int      M_IDEN%TYPE;
  saga_status          NUMBER;
  return_opcode        NUMBER;
  type enqueue_record is record(
    participant_name M_IDEN%TYPE,
    status           NUMBER
  );
  type enqueue_record_list is table of enqueue_record;
  er enqueue_record_list;
  collection_stmt      VARCHAR2(500);
  INVALIDSAGAID        EXCEPTION;
  UNAUTHACCESS         EXCEPTION;

BEGIN
  /* Canonicalize participant name */
  dbms_utility.canonicalize(saga_participant, participant_int,
                            MAX_ENTITY_NAME);

  /* check for the saga level , if coordinator enqueue COMMIT/ROLLBACK to
     other participants , if participant just update the table. */
  BEGIN
    select saga_level, coordinator, status, owner into saga_level_entity,
    coordinator_name, saga_status, saga_owner
    from saga$ where id = deq_saga_id and participant = participant_int;
  EXCEPTION
    /* Saga ID */
    WHEN NO_DATA_FOUND THEN
      RAISE INVALIDSAGAID;
  END;

 /* Check the participant does not belong to current schema */
  IF saga_owner <> current_user THEN
   RAISE UNAUTHACCESS;
  END IF;

  /* If this is the initiator */
  IF saga_level_entity = dbms_saga_sys.INITIATOR THEN
    collection_stmt := 'select participant,status from
                        saga_participant_set$ where
                        saga_id= :1';
    execute immediate collection_stmt bulk collect into er using deq_saga_id;
    IF er.count > 0 THEN
      FOR i in er.first .. er.last LOOP
        update saga_participant_set$
        set status = dbms_saga_sys.FINALIZATION
        where participant = er(i).participant_name
        and saga_id = deq_saga_id;

        enqueue_opcode(deq_saga_id, coordinator_name, er(i).participant_name,
                       saga_opcode);
      END LOOP;
    END IF;
  END IF;

  /* Call commit_or_rollback_saga_int() */
  commit_or_rollback_int(participant_int, saga_level_entity, deq_saga_id,
                 saga_opcode, force, saga_status, participant_int,
                 coordinator_name, null, null);

EXCEPTION
  WHEN INVALIDSAGAID THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Saga ID not found');
  WHEN UNAUTHACCESS THEN
    RAISE_APPLICATION_ERROR(-20001, 'Unauthorized Access: owner of the
    initiator does not match the current user');
  WHEN OTHERS THEN
    RAISE;
END;


/* Commit Or Rollback Saga Internal Procedure */
procedure commit_or_rollback_int(participant_name IN VARCHAR2,
                                 participant_level IN NUMBER,
                                 saga_id IN saga_id_t,
                                 saga_opcode IN NUMBER,
                                 force IN BOOLEAN,
                                 saga_status IN NUMBER,
                                 saga_sender IN VARCHAR2,
                                 coordinator IN VARCHAR2,
                                 cbk_package IN VARCHAR2,
                                 cbk_schema IN VARCHAR2) AS

  saga_status_int      NUMBER;
  cbk_package_int      M_IDEN%TYPE;
  cbk_schema_int       M_IDEN%TYPE;
  cr_result            BOOLEAN := TRUE;
  return_opcode        NUMBER;
  INVALIDSAGAID        EXCEPTION;

BEGIN
  /* Get saga status if it is NULL */
  BEGIN
    IF saga_status IS NULL THEN
      select status into saga_status_int from saga$ where id = saga_id and
      participant = participant_name;
    ELSE
      saga_status_int := saga_status;
    END IF;
  EXCEPTION
    /* Saga ID */
    WHEN NO_DATA_FOUND THEN
      RAISE INVALIDSAGAID;
  END;

  /* Get callback package and schema if it is NULL */
  BEGIN
    IF cbk_package IS NULL THEN
     select callback_schema, callback_package into cbk_schema_int,
      cbk_package_int from saga_participant$ where name = participant_name;
    ELSE
      cbk_package_int := cbk_package;
      cbk_schema_int := cbk_schema;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      cbk_schema_int := NULL;
      cbk_package_int := NULL;
  END;

  /* Call commit/rollback only for sagas whose status is JOINED */
  IF saga_status_int = dbms_saga_sys.JOINED THEN
    /* Commit Saga Path */
    IF saga_opcode = dbms_saga_sys.CMT_SAGA THEN
      call_callbacks(cbk_package, cbk_schema, 'BEFORE_COMMIT', saga_id,
                     null, saga_sender, null, null);
      /* Update saga$ */
      /* We will add a check here for the escrow columns integration and wait
         for the result. If status = true then dbms_saga.COMMITED if false then
         status = dbms_saga.COMMIT_FAILED;
       */
      IF cr_result = TRUE THEN
        return_opcode := dbms_saga_sys.CMT_SAGA;
        saga_status_int := dbms_saga_sys.COMMITED;
      ELSE
        return_opcode := dbms_saga_sys.CMT_FAIL;
        saga_status_int := dbms_saga_sys.COMMIT_FAILED;
      END IF;
      call_callbacks(cbk_package, cbk_schema, 'AFTER_COMMIT', saga_id,
                     null, saga_sender, null, null);
    /* Rollback Saga Path */
    ELSIF saga_opcode = dbms_saga_sys.ABRT_SAGA THEN
      call_callbacks(cbk_package, cbk_schema, 'BEFORE_ROLLBACK', saga_id,
                     null, saga_sender, null, null);
      /* Update saga$ */
      IF cr_result = TRUE THEN
        return_opcode := dbms_saga_sys.ABRT_SAGA;
        saga_status_int := dbms_saga_sys.ROLLEDBACK;
      ELSE
        return_opcode := dbms_saga_sys.ABRT_FAIL;
        saga_status_int := dbms_saga_sys.ROLLEDBACK_FAILED;
      END IF;
      call_callbacks(cbk_package, cbk_schema, 'AFTER_ROLLBACK', saga_id,
                     null, saga_sender, null, null);
    END IF;

    /* Update saga$ */
    update saga$ set status = saga_status_int, end_time = CURRENT_TIMESTAMP
    where id = saga_id and participant = participant_name;
  END IF;

  /* If this is not the saga initiator return a response back to the
     coordinator according to the return_opcode */
  IF participant_level = dbms_saga_sys.PARTICIPANT THEN
    enqueue_opcode(saga_id, participant_name, coordinator,
                          return_opcode);
  END IF;

COMMIT;
EXCEPTION
  WHEN INVALIDSAGAID THEN
    RAISE_APPLICATION_ERROR(-20001 , 'Saga ID not found');
END;


-------------------------------------------------------------------------------
--
--  NAME :
--    join_saga_int
--
--  PARAMETERS :
--      saga_id                 (IN)         - saga id
--      initiator               (IN)         - join saga initiator
--      saga_initiator          (IN)         - saga initiator
--      coordinator             (IN)         - saga coordinator
--      payload                 (IN)         - request payload

--
--  DESCRIPTION:
--    This is an internal function. It completes the join saga for a
--    participant. It sends the request payload to the coordinator
--    and waits for the coordinator to send back an ACK message along
--    with the payload.
--
--  RETURNS:
--      saga_status - NUMBER
--
-------------------------------------------------------------------------------
function join_saga_int(saga_id IN saga_id_t,
                        initiator_name IN VARCHAR2,
                        saga_initiator IN VARCHAR2,
                        coordinator IN VARCHAR2,
                        payload IN CLOB) return NUMBER as

  dequeue_options       dbms_aq.dequeue_options_t;
  message_properties    dbms_aq.message_properties_t;
  message_handle        RAW(16);
  message               SYS.AQ$_JMS_TEXT_MESSAGE;
  initiator_schema      M_IDEN%TYPE;
  initiator_schema_q    M_IDEN_Q%TYPE;
  saga_status           NUMBER;

  /* autonomous transaction which enqueues a JOIN_SAGA opcode for
     the coordinator. */
  procedure enqueue_coordinator(saga_id IN saga_id_t,
                                initiator_schema IN VARCHAR2,
                                initiator_name IN VARCHAR2,
                                coordinator_name IN VARCHAR2,
                                saga_initiator IN VARCHAR2,
                                payload IN CLOB) is
    enqueue_options         dbms_aq.enqueue_options_t;
    message_properties_enq  dbms_aq.message_properties_t;
    message_handle_enq      RAW(16);
    message_enq             SYS.AQ$_JMS_TEXT_MESSAGE;
    subscriber_ack          SYS.aq$_agent;
    q_out                   M_IDEN%TYPE;
    q_out_q                 M_IDEN_Q%TYPE;
    q_out_schema            M_IDEN_SCM%TYPE;
    q_in                    M_IDEN%TYPE;
    pragma autonomous_transaction;

  BEGIN
    write_trace('JOIN_SAGA_INT : enqueue a join message
                 to the coordinator. Saga ID : ' || saga_id);
    q_out := 'SAGA$_' || initiator_name || '_OUT_Q';
    q_out_q := dbms_assert.enquote_name(q_out, FALSE);
    /* Enquote schema */
    initiator_schema_q := dbms_assert.enquote_name(initiator_schema, FALSE);
    q_out_schema := initiator_schema_q || '.' || q_out_q;

    message_enq :=  SYS.AQ$_JMS_TEXT_MESSAGE.construct;
    dbms_saga.set_saga_sender(message_enq, initiator_name);
    dbms_saga.set_saga_recipient(message_enq, coordinator_name);
    dbms_saga.set_saga_opcode(message_enq, dbms_saga_sys.JOIN_SAGA);
    dbms_saga.set_saga_id(message_enq, saga_id);
    message_enq.set_text(payload);
    DBMS_AQ.ENQUEUE(queue_name => q_out_schema,
                    enqueue_options    => enqueue_options,
                    message_properties => message_properties_enq,
                    payload  => message_enq,
                    msgid   => message_handle_enq);
    /* set the current saga status to : JOINING - will be changed when
       we successfully recieve ACK message from coordinator.
     */
    insert into saga$ values(saga_id, dbms_saga_sys.PARTICIPANT,
                                 saga_initiator, coordinator_name,
                                 initiator_schema,
                                 initiator_name, 86400, CURRENT_TIMESTAMP,
                                 NULL, dbms_saga_sys.JOINING);
  COMMIT;
  END;

BEGIN

  write_trace('JOIN_SAGA_INT : begin join_saga_int');

  /* Check the saga status for this saga id before sending a message
     to the coordinator */
  BEGIN
    select status into saga_status from saga$ where id = saga_id
    and participant = initiator_name;

    IF saga_status = dbms_saga_sys.JOINED THEN
      return dbms_saga_sys.JOIN_EXISTS;
    ELSE
      return dbms_saga_sys.JOIN_SKIP;
    END IF;

  EXCEPTION
    /* We are seeing this saga_id for this participant for the first
       time so just simply proceed */
    WHEN NO_DATA_FOUND THEN
      null;
  END;

  /* get the owner's schema */
  /* No need to check for NO_DATA because this message won't even have
     reached here if the initiator name was wrong */
  select owner into initiator_schema from saga_participant$
  where name = initiator_name;

  /* enqueue back the message to the coordinator */
  /* Bug 33304871: No need to create ACK subscriber and then dequeue the
                   the saga ACK. We will fire and forget to the
                   coordinator along with the payload and then wait for
                   the payload as a part of the ACK.
   */
  enqueue_coordinator(saga_id, initiator_schema, initiator_name,
                      coordinator, saga_initiator, payload);
  --insert into test values(saga_id);
  --insert into test values(initiator_name);
  --insert into test values(coordinator);

  write_trace('JOIN_SAGA_INT : end join_saga_int');

  /* join_saga completed successfully */
  return dbms_saga_sys.JOIN_SUCCESS;

END;


/* helper procedure to enqueue a response opcode either from coordinator
   to participants vice-versa.
 */
procedure enqueue_opcode(saga_id IN saga_id_t,
                         sender IN VARCHAR2,
                         recipient IN VARCHAR2,
                         opcode IN NUMBER) AS

  enqueue_options         dbms_aq.enqueue_options_t;
  message_properties      dbms_aq.message_properties_t;
  message_handle          RAW(16);
  message                 SYS.AQ$_JMS_TEXT_MESSAGE;
  q_out                   M_IDEN%TYPE;
  q_out_q                 M_IDEN_Q%TYPE;
  q_out_schema            M_IDEN_SCM%TYPE;
  s_schema                M_IDEN%TYPE;
  s_schema_q              M_IDEN_Q%TYPE;

BEGIN

  /* Get the senders schema */
  select owner into s_schema from saga_participant$
  where name = sender;

  /* Enquote schema */
  s_schema_q := dbms_assert.enquote_name(s_schema, FALSE);

  /* Construct OUT queue */
  q_out := 'SAGA$_' || sender || '_OUT_Q';
  q_out_q := dbms_assert.enquote_name(q_out, FALSE);
  q_out_schema := s_schema_q || '.' || q_out_q;

  /* Construct CONTROL message */
  message :=  SYS.AQ$_JMS_TEXT_MESSAGE.construct;
  dbms_saga.set_saga_sender(message, sender);
  dbms_saga.set_saga_recipient(message, recipient);
  dbms_saga.set_saga_opcode(message, opcode);
  dbms_saga.set_saga_id(message, saga_id);

  DBMS_AQ.ENQUEUE(queue_name         => q_out_schema,
                  enqueue_options    => enqueue_options,
                  message_properties => message_properties,
                  payload            => message,
                  msgid              => message_handle);
COMMIT;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    call_callbacks
--
-- PARAMETERS :
--      package_name        (IN)         - user defined callback package name
--      package_schema      (IN)         - callback package schema
--      proc_name           (IN)         - callback procedure name
--      saga_id             (IN)         - Saga Id for this Saga
--      initiator           (IN)         - Current Participant
--      saga_initiator      (IN)         - Saga Initiator
--      coordinator         (IN)         - Saga Coordinator for this Saga
--      payload             (IN)         - payload for the procedure
--
-- DESCRIPTION:
--    This is an internal procedure. This procedure calls the respective
--    callback function declared by the user in a callback package based
--    upon the opcode of the message.
-------------------------------------------------------------------------------
procedure call_callbacks(package_name    IN VARCHAR2,
                         package_schema  IN VARCHAR2,
                         proc_name       IN VARCHAR2,
                         saga_id         IN saga_id_t,
                         initiator       IN VARCHAR2,
                         saga_initiator  IN VARCHAR2,
                         coordinator     IN VARCHAR2,
                         payload         IN JSON DEFAULT NULL) as

  v_sql                 VARCHAR2(700);
  pkg_owner_q           M_IDEN_Q%TYPE;
  pkg_name_q            M_IDEN_Q%TYPE;
  proc_name_q           M_IDEN_Q%TYPE;
  package_def           VARCHAR2(650);
  procedure_exists      NUMBER;
  response              JSON;

  /* enqueue response back to the saga initiator. */
  procedure enqueue_response(saga_id IN saga_id_t , receiver IN VARCHAR2 ,
                             sender IN VARCHAR2,
                             coordinator_name in VARCHAR2) is
    enqueue_options     dbms_aq.enqueue_options_t;
    message_properties  dbms_aq.message_properties_t;
    message_handle      RAW(16);
    message             SYS.AQ$_JMS_TEXT_MESSAGE;
    q_out               M_IDEN%TYPE;
    q_out_q             M_IDEN_Q%TYPE;
    q_out_schema        M_IDEN_SCM%TYPE;
    sender_schema       M_IDEN%TYPE;

  BEGIN
    BEGIN
      /* Get the senders schema */
      select owner into sender_schema from saga_participant$
      where name = sender;
    EXCEPTION
      /* This is a very rare case but still adding a check for the corner
         case. This should always return a value when the participant is
         not deleted. However, there might be a case where the participant
         has been deleted and the broker doesn't know about it yet, and
         sends a message to this participant. and the participant queue
         is in the process of deletion */
      WHEN NO_DATA_FOUND THEN
        RETURN;
    END;
    /* Construct OUT Queue */
    q_out := 'SAGA$_' || sender || '_OUT_Q';
    q_out_q := dbms_assert.enquote_name(q_out, FALSE);
    q_out_schema := sender_schema || '.' || q_out_q;
    /* Construct response message */
    message :=  SYS.AQ$_JMS_TEXT_MESSAGE.construct;
    dbms_saga.set_saga_sender(message, sender);
    dbms_saga.set_saga_recipient(message, receiver);
    dbms_saga.set_saga_opcode(message, dbms_saga_sys.RESPONSE);
    dbms_saga.set_saga_id(message, saga_id);
    message.set_text(to_clob(json_serialize(response)));

    DBMS_AQ.ENQUEUE(queue_name => q_out_schema,
                    enqueue_options    => enqueue_options,
                    message_properties => message_properties,
                    payload  => message,
                    msgid   => message_handle);
    COMMIT;
    END;

BEGIN

  BEGIN
    /* Check if the user has declared this procedure */
    select count(*) into procedure_exists from all_procedures
    where object_name = package_name
    and owner = package_schema
    and procedure_name = proc_name;

    /* This procedure is not declared or the package is deleted. Return */
    IF procedure_exists = 0 THEN
      RETURN;
    END IF;
  END;

  /* Enquoute all identifiers */
  pkg_owner_q := dbms_assert.enquote_name(package_schema, FALSE);
  pkg_name_q := dbms_assert.enquote_name(package_name, FALSE);
  proc_name_q := dbms_assert.enquote_name(proc_name, FALSE);

  -- construct the request function definition.
  package_def := pkg_owner_q || '.' || pkg_name_q
                             || '.' || proc_name_q;

  /* If coordinator is not null it means we are processing a request message,
     we need to collect the response and send it back to the initiator. */
  IF coordinator IS NOT NULL THEN
    v_sql := 'BEGIN :r := ' ||
              package_def ||
              '(:1,:2,:3); END;';
    execute immediate v_sql using out response, in saga_id,
                                            in saga_initiator, in payload;
    --send the response back to the saga_initiator now.
    enqueue_response(saga_id, saga_initiator, initiator, coordinator);
  /* All other messages except the request messagw */
  ELSE
    v_sql := 'BEGIN ' ||
             package_def ||
             '(:1,:2,:3); END;';
    execute immediate v_sql using saga_id, saga_initiator, payload;
  END IF;

COMMIT;
END;


-------------------------------------------------------------------------------
--
-- NAME :
--    write_trace
--
--  DESCRIPTION:
--    Write a message to the trace file for a given event and event level
--
-------------------------------------------------------------------------------

procedure write_trace(
      message      IN varchar2,
      event        IN binary_integer DEFAULT 10855,
      event_level  IN binary_integer DEFAULT 1,
      time_info    IN boolean DEFAULT FALSE) AS

  event_value BINARY_INTEGER := 0;

BEGIN
--  dbms_system.read_ev(event, event_value);
  IF bitand(event_value, event_level) = event_level THEN
    dump_trace(message, time_info);
  END IF;
END write_trace;


-------------------------------------------------------------------------------
--
-- NAME :
--    dump_trace
--
-- DESCRIPTION:
--    Called by write_trace after checking if the event and even_level
--    bits are set to write a message to the trace file.
--
-------------------------------------------------------------------------------

procedure dump_trace(
    message      IN varchar2,
    time_info    IN boolean DEFAULT FALSE) AS

  pos        BINARY_INTEGER := 1;
  mesg_len   BINARY_INTEGER := LENGTH(message);

BEGIN
--  IF time_info THEN
--    dbms_system.ksdddt;
--  END IF;

  WHILE pos <= mesg_len LOOP
--    dbms_system.ksdwrt(1, substr(message, pos, 80));
    pos := pos + 80;
  END LOOP;
END dump_trace;


end dbms_saga_sys;
/
show errors;
create or replace package body dbms_saga_connect_int as

-------------------------------------------------------------------------------
----------------------------INTERNAL PROCEDURES--------------------------------
-------------------------------------------------------------------------------

function isTrusted(dblink_to_entity_int IN varchar2,
                   participant_id IN RAW,
                   saga_operation IN NUMBER,
                   saga_secret IN NUMBER) return boolean;

-------------------------------------------------------------------------------
-------------------------------BODY DECLARATION--------------------------------
-------------------------------------------------------------------------------
/* Internal procedure to connect broker to the saga participant.
 * add_participant() is called on the other database which calls this procedure
 * using RPC. This procedure then completes add_participant() by attaching the
 * broker at this pdb with the participant at the other pdb
 */
procedure connectBrokerToInqueue(participant_id IN RAW,
                                 entity_name_int IN varchar2 ,
                                 entity_schema_int IN varchar2 ,
                                 coordinatorOrParticipant IN number,
                                 broker_id IN RAW,
                                 coordinator_id IN RAW,
                                 dblink_to_broker_int IN varchar2,
                                 dblink_to_entity_int IN varchar2,
                                 inbound_queue IN varchar2,
                                 outbound_queue IN varchar2,
                                 callback_schema_int IN varchar2 ,
                                 callback_package_int IN varchar2 ,
                                 participant_iscomplete IN number,
                                 broker_schema_int IN varchar2 ,
                                 broker_name_int IN varchar2,
                                 saga_secret IN number) AS

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_connect_int.ROLLINGUNSUPPORTED;
  END IF;

  IF isTrusted(dblink_to_entity_int, participant_id,
               dbms_saga_adm_sys.CONNECT_BROKER, saga_secret) THEN
    dbms_saga_adm_sys.connectBrokerToInqueue(
                        participant_id => participant_id,
                        entity_name_int => entity_name_int,
                        entity_schema_int => entity_schema_int,
                        coordinatorOrParticipant => coordinatorOrParticipant,
                        broker_id => broker_id,
                        coordinator_id => coordinator_id,
                        dblink_to_broker_int => dblink_to_broker_int,
                        dblink_to_entity_int => dblink_to_entity_int,
                        inbound_queue => inbound_queue,
                        outbound_queue => outbound_queue,
                        callback_schema_int => callback_schema_int,
                        callback_package_int => callback_package_int,
                        participant_iscomplete => participant_iscomplete,
                        broker_schema_int => broker_schema_int,
                        broker_name_int => broker_name_int,
                        saga_secret => saga_secret);
  ELSE
    RAISE NO_DATA_FOUND;
  END IF;
END;


/* Internal procedure to disconnect broker from the saga participant.
 * drop_participant() is called on the other database which calls this procedure
 * using RPC. This procedure then completes drop_participant() by dropping
 * the connections made by add_participant() with the participant being
 * dropped at the other pdb.
 */
procedure disconnectBrokerFromInqueue(entity_name_int IN varchar2 ,
                                      entity_schema_int IN varchar2,
                                      dblink_to_entity_int IN varchar2,
                                      broker_schema_int IN varchar2,
                                      broker_name_int IN varchar2,
                                      dblink_to_broker IN varchar2,
                                      entity_id IN RAW,
                                      saga_secret IN number) AS

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_connect_int.ROLLINGUNSUPPORTED;
  END IF;

  IF isTrusted(dblink_to_entity_int, entity_id,
               dbms_saga_adm_sys.DISCONNECT_BROKER, saga_secret) THEN
    dbms_saga_adm_sys.disconnectBrokerFromInqueue(
                                entity_name_int => entity_name_int,
                                entity_schema_int => entity_schema_int,
                                dblink_to_entity_int => dblink_to_entity_int,
                                broker_schema_int => broker_schema_int,
                                broker_name_int => broker_name_int,
                                dblink_to_broker => dblink_to_broker,
                                entity_id => entity_id,
                                saga_secret => saga_secret);
  ELSE
    RAISE NO_DATA_FOUND;
  END IF;

END;


/* Internal function that returns if the broker at this pdb is currently
 * handling a participant with the same name that is being created at the
 * remote database.
 */
function uniqueEntityAtPDB(entity_name IN varchar2,
                           broker_name IN varchar2,
                           mailbox_schema IN varchar2,
                           broker_pdb_link IN varchar2,
                           entity_dblink IN varchar2) return boolean AS
BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_connect_int.ROLLINGUNSUPPORTED;
  END IF;

  RETURN dbms_saga_adm_sys.uniqueEntityAtPDB(
                                          entity_name => entity_name,
                                          broker_name => broker_name,
                                          mailbox_schema => mailbox_schema,
                                          broker_pdb_link => broker_pdb_link,
                                          entity_dblink => entity_dblink);
END;


/* Internal procedure to get information about the broker such as the broker
 * id, broker name or broker schema.
 */
procedure getBrokerInfo(broker_id IN OUT RAW,
                        broker_name IN OUT varchar2,
                        broker_schema IN OUT varchar2,
                        isCreate IN BOOLEAN) AS
BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_connect_int.ROLLINGUNSUPPORTED;
  END IF;

  dbms_saga_adm_sys.getBrokerInfo(broker_id => broker_id,
                                      broker_name => broker_name,
                                      broker_schema => broker_schema,
                                      isCreate => isCreate);
END;


/* Internal procedure to update the callback information for a participant
 * on this database, if the remote participant updates their callback.
 */
procedure updateCallbackInfo(cbk_schema IN varchar2,
                             cbk_package IN varchar2,
                             p_status IN number,
                             p_id IN RAW,
                             saga_secret IN number) AS
BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_connect_int.ROLLINGUNSUPPORTED;
  END IF;

  dbms_saga_adm_sys.updateCallbackInfo(cbk_schema => cbk_schema,
                                           cbk_package => cbk_package,
                                           p_status => p_status,
                                           p_id => p_id,
                                           saga_secret => saga_secret);
END;


/* Internal procedure to validate the saga secret passed during a RPC
 * call.
 */
function validateSecret(entity_id IN RAW,
                        saga_operation IN NUMBER,
                        saga_secret IN NUMBER) return boolean AS

BEGIN

  /* Throw exception if in rolling upgrade */
  IF upper(sys_context('userenv','IS_DG_ROLLING_UPGRADE'))  = 'TRUE' THEN
    RAISE dbms_saga_connect_int.ROLLINGUNSUPPORTED;
  END IF;

  RETURN dbms_saga_adm_sys.validateSecret(
                                    entity_id => entity_id,
                                    saga_operation => saga_operation,
                                    saga_secret => saga_secret);
END;


/* Internal function to check if the call is trusted or not */
function isTrusted(dblink_to_entity_int IN varchar2,
                   participant_id IN RAW,
                   saga_operation IN NUMBER,
                   saga_secret IN NUMBER) return boolean AS

  validation_success    BOOLEAN;
  validation_string     VARCHAR2(500);
  v_sql                 VARCHAR2(1500);
  dblink_entity_q       VARCHAR2(130);

BEGIN
  /* First check if this call is trusted or not */
  IF dblink_to_entity_int IS NOT NULL THEN
    dblink_entity_q := dbms_assert.enquote_name(dblink_to_entity_int, FALSE);
    validation_string := ':r := dbms_saga_connect_int'
                      || '.' || 'validateSecret' || '@' || dblink_entity_q;
  ELSE
    validation_string := ':r := dbms_saga_connect_int'
                      || '.' || 'validateSecret';
  END IF;

  v_sql := 'BEGIN' ||
           validation_string ||
           '(:1, :2, :3); END;';

  execute immediate v_sql using OUT validation_success, IN participant_id,
              IN saga_operation, IN saga_secret;

  RETURN validation_success;
END;

end dbms_saga_connect_int;
/
show errors;
