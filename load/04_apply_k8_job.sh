# Substitute environment variables in the Kubernetes job template and apply it
envsubst < k8s_job.yaml.template > k8s_job.yaml
kubectl apply -f k8s_job.yaml