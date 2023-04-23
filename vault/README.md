# Intial Setup 

Vault server requires certain extra Kubernetes permissions to do its operations. Therefore, a ClusterRole is required (with the appropriate permissions) to be assigned to a ServiceAccount via a ClusterRoleBinding.

Kubernetes by default has a ClusterRole created with the required permissions i.e. ‘system:auth-delegator‘ so it’s not required to be created again for this case. Service account and Role Binding are required to be created.

Let’s create the required RBAC for Vault.

    kubectl apply -f rbac.yaml
    
Create Configmap with vault configuration

    kubectl apply -f configmap.yaml      

For the vault server, we will create a headless service for internal usage. It will be very useful when we scale the vault to multiple replicas.

A non-headless service will be created for UI as we want to load balance requests to the replicas when accessing the UI.
Deploy Services

    kubectl apply -f services.yaml
    
Deploy the vault statefulset deployment,Before deploying make sure storageclass is available for VolummeClaimTemplates :

    kubectl apply -f deployment.yaml
    
```   
 volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
      volumeMode: Filesystem
```

Next, initialize and unseal vault-0 pod:

    kubectl exec -ti vault-0 -- vault operator init
    kubectl exec -ti vault-0 -- vault operator unseal
    
To verify if the Raft cluster has successfully been initialized, run the following.

First, login using the root token on the vault-0 pod:

      kubectl exec vault-0 -- vault login $VAULT_ROOT_KEY

Next, list all the raft peers:

      kubectl exec -ti vault-0 -- vault operator raft list-peers

# Create Secrets 

      vault secrets enable -version=2 -path="kv" kv

Create a secret in key-value format and list it. The id (key) is name and secret(value) would be devopscube. Path is demo-app/user01

      vault kv put kv/user01 name=jacksparrow
      vault kv get kv/user01 

## Create a Policy

By default, the secret path has the deny policy enabled. We need to explicitly add a policy to read/write/delete the secrets.

The following policy dictates that the entity be allowed the read operation for secrets stored under “kv“. Execute it to create the policy

        vault policy write demo-policy - <<EOF
        path "kv/*" {
          capabilities = ["read"]
        }
        EOF

You can list and validate the policy.

      vault policy list

# Enable Vault Kubernetes Authentication Method

For Kubernetes pods to interact with Vault and get the secrets, it needs a vault token. The kubernetes auth method with the pod service account makes it easy for pods to retrieve secrets from the vault.
In this way, any pod which has been assigned the “vault” as the service account – will be able to read these secrets without requiring any vault token.

Let’s enable the kubernetes auth method.

      vault auth enable kubernetes

We have attached a service account with a ClusterRole to the vault Statefulset. The following command configures the service account token to enable the vault server to make API calls to Kubernetes using the token, Kubernetes URL and the cluster API CA certificate. KUBERNETES_PORT_443_TCP_ADDR is the env variable inside the pod that returns the internal API endpoint.

```
vault write auth/kubernetes/config token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
   kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"  \
   kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

Now we have to create a vault approle that binds a Kubernetes service account, namespace, and vault policies. This way vault server knows if a specific service account is authorized to read the stored secrets.

Let’s create a service account that can be used by application pods to retrieve secrets from the vault.

    kubectl create serviceaccount vault-auth

Let’s create a vault approle named webapp and bind a service account named vault-auth in the default namespace. Also, we are attaching the demo-policy we have created which has read access to a secret.

vault write auth/kubernetes/role/webapp \
        bound_service_account_names=vault-auth \
        bound_service_account_namespaces=default \
        policies=demo-policy \
        ttl=72h


# Fetching Secrets Stored in Vault With Service Accounts

```
---
apiVersion: v1
kind: Pod
metadata:
  name: vault-client
  namespace: default
spec:
  containers:
  - image: nginx:latest
    name: nginx
  serviceAccountName: vault-auth
```

    kubectl apply -f pod.yaml

    kubectl exec -it vault-client /bin/bash

Make an API request to the vault server using the service account token (JWT) to acquire a client token.

Save the service account token to a variable jwt_token

    jwt_token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

Make the API call using curl. Replace http://vaultraft.default:8200 (Vault Service URL) with your vault URL.

```
curl --request POST \
    --data '{"jwt": "'$jwt_token'", "role": "webapp"}' \
    http://vaultraft.default:8200/v1/auth/kubernetes/login
```

The above API request will return a JSON containing the client_token. Using this token, secrets can be read. 

```
{"request_id":"64afd3c7-7688-e2a2-c748-2be14dfd45d1","lease_id":"","renewable":false,"lease_duration":0,"data":null,"wrap_info":null,"warnings":null,"auth":{"client_token":"hvs.CAESIGYeipT0ULcKpR1bN0J-77BHnDZrOoFrmKslBUvGTgWTGh4KHGh2cy4yZTM2M0d3WmZIdkQ4QzUxelpQa3FodzA","accessor":"TkdYyiJRvSkDA5uUM6Cop4aX","policies":["default","demo-policy"],"token_policies":["default","demo-policy"],"metadata":{"role":"webapp","service_account_name":"vault-auth","service_account_namespace":"default","service_account_secret_name":"","service_account_uid":"e2266117-c2b2-477f-b0c9-7d48fcd148eb"},"lease_duration":259200,"renewable":true,"entity_id":"d1dbfb27-c922-45fe-9bab-3120c2b4a64b","token_type":"service","orphan":true,"mfa_requirement":null,"num_uses":0}}
```

```
root@vault-client:/# curl -H "X-Vault-Token: hvs.CAESIGYeipT0ULcKpR1bN0J-77BHnDZrOoFrmKslBUvGTgWTGh4KHGh2cy4yZTM2M0d3WmZIdkQ4QzUxelpQa3FodzA"      -H "X-Vault-Namespace: vault"      -X GET http://vaultraft.default:8200/v1/kv/data/user01?version=1
```
