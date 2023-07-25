# Traefik Ingress

To install Traefik on Kubernetes run the terraform apply, but make sure your kuberentes context is set correctly and kubeconfig should also have correct privileges.

To push the changes, execute following commands:

    terraform init
    terraform apply

If you see svc.yaml, Service Type is ClusterIP(feel free to set to "LoadBalancer")

To access ClusterIP based Service, use the following command to access traefik Dashboard. 

    kubectl port-forward svc/traefik-dashboard-service 8080:8080

then go to browser and hit "http://localhost:8080"

To expose services via Ingress create an ingress object and point it to right services. To create the ingress object in traefik there are two ways, First use the native definitions to create the ingress resources and second one is using the Traefik CRDs. Below sample is using native way of defining ingress resources. You also found the CRDs configuration ingress resources defintion in ingress-crd.yaml .

```
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
```

To check Ingress resources get created or not make sure desribe the ingress object and make sure it showed an endpoint(Marked in BOLD ). If these endpoints are missing then make sure serving POD is up and running.

```
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
              /rabbitmq/   import-definitions:15672 (**10.0.0.15:15672**)
              /ui/*        vaultraft:8200 (**10.0.0.14:8200**)
Annotations:  kubernetes.io/ingress.class: traefik
Events:       <none>

```

### Advance Configuration in Traefik

1. Rate Limiting

```
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: ratelimit
spec:
  rateLimit:
    average: 100
    burst: 50
```

it specifies a rate limiting rule of 100 requests per second with a burst rate of 50 requests. You can adjust these values to suit your specific requirements.

2. Add the Rate Limiting Middleware to Service:
```
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-ratelimit@kubernetescrd
spec:
  selector:
    app: my-app
  ports:
    - name: http
      port: 80
```

#### Enable TCP entrypoint

To handle TCP request like connecting to MySQL, MongoDB, Vault. We have to use TCP entrypoint feature of Traefik. Configure the entrypoint in deployment and then use the "IngressRouteTCP" CRD object to forward traffic to TCP backend.

Issue: Vault service is exposed on port 8200, i tried it to access it via HTTP entrypoint, but getting 404 Page not found error.

Solution: Enabled TCP entrypoint by adding the following entry in the Traefik deployment.yaml and then later exposed that TCP port in traefik svc.yaml.

    spec.template.spec.containers.args =  - --entryPoints.tcpep.address=:8085

in Service yaml exposed TCP port:

```
apiVersion: v1
kind: Service
metadata:
  name: traefik-tcp-service

spec:
  type: ClusterIP
  ports:
    - port: 8085
      targetPort: 8085
  selector:
    app: traefik
```

Then by using the IngressRouteTCP object of traefik CRDs, exposed the vault svc

```
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: vault-ingress
spec:
  entryPoints:
  - tcpep
  routes:
  - match: HostSNI(`*`)
    services:
    - name: vaultraft
      port: 8200
```

To access the service, execute the following command and hit the localhost:8085

    kubectl port-forward svc/traefik-tcp-service 8085:8085

## Enable access logs 
The setup we have done is not collecting logs, To enable access logging in traefik we have to perform following steps:
1. Add Volume and VolumeMount in deployment.yaml
1. Add below snippet containers.arg section.

              volumeMounts:
                - mountPath: /data/log
                  name: logdir
          volumes:
          - name: logdir
            emptyDir: {}

```
- --accesslog
- --accesslog.format=json
- --accesslog.filepath=/data/access.log
```
