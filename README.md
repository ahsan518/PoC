Below is the updated README reflecting the current repository structure, Terraform configuration, Helm values, and automation scripts.

Self-Hosted Weights & Biases on GKE
===================================

This repository demonstrates how to provision a **private** GKE cluster using **Terraform**, deploy a self-hosted instance of [Weights & Biases (W&B)](https://wandb.ai/) with **Helm**, and log sample runs via a Python script. This setup includes:

*   A **private** GKE cluster with no external node IPs.
    
*   **Shielded VM** enabled (to comply with constraints/compute.requireShieldedVm if enforced).
    
*   A **Google Cloud Storage (GCS) bucket** for artifact storage.
    
*   Automated deployment steps with optional scripts.
    

Prerequisites
-------------

*   **Google Cloud SDK (gcloud)** – Installed and authenticated with your GCP account.
    
*   **Terraform (>= 1.3.0)**
    
*   **Helm (>= v3)**
    
*   **kubectl** – For managing your Kubernetes cluster.
    
*   **Python 3** and **pip** – For running the wandb Python package.
    
*   **Organization Policies** (if applicable):
    
    *   Verify that constraints/compute.requireShieldedVm is enabled if your organization mandates it.
        
    *   Adjust node pool settings (e.g., enabling secure boot) as needed.
        

Repository Structure
--------------------

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   .  ├── terraform/  │   ├── providers.tf       # Providers & required versions (Google: >= 6.0.0, < 7.0.0)  │   ├── variables.tf       # Terraform variables  │   ├── main.tf            # GKE cluster, VPC, GCS bucket, service account, and Helm deployment (via null_resource)  │   ├── outputs.tf         # Terraform outputs (GKE cluster name, bucket name, service account email)  ├── helm/  │   ├── values.yaml        # Custom Helm values for W&B  │   └── wandb-ingress.yaml # Ingress resource for W&B  ├── scripts/  │   ├── setup.sh           # (Optional) Automates provisioning, Helm install, and ingress setup  │   ├── verify.sh          # (Optional) Verifies the W&B deployment on GKE  │   ├── log_runs.sh        # (Optional) Bash script to log 10 runs  │   └── log_runs.py        # Python script to log 10 runs via W&B SDK  └── README.md              # This file   `

Deployment Steps
----------------

There are two approaches to deploy the infrastructure and W&B instance: **automated** (using provided scripts) or **manual**.

### Option 1: Automated Deployment with Scripts

1.  git clone https://github.com/your-org/your-repo.gitcd your-repo
    
2.  chmod +x scripts/setup.sh./scripts/setup.shThis script will:
    
    *   Initialize and apply Terraform from the terraform/ directory.
        
    *   Fetch the GKE credentials.
        
    *   Install the W&B Helm chart (using values from helm/values.yaml).
        
    *   Apply the ingress configuration from helm/wandb-ingress.yaml.
        

### Option 2: Manual Deployment

1.  Change to the terraform directory and deploy the infrastructure:cd terraformterraform initterraform apply -auto-approveThis will provision:
    
    *   A **VPC** with a custom subnetwork (including secondary IP ranges for GKE pods and services).
        
    *   A **GKE cluster** with Shielded VMs and a custom node pool.
        
    *   A **GCS bucket** for W&B artifacts.
        
    *   A **service account** with the storage.admin role.
        
    *   A Terraform-managed Helm deployment via a null\_resource.
        
2.  Retrieve the cluster name from Terraform output and fetch the credentials:CLUSTER\_NAME=$(terraform output -raw gke\_name)gcloud container clusters get-credentials "$CLUSTER\_NAME" --region us-central1_(Adjust the region if necessary.)_
    
3.  Add the W&B Helm repository and update it:helm repo add wandb https://wandb.github.io/helm-chartshelm repo updateRetrieve the GCS bucket name from Terraform output and install the chart:BUCKET\_NAME=$(terraform -chdir=terraform output -raw gcs\_bucket)helm upgrade --install wandb wandb/wandb \\ --namespace wandb --create-namespace \\ --set storage.bucket="gs://$BUCKET\_NAME" \\ --values helm/values.yaml
    
4.  _(If using the provided ingress configuration)_kubectl apply -f helm/wandb-ingress.yaml
    

Verifying the Deployment
------------------------

You can verify that all components are running correctly by using either the provided script or manual kubectl commands.

### Using the Verification Script

Run the script to check pods, services, and ingress:

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   chmod +x scripts/verify.sh  ./scripts/verify.sh   `

### Manual Verification

Check the status of resources in the wandb namespace:

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   kubectl get pods -n wandb  kubectl get svc -n wandb  kubectl get ingress -n wandb   `

You can also view logs for the W&B deployment:

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   kubectl logs -n wandb -l app.kubernetes.io/name=wandb --tail=50   `

If you have set up an ingress (e.g., with the host wandb.example.com), open that URL in your browser to see the W&B login page.

Logging 10 Runs
---------------

The repository includes both a Python script and a shell wrapper to log sample runs to your self-hosted W&B instance.

### Python Script Approach

1.  pip install --upgrade wandb
    
2.  Replace the host with your domain if needed:wandb login --host https://wandb.example.com# Provide your API key when prompted
    
3.  python3 scripts/log\_runs.pyThis script creates 10 runs (named test-run-0 to test-run-9) under the project my-wandb-project.
    

### Shell Script Option

Alternatively, you can use the provided shell script:

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   chmod +x scripts/log_runs.sh  ./scripts/log_runs.sh   `

After running, verify that the runs appear in your W&B UI under the specified project.

Screenshots
-----------

Include or attach screenshots demonstrating your setup, such as:

*   **W&B Home Page** – Showing the login or project dashboard.
    
*   **W&B Project Page** – Listing the 10 logged runs.
    
*   **GCP Console** – Displaying the GKE cluster, VPC/subnets, and GCS bucket.
    

Cleanup
-------

To tear down the deployment and remove all provisioned resources:

1.  helm uninstall wandb -n wandb
    
2.  cd terraformterraform destroy -auto-approve
    
3.  **Confirm** that all resources have been removed in the GCP Console.
    