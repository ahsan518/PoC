output "gke_name" {
  description = "GKE Cluster Name"
  value       = module.gke.name
}

output "gcs_bucket" {
  description = "W&B Artifact Storage Bucket"
  value       = google_storage_bucket.wandb_bucket.name
}

output "service_account_email" {
  description = "IAM Service Account Email"
  value       = google_service_account.wandb_sa.email
}
