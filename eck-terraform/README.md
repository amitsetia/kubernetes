[WIP]

Following setup has been tested on GKE-1.25.8-gke.500 

Before applying this code make sure you have check the kube-state-metrics compatability matrix. And set the appVersion value accordingly in main.tf line 20

    set {
      name  = "appVersion"
      value = "2.7.0"
    }


https://github.com/kubernetes/kube-state-metrics#versioning

     terraform init
 
     terraform apply

Execute the following commands to get the secrets value of Elastic user and port-forward kibana service:

    kubectl -n monitoring  get secret elasticsearch-logging-es-elastic-user  -o go-template='{{.data.elastic | base64decode}}'

    kubectl port-forward svc/kibana-logging-kb-http 5601:5601  -n monitoring

Open browser and hit http://localhost:5601 use the "elastic" username and password received from above secret command.
