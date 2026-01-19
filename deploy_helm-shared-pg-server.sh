# Generate a standard-looking uuid
uuid=$(cat /proc/sys/kernel/random/uuid)
userid='user1'
helm install "$userid"-nfshard ./helm_shared-pg-server --namespace nf-shard --create-namespace \
        --set user.name="$userid" \
        --set user.username="$userid" \
        --set user.password="$userid"pass \
        --set app.secretKey=$(openssl rand -hex 32) \
        --set app.defaultAccessToken="$uuid" \
	--set app.image.repository=registry.rc.umass.edu:5050/harmony/infrastructure/user-resources/nf-shard \
        --set app.image.tag=base \
	--set app.image.pullPolicy=Always \
        --set app.service.nodePort=30001 \
        --set postgres.auth.user=postgres \
        --set postgres.auth.password=password \
        --set postgres.auth.host=postgres-0.postgres.postgres-shared.svc.cluster.local
#        --set postgres.auth.host=postgres-0.postgres.postgres-shared.svc.cluster.local
