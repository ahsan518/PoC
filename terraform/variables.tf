variable "project_id" {
  description = "GCP Project ID"
  type        = string
  }

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "gke_cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "wandb-cluster"
}

variable "node_count" {
  description = "Number of GKE nodes"
  type        = number
  default     = 1
}