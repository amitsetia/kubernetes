To run the postgresql on kubernetes(GKE), follow the below steps. To deploy it on different kubernetes like EKS,AKS,or locally, make sure to change the PV and PVC configuration 

Execute the following commands:

	kubectl apply -f configmap.yaml
	kubectl apply -f pv-pvc.yaml
	kubectl apply -f deployment.yaml
	kubectl apply -f svc.yaml

	kubectl exec -it $(kubectl get pod -l app=postgres -o jsonpath='{.items..metadata.name}') -- psql -h localhost -U admin --password -p 5432 postgresdb

