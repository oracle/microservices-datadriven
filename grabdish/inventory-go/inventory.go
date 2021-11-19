package main

import (
	"context"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/godror/godror"
	"github.com/oracle/oci-go-sdk/v49/common"
	"github.com/oracle/oci-go-sdk/v49/common/auth"
	"github.com/oracle/oci-go-sdk/v49/secrets"
)

func main() {
	tnsAdmin := os.Getenv("TNS_ADMIN")
	user := os.Getenv("user")
	inventoryPDBName := os.Getenv("INVENTORY_PDB_NAME")
	//uncomment to enable vault retrieval...
	// dbpassword := getSecretFromVault()
	// if dbpassword == "" { dbpassword = os.Getenv("dbpassword") }
	dbpassword := os.Getenv("dbpassword")
	fmt.Println("os.Getenv(TNS_ADMIN): %s", tnsAdmin)
	connectionString := user + "/" + dbpassword + "@" + inventoryPDBName
	//+ " walletLocation=" + tnsAdmin
	// fmt.Println("About to get connection... connectionString: %s", connectionString)
	db, err := sql.Open("godror", connectionString)
	// fmt.Printf("db: %s\n", db)
	// var P godror.ConnectionParams
	// P.Username, P.Password = user, dbpassword
	// P.ConnectString = inventoryPDBName
	// // P.SessionTimeout = 42 * time.Second
	// P.SetSessionParamOnInit("NLS_NUMERIC_CHARACTERS", ",.")
	// P.SetSessionParamOnInit("WALLET_LOCATION", tnsAdmin)
	// fmt.Println(P.StringWithPassword())
	// db, err := sql.OpenDB(godror.NewConnector(P))
	if err != nil {
		fmt.Println(err)
		return
	}
	defer db.Close()
	rows, err := db.Query("select sysdate from dual")
	if err != nil {
		fmt.Println("Error running query")
		fmt.Println(err)
		return
	}
	defer rows.Close()
	var thedate string
	for rows.Next() {
		rows.Scan(&thedate)
	}
	fmt.Printf("Listening for messages... start time: %s\n", thedate)
	ctx := context.Background()
	listenForMessages(ctx, db)
}

func listenForMessages(ctx context.Context, db *sql.DB) {
	for {
		tx, err := db.BeginTx(ctx, nil)
		if err != nil {
			//         		t.Fatal(err)
			fmt.Printf("Error during db.BeginTx(ctx, nil): %s\n", err)
		}
		defer tx.Rollback()
		fmt.Printf("Listening for messages...tx: %s\n", tx)
		// fmt.Println("__________________________________________")
		//receive order...
		var orderJSON string
		dequeueOrderMessageSproc := `BEGIN dequeueOrderMessage(:1); END;`
		// 		if _, err := db.ExecContext(ctx, dequeueOrderMessageSproc, sql.Out{Dest: &orderJSON}); err != nil {
		if _, err := tx.ExecContext(ctx, dequeueOrderMessageSproc, sql.Out{Dest: &orderJSON}); err != nil {
			log.Printf("Error running %q: %+v", dequeueOrderMessageSproc, err)
			return
		}
		// fmt.Println("orderJSON:" + orderJSON)
		type Order struct {
			Orderid           string
			Itemid            string
			Deliverylocation  string
			Status            string
			Inventorylocation string
			SuggestiveSale    string
		}
		var order Order
		jsonerr := json.Unmarshal([]byte(orderJSON), &order)
		if jsonerr != nil {
			tx.Commit()
			continue
			// fmt.Printf("Order Unmarshal fmt.Sprint(data) err = %s", jsonerr)
		}
		if jsonerr == nil {
			fmt.Printf("order.orderid: %s", order.Orderid)
		}
		// fmt.Println("__________________________________________")
		//check inventory...
		var inventorylocation string
		sqlString := "update INVENTORY set INVENTORYCOUNT = INVENTORYCOUNT - 1 where INVENTORYID = :inventoryid and INVENTORYCOUNT > 0 returning inventorylocation into :inventorylocation"
		// 		_, errFromInventoryCheck := db.Exec(sqlString, sql.Named("inventoryid", order.Itemid), sql.Named("inventorylocation", sql.Out{Dest: &inventorylocation}))
		_, errFromInventoryCheck := tx.ExecContext(ctx, sqlString, sql.Named("inventoryid", order.Itemid), sql.Named("inventorylocation", sql.Out{Dest: &inventorylocation}))
		if err != nil {
			fmt.Println("errFromInventoryCheck: %s", errFromInventoryCheck)
		}
		// numRows, err := res.RowsAffected()
		// if err != nil {
		// 	fmt.Println(errFromInventoryCheck)
		// }
		// fmt.Println("numRows:" + string(numRows))
		if inventorylocation == "" {
			inventorylocation = "inventorydoesnotexist"
		}
		fmt.Println("inventorylocation:" + inventorylocation)
		// fmt.Println("__________________________________________")
		//create inventory reply message...
		type Inventory struct {
			Orderid           string `json:"orderid"`
			Itemid            string `json:"itemid"`
			Inventorylocation string `json:"inventorylocation"`
			SuggestiveSale    string `json:"suggestiveSale"`
		}
		inventory := &Inventory{
			Orderid:           order.Orderid,
			Itemid:            order.Itemid,
			Inventorylocation: inventorylocation,
			SuggestiveSale:    "beer",
		}
		inventoryJsonData, err := json.Marshal(inventory)
		if err != nil {
			fmt.Println(err)
		}
		inventoryJsonString := string(inventoryJsonData)
		fmt.Println("inventoryJsonData:" + inventoryJsonString) // :inventoryid
		messageSendSproc := `BEGIN enqueueInventoryMessage(:1); END;`
		// 		if _, err := db.ExecContext(ctx, messageSendSproc, inventoryJsonString); err != nil {
		if _, err := tx.ExecContext(ctx, messageSendSproc, inventoryJsonString); err != nil {
			log.Printf("Error running %q: %+v", messageSendSproc, err)
			return
		}
		fmt.Println("inventory status message sent:" + inventoryJsonString)
		commiterr := tx.Commit()
		if commiterr != nil {
			fmt.Println("commiterr:", commiterr)
		}
		fmt.Println("commit complete for message sent:" + inventoryJsonString)
	}
}

func listenForMessagesAQAPI(ctx context.Context, db *sql.DB) {
	for {
		tx, err := db.BeginTx(ctx, nil)
		if err != nil {
			fmt.Println(err)
		}
		defer tx.Rollback()
		orderqueue, err := godror.NewQueue(ctx, tx, "orderqueue", "SYS.AQ$_JMS_TEXT_MESSAGE",
			godror.WithDeqOptions(godror.DeqOptions{
				Mode:       godror.DeqRemove,
				Visibility: godror.VisibleOnCommit,
				Navigation: godror.NavNext,
				Wait:       10000,
				// Consumer:   "inventoryuser", for topic/multiconsumer
			}))
		if err != nil {
			fmt.Println(err)
		}
		defer orderqueue.Close()
		msgs := make([]godror.Message, 1)
		n, err := orderqueue.Dequeue(msgs)
		if err != nil {
			fmt.Printf("dequeue:", err)
		}
		textVC, _ := msgs[0].Object.Get("TEXT_VC")
		fmt.Printf("TEXT_VC from msg %s %q \n", n, textVC) // "{\"orderid\":\"63\",\"itemid\":\"sushi\",\"deliverylocation\":\"780 PANORAMA DR,San Francisco,CA\",\"status\":\"pending\",\"inventoryLocation\":\"\",\"suggestiveSale\":\"\"}"
		type Order struct {
			Orderid           string
			Itemid            string
			Deliverylocation  string
			Status            string
			Inventorylocation string
			SuggestiveSale    string
			// Id      int64  `json:"ref"`
		}
		var order Order
		//todo convert textVC properly to replace this literal...
		jsonerr2 := json.Unmarshal([]byte("{\"orderid\":\"72\",\"itemid\":\"sushi\",\"deliverylocation\":\"780 PANORAMA DR,San Francisco,CA\",\"status\":\"pending\",\"inventoryLocation\":\"\",\"suggestiveSale\":\"\"}"), &order)
		if jsonerr2 != nil {
			fmt.Printf("Order Unmarshal fmt.Sprint(data) err = %s", jsonerr2) // err = invalid character '3' after array elementorder.orderid: %!(EXTRA string=)
		}
		fmt.Printf("order.orderid: %s", order.Orderid)
		fmt.Println("__________________________________________")
		//check inventory...
		var inventorylocation string
		sqlString := "update INVENTORY set INVENTORYCOUNT = INVENTORYCOUNT - 1 where INVENTORYID = :inventoryid and INVENTORYCOUNT > 0 returning inventorylocation into :inventorylocation"
		res, errFromInventoryCheck := db.Exec(sqlString, sql.Named("inventoryid", order.Orderid), sql.Named("inventorylocation", sql.Out{Dest: &inventorylocation}))
		if err != nil {
			fmt.Println(errFromInventoryCheck)
		}
		numRows, err := res.RowsAffected()
		if err != nil {
			fmt.Println(errFromInventoryCheck)
		}
		fmt.Println("numRows:" + string(numRows))
		if inventorylocation == "" {
			inventorylocation = "inventorydoesnotexist"
		}
		fmt.Println("inventorylocation:" + inventorylocation)
		fmt.Println("__________________________________________")
		//create inventory reply message...
		type Inventory struct {
			Orderid           string
			Itemid            string
			Inventorylocation string
			SuggestiveSale    string
		}
		inventory := &Inventory{
			Orderid:           order.Orderid,
			Itemid:            order.Itemid,
			Inventorylocation: inventorylocation,
			SuggestiveSale:    "beer",
		}
		inventoryJsonData, err := json.Marshal(inventory)
		if err != nil {
			fmt.Println(err)
		}
		fmt.Printf("inventoryJsonData: %s ", inventoryJsonData)
		fmt.Println("__________________________________________")
		fmt.Printf("string(inventoryJsonData): %s ", string(inventoryJsonData))
		inventoryqueue, err := godror.NewQueue(ctx, tx, "orderqueue", "SYS.AQ$_JMS_TEXT_MESSAGE",
			godror.WithEnqOptions(godror.EnqOptions{
				Visibility:   godror.VisibleOnCommit, //Immediate
				DeliveryMode: godror.DeliverPersistent,
			}))
		if err != nil {
			fmt.Println(err)
		}
		defer inventoryqueue.Close()
		fmt.Printf("inventoryqueue is: %s\n", inventoryqueue)
		fmt.Println("__________________________________________")
		obj, err := inventoryqueue.PayloadObjectType.NewObject()
		sendmsg := godror.Message{Object: obj}
		sendmsg.Expiration = 10000
		fmt.Printf("sendmsg is: %s\n", sendmsg)
		inventoryJsonDatastr := string(inventoryJsonData)
		fmt.Printf("inventoryJsonDatastr is: %s\n", inventoryJsonDatastr)
		fmt.Printf("len(inventoryJsonDatastr) is not set: %s\n", len(inventoryJsonDatastr))
		obj.Set("TEXT_VC", inventoryJsonDatastr)
		// 	obj.Set("TEXT_LEN", len(inventoryJsonDatastr)    )
		// 	obj.Set("TEXT_LEN", []byte{len(inventoryJsonDatastr)}    )
		// 	obj.Set("TEXT_LEN", []byte(string(len(inventoryJsonDatastr))  ) )
		//sendmsg.Expiration = 10000
		fmt.Printf("message to send is: %s\n", sendmsg)
		sendmsgs := make([]godror.Message, 1)
		sendmsgs[0] = sendmsg
		if err = inventoryqueue.Enqueue(sendmsgs); err != nil { //enqOne
			fmt.Printf("\nenqueue error:", err)
		}
		fmt.Printf("\nenqueue complete: %s", sendmsg)
		fmt.Println("about to commit...")
		if err := tx.Commit(); err != nil {
			fmt.Printf("commit:", err)
		}
		fmt.Println("commit done...")
		fmt.Printf("commit complete %d message", sendmsg)
	}

}

func getSecretFromVault() string {
  vault_secret_ocid := os.Getenv("VAULT_SECRET_OCID")
	if vault_secret_ocid == "" {
		return ""
	}
	oci_region := os.Getenv("OCI_REGION") //eg "us-ashburn-1" ie common.RegionIAD
	if oci_region == "" {
		return ""
	}
	instancePrincipalConfigurationProvider, err := auth.InstancePrincipalConfigurationProviderForRegion(common.RegionIAD)
	client, err := secrets.NewSecretsClientWithConfigurationProvider(instancePrincipalConfigurationProvider)
	if err != nil {
		fmt.Printf("failed to create client err = %s", err)
		return ""
	}
	req := secrets.GetSecretBundleRequest{SecretId: common.String(vault_secret_ocid)}
	resp, err := client.GetSecretBundle(context.Background(), req)
	if err != nil {
		fmt.Printf("failed to create resp err = %s", err)
		return ""
	}
	base64SecretBundleContentDetails := resp.SecretBundle.SecretBundleContent.(secrets.Base64SecretBundleContentDetails)
	secretValue, err := base64.StdEncoding.DecodeString(*base64SecretBundleContentDetails.Content)
	if err != nil {
		fmt.Printf("failed to decode err = %s", err)
		return ""
	}
	return string(secretValue)
}
