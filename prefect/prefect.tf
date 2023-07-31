# Bucket for anything to write or read from prefect
resource "google_storage_bucket" "prefect" {
  name     = "${var.project_id}-prefect-data"
  project  = var.project_id
  location = "australia-southeast1"
}

# A service account to be used by prefect flows
resource "google_service_account" "prefect_service_account" {
  account_id   = "prefect"
  display_name = "Prefect Service Account"
  description  = "Service Account used by prefect cloud and agent"
  project      = var.project_id
}

data "google_iam_policy" "prefect_bucket_admin" {
  binding {
    role = "roles/storage.objectAdmin"
    members = [
      "serviceAccount:${google_service_account.prefect_service_account.email}"
    ]
  }
}

# Provide service account access to work on bucket
resource "google_storage_bucket_iam_policy" "policy" {
  bucket      = google_storage_bucket.prefect.name
  policy_data = data.google_iam_policy.prefect_bucket_admin.policy_data
  depends_on  = [google_storage_bucket.prefect]
}

resource "google_project_iam_binding" "sa_user_binding" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${google_service_account.prefect_service_account.email}"
  ]
}

# Service account access as run admin to run cloud run jobs
resource "google_project_iam_binding" "cloud_run_binding" {
  project = var.project_id
  role    = "roles/run.admin"
  members = [
    "serviceAccount:${google_service_account.prefect_service_account.email}"
  ]
}

# Artifact registry to store flow code and dependencies as docker image
resource "google_artifact_registry_repository" "prefect_flows_repo" {
  provider      = google-beta
  project       = var.project_id
  location      = var.region
  repository_id = "prefect-repo"
  description   = "Repository for prefect flow images"
  format        = "DOCKER"
}
