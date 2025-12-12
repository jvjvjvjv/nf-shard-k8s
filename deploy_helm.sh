# Generate a standard-looking uuid
uuid=$(cat /proc/sys/kernel/random/uuid)
helm install user1-nfshard ./helm \
        --set user.name=user1 \
        --set user.username=user1 \
        --set user.password=user1pass \
        --set app.secretKey=$(openssl rand -hex 32) \
        --set app.defaultAccessToken="$uuid" \
	--set app.image.repository=registry.rc.umass.edu:5050/harmony/infrastructure/user-resources/nf-shard \
        --set app.image.tag=base \
	--set app.image.pullPolicy=Always \
        --set postgres.auth.password=postgres-user1-$(openssl rand -hex 8) \
	--set postgres.persistence.storageClass=vastdata-vast1 \
	--set nextflow.storage.storageClass=vastdata-vast1 \
        --set app.service.nodePort=30000
