#/bin/bash

while true; do
  if FE_PASSWORD=`kubectl get secret frontendadmin -n msdataworkshop --template={{.data.password}} | base64 --decode`; then
    if ! test -z "$FE_PASSWORD"; then
	echo $FE_PASSWORD;
      break
    fi
  fi
  echo "Error: Failed to get DB password.  Retrying..."
  sleep 5
done
