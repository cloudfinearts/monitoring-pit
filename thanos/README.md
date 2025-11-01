# Mastering prometheus

https://enix.io/en/blog/thanos-k8s/

## Thanos
Access prometheus-like GUI for blocks in the bucket
k port-forward svc/thanos-query-frontend 9090:9090

gcloud storage buckets create gs://thanos-lab-bucket --location europe-central2

## Old
gcloud container clusters create lab \
    --num-nodes 3 --preemptible --machine-type e2-standard-2 \
    --monitoring NONE \
    --workload-pool=bob-lab-320120.svc.id.goog

helm upgrade -i -n prometheus --create-namespace mastering-prom prometheus/kube-prometheus-stack --values values.yaml