#!/bin/bash
set -e

# A script to provision GCP infrastructure using Terraform,
# and install Weights & Biases on a GKE cluster via Helm.

# 1. Terraform Deployment
echo "Initializing Terraform..."
cd terraform

terraform init
terraform apply -auto-approve

cd ..

# 2. Fetch GKE Credentials
echo "Fetching GKE cluster credentials from Terraform output..."
CLUSTER_NAME=$(terraform -chdir=terraform output -raw gke_name)
gcloud container clusters get-credentials "$CLUSTER_NAME" --region us-central1

# 3. Helm Installation
echo "Installing W&B with Helm..."
helm repo add wandb https://wandb.github.io/helm-charts
helm repo update

# Retrieve GCS Bucket name from Terraform output
GCS_BUCKET=$(terraform -chdir=terraform output -raw gcs_bucket)

helm upgrade --install wandb wandb/wandb \
  --namespace wandb --create-namespace \
  --set storage.bucket="gs://$GCS_BUCKET" \
  --values helm/values.yaml

# 4. Apply Ingress configuration
echo "Applying Ingress resource..."
kubectl apply -f helm/wandb-ingress.yaml

echo "Deployment Completed!"
