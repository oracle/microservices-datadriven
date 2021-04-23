package main

import (
    "fmt"
	"os"
    "database/sql"
    _ "github.com/godror/godror"
)

func main(){
    tnsAdmin := os.Getenv("TNS_ADMIN")
    user := os.Getenv("user")
    inventoryPDBName := os.Getenv("INVENTORY_PDB_NAME")
    dbpassword := os.Getenv("dbpassword")
    fmt.Println("os.Getenv(TNS_ADMIN): %s", tnsAdmin)
    fmt.Println("os.Getenv(user): %s", user)
    fmt.Println("os.Getenv(INVENTORY_PDB_NAME): %s", inventoryPDBName)
    fmt.Println("os.Getenv(dbpassword): %s", dbpassword)

    // connectionString := user + "/" + dbpassword + "@" + inventoryPDBName
     //+ " walletLocation=" + tnsAdmin
    fmt.Println("About to get connection... connectionString: %s", connectionString )
    // db, err := sql.Open("godror", connectionString + " walletLocation=" + tnsAdmin)


    var P godror.ConnectionParams
    P.Username, P.Password = user, dbpassword
    P.ConnectString = inventoryPDBName
    P.SessionTimeout = 42 * time.Second 
    P.SetSessionParamOnInit("NLS_NUMERIC_CHARACTERS", ",.")
    P.SetSessionParamOnInit("WALLET_LOCATION", tnsAdmin)
    fmt.Println(P.StringWithPassword())
    db := sql.OpenDB(godror.NewConnector(P))

    if err != nil {
        fmt.Println(err)
        return
    }
    defer db.Close()


    rows,err := db.Query("select sysdate from dual")
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
}

