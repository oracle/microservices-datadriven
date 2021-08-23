package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"github.com/godror/godror"
)

func main() {
	tnsAdmin := os.Getenv("TNS_ADMIN")
	user := os.Getenv("user")
	inventoryPDBName := os.Getenv("INVENTORY_PDB_NAME")
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
	listenForMessagesAQAPI(ctx, db)
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
		if _, err := tx.ExecContext(ctx,  dequeueOrderMessageSproc, sql.Out{Dest: &orderJSON}); err != nil {
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

func listenForMessagesAQAPI(ctx context.Context, db *sql.DB) { //todo incomplete - using PL/SQL above

	tx, err := db.BeginTx(ctx, nil)
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// defer tx.Rollback()
	orderqueue, err := godror.NewQueue(ctx, tx, "orderqueue", "SYS.AQ$_JMS_TEXT_MESSAGE",
		godror.WithDeqOptions(godror.DeqOptions{
			Mode:       godror.DeqRemove,
			Visibility: godror.VisibleOnCommit,
			Navigation: godror.NavNext,
			Wait:       10000,
			// Consumer:   "inventoryuser", for topic/multiconsumer
		}))
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// defer q.Close()
	//t.Logf("name=%q q=%#v", q.Name(), q)
	msgs := make([]godror.Message, 1)
	n, err := orderqueue.Dequeue(msgs)
	if err != nil {
		fmt.Printf("dequeue:", err)
	}
	// fmt.Printf("received msgs (should be one only):%s \n", n)
	// var data godror.Data
	// msgs[0].ObjectGetAttribute(&data, "TEXT_VC")
	// msgs[0].Object.Close()
	// objecttype := int(data.GetObjectType)
	// payload := int(data.getPayload)

	textVC, _ := msgs[0].Object.Get("TEXT_VC")
	fmt.Printf("TEXT_VC msg %s %q \n", n, textVC) // "{\"orderid\":\"63\",\"itemid\":\"sushi\",\"deliverylocation\":\"780 PANORAMA DR,San Francisco,CA\",\"status\":\"pending\",\"inventoryLocation\":\"\",\"suggestiveSale\":\"\"}"
// 	fmt.Printf("TEXT_VC fmt.Sprint(textVC) %s %q \n", n, fmt.Sprintf("%b", textVC)) // %!s(int=1) "[1111011 100010 110

	// fmt.Printf("TEXT_VC string msg %s %q \n", n, string(textVC))
	// if err = tx.Commit(); err != nil {
	// 	fmt.Printf("commit:", err)
	// }

	// fmt.Printf("\nstrconv.Itoa(s) %q \n", strconv.Itoa(msgs[0].Object))

	//get order request message
	type Order struct {
		Orderid           string
		Itemid            string
		Deliverylocation  string
		Status            string
		Inventorylocation string
		SuggestiveSale    string
		// Id      int64  `json:"ref"`
	}

	// type Message struct {
	// 	Enqueued                time.Time
	// 	Object                  *Object
	// 	Correlation, ExceptionQ string
	// 	Raw                     []byte
	// 	Delay, Expiration       time.Duration
	// 	DeliveryMode            DeliveryMode
	// 	State                   MessageState
	// 	Priority, NumAttempts   int32
	// 	MsgID, OriginalMsgID    [16]byte
	// }
	// getPayload

	var order Order
	// err := json.Unmarshal(jsonData, &basket)
	// jsonData := []byte(msgs[0])
	// textVCstring := make([]string, len(textVC))
	// for i, v := range textVC {
	// 	textVCstring[i] = fmt.Sprint(v)
	// }
	// jsonerr := json.Unmarshal([]byte(textVC), &order)
	// if jsonerr != nil {
	// 	fmt.Printf("Order Unmarshal err = %s", jsonerr)
	// }
	jsonerr2 := json.Unmarshal([]byte(fmt.Sprint(textVC)), &order)
	if jsonerr2 != nil {
		fmt.Printf("Order Unmarshal fmt.Sprint(data) err = %s", jsonerr2) // err = invalid character '3' after array elementorder.orderid: %!(EXTRA string=)
	}
	fmt.Printf("order.orderid: ", order.Orderid)
	order.Orderid = "sushi"

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
		Orderid:           "66",
		Itemid:            "sushi",
		Inventorylocation: inventorylocation,
		SuggestiveSale:    "beer",
	}

	inventoryJsonData, err := json.Marshal(inventory)
	if err != nil {
		fmt.Println(err)
	}
	fmt.Printf("inventoryJsonData: %s ", inventoryJsonData)
	fmt.Printf("::::::::::::::::::::::::SENDING EMPTY JSON BRACKET::::::::::::::::::::::::::::::::::::: ")
	fmt.Printf("string(inventoryJsonData): %s ", string(inventoryJsonData))

	//send inventory reply message...
	// inventoryq, err := godror.NewQueue(ctx, tx, "inventoryqueue", "SYS.AQ$_JMS_TEXT_MESSAGE",
	// 	godror.WithDeqOptions(godror.DeqOptions{
	// 		Mode:       godror.DeqRemove,
	// 		Visibility: godror.VisibleOnCommit,
	// 		Navigation: godror.NavNext,
	// 		Wait:       10000,
	// 	}))

	inventoryqueue, err := godror.NewQueue(ctx, tx, "inventoryqueue", "SYS.AQ$_JMS_TEXT_MESSAGE",
		godror.WithEnqOptions(godror.EnqOptions{
			Visibility:   godror.VisibleOnCommit, //Immediate
			DeliveryMode: godror.DeliverPersistent,
		}))
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// defer inventoryq.Close()

	fmt.Printf("inventoryqueue is: %s\n", inventoryqueue)
	fmt.Println("__________________________________________")

	// outgoingmsgs := make([]godror.Message, 1)
	// msgs[j], s = newMessage(q, i)
	sendmsgs := make([]godror.Message, 1)
	// for i := 0; i < msgCount; {
	// for j := range msgs {
	// var s string
	// sendmsgs[0], s = newMessage(q, 0)
	// sendmsgs[0], s = newMessage(q, 0)
	// s := fmt.Sprintf("%03d. árvíztűrő tükörfúrógép", 1)

	// sendmsgs[0], s = godror.Message{Raw: []byte(s)}, s
	obj, err := inventoryqueue.PayloadObjectType.NewObject()
	sendmsgs[0] = godror.Message{}
	// sendmsgs[0] = newMessage(inventoryqueue, 1, inventorylocation)
	sendmsgs[0].Expiration = 10000
	// sendmsgs[0].Raw = []byte(inventoryJsonData)

	//from python...
	// payload =orderQueue.deqOne().payload
	// logger.debug(payload.TEXT_VC)
	// orderInfo = simplejson.loads(payload.TEXT_VC)

	// # Update the inventory for this order.  If no row is updated there is no inventory.
	// ilvar = cursor.var(str)
	// cursor.execute(sql, [orderInfo["itemid"], ilvar])

	// # Enqueue the response on the inventory queue
	// payload = conn.gettype("SYS.AQ$_JMS_TEXT_MESSAGE").newobject()
	// payload.TEXT_VC = simplejson.dumps(
	//     {'orderid': orderInfo["orderid"],
	//      'itemid': orderInfo["itemid"],
	//      'inventorylocation': ilvar.getvalue(0)[0] if cursor.rowcount == 1 else "inventorydoesnotexist",
	//      'suggestiveSale': "beer"})
	// payload.TEXT_LEN = len(payload.TEXT_VC)
	// inventoryQueue.enqOne(conn.msgproperties(payload = payload))

	// obj, _ := inventoryqueue.PayloadObjectType.NewObject()
	// godror.Message{Object: obj}

	obj.Set("TEXT_VC", inventoryJsonData)
	sendmsgs[0].Object = obj
	fmt.Printf("sendmsgs[0] is: %s\n", sendmsgs[0])
	// sendmsgs[1] = newMessage(inventoryqueue, 1, inventorylocation)
	// sendmsgs[1].Expiration = 10000
	// sendmsgs[0].Raw = []byte(inventoryJsonData)
	// fmt.Printf("sendmsgs[1] is: %s\n", sendmsgs[1])

	// sendmsgs[1] = godror.Message{Raw: []byte(s)}
	// sendmsgs[1] = godror.Message{Raw: inventoryJsonData}
	// sendmsgs[1].Expiration = 10000
	// fmt.Printf("sendmsgs[1] is: %s\n", sendmsgs[1])

	// want = append(want, s)
	// i++
	// }
	if err = inventoryqueue.Enqueue(sendmsgs); err != nil {
		// var ec interface {
		// 	Code() int
		// }
		// if errors.As(err, &ec) && ec.Code() == 24444 {
		// t.Skip(err)
		// fmt.Printf("24444 during enqueue:", err)
		// }
		fmt.Printf("\nenqueue error:", err)
	}
	fmt.Printf("\nenqueue complete0: %s", sendmsgs[0])
	// fmt.Printf("\nenqueue complete1: %s", sendmsgs[1])
	// if objName != "" {
	// 	for _, m := range msgs {
	// 		if m.Object != nil {
	// 			m.Object.Close()
	// 		}
	// 	}
	// }

	// Let's test enqOne
	// if i > msgCount/3 {
	// msgs = msgs[:1]
	// }
	// }
	// fmt.Printf("enqueued %d messages", sendmsgs[0])
	fmt.Println("about to commit...")
	if err := tx.Commit(); err != nil {
		fmt.Printf("commit:", err)
	}
	fmt.Println("commit done...")
	fmt.Printf("commmit complete %d message", sendmsgs[0])
	// fmt.Printf("commmit complete %d message", string(inventoryJsonData))

}
