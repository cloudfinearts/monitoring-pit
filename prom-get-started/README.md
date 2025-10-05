# Prom get started

https://spacelift.io/blog/prometheus-operator

```
helm upgrade --install kube-prom prometheus/kube-prometheus-stack \
    --namespace monitoring --create-namespace --values values.yaml
```

sum without(device)(rate(node_network_receive_bytes_total[5m]))
equals to
sum by (container, endpoint, job...)(rate...)

meaning group by the labels having the same value


increase(prometheus_http_request_duration_seconds_bucket{le='0.1',handler='/-/healthy'}[5m])
breakdown query:
- get requests with (response) latency <= 100ms
- get samples over 5m range => range vector
- calculate total increase over time
- usefull for SLO when you divide _seconds_count for a percentile of requests

WARNING, kube-scheduler, kube-controller-manager could not be scraped for not having exposed ports
--bind-address=127.0.0.1

load app to get meaningful metrics
m=("aa" "bb" "cc"); while true; do num=$(( $RANDOM % 3 )); url="http://localhost:8080/${m[$num]}"; curl --silent $url >/dev/null; sleep 3; done