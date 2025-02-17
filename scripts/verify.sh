#!/bin/bash
set -e

# A script to verify the status of the W&B deployment on your GKE cluster.

NAMESPACE="wandb"

echo "Verifying W&B Deployment..."

echo "--> Checking pods in $NAMESPACE namespace..."
kubectl get pods -n "$NAMESPACE"

echo "--> Checking services in $NAMESPACE namespace..."
kubectl get svc -n "$NAMESPACE"

echo "--> Checking ingress in $NAMESPACE namespace..."
kubectl get ingress -n "$NAMESPACE"

echo "--> Checking W&B logs..."
kubectl logs -n "$NAMESPACE" -l app.kubernetes.io/name=wandb --tail=50

echo "Verification Completed!"
