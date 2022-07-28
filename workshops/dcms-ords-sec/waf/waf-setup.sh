oci waf web-app-firewall list --compartment-id $TF_VAR_compartment_ocid --profile MAACLOUD
oci  waf web-app-firewall-policy list  --compartment-id $TF_VAR_compartment_ocid --profile MAACLOUD

oci waf web-app-firewall-policy get --web-app-firewall-policy-id ocid1.webappfirewallpolicy.oc1.iad.amaaaaaaq33dybyatowz5c3u3h6rvflegfzlfdbhvveszprmjdlqu6yv4mta --compartment-id $TF_VAR_compartment_ocid --profile MAACLOUD

#CREATE POLICY FOR RATE_LIMITING - WORKS
export web_app_firewall_policy_id=$(oci waf web-app-firewall-policy create --compartment-id $TF_VAR_compartment_ocid --display-name RateLimitingPolicy --query data.id --raw-output --actions file://actions.json --request-rate-limiting file://request-rate-limiting.json --profile MAACLOUD)

#GET LOAD BALANCER - WORKS
export load_balancer_id=$(oci lb load-balancer list --compartment-id $TF_VAR_compartment_ocid --query 'data[0]."id"' --raw-output --profile MAACLOUD)

#ASSIGN POLICY TO LB - WORKS
oci waf web-app-firewall create-for-load-balancer --compartment-id $TF_VAR_compartment_ocid --load-balancer-id $load_balancer_id --web-app-firewall-policy-id $web_app_firewall_policy_id --profile MAACLOUD