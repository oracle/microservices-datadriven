

kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/bundle.yaml
kubectl get deploy
kubectl apply -f prom_rbac.yaml -n msdataworkshop
kubectl apply -f prometheus.yaml -n msdataworkshop
kubectl get prometheus -n msdataworkshop
kubectl get pod -n msdataworkshop |grep prometheus
kubectl apply -f prom_svc.yaml -n msdataworkshop
kubectl get service -n msdataworkshop
#kubectl port-forward svc/prometheus 9090
#kubectl apply -f prometheus_servicemonitor.yaml -n msdataworkshop
kubectl apply -f prom_msdataworkshop_servicemonitor.yaml -n msdataworkshop

kubectl create secret generic kubepromsecret \
  --from-literal=username=<your_grafana_cloud_prometheus_username>\
  --from-literal=password='<your_grafana_cloud_API_key>'

helm repo add grafana https://grafana.github.io/helm-charts
helm install stable/prometheus-operator --generate-name

#latest...
kubectl apply -f prom_rbac.yaml -n msdataworkshop
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install stable prometheus-community/kube-prometheus-stack
kubectl get pods
kubectl get svc
kubectl edit svc stable-kube-prometheus-sta-prometheus
kubectl edit svc stable-grafana
# admin/prom-operator
#MicroProfile https://grafana.com/grafana/dashboards/12853
#Fault Tolerance https://grafana.com/grafana/dashboards/8022

