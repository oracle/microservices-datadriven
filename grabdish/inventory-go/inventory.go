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
    fmt.Println("About to get connection..." + "godror", user + "/" + dbpassword + "@" + inventoryPDBName walletLocation=" + tnsAdmin)
//     db, err := sql.Open("godror", "INVENTORYUSER/Welcome12345@grabdish4x2_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_grabdish4X2")
    db, err := sql.Open("godror", user + "/" + dbpassword + "@" + inventoryPDBName walletLocation=" + tnsAdmin)
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

