# SLMs on GKE - PromQL Queries

## vLLM Pods & Infrastructure Health

### vLLM Pods Serving + Pending
* **Running Pod Count by Instance**:
  ```promql
  count by (app_kubernetes_io_instance) (vllm:num_requests_running{container!="admission", cluster=~"$slm_cluster"})
  ```
* **Pending Pod Count (GPU Stockout Detection)**:
  ```promql
  count(groundcover_kube_pod_status_unschedulable{cluster=~"$slm_cluster", namespace="default"} == 1 and on(pod, namespace, cluster) groundcover_kube_pod_uptime{cluster=~"$slm_cluster", namespace="default"} > 800) or vector(0)
  ```

### GPU Replicas By Pool
* **Active GPU Nodes Grouped by Machine Pool**:
  ```promql
  count by (pool) (max by (node, pool) (label_replace(groundcover_kube_node_status_condition{cluster=~"$slm_cluster", condition="Ready", node=~".*slm-gpu.*"}, "pool", "slm-gpu-$1", "node", ".*slm-gpu-([a-z0-9-]+?)-[0-9a-f]{8}-[a-z0-9]+$")))
  ```

### Container Resource Usage (avg/max)
* **Max Pod CPU Request Usage %**:
  ```promql
  max(groundcover_container_cpu_request_usage_percent{cluster=~"$slm_cluster", container=~"$slm_app"})
  ```
* **Avg Pod CPU Request Usage %**:
  ```promql
  avg(groundcover_container_cpu_request_usage_percent{cluster=~"$slm_cluster", container=~"$slm_app"})
  ```
* **Max Container Memory Used % of Request**:
  ```promql
  max by (pod)(groundcover_container_memory_request_used_percent{cluster=~"$slm_cluster", container=~"$slm_app"})
  ```
* **Container Restarts (1-hour increase)**:
  ```promql
  sum by (pod)(increase(groundcover_container_restart_count_total{cluster=~"$slm_cluster", namespace="default"}[1h]))
  ```

## Queue Depth & Capacity Scaling Metrics

### Total Queue Depth
* **Total Waiting Requests Grouped by Status**:
  ```promql
  sum (vllm:num_requests_waiting{container!="admission", cluster=~"$slm_cluster"}) by (status)
  ```

### Per-Pod Queue Depth (min/avg/max)
* **Maximum Pod Queue Depth**:
  ```promql
  max(vllm:num_requests_waiting{container!="admission", cluster=~"$slm_cluster"})
  ```
* **Average Pod Queue Depth**:
  ```promql
  avg(vllm:num_requests_waiting{container!="admission", cluster=~"$slm_cluster"})
  ```

### Queue Skew (Hot-Pod Detection)
* **Skew Ratio — max waiting / median waiting** (leading indicator for p99 latency breaches; spikes above ~5 correlated with every >90s p99 on 2026-07-14/15/16; only meaningful at ≥2 replicas):
  ```promql
  max(vllm:num_requests_waiting{container!="admission", cluster=~"$slm_cluster", app_kubernetes_io_instance="$slm_app"}) / clamp_min(quantile(0.5, vllm:num_requests_waiting{container!="admission", cluster=~"$slm_cluster", app_kubernetes_io_instance="$slm_app"}), 1)
  ```
* **Per-Pod Waiting Queue Depth** (companion to skew ratio — shows absolute depth and which pod is hot):
  ```promql
  max by (pod) (vllm:num_requests_waiting{container!="admission", cluster=~"$slm_cluster", app_kubernetes_io_instance="$slm_app"})
  ```

### Queue Composition by Reason
* **Waiting Queue Splitting (Capacity vs. Deferred Batch Siblings)**:
  ```promql
  sum by (reason)(vllm:num_requests_waiting_by_reason{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])
  ```

## Throughput & Cache Performance

### Server Request Rate
* **Total Finished Requests Rate (req/s)**:
  ```promql
  sum(rate(vllm:request_success_total{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval]))
  ```
* **Clean Stop Finished Requests Rate (req/s)**:
  ```promql
  sum(rate(vllm:request_success_total{container!="admission", cluster=~"$slm_cluster", finished_reason="stop"}[$__rate_interval]))
  ```

### Token Throughput & Request Characteristics
* **Input/Prompt Token Flow Rate (tokens/s)**:
  ```promql
  sum(rate(vllm:prompt_tokens_total{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval]))
  ```
* **Output/Generation Token Flow Rate (tokens/s)**:
  ```promql
  sum(rate(vllm:generation_tokens_total{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval]))
  ```
* **Per-Replica Total Throughput (req/s/pod)**:
  ```promql
  sum(rate(vllm:generation_tokens_total[10m])) / count(vllm:num_requests_running)
  ```
* **Generation Throughput per Active GPU (tokens/s/pod)**:
  ```promql
  sum(rate(vllm:generation_tokens_total{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])) / clamp_min(count(vllm:num_requests_running{container!="admission", cluster=~"$slm_cluster"}), 1)
  ```
* **Average Output Tokens per General Request**:
  ```promql
  sum(rate(vllm:request_generation_tokens_sum{container!="admission", cluster=~"$slm_cluster"}[15m])) / clamp_min(sum(rate(vllm:request_generation_tokens_count{container!="admission", cluster=~"$slm_cluster"}[15m])), 1)
  ```

### Cache Efficiency
* **Prefix Cache Hit Rate Percentage**:
  ```promql
  100 * sum(rate(vllm:prefix_cache_hits_total{container!="admission", cluster=~"$slm_cluster"}[10m])) / clamp_min(sum(rate(vllm:prefix_cache_queries_total{container!="admission", cluster=~"$slm_cluster"}[10m])), 1)
  ```
* **KV Cache Allocation/Utilization Fraction**:
  ```promql
  avg(vllm:kv_cache_usage_perc{container!="admission", cluster=~"$slm_cluster"})
  ```

## Latency & Performance Quantiles

### E2E Request Latency (p50/p95/p99)
* **p50 End-to-End Latency**:
  ```promql
  histogram_quantile(0.5, sum by (le) (rate(vllm:e2e_request_latency_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))
  ```
* **p95 End-to-End Latency**:
  ```promql
  histogram_quantile(0.95, sum by (le) (rate(vllm:e2e_request_latency_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))
  ```
* **p99 End-to-End Latency**:
  ```promql
  histogram_quantile(0.99, sum by (le) (rate(vllm:e2e_request_latency_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))
  ```

### Processing Stage Latencies
* **Queue Wait Time (p50 / p99)**:
  ```promql
  histogram_quantile(0.5, sum by (le) (rate(vllm:request_queue_time_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))

  histogram_quantile(0.99, sum by (le) (rate(vllm:request_queue_time_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))
  ```
* **Time To First Token / Prefill Responsiveness (p50 / p95 / p99)**:
  ```promql
  histogram_quantile(0.5, sum by (le) (rate(vllm:time_to_first_token_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))

  histogram_quantile(0.95, sum by (le) (rate(vllm:time_to_first_token_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))

  histogram_quantile(0.99, sum by (le) (rate(vllm:time_to_first_token_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))
  ```
* **Time Per Output Token / Decode Speed (p50 / p95 / p99)**:
  ```promql
  histogram_quantile(0.5, sum by (le) (rate(vllm:request_time_per_output_token_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))

  histogram_quantile(0.95, sum by (le) (rate(vllm:request_time_per_output_token_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))

  histogram_quantile(0.99, sum by (le) (rate(vllm:request_time_per_output_token_seconds_bucket{container!="admission", cluster=~"$slm_cluster"}[$__rate_interval])))
  ```

### In-Flight Concurrency per Pod
* **Max/Avg/Min Pod Load Concurrency**:
  ```promql
  max(vllm:num_requests_running{container!="admission", cluster=~"$slm_cluster"})

  avg(vllm:num_requests_running{container!="admission", cluster=~"$slm_cluster"})

  min(vllm:num_requests_running{container!="admission", cluster=~"$slm_cluster"})
  ```

## Error Tracking & Failure Modes

### vLLM Abnormal Finish Reasons
* **Request Failures / Aborts / Repetitions (req/s)**:
  ```promql
  sum by (finished_reason)(rate(vllm:request_success_total{container!="admission", cluster=~"$slm_cluster", finished_reason=~"error|abort|repetition"}[$__rate_interval]))
  ```

### Coordinator & HPA Error Tracking
* **Coordinator Terminal Failures (15m Increase)**:
  ```promql
  sum by (flow_type) (increase(dlp_coordinator_fatal_errors_per_component{component="categorizer", cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})"}[15m]))
  ```
* **SLM Client Error Percentage by Operation**:
  ```promql
  100 * sum by (operation)(rate(dlp_categorizer_slm_requests_total{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})", status!="success"}[15m])) / clamp_min(sum by (operation)(rate(dlp_categorizer_slm_requests_total{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})"}[15m])), 0.0001)
  ```
* **vLLM Preemptions Rate / Capacity Collapse Warning (req/s)**:
  ```promql
  sum(rate(vllm:num_preemptions_total{container!="admission", cluster=~"$slm_cluster"}[15m]))
  ```

## PubSub Client Backlog & Scaling Signals

### Categorizer Subscriptions Scaling Signals
* **Oldest Unacked Message Age (Primary Autoscaler HPA Key Metric)**:
  ```promql
  max by (subscription_id)(gcp_pubsub_subscription_pubsub_googleapis_com_subscription_oldest_unacked_message_age{subscription_id=~".*${Customer}.*categorizer-sub", subscription_id!~"ch-(${onprem_ignore})-.*"})
  ```
* **Unacked Backlog Message Depth (Context Only)**:
  ```promql
  max by (subscription_id)(gcp_pubsub_subscription_pubsub_googleapis_com_subscription_num_undelivered_messages{subscription_id=~".*${Customer}.*categorizer-sub", subscription_id!~"ch-(${onprem_ignore})-.*"})
  ```

### Data Pipeline Flow Tracking
* **CI Processing Dead-Letter Queue Growth Rate (1h increase)**:
  ```promql
  sum by (subscription_id)(increase(gcp_pubsub_subscription_pubsub_googleapis_com_subscription_num_undelivered_messages{subscription_id=~".*ci_stack.v1.ci_processing_response-deadletter-sub", subscription_id!~"ch-(${onprem_ignore})-.*"}[1h]))
  ```
* **Message Delivery Rate vs. Acknowledgment Rate**:
  ```promql
  sum by (subscription_id)(rate(gcp_pubsub_subscription_pubsub_googleapis_com_subscription_sent_message_count{subscription_id=~".*${Customer}.*categorizer-sub", subscription_id!~"ch-(${onprem_ignore})-.*"}[10m]))

  sum by (subscription_id)(rate(gcp_pubsub_subscription_pubsub_googleapis_com_subscription_ack_message_count{subscription_id=~".*${Customer}.*categorizer-sub", subscription_id!~"ch-(${onprem_ignore})-.*"}[10m]))
  ```

## Client-Side Categorizer Workload Metrics

### Client Request & Execution Profiles
* **Successful SLM Request Rates by Functional Operation**:
  ```promql
  sum by (operation)(rate(dlp_categorizer_slm_requests_total{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})", status="success"}[$__rate_interval]))
  ```
* **Client-Observed Network + Execution Latency (p50/p90/p99)**:
  ```promql
  histogram_quantile(0.50, sum by (le, operation)(rate(dlp_categorizer_slm_request_latency_seconds_bucket{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})"}[30m])))

  histogram_quantile(0.90, sum by (le, operation)(rate(dlp_categorizer_slm_request_latency_seconds_bucket{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})"}[30m])))

  histogram_quantile(0.99, sum by (le, operation)(rate(dlp_categorizer_slm_request_latency_seconds_bucket{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})"}[30m])))
  ```
* **Total Tokens Managed by Client per Operation**:
  ```promql
  sum by (operation)(rate(dlp_categorizer_slm_tokens_total{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})"}[$__rate_interval]))
  ```
* **p95 Batch Evaluation Size (labels/file)**:
  ```promql
  histogram_quantile(0.95, sum by (le, operation)(rate(dlp_categorizer_slm_batch_size_bucket{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})"}[30m])))
  ```
* **Generative Output Length vs max_tokens (Truncation / Summary Cutoff Watch)**:
  ```promql
  sum by (operation)(rate(dlp_categorizer_slm_tokens_total{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})", token_type="completion", operation!="data_type"}[15m])) / clamp_min(sum by (operation)(rate(dlp_categorizer_slm_requests_total{cluster=~".*$Customer", cluster!~".*-(${onprem_ignore})", status="success", operation!="data_type"}[15m])), 1)
  ```

## Fleet Autoscaling & Cluster Saturation Metrics

### Correlation Framework
* **Ready Replicas for Dlp-Categorizer**:
  ```promql
  sum(groundcover_kube_deployment_status_replicas_ready{deployment="dlp-categorizer", clusterId=~".*$Customer", clusterId!~".*-(${onprem_ignore})", env=~".*$pg"})
  ```
* **Total Number of Capacity-Constrained Customers At Max Replica Cap (≥30)**:
  ```promql
  count(max by (clusterId) (groundcover_kube_deployment_status_replicas_ready{deployment="dlp-categorizer",clusterId=~".*$Customer", clusterId!~".*-(${onprem_ignore})", env=~".*$pg"}) >= 30)
  ```

### Customer Replica Distribution (Stacked Buckets)
* **Count of customers utilizing 1–15 replicas**:
  ```promql
  count(max by (clusterId) (groundcover_kube_deployment_status_replicas_ready{deployment="dlp-categorizer",clusterId=~".*$Customer", clusterId!~".*-(${onprem_ignore})", env=~".*$pg"}) < 15)
  ```
* **Count of customers utilizing 15–25 replicas**:
  ```promql
  count((max by (clusterId) (groundcover_kube_deployment_status_replicas_ready{deployment="dlp-categorizer",clusterId=~".*$Customer", clusterId!~".*-(${onprem_ignore})", env=~".*$pg"}) >= 15) and (max by (clusterId) (groundcover_kube_deployment_status_replicas_ready{deployment="dlp-categorizer",clusterId=~".*$Customer", clusterId!~".*-(${onprem_ignore})", env=~".*$pg"}) < 25))
  ```
* **Count of customers utilizing 25–30 replicas**:
  ```promql
  count((max by (clusterId) (groundcover_kube_deployment_status_replicas_ready{deployment="dlp-categorizer",clusterId=~".*$Customer", clusterId!~".*-(${onprem_ignore})", env=~".*$pg"}) >= 40) and (max by (clusterId) (groundcover_kube_deployment_status_replicas_ready{deployment="dlp-categorizer",clusterId=~".*$Customer", clusterId!~".*-(${onprem_ignore})", env=~".*$pg"}) < 30))
  ```
* **Instant Snapshot of Top Replica Leader Customers Maxed Out at Ceiling (≥30)**:
  ```promql
  max by (clusterId) (groundcover_kube_deployment_status_replicas_ready{deployment="dlp-categorizer",clusterId=~".*$Customer", clusterId!~".*-(${onprem_ignore})", env=~".*$pg"}) >= 30
  ```

### Per-Customer Migration Strategy
* **Top 25 Heavy Customer Load Profiles (files/s proxy)**:
  ```promql
  topk(25, sum by (cluster) (rate(dlp_categorizer_input_files_total{cluster=~".*$Customer", cluster!~".*(${onprem_ignore})"}[$__rate_interval])))
  ```

## Hardware Node Acceleration Metrics (GKE Cloud Monitoring)

### GPU Duty Cycle — HARDWARE
* **Average Fleet Accelerator Hardware Duty Cycle %**:
  ```promql
  avg by (node_name) (avg_over_time(gcp_kubernetes_io_node_accelerator_duty_cycle{node_name=~".*slm-gpu.*"}[5m]))
  ```
* **Per-Node Hardware Duty Cycle % (Uncovering Routing Imbalances)**:
  ```promql
  max by (node_name) ({__name__=~"gcp_.*node_accelerator_duty_cycle", node_name=~".*slm-gpu.*"})
  ```

### GPU VRAM Used (bytes) — HARDWARE
* **Absolute Accelerator Memory Allocation per Node**:
  ```promql
  sum by (node_name) ({__name__=~"gcp_.*node_accelerator_memory_used", node_name=~".*slm-gpu.*"}[30m])
  ```
