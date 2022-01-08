# Sample Application: TravelAgency

Source code and workshop scripts for the
[Simplify Sagas with Oracle Database, Data Integrity Across Microservices][1]
available on [Oracle LiveLabs][2].


 mkdir wallet
  cd wallet
  oci db autonomous-database list --compartment-id "$(cat state/COMPARTMENT_OCID)" --query 'join('"' '"',data[?"display-name"=='"'TRAVELAGENCYDB'"'].id)' --raw-output
oci db autonomous-database generate-wallet --autonomous-database-id [YOUR_DB_OCID_HERE] --file 'wallet.zip' --password 'Welcome1' --generate-type 'ALL'
  unzip wallet.zip
  cd ../
  



## License

Copyright (c) 2021 Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at <https://oss.oracle.com/licenses/upl>.

[1]: https://apexapps.oracle.com/pls/apex/dbpm/r/livelabs/view-workshop?wid=8781
[2]: https://apexapps.oracle.com/pls/apex/dbpm/r/livelabs/home
