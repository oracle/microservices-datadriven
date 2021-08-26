#/bin/bash

while true; do
  if DB_PASSWORD=`kubectl get secret dbuser -n msdataworkshop --template={{.data.dbpassword}} | base64 --decode`; then
    if ! test -z "$DB_PASSWORD"; then
	echo $DB_PASSWORD;
      break
    fi
  fi
  echo "Error: Failed to get DB password.  Retrying..."
  sleep 5
done
