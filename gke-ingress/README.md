Prerequisite: GKE setup

1. Enable GKE API

gcloud services enable container.googleapis.com

2. Create simple zonal GKE cluster for tests

gcloud container clusters create cluster-asia-test \
--zone asia-southeast1-a \
--release-channel regular \
--enable-ip-alias

3. Configure client credentials for a new cluster

gcloud container clusters get-credentials cluster-asia-test \
--zone asia-southeast1-a
