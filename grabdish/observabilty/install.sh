

kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/bundle.yaml
kubectl get deploy
kubectl apply -f prom_rbac.yaml
kubectl apply -f prometheus.yaml
kubectl get prometheus
kubectl get pod
kubectl apply -f prom_svc.yaml
kubectl get service
#kubectl port-forward svc/prometheus 9090
kubectl apply -f prometheus_servicemonitor.yaml
kubectl apply -f prom_msdataworkshop_servicemonitors.yaml

kubectl create secret generic kubepromsecret \
  --from-literal=username=<your_grafana_cloud_prometheus_username>\
  --from-literal=password='<your_grafana_cloud_API_key>'

helm repo add grafana https://grafana.github.io/helm-charts
helm install stable/prometheus-operator --generate-name
