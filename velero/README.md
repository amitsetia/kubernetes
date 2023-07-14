In this thread we will gonna setup velero on EKS.

First Basic question what is velero and why we need it? 
Velero is an open-source tool that helps automate the backup and restore of Kubernetes clusters, including any application and its data.It can be helpful in Disaster recovery, Data Migration and Data Mangement, Application Migration and Application Cloning.

Prerequisites:

For EKS:
1. AWS Cli
2. kubectl 
3. velero binary(if not installed follow the step mentioned in this doc to install it)


Now we will setup and create few resources on AWS to store the backup and privileges to go with the least privileges principal.

1. Create an S3 bucket.

 aws s3 mb s3://eksclustername-velerobackup

2. IAM user with below policy.

aws iam create-user --user-name jacksparrow

3. Create Policy:
aws iam create-policy \
    --policy-name AmazonEKSClusterveleros3Policy \
    --policy-document \
'{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${VELERO_BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${VELERO_BUCKET}"
            ]
        }
    ]
}'

#list policies with command and grep which we created on above step to make sure its reflecting in policy list.

aws iam list-policies | grep AmazonEKSClusterveleros3Policy

###Now Attach this policy to user:

aws iam attach-user-policy --user-name jacksparrow --policy-arn "arn:aws:iam::aws:policy/AmazonEKSClusterveleros3Policy

4. Download Velero visit https://github.com/vmware-tanzu/velero/tags check the latest version and download it.

wget https://github.com/vmware-tanzu/velero/releases/download/v1.11.0/velero-v1.11.0-darwin-amd64.tar.gz

extract tar:
tar -xvf velero-v1.3.2-linux-amd64.tar.gz -C /tmp

Move the extracted velero binary to /usr/local/bin
sudo mv /tmp/velero-v1.3.2-linux-amd64/velero /usr/local/bin

Verify binary:

velero version


output:

ASRHQ872:eck-terraform amit.setia$ velero version
Client:
	Version: v1.11.0
	Git commit: -
<error getting server version: no matches for kind "ServerStatusRequest" in version "velero.io/v1">


NOTE: if you got the velero not found message then set a below path variable for velero.
 export PATH=$PATH:/usr/local/bin

5, Install velero on EKS:

velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.2.0 \
    --bucket eksclustername-velerobackup\
    --backup-location-config region=<region> \
    --snapshot-location-config region=<region> \
    --secret-file /root/.aws/credentials


Inspect the resource and logs of deployment, execute following commands:
kubectl get all -n velero

 kubectl logs deployment/velero -n velero


5. Testing Phase (Backup and Restore)

a. Deploy a test Application
 kubectl create namespace shunya
 kubectl create deployment nginx --image=nginx -n shunya

Verify the deployments 
kubectl get deployments -n harshal

b. Backup

velero backup create shunyans --include-namespaces shunya

Check the status of backup :

velero backup describe <backupname>

In our case its 
velero backup describe shunyans

c. Restore Phase:

Before restoring let's delete the "shunya" namespace 

kubectl delete namespace harshal

After deleting namespace you will see nginx deployment is also deleted and Now is the restoring time:

velero restore create --from-backup shunyans


