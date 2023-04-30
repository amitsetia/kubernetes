There are multiple ways to run kube-bench. You can run kube-bench inside a pod, but it will need access to the host's PID namespace in order to check the running processes, as well as access to some directories on the host where config files and other files are stored.

kubectl apply -f job-gke.yaml

After successfull execution of POD you can see the logs with following command:
kubectl logs $(kubectl get pods | grep kube-bench | awk '{print $1}')
