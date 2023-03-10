kaniko is a tool to build container images from a Dockerfile, inside a container or Kubernetes cluster.

kaniko doesn't depend on a Docker daemon and executes each command within a Dockerfile completely in userspace. This enables building container images in environments that can't easily or securely run a Docker daemon, such as a standard Kubernetes cluster.

kaniko is meant to be run as an image: gcr.io/kaniko-project/executor. We do not recommend running the kaniko executor binary in another image, as it might not work.

Create Dockerhub Kubernetes Secret
We have to create a kubernetes secret of type docker-registry for the kaniko pod to authenticate the Docker hub registry and push the image.

Use the following command format to create the docker registry secret. Replace the parameters marked in bold.
 ```
kubectl create secret docker-registry dockercred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=<dockerhub-username> \
    --docker-password=<dockerhub-password>\
    --docker-email=<dockerhub-email>
```            
This secret gets mounted to the kaniko pod for it to authenticate the Docker registry to push the built image.

Note: If you have a self hosted docker regpository, you can replace the server URL wiht your docker registry API endpoint.

Deploy Kaniko Pod To Build Docker Image
Now, let’s test the kaniko image builder using a pod deployment.

I have hosted the manifest and Dockerfile in the public Github repository. It is a simple Dockerfile with update instructions.

I will use that repository for demonstration. You can fork it or create your own repo with similar configurations.

```
https://github.com/scriptcamp/kubernetes-kaniko
Save the following manifest as pod.yaml

apiVersion: v1
    kind: Pod
    spec:
      containers:
      - name: maven
        image: maven:3.8.1-jdk-8
        command:
        - sleep
        args:
        - 99d
      - name: kaniko
        image: gcr.io/kaniko-project/executor:debug
        command:
        - sleep
        args:
        - 9999999
        volumeMounts:
        - name: kaniko-secret
          mountPath: /kaniko/.docker
      restartPolicy: Never
      volumes:
      - name: kaniko-secret
        secret:
            secretName: dockercred
            items:
            - key: .dockerconfigjson
              path: config.json
 ```
 
              
–context: This is the location of the Dockerfile. In our case, the Dockerfile is located in the root of the repository. So I have given the git URL of the repository. If you are using a private git repository, then you can use GIT_USERNAME and GIT_PASSWORD (API token) variables to authenticate git repository.
–destination: Here, you need to replace <dockerhub-username> with your docker hub username with your dockerhub username for kaniko to push the image to the dockerhub registry. For example, in my case its, setiaamit/kaniko-test-image:1.0
All the other configurations remain the same.

Now deploy the pod.

kubectl apply -f pod.yaml
To validate the docker image build and push, check the pod logs.

kubectl logs kaniko --follow

Here we used a static pod name. So to deploy again; first you have to delete the kaniko pod. When you use kaniko for your CI/CD pipeline, the pod gets a random name based on the CI tool you use, and it takes care of deleting the pod.


If you are using Kubernetes for scaling Jenkins build agents, you can make use of Kaniko docker build pods to build the docker images in the CI pipeline.

You can check out my Jenkins build agent setup on Kubernetes where the Jenkins master and agent runs on the kubernetes cluster.

To leverage Kaniko for your build pipelines, you should have the Dockerfile along with the application.

Also, you should use the multi-container pod template with a build and kaniko container. For example, maven containers for java build and kaniko containers to take the jar and build the docker image using the Dockerfile present in the repository.

Here is a Jenkinsfile based on a multi-container pod template where you can build your application and use the kaniko container to build the docker image with the application and push it to a Docker registry.

Important Note: You should use the kaniko image with the debug tag in the pod template because we will explicitly run the kaniko executer using bash. The latest tag images do not have a bash.

```
            podTemplate(yaml: '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: maven
                    image: maven:3.8.1-jdk-8
                    command:
                    - sleep
                    args:
                    - 99d
                  - name: kaniko
                    image: gcr.io/kaniko-project/executor:debug
                    command:
                    - sleep
                    args:
                    - 9999999
                    volumeMounts:
                    - name: kaniko-secret
                      mountPath: /kaniko/.docker
                  restartPolicy: Never
                  volumes:
                  - name: kaniko-secret
                    secret:
                        secretName: dockercred
                        items:
                        - key: .dockerconfigjson
                          path: config.json
            ''') {
              node(POD_LABEL) {
                stage('Get a Maven project') {
                  git url: 'https://github.com/amitsetia/spring-boot.git', branch: 'master'
                  container('maven') {
                    stage('Build a Maven project') {
                      sh '''
                      mvn package
                      '''
                    }
                  }
                }

                stage('Build Java Image') {
                  container('kaniko') {
                    stage('Build a Go project') {
                      sh '''
                        /kaniko/executor --context `pwd` --destination setiaamit/hello-kaniko:0.1
                      '''
                    }
                  }
                }

              }
            }

```
 
You can use the above Jenkinsfile directly on a pipeline job and test it. It is just a template to get started. You need to replace the repo with your code repo and write the build logic as per the application’s needs



Here is how Kaniko works,

There is a dedicated Kaniko executer image that builds the container images. It is recommended to use the gcr.io/kaniko-project/executor image to avoid any possible issues. Because this image contains only static go binary and logic to push/pull images from/to registry.
kaniko accepts three arguments. A Dockerfile, build context, and a remote Docker registry.
When you deploy the kaniko image, it reads the Dockerfile and extracts the base image file system using the FROM instruction.
Then, it executes each instruction from the Dockerfile and takes a snapshot in the userspace.
After each snapshot, kaniko appends only the changed image layers to the base image and updates the image metadata. It happens for all the instructions in the Dockerfile.
Finally, it pushes the image to the given registry.


As you can see, all the image-building operations happen inside the Kaniko container’s userspace and it does not require any privileged access to the host.

Kaniko supports the following type of build context.

GCS Bucket
S3 Bucket
Azure Blob Storage
Local Directory
Local Tar
Standard Input
Git Repository
For this blog, I will use the Github repo as a context.

Also, you can push to any container registry.

To demonstrate the Kaniko workflow, I will use publicly available tools to build Docker images on kubernetes using Kaniko.

Here is what you need

A valid Github repo with a Dockerfile: kaniko will use the repository URL path as the Dockerfile context
A valid docker hub account: For kaniko pod to authenticate and push the built Docker image.
Access to Kubernetes cluster: To deploy kaniko pod and create docker registry secret.
