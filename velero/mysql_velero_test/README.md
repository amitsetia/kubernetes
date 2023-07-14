kubectl apply -f pv-pvc.yaml

kubectl apply -f deployment.yaml

kubectl apply -f svc.yaml


kubectl run -it --rm --image=mysql:8.0 --restart=Never mysql-client -- mysql -h mysql -password="Passw0rd321"


Get the deployment with selector and used that in velero:
kubectl get deployment --selector app=mysql


velero backup create mysqlbackup  --selector app=mysql
