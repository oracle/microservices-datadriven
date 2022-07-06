

  initialized = false

  async function runSQL(statement) {
    const oracledb = require('oracledb')

    const user = "admin";
    const password = "password";
    const connectString = "parsemongo_high";
    let connection;
    try {
        connection = await oracledb.getConnection({
            user: user,
            password: password,
            connectString: connectString
        });
        const result = await connection.execute(statement);
        console.log(result.rows);
        return result.rows
    } catch (err) {
        console.log(err);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.log(err);
            }
        }
    }
  }

  async function publish(message_content) {
    const oracledb = require('oracledb')
    const tnsnames = "/wallet"


    oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
    if(initialized === false) {
        oracledb.initOracleClient({configDir: tnsnames});
        
        await runSQL(`
        declare
            already_exists number;
        begin 
            select count(*)
            into already_exists
            from user_queues
            where upper(name) = 'PUBLISH';
            if already_exists = 0 then  
                DBMS_AQADM.CREATE_QUEUE_TABLE (
                queue_table => 'publish_queuetable',
                queue_payload_type  => 'RAW');   
                DBMS_AQADM.CREATE_QUEUE ( 
                queue_name => 'publish',
                queue_table => 'publish_queuetable');  
                DBMS_AQADM.START_QUEUE ( 
                queue_name => 'publish');
            end if;
        end;`)


    initialized = true;
    }

    await runSQL(`
    DECLARE
        enqueue_options     dbms_aq.enqueue_options_t;
        message_properties  dbms_aq.message_properties_t;
        message_handle      RAW(16);
        message             RAW(4096); 
    
    BEGIN
        message :=  utl_raw.cast_to_raw('` + message_content + `'); 
        DBMS_AQ.ENQUEUE(
            queue_name           => 'publish',           
            enqueue_options      => enqueue_options,       
            message_properties   => message_properties,     
            payload              => message,               
            msgid                => message_handle);
        COMMIT;
    END;`)
}

async function runQuery(sql) {
    const oracledb = require('oracledb')
    const tnsnames = "/wallet"

    if(initialized === false) {
        oracledb.initOracleClient({configDir: tnsnames});
        initialized = true;
     }

     return await runSQL(sql)
}


  Parse.Cloud.define('helloDB', async req => {
    req.log.info(req);
    result = await runQuery(`select JSON_Serialize(DATA) from "Review"`)
    return result
  });

  Parse.Cloud.afterSave("Review", async (request) => {
    movie = request.object.get("movie")
    comment =  request.object.get("comment")
    let message_content = movie.concat(":", comment)
    result = await publish(message_content)
  });

