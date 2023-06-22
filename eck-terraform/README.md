[WIP]

Before applying this code make sure you have check the kube-state-metrics compatability matrix. And set the appVersion value accordingly in main.tf line 20

    set {
      name  = "appVersion"
      value = "2.7.0"
    }


https://github.com/kubernetes/kube-state-metrics#versioning

   terraform init
 
   terraform apply

