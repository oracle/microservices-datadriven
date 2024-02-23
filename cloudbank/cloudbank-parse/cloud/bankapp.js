const oracledb = require('oracledb')
isInitialized = false;

Parse.Cloud.beforeSave("BankAccount", async request => {

    const userid = request.object.get("userId");
    const accountType = request.object.get("accountType");
    const action = request.object.get("action");
    const amount = request.object.get("amount");
    const accountNum = request.object.get("accountNum");
    const toAccountNum = request.object.get("toAccountNum")
    const externalAccountNum = request.object.get("externalAccountNum")
    const fromAccountNum = request.object.get("fromAccountNum")
    const balance = await Parse.Cloud.run("balance",{ "accountNum": accountNum });
    const existingUserId = await Parse.Cloud.run("getuserforaccountnum", { "accountNum": accountNum });
    const existingAccountType = await Parse.Cloud.run("getaccounttypeforaccountnum", { "accountNum": accountNum });


    // Verify account number isn't already used for a different user
    // fromAccountNum is valued in AfterSave and indicates a Transfer Deposit so gate the check
    if(typeof fromAccountNum === 'undefined') {
      if (existingUserId.length != 0 && userid !== existingUserId) {
        throw "Account Number error: " + accountNum + " associated with a different user";
      }
    }

    // Verify AccountType matches if already exists for acct number
    if (existingAccountType.length != 0 && accountType !== existingAccountType) {
      throw "Account Number error: " + accountNum + " associated with account type " + existingAccountType;
    }

    // Verify current balance > withdrawal amount
    if (action === "Withdrawal" && amount > balance ) {
        throw "Withdrawal Amount is greater than current balance of " + balance;
    }

    // Verify toAccountNum or externalAccountNum exists when action = Transfer
    if(action === "Transfer" && (typeof toAccountNum === 'undefined' && typeof externalAccountNum === 'undefined' && typeof fromAccountNum === 'undefined'))  {
        throw "Missing toAccountNum(internal), externalAccountNum(External) or fromAccountNum(internal) for Transfer Action";
    }
    if(action === "Transfer" && (typeof toAccountNum !== 'undefined' && typeof externalAccountNum !== 'undefined'))  {
        throw "Both toAccountNum(internal) and externalAccountNum(External) for Transfer is invalid.   Pick one or the other";
    }

    // Verify local transfer account exists
    if(typeof toAccountNum !== 'undefined') {
        const accountExists = await Parse.Cloud.run("accountexists", { "accountNum": toAccountNum });
        if(action === "Transfer" && !accountExists){
            throw ("Transfer toAccountNum does not exist, toAccountNum = %s", toAccountNum);
        }
            
        // Verify current balance > transfer amount
        if (action === "Transfer" && amount > balance ) {
            throw "Transfer Amount is greater than current balance of " + balance;
        }
    }

    // Verify current balance > transfer amount
    // fromAccountNum is valued in AfterSave and indicates a Transfer Deposit so gate the check
    if(typeof fromAccountNum === 'undefined') {
      if (action === "Transfer" && amount > balance) {
          throw "Transfer Amount is greater than current balance of " + balance;
      }
    }
    // Make Withdrawals negative, Balance is just summed
    if (action === "Withdrawal" || action === "Transfer" && typeof fromAccountNum === 'undefined') {
      request.object.set("amount", amount * -1)
    }
    },{
      fields: {
        userId: {
          required:true,
          options: userId => {
            return isAlphaNumeric(userId);
          },
          error: 'userId must be AlphaNumeric'          
        },
        accountNum : {
          required:true,
          options: accountNum => {
            return accountNum > 0;
          },
          error: 'accountNum must be greater than 0'          
        },
        accountType : {
          required:true,
          options: accountType => {
            return accountType === "Savings" || accountType === "Checking";
          },
          error: 'accountType must be either Savings or Checking'
        },        
        action : {
          required:true,
          options: action => {
            return action === "Deposit" || action === "Withdrawal" || action === "Transfer";
          },
          error: 'action must be either a Deposit, Withdrawal or Transfer'
        },
        amount : {
          required:true,
          options: amount => {
            return amount > 0;
          },
          error: 'amount must be greater than 0'
        },
        toAccountNum : {
            required:false,
            options: toAccountNum => {
              return toAccountNum > 0;
            },
            error: 'toAccountNum must be greater than 0'          
        },     
        externalAccountNum : {
            required:false,
            options: externalAccountNum => {
              return externalAccountNum > 0;
            },
            error: 'externalAccountNum must be greater than 0'          
        }            
      }
    });

    function isAlphaNumeric(str) {
      var code, i, len;
    
      for (i = 0, len = str.length; i < len; i++) {
        code = str.charCodeAt(i);
        if (!(code > 47 && code < 58) && // numeric (0-9)
            !(code > 64 && code < 91) && // upper alpha (A-Z)
            !(code > 96 && code < 123)) { // lower alpha (a-z)
          return false;
        }
      }
      return true;
    };    

Parse.Cloud.define('balance', async (request) => {
      const query = new Parse.Query("BankAccount");
      query.equalTo("accountNum", request.params.accountNum);
      const results = await query.find({ useMasterKey: true });
      let sum = 0;
      for (let i = 0; i < results.length; ++i) {
        sum += results[i].get("amount");
      }
      return sum;
    });

Parse.Cloud.define('accountexists', async (request) => {
        const query = new Parse.Query("BankAccount");
        query.equalTo("accountNum", request.params.accountNum);
        const results = await query.find({ useMasterKey: true });
        var count = Object. keys(results).length
        return count > 0;
      });

Parse.Cloud.define('history', async req => {
        req.log.info(req);
        const query = new Parse.Query("BankAccount");
        query.equalTo("accountNum", req.params.accountNum);
        const result = await query.find({ useMasterKey: true });
        return result
      });

Parse.Cloud.define('getaccountsforuser', async req => {
        req.log.info(req);
        const query = new Parse.Query("BankAccount");
        query.equalTo("userId", req.params.userId);

        const results = await query.find({ useMasterKey: true });
        var lookup = {};
        var accounts = [];
        if (results.length > 0) {
          results.forEach(function (result) {
            var name = result.get("accountNum");
            if (!(name in lookup)) {
              lookup[name] = 1;
              accounts.push(name);
            }
          });    
        }
       return accounts;
      });  
      
Parse.Cloud.define('getuserforaccountnum', async req => {

      const query = new Parse.Query("BankAccount");
      query.equalTo("accountNum", req.params.accountNum);
      const results = await query.first({ useMasterKey: true });
      if (typeof results !== 'undefined') {
        return results.get("userId");
      }
      return "";
    });

  Parse.Cloud.define('getaccounttypeforaccountnum', async req => {

      const query = new Parse.Query("BankAccount");
      query.equalTo("accountNum", req.params.accountNum);
      const results = await query.first({ useMasterKey: true });
      if (typeof results !== 'undefined') {
        return results.get("accountType");
      }
      return "";
    });    

Parse.Cloud.afterSave("BankAccount", async (request) => {
    
        const action = request.object.get("action");
        const toAccountNum = request.object.get("toAccountNum");
        const externalAccountNum = request.object.get("externalAccountNum");
        const fromAccountNum = request.object.get("accountNum");

        if (action === "Transfer" && typeof externalAccountNum !== 'undefined') {
            amount =  request.object.get("amount");
            let message_content = "{\"accountNum\":"+externalAccountNum+ ", \"fromAccountNum\":" + fromAccountNum + ", \"action\":\"Transfer\", \"amount\":"+amount*-1+"}";
            result = await publish(message_content);
        }

        if (action === "Transfer" && typeof toAccountNum !== 'undefined') {
            const BankAccount = Parse.Object.extend("BankAccount");
            const bankaccount = new BankAccount();

            const toAccountType = await Parse.Cloud.run("getaccounttypeforaccountnum", { "accountNum": toAccountNum });
            const toUserId = await Parse.Cloud.run("getuserforaccountnum", { "accountNum": toAccountNum });

            bankaccount.set("userId", toUserId);
            bankaccount.set("accountType", toAccountType);
            bankaccount.set("accountNum", toAccountNum);
            bankaccount.set("fromAccountNum", fromAccountNum);
            bankaccount.set("action", "Transfer");
            const amount = request.object.get("amount");
            bankaccount.set("amount", amount*-1);

            let result;
            await bankaccount.save()
            .then((bankaccount) => {
              // Execute any logic that should take place after the object is saved.
              result = 'New object created with objectId: ' + bankaccount.id;
            }, (error) => {
              // Execute any logic that should take place if the save fails.
              // error is a Parse.Error with an error code and message.
              result = 'Failed to process Transfer, with error code: ' + error.message;
            });
            
            return result;
        }
      });

    async function initialize() {
      const tnsnames = "/wallet"
      oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
      if(isInitialized === false) {
          oracledb.initOracleClient({configDir: tnsnames});
          await runSQL(`
          declare
              already_exists number;
              subscriber     sys.aq$_agent;
              subscriber1    sys.aq$_agent;
          begin 
              select count(*)
              into already_exists
              from user_queues
              where upper(name) = 'PUBLISH';
              if already_exists = 0 then                  
                  DBMS_AQADM.CREATE_QUEUE_TABLE ( queue_table    => 'publish_queuetable',     queue_payload_type  => 'RAW', multiple_consumers => TRUE); 
                  DBMS_AQADM.CREATE_QUEUE       ( queue_name     => 'publish',                queue_table         => 'publish_queuetable');
                  DBMS_AQADM.START_QUEUE        (queue_name => 'publish');

                  --- Create the subscriber agent
                  subscriber := sys.aq$_agent('BankA_subscriber', NULL, NULL);
                  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'publish',   subscriber => subscriber);
                  subscriber1 := sys.aq$_agent(NULL, 'admin.reggiebank@reggiebank', NULL);
                  DBMS_AQADM.ADD_SUBSCRIBER(queue_name => 'publish',   subscriber => subscriber1, queue_to_queue => true);
                  DBMS_AQADM.SCHEDULE_PROPAGATION(queue_name => 'publish', destination => 'reggiebank', destination_queue => 'reggiebank');
              end if;
          end;`)
          isInitialized = true;
      }
    }

    async function publish(message_content) {
        await initialize();
        await enquemsg(message_content);
    }

    async function checkTransfersQueue() {
        await initialize();
        const msg = await dequemsg();
        return msg;
    }


    async function runSQL(statement) {
    
        const user = "user";
        const password = "password";
        const connectString = "database";
        console.log(statement);

        let connection;
        try {
            connection = await oracledb.getConnection({
                user: user,
                password: password,
                connectString: connectString
            });
            const result = await connection.execute(statement);
            return result
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

      async function enquemsg(message_content) {  
    
        const user = "user";
        const password = "password";
        const connectString = "database";

          let connection;
          try {
            connection = await oracledb.getConnection({
                user: user,
                password: password,
                connectString: connectString
            });
            const queueName = "publish";
            const queue = await connection.getQueue(queueName);
            queue.enqOptions.consumerName = "BankA_subscriber";
            await queue.enqOne(message_content);
            await connection.commit();
            return connection
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


        async function dequemsg() {  
      
          const user = "user";
          const password = "password";
          const connectString = "database";

            let connection;
            try {
              connection = await oracledb.getConnection({
                  user: user,
                  password: password,
                  connectString: connectString
              });
              const queueName = "publish";
              const queue = await connection.getQueue(queueName);
              queue.deqOptions.consumerName = "BankA_subscriber";
              queue.deqOptions.mode = oracledb.AQ_DEQ_MODE_REMOVE;
              queue.deqOptions.wait = oracledb.AQ_DEQ_NO_WAIT;
              queue.deqOptions.navigation = oracledb.AQ_DEQ_NAV_FIRST_MSG;
              const msg = await queue.deqOne();
              await connection.commit();
              if( typeof msg === 'undefined') {
                    return "";
              }
              return msg.payload.toString();
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
      


          Parse.Cloud.job("checkForTransfers", async (request) =>  {
            // params: passed in the job call
            // headers: from the request that triggered the job
            // log: the ParseServer logger passed in the request
            // message: a function to update the status message of the job object
            const { params, headers, log, message } = request;
    
            result = await checkTransfersQueue();

            const obj = JSON.parse(result);

            const BankAccount = Parse.Object.extend("BankAccount");
            const bankaccount = new BankAccount();

            const userId = await Parse.Cloud.run("getuserforaccountnum", { "accountNum": obj.accountNum });
            if (userId === "") {
              console.log("Account Number " + obj.accountNum + " does not exist");
              return;
            }
            const accountType = await Parse.Cloud.run("getaccounttypeforaccountnum", { "accountNum": obj.accountNum });
    
            bankaccount.set("userId", userId);
            bankaccount.set("accountType", accountType);
            bankaccount.set("accountNum", obj.accountNum);
            bankaccount.set("fromAccountNum", obj.fromAccountNum);
            bankaccount.set("action", obj.action);
            bankaccount.set("amount", obj.amount);
    
            await bankaccount.save()
            .then((bankaccount) => {
              // Execute any logic that should take place after the object is saved.
              console.log('New object created with objectId: ' + bankaccount.id);
            }, (error) => {
              // Execute any logic that should take place if the save fails.
              // error is a Parse.Error with an error code and message.
              console.log('Failed to process Transfer, with error code: ' + error.message);
            });

          });

