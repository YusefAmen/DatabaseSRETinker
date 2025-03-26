#!/bin/bash

# setup-cluster.sh
# Script to set up a Kind cluster with Consul, Prometheus, and Grafana for observability.
# Uses existing kind-config.yaml, values.yaml, and consul-service-monitor.yaml files.

set -e  # Exit on error

# Variables
CLUSTER_NAME="data-tinkering"
KIND_CONFIG_FILE="$HOME/DatabaseSRETinker/kind-config.yaml"
CONSUL_VALUES_FILE="$HOME/DatabaseSRETinker/kubernetes/consul/values.yaml"
PROMETHEUS_VALUES_FILE="$HOME/DatabaseSRETinker/kubernetes/prometheus/values.yaml"
SERVICEMONITOR_FILE="$HOME/DatabaseSRETinker/kubernetes/consul/consul-servicemonitor.yaml"
#LOKI_VALUES_FILE="$HOME/DatabaseSRETinker/kubernetes/loki/values.yaml"

# Define an array of required files
REQUIRED_FILES=(
  "$KIND_CONFIG_FILE"
  "$CONSUL_VALUES_FILE"
  "$PROMETHEUS_VALUES_FILE"
  "$SERVICEMONITOR_FILE"
)

# Verify that required files exist
echo "Verifying required files exist..."
#for file in "$KIND_CONFIG_FILE" "$CONSUL_VALUES_FILE" "$PROMETHEUS_VALUES_FILE" "$SERVICEMONITOR_FILE" "$LOKI_VALUES_FILE"; do
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Error: $file does not exist. Please create it before running this script."
    echo "Please ensure the file is created in the appropriate directory (e.g., ~/DatabaseSRETinker/kubernetes/<component>/)."
    exit 1
  fi
done

# Delete the existing Kind cluster (if it exists) and create a new one
echo "Deleting existing Kind cluster (if any)..."
kind delete cluster --name "$CLUSTER_NAME" || true

echo "Creating new Kind cluster..."
kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG_FILE"

# Deploy Consul
echo "Deploying Consul..."
helm install consul hashicorp/consul \
  --version 1.6.3 \
  --namespace consul \
  --create-namespace \
  --kube-context kind-data-tinkering \
  --values "$CONSUL_VALUES_FILE"

# Deploy Prometheus and Grafana
echo "Deploying Prometheus and Grafana..."
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 70.2.1 \
  --namespace monitoring \
  --create-namespace \
  --kube-context kind-data-tinkering \
  --values "$PROMETHEUS_VALUES_FILE"

# Apply the ServiceMonitor for Consul
echo "Applying Consul ServiceMonitor..."
kubectl apply -f "$SERVICEMONITOR_FILE" --context kind-data-tinkering

# Add annotations to consul-server service
#echo "Adding Prometheus scraping annotations to consul-server..."
#kubectl annotate svc consul-server -n consul --context kind-data-tinkering \
#  prometheus.io/scrape="true" \
#  prometheus.io/port="8500" \
#  --overwrite


# echo "Deploying Loki..."
#helm install loki grafana/loki \
#  --namespace monitoring \
#  --create-namespace \
#  --kube-context kind-data-tinkering \
#  --values "$LOKI_VALUES_FILE"

# Verify deployments
echo "Verifying Consul services..."
kubectl get svc -n consul --context kind-data-tinkering

echo "Verifying Prometheus/Grafana services..."
kubectl get svc -n monitoring --context kind-data-tinkering

echo "Verifying Consul pods..."
kubectl get pods -n consul --context kind-data-tinkering

echo "Verifying Prometheus/Grafana pods..."
kubectl get pods -n monitoring --context kind-data-tinkering

#echo "Verifying Prometheus/Grafana/Loki pods..."
#kubectl get pods -n monitoring --context kind-data-tinkering

echo "Verifying ServiceMonitor..."
kubectl get servicemonitor -n monitoring --context kind-data-tinkering

echo "Verifying Consul ServiceMonitor..."
kubectl get servicemonitor -n consul --context kind-data-tinkering

# Print access instructions
echo "Setup complete! Access the services at:"
echo "  - Consul UI: http://localhost:8500"
echo "  - Grafana: http://localhost:3000 (username: admin, password: admin123)"
echo "  - Prometheus: http://localhost:9090"
#echo "  - Loki: http://localhost:3100 (for verification)"
