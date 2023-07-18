To install Traefik on Kubernetes run the terraform apply, but make sure your kuberentes context is set correctly and kubeconfig should also have correct privileges.

To push the changes, execute following commands:

  terraform init
  terraform apply

Right now traefik service Type is set to "ClusterIP" , feel free to set to "LoadBalancer". 

If its set to ClusterIP, feel free to use kubectl port-forward utility to check the ingress functionality.

  kubectl port-forward svc/traefik-web-service 80:80

then go to browser and access

  http://localhost:80/path (which we set during ingress object creation as mentioned below)

'''
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - http:
      paths:
      - path: /rabbitmq/
        pathType: Prefix
        backend:
          service:
            name: import-definitions
            port:
              number: 15672
      - path: /ui
        pathType: Prefix
        backend:
          service:
            name: vaultraft
            port:
              number: 8200
'''

To check Ingress object has attached to an endpoint

ASRHQ872:traefik $ kubectl describe ing
Name:             frontend
Labels:           <none>
Namespace:        default
Address:
Ingress Class:    <none>
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /rabbitmq/   import-definitions:15672 (10.0.0.15:15672)
              /ui/*        vaultraft:8200 (10.0.0.14:8200)
Annotations:  kubernetes.io/ingress.class: traefik
Events:       <none> 
