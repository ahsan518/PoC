Self-Hosted Weights & Biases on GKE
===================================

This repository demonstrates how to provision a **private** GKE cluster using **Terraform**, deploy a self-hosted instance of [Weights & Biases (W&B)](https://wandb.ai/) with **Helm**, and log sample runs via a Python script. This setup includes:

-   A **private** GKE cluster with no external node IPs.
-   **Shielded VMs** (if enforced by your organization).
-   A **Google Cloud Storage (GCS) bucket** for artifact storage.
-   Automated deployment steps with supporting scripts.

* * * * *

Prerequisites
-------------

-   **Google Cloud SDK (gcloud)** -- Installed and authenticated with your GCP account.
-   **Terraform (>= 1.3.0)**
-   **Helm (>= v3)**
-   **kubectl** -- For managing your Kubernetes cluster.
-   **Python 3** and **pip** -- For running the wandb Python package.
-   **Organization Policies** (if applicable):
    -   Verify that `constraints/compute.requireShieldedVm` is enabled if required.
    -   Adjust node pool settings (e.g., enabling secure boot) as needed.

* * * * *

Repository Structure
--------------------

```
.
├── terraform/
│   ├── providers.tf       # Providers & required versions (Google: >= 6.0.0, < 7.0.0)
│   ├── variables.tf       # Terraform variables
│   ├── main.tf            # GKE cluster, VPC, GCS bucket, service account, etc.
│   ├── outputs.tf         # Terraform outputs (GKE cluster name, bucket name, etc.)
├── helm/
│   ├── values.yaml        # Custom Helm values for W&B
│   └── wandb-ingress.yaml # Ingress resource for W&B
├── scripts/
│   ├── setup.sh           # (Optional) Automates provisioning, Helm install, and ingress setup
│   ├── verify.sh          # (Optional) Verifies the W&B deployment on GKE
│   ├── log_runs.sh        # (Optional) Bash script to log 10 runs
│   └── log_runs.py        # Python script to log 10 runs via W&B SDK
└── README.md              # This file

```

* * * * *

Deployment Steps
----------------

There are two approaches to deploy the infrastructure and W&B instance: **automated** (using provided scripts) or **manual**.

### Option 1: Automated Deployment with Scripts

1.  **Clone the Repository:**

    ```
    git clone https://github.com/your-org/your-repo.git
    cd your-repo

    ```

2.  **Run the Setup Script:**

    Make the setup script executable and run it:

    ```
    chmod +x scripts/setup.sh
    ./scripts/setup.sh

    ```

    This script will:

    -   Initialize and apply Terraform (from the `terraform/` directory).
    -   Fetch the GKE credentials.
    -   Install the W&B Helm chart (using values from `helm/values.yaml`).
    -   Apply the ingress configuration from `helm/wandb-ingress.yaml`.

### Option 2: Manual Deployment

1.  **Deploy the Infrastructure with Terraform:**

    Change to the terraform directory and initialize/apply the configuration:

    ```
    cd terraform
    terraform init
    terraform apply -auto-approve

    ```

    This provisions:

    -   A **VPC** with a custom subnetwork (with secondary IP ranges for GKE pods and services).
    -   A **GKE cluster** with Shielded VMs (if required) and a custom node pool.
    -   A **GCS bucket** for W&B artifacts.
    -   A **service account** with the storage.admin role.
2.  **Fetch Cluster Credentials:**

    Retrieve the cluster name from Terraform outputs and fetch credentials:

    ```
    CLUSTER_NAME=$(terraform output -raw gke_name)
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region $(terraform output -raw region)

    ```

3.  **Deploy the W&B Helm Chart:**

    Add and update the W&B Helm repository:

    ```
    helm repo add wandb https://wandb.github.io/helm-charts
    helm repo update

    ```

    Retrieve the GCS bucket name from Terraform outputs and install the chart:

    ```
    BUCKET_NAME=$(terraform -chdir=terraform output -raw gcs_bucket)
    helm upgrade --install wandb wandb/wandb\
      --namespace wandb --create-namespace\
      --set storage.bucket="gs://${BUCKET_NAME}"\
      --values ../helm/values.yaml

    ```

4.  **Apply the Ingress Configuration:**

    ```
    kubectl apply -f ../helm/wandb-ingress.yaml

    ```

    *Note:* Ensure that your ingress host (e.g., `wandb.example.com`) is correctly configured in DNS or your hosts file.

* * * * *

Verifying the Deployment
------------------------

You can verify that all components are running correctly by using the provided verification script or manual kubectl commands.

### Using the Verification Script

```
chmod +x scripts/verify.sh
./scripts/verify.sh

```

This script checks:

-   Pods in the `wandb` namespace.
-   Services and ingress configuration.
-   Recent logs for troubleshooting.

### Manual Verification

Check the status of resources in the `wandb` namespace:

```
kubectl get pods -n wandb
kubectl get svc -n wandb
kubectl get ingress -n wandb

```

View logs for the W&B deployment:

```
kubectl logs -n wandb -l app.kubernetes.io/name=wandb --tail=50

```

If you have set up an ingress (e.g., with host `wandb.example.com`), open that URL in your browser to view the W&B login page.

* * * * *

Logging 10 Runs
---------------

The repository includes both a Python script and a shell wrapper to log sample runs to your self-hosted W&B instance.

### Python Script Approach

1.  Install the wandb package:

    ```
    pip install --upgrade wandb

    ```

2.  Log in to your W&B server (replace the host with your domain if necessary):

    ```
    wandb login --host https://wandb.example.com

    ```

3.  Run the Python script:

    ```
    python3 scripts/log_runs.py

    ```

This script logs 10 runs (named `test-run-0` to `test-run-9`) under the project `my-wandb-project`.

### Shell Script Option

Alternatively, run the provided shell script:

```
chmod +x scripts/log_runs.sh
./scripts/log_runs.sh

```

After running, verify that the runs appear in your W&B UI under the specified project.

* * * * *

Screenshots
-----------

Include or attach screenshots demonstrating your setup, such as:

-   **W&B Home Page** -- Showing the login or project dashboard.
-   **W&B Project Page** -- Listing the 10 logged runs.
-   **GCP Console** -- Displaying the GKE cluster, VPC/subnets, and GCS bucket.

* * * * *

Cleanup
-------

To tear down the deployment and remove all provisioned resources:

1.  Uninstall the Helm release:

    ```
    helm uninstall wandb -n wandb

    ```

2.  Destroy the Terraform-managed infrastructure:

    ```
    cd terraform
    terraform destroy -auto-approve

    ```

3.  Confirm that all resources have been removed in the GCP Console.

* * * * *

Additional Notes
----------------

-   **Autoscaling:**\
    The GKE cluster is configured via Terraform with autoscaling enabled for the node pool. The default settings allow a minimum of 1 node and a maximum of 5 nodes. Adjust these values in `terraform/main.tf` as needed.

-   **Service Account:**\
    The deployment uses a manually created service account (`wandb-service-account`). Ensure it exists in the `wandb` namespace if you set `serviceAccount.create` to `false` in your Helm values.

-   **Resource Requirements:**\
    If you encounter scheduling issues (e.g., insufficient CPU/memory), consider increasing the maximum node count or adjusting the resource requests/limits in `helm/values.yaml`.

* * * * *