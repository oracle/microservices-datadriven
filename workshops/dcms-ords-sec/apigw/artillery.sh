#TRIMMEDURL=${api_gw_base_url:8}
TRIMMEDURL=${api_gw_base_url}
echo $TRIMMEDURL
sed "s/TOKEN/$ACCESS_TOKEN/" ./stress.yaml.temp &>./stress1.yaml
sed "s/API_GW_BASE_URL/$TRIMMEDURL/" ./stress1.yaml &>./stress.yaml
rm ./stress1.yaml
docker run --rm -it -v ${PWD}:/scripts artilleryio/artillery:latest run /scripts/stress.yaml
rm ./stress.yaml
