cd $HOME ;
sqlplus DBUSER/$(cat cred.txt |openssl enc -aes256 -md sha512 -a -d -salt -pass pass:Secret@123#)@AQDATABASE_TP @$HOME/oracleAQ/teqBasicCleanups.sql