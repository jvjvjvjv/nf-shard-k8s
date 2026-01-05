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
        --set app.service.nodePort=30000 \
        --set postgres.auth.user=postgres \
        --set postgres.auth.password=password \
        --set postgres.auth.host=postgres-0.postgres.postgres-shared.svc.cluster.local
