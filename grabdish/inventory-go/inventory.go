package main

import (
	"context"
	"database/sql"
	"fmt"
	"os"

	"github.com/godror/godror"
)

func main() {
	tnsAdmin := os.Getenv("TNS_ADMIN")
	user := os.Getenv("user")
	inventoryPDBName := os.Getenv("INVENTORY_PDB_NAME")
	dbpassword := os.Getenv("dbpassword")
	fmt.Println("os.Getenv(TNS_ADMIN): %s", tnsAdmin)
	fmt.Println("os.Getenv(user): %s", user)
	fmt.Println("os.Getenv(INVENTORY_PDB_NAME): %s", inventoryPDBName)
	fmt.Println("os.Getenv(dbpassword): %s", dbpassword)

	connectionString := user + "/" + dbpassword + "@" + inventoryPDBName
	//+ " walletLocation=" + tnsAdmin
	fmt.Println("About to get connection... connectionString: %s", connectionString)
	db, err := sql.Open("godror", connectionString)

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
	fmt.Printf("The db is: %s\n", db)
	fmt.Printf("The date is: %s\n", thedate)

	// DeqOptions DPI_OCI_ATTR_CONSUMER_NAME

	ctx := context.Background()

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		fmt.Println(err)
	}
	defer tx.Rollback()
	// Let's test deqOne
	// if i == msgCount/3 {
	// 	msgs = msgs[:1]
	// }

	// type DeqOptions struct {
	// 	Condition, Consumer, Correlation string
	// 	MsgID, Transformation            string
	// 	Mode                             DeqMode
	// 	DeliveryMode                     DeliveryMode
	// 	Navigation                       DeqNavigation
	// 	Visibility                       Visibility
	// 	Wait                             uint32
	// }

	fmt.Printf("The date is: %s\n", thedate)
	q, err := godror.NewQueue(ctx, tx, "orderqueue", "SYS.AQ$_JMS_TEXT_MESSAGE",
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
	defer q.Close()
	//t.Logf("name=%q q=%#v", q.Name(), q)
	msgs := make([]godror.Message, 1)
	n, err := q.Dequeue(msgs)
	if err != nil {
		fmt.Printf("dequeue:", err)
	}
	fmt.Printf("received %d message", n)
	if err = tx.Commit(); err != nil {
		fmt.Printf("commit:", err)
	}
	// if n == 0 {
	// 	return 0
	// }
	// for j, m := range msgs[:n] {
	// 	s, err := checkMessage(m, i+j)
	// 	if err != nil {
	// 		t.Error(err)
	// 	}
	// 	t.Logf("%d: got: %q", i+j, s)
	// 	if k, ok := seen[s]; ok {
	// 		t.Fatalf("%d. %q already seen in %d", i, s, k)
	// 	}
	// 	seen[s] = i
	// }
	// //i += n
	// if err = tx.Commit(); err != nil {
	// 	t.Fatal(err)
	// }

}

// 	ctx := context.Background()

// 	for i := 0; i < 10; i++ {
// 		err = transaction(ctx, db, "inventoryqueue")
// 		if err != nil {
// 			panic(err)
// 		}
// 		godror.Raw(ctx, db, func(c godror.Conn) error {
// 			poolStats, err := c.GetPoolStats()
// 			fmt.Printf("stats: %+v %v\n", poolStats, err)
// 			return err
// 		})
// 	}
// }

// func transaction(ctx context.Context, db *sql.DB, dbQueue string) error {
// 	tx, err := db.BeginTx(ctx, nil)
// 	if err != nil {
// 		return err
// 	}
// 	defer tx.Rollback()

// 	q, err := godror.NewQueue(ctx, tx, qName, objName, godror.WithEnqOptions(godror.EnqOptions{
// 		Visibility:   godror.VisibleOnCommit,
// 		DeliveryMode: godror.DeliverPersistent,
// 	}))

// 	q, err := godror.NewQueue(ctx, tx, dbQueue, "SYS.AQ$_JMS_TEXT_MESSAGE")
// 	if err != nil {
// 		return err
// 	}
// 	defer q.Close()

// 	msgs := make([]godror.Message, 1)
// 	n, err := q.Dequeue(msgs)
// 	if err != nil {
// 		return err
// 	}
// 	if n == 0 {
// 		return nil
// 	}

// 	for _, m := range msgs[:n] {
// 		fmt.Printf("Got message %+v\n", m)
// 		err = m.Object.Close()
// 		if err != nil {
// 			return err
// 		}
// 	}

// 	return tx.Commit()
// }

//SPROC STUFF....

// var rset1, rset2 driver.Rows

// query := `BEGIN checkInventoryReturnLocation(:1, :2); END;`

// if _, err := db.ExecContext(ctx, query, sql.Out{Dest: &rset1}, sql.Out{Dest: &rset2}); err != nil {
//     log.Printf("Error running %q: %+v", query, err)
//     return
// }
// defer rset1.Close()
// defer rset2.Close()

// cols1 := rset1.(driver.RowsColumnTypeScanType).Columns()
// dests1 := make([]driver.Value, len(cols1))
// for {
//     if err := rset1.Next(dests1); err != nil {
//         if err == io.EOF {
//             break
//         }
//         rset1.Close()
//         return err
//     }
//     fmt.Println(dests1)
// }

// cols2 := rset1.(driver.RowsColumnTypeScanType).Columns()
// dests2 := make([]driver.Value, len(cols2))
// for {
//     if err := rset2.Next(dests2); err != nil {
//         if err == io.EOF {
//             break
//         }
//         rset2.Close()
//         return err
//     }
//     fmt.Println(dests2)
// }

// logpod ory-go
// kubectl logs -f inventory-go-6877c8bc84-795lm -n msdataworkshop
// os.Getenv(TNS_ADMIN): %s /msdataworkshop/creds
// os.Getenv(user): %s inventoryuser
// os.Getenv(INVENTORY_PDB_NAME): %s grabdish4X2_tp
// os.Getenv(dbpassword): %s Welcome12345
// About to get connection... connectionString: %s inventoryuser/Welcome12345@grabdish4X2_tp
// The db is: &{%!s(int64=0) {%!s(*godror.drv=&{{{0 0} 0 0 0 0} 0x7f4cd4cfa4c0 map[inventoryuser   grabdish4X2_tp  1       1000    1       30s     1h0m0s  5m0s    false   false   false:0xc0000ce000] map[UTC     user=inventoryuser password="SECRET-6tpAd_Mk_Yg=" connectString=grabdish4X2_tp
// configDir= connectionClass= enableEvents=0 heterogeneousPool=0 libDir= poolIncrement=1
// poolMaxSessions=1000 poolMinSessions=1 poolSessionMaxLifetime=1h0m0s poolSessionTimeout=5m0s
// poolWaitTimeout=30s prelim=0 standaloneConnection=0 sysasm=0 sysdba=0 sysoper=0
// timezone=local:{0x6a8f00 0}] { 19 3 0 0 0 192}}) {{inventoryuser grabdish4X2_tp {Welcome12345}   %!s(func(driver.Conn) error=<nil>) [] [] %!s(*time.Location=&{UTC [] []  0 0 <nil>}) %!s(bool=false)} {{}  %!s(bool=false) %!s(bool=false) %!s(bool=false) %!s(bool=false) [] []} {%!s(int=1) %!s(int=1000) %!s(int=1) %!s(time.Duration=30000000000) %!s(time.Duration=3600000000000) %!s(time.Duration=300000000000) %!s(bool=false) %!s(bool=false)} {} %!s(bool=false)}} %!s(uint64=0) {%!s(int32=0) %!s(uint32=0)} [%!s(*sql.driverConn=&{0xc00009ad00 {13842095394504166490 229994707 0x6c0060} {0 0} 0xc0000d2000 true false false map[] false {13842095394506597747 232426024 0x6c0060} [] false})] map[] %!s(uint64=0) %!s(int=1) %!s(chan struct {}=0xc000082120) %!s(bool=false) map[%!s(*sql.driverConn=&{0xc00009ad00 {13842095394504166490 229994707 0x6c0060} {0 0} 0xc0000d2000 true false false map[] false {13842095394506597747 232426024 0x6c0060} [] false}):map[%!s(*sql.driverConn=&{0xc00009ad00 {13842095394504166490 229994707 0x6c0060} {0 0} 0xc0000d2000 true false false map[] false {13842095394506597747 232426024 0x6c0060} [] false}):%!s(bool=true)]] map[] %!s(int=0) %!s(int=0) %!s(time.Duration=0) %!s(time.Duration=0) %!s(chan struct {}=<nil>) %!s(int64=0) %!s(int64=0) %!s(int64=0) %!s(int64=0) %!s(func()=0x48f3c0)}
// The date is: 2021-04-24T03:02:08Z
// panic: dequeue: ORA-25231: cannot dequeue because CONSUMER_NAME not specified

// goroutine 1 [running]:
// main.main()
//         /src/inventory.go:63 +0x9ec
// paul_parki@cloudshell:inventory-go (us-phoenix-1)$

// repeat
//     work();
// until condition
