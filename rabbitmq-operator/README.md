Operators in Kubernetes allow you to extend the cluster's behavior without modifying the code of Kubernetes itself. In our case, the behavior of RabbitMQ will be delegated to the operators. This will save us a lot of time on our side.

The RabbitMQ team develops and maintains two Kubernetes operators :

RabbitMQ Cluster Kubernetes Operator to automate provisioning, management, and operations of RabbitMQ clusters running on Kubernetes.
RabbitMQ Messaging Topology Operator to manage the topology of the clusters (Permissions, Users, etc...)
The Operators are installed through CRDs (Custom Resource Definition) in the Kubernetes cluster. Once installed, new resources are known in the cluster such as classical kinds (Pod, Deployment, etc...). You just have to create the YAML manifests to invoke them.

The CRD is available here https://github.com/rabbitmq/cluster-operator/releases 

		kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/download/v2.2.0/cluster-operator.yml

The new resources are inside the rabbitmq-system namespace:


A new custom resource rabbitmqclusters.rabbitmq.com. The custom resource allows us to define an API for the creation of RabbitMQ Clusters.


Create The RabbitMQ Cluster

``` 
cat << EOF | kubectl create -f -
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  labels:
    app: rabbitmq
  name: rabbitmq
spec:
  replicas: 3
  image: rabbitmq:6.2.12
  service:
    type: ClusterIP
  persistence:
    storage: 2Gi
  resources:
    requests:
      cpu: 256m
      memory: 1Gi
    limits:
      cpu: 256m
      memory: 1Gi
  rabbitmq:
    additionalPlugins:
      - rabbitmq_management
      - rabbitmq_peer_discovery_k8s
    additionalConfig: |
      cluster_formation.peer_discovery_backend = rabbit_peer_discovery_k8s
      cluster_formation.k8s.host = kubernetes.default.svc.cluster.local
      cluster_formation.k8s.address_type = hostname
      vm_memory_high_watermark_paging_ratio = 0.85
      cluster_formation.node_cleanup.interval = 10
      cluster_partition_handling = autoheal
      queue_master_locator = min-masters
      loopback_users.guest = false
      default_user = guest
      default_pass = guest
    advancedConfig: ""
EOF

```

		kubectl get pods -l app.kubernetes.io/name=rabbitmq

To access the UI execute below command

		kubectl port-forward svc/rabbitmq 15672:15672

To fetch the username password execute these command or try to login with
username: guest
password: guest


		kubectl get secrets rabbitmq-default-user -o jsonpath="{.data.password}" | base64 -d

		kubectl get secrets rabbitmq-default-user -o jsonpath="{.data.username}" | base64 -d

