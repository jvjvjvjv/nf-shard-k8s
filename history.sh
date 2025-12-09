# Create the kind cluster (1 control plane, 2 worker nodes)
kind create cluster --config kind-config.yaml --name testing

# Delete the kind cluster
kind delete cluster --name testing

# Make a namespace for the app
kubectl create namespace nf-shard --context kind-testing

# Launch the postgres service
kubectl apply -f postgres.yaml --context kind-testing

# Verify the postgres server is running
kubectl logs -n nf-shard -l app=postgres

# Launch the nf-shard app
kubectl apply -f nf-shard.yaml --context kind-testing

# Verify that the nf-shard app is running
kubectl logs -n nf-shard -l app=nf-shard
# > yarn run v1.22.19
# > $ next start
# > - ready started server on [::]:3000, url: http://localhost:3000

# Forward port to make the program accessible
kubectl port-forward -n nf-shard service/nf-shard 3000:3000

# Pause deployment of nf-shard and restart
kubectl scale deployment nf-shard -n nf-shard --replicas=0
kubectl scale deployment nf-shard -n nf-shard --replicas=1


### Running nextflow in the cluster
kubectl apply -f nextflow-storage.yaml
kubectl apply -f nextflow-sa.yaml

# Set up secrets for ghcr
kubectl create secret docker-registry ghcr-secret \
    -n nf-shard \
    --docker-server=ghcr.io \
    --docker-username=jvjvjvjv \
    --docker-password=<TOKEN> \
    --docker-email=jvailionis99@gmail.com

# Kompose to set up the nf-shard files
### cd to git
cd ~/git/nf-shard-clones/GallVp/nf-shard

### Required variables
export POSTGRES_PASSWORD="postgres123"
export POSTGRES_URI=postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/postgres?schema=public
export APP_SECRET_KEY=$(openssl rand -hex 32)
export DEFAULT_ACCESS_TOKEN=$(openssl rand -hex 32 | sed -E 's/(.{16})(.{16})(.{16})(.{16})/\1-\2-\3-\4/')
export APP_USERNAME="user1"
export APP_PASSWORD="password"

### Kompose command
kompose convert --profile all -f docker-compose.yml -n nf-shard

### Mv files to the right place
mv *.yaml ../../../minicluster/nf-shard-compose/
cd ../../../minicluster

### I had to change the image for nextjs to ghcr.io/gallvp/nf-shard:latest
vim nf-shard-compose/nextjs-deployment.yaml

### I had to change the mount path for postgres
### This is related to a change in new postgres 18, other way is to make the docker use older postgres
### Old path: /var/lib/postgresql/data	new path: /var/lib/postgresql
vim nf-shard-compose/postgres-deployment.yaml

### I changed the ports in the postgres file to all be 5432

kubectl apply -f nf-shard-compose

# Move the local docker image to the kind cluster for testing
kind load docker-image nf-shard:local --name testing

# redeploy
kubectl apply -f nextjs-deployment.yaml
kubectl rollout restart deployment.apps/nextjs -n nf-shard

# Start nfs server (required for the nextflow pv to work)
sudo systemctl start nfs-server

# Example creating a deployment for new user
helm install user1-nfshard ./helm \
	--set user.name=user1 \
	--set user.username=user1 \
	--set user.password=user1pass \
	--set app.secretKey=$(openssl rand -hex 32) \
	--set app.defaultAccessToken=$(uuidgen)-$(uuidgen) \
	--set postgres.auth.password=postgres-user1-$(openssl rand -hex 8) \
	--set app.service.nodePort=30000 \
	--set nextflow.storage.nfs.enabled=true \
	--set nextflow.storage.nfs.server=172.18.0.1 \
	--set nextflow.storage.nfs.path=/srv/nfs/user1/nextflow

helm list
helm uninstall user1-nfshard
# To make this fully work simultaneously, you need to start the kind cluster with multiple ports, and map each new user to one of the ports
