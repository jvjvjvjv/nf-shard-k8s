# Quick one-liner
kubectl run -it --rm debug-pvc \
  --image=busybox \
  --restart=Never \
  -n nf-shard \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "debug",
      "image": "busybox",
      "command": ["sh"],
      "stdin": true,
      "tty": true,
      "volumeMounts": [{
        "name": "workspace",
        "mountPath": "/workspace"
      }]
    }],
    "volumes": [{
      "name": "workspace",
      "persistentVolumeClaim": {
        "claimName": "nextflow-pvc"
      }
    }]
  }
}' \
-- sh
