// VPC & Subnet configuration based on the terraform-google-wandb repo
resource "google_compute_network" "gke_vpc" {
  name                    = "wandb-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = "wandb-subnet"
  network       = google_compute_network.gke_vpc.id
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region

  // Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "gke-pods-range"
    ip_cidr_range = "10.1.0.0/16"
  }
  secondary_ip_range {
    range_name    = "gke-services-range"
    ip_cidr_range = "10.2.0.0/20"
  }
}

resource "google_compute_global_address" "gke_pods_range" {
  name          = "gke-pods-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.gke_vpc.id
}

resource "google_compute_global_address" "gke_services_range" {
  name          = "gke-services-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.gke_vpc.id
}

// Optional: Firewall rule to allow ingress traffic on port 8080 (W&B service port)
// This may be managed by GCE Ingress automatically but can be added for extra clarity.
resource "google_compute_firewall" "wandb_allow" {
  name    = "wandb-allow"
  network = google_compute_network.gke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  // Allow from all sources (adjust for your security needs)
  source_ranges = ["0.0.0.0/0"]
  // Optionally, if you want to target specific tags, add target_tags.
  // target_tags = ["wandb-server"]
}

# GKE Cluster Module
module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google"

  project_id          = var.project_id
  name                = var.gke_cluster_name
  deletion_protection = false
  region              = var.region
  network             = google_compute_network.gke_vpc.name
  subnetwork          = google_compute_subnetwork.gke_subnet.name

  ip_range_pods         = google_compute_global_address.gke_pods_range.name
  ip_range_services     = google_compute_global_address.gke_services_range.name

  remove_default_node_pool = true
  initial_node_count       = var.node_count

  node_pools = [
    {
      name         = "default-pool"
      machine_type = "n2-standard-4"
      node_count   = var.node_count
      auto_repair  = false
      auto_upgrade = true
      min_count    = 1
      max_count    = 3
      node_config = jsonencode({
        disk_type = "pd-standard"
        disk_size = 10
        shielded_instance_config = {
          enable_secure_boot          = false 
          enable_integrity_monitoring = false 
        }
      })
    }
  ]
}

// Google Cloud Storage bucket for W&B artifacts.
resource "google_storage_bucket" "wandb_bucket" {
  name                        = "wandb-artifacts-${var.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

// Service Account for W&B (used for storage access)
resource "google_service_account" "wandb_sa" {
  account_id   = "wandb-service-account"
  display_name = "Service Account for W&B"
}

// Grant the service account storage admin rights.
resource "google_project_iam_member" "wandb_storage" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.wandb_sa.email}"
}
