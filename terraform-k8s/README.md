First step to create namespace with terraform.
  
    terraform init
  
#watch out the plan output and make sure to change the namespace variable value to create a namespace and also make sure to set the correct context
  
    terraform plan
  
    terraform apply -var "namespace=tf-namespace"
