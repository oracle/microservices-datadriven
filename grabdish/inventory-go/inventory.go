package main

import (
    "fmt"
	"os"
    "database/sql"
    _ "github.com/godror/godror"
)

func main(){
//         os.Setenv("TNS_ADMIN", "/Users/pparkins/Downloads/Wallet_grabdish4X2");
        fmt.Println("concat os.Getenv(TNS_ADMIN):" + os.Getenv("TNS_ADMIN"));
    fmt.Printf("os.Getenv(TNS_ADMIN): %s\n", os.Getenv("TNS_ADMIN"))
        fmt.Println("About to get connection...")
//     db, err := sql.Open("godror", "INVENTORYUSER/Welcome12345@grabdish4x2_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_grabdish4X2")
    db, err := sql.Open("godror", "INVENTORYUSER/Welcome12345@grabdish4x2_tp")
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

